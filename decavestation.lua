--COMMAND TURTLE CODE
--WIRED VERSION
local computercraftTurtleName = "computercraft:turtle_normal"
local computercraftAdvancedTurtleName = "computercraft:turtle_advanced"
local computercraftDiskDrive = "computercraft:peripheral"
local computercraftDisk = "computercraft:disk_expanded"

--This will determine the how much fuel is left in a turtle
--Returns if it is able to start/move
function determine_fuel_state()
	local able_to_start = true
	local fuel_amt = turtle.getFuelLevel()
	if fuel_amt == 0 then
		able_to_start = false
		print("This turtle does not have any fuel")
	end
	return able_to_start
end

--Method for the command turtle that controls the miner turtles
function commandTurtle()
	--Prints amount of fuel remaining to user
	local continue_process = false
	local fuel_amt = turtle.getFuelLevel()
	print("Fuel: " .. (fuel_amt/turtle.getFuelLimit())*100 .. "%")

	local chest_with_fuel = false
	local state, block = turtle.inspectDown()
	--Checks if block underneath is a chest block
	if string.find(block.name, "chest") ~= nil then
		chest_with_fuel = true
	end
	--While loop that runs to check for a chest to be placed under
	while chest_with_fuel == false do
		print("Place a chest with fuel under")
		print("Checking in 3 seconds")
		sleep(1)
		print("Checking in 2 seconds")
		sleep(1)
		print("Checking in 1 second")
		sleep(1)
		state, block = turtle.inspectDown()
		if string.find(block.name, "chest") ~= nil then
			chest_with_fuel = true
		end
	end

	--Asks user number of turtles to deploy, and if shulkers are to be used
	io.write("Deploy amount?: ")
	local numTurtles = tonumber(io.read())
	io.write("Use Shulkers?: ")
	local use_shulker = io.read()

	if numTurtles <= 0 then
		return
	end

	local turtles_in_shulker = false
	local found_disk_drive = false
	local found_disk = false
	local turtle_found = false
	local found_shulker = false

	local turtles_in_inv = 0
	--If shulkers not used, inventory of command turtle will be iterated for items needed
	if use_shulker == "no" then
		for slot=1, 16 do
			turtle.select(slot)
			local item = turtle.getItemDetail()
			if item ~= nil then
				--If item in slot is a turtle, turtles found becomes true, and amount of turtles found will be added
				if (item.name == computercraftTurtleName or item.name == computercraftAdvancedTurtleName) then
					local amt = item.count
					turtle_found = true
					turtles_in_inv = turtles_in_inv + amt
				--If the item is a disk_drive, it will change boolean to true and keep note of the slot
				elseif item.name == computercraftDiskDrive then
					found_disk_drive = true
					disk_drive_slot = slot
				--If the item is a disk, it will change boolean to true and keep note of the slot
				elseif item.name == computercraftDisk then
					found_disk = true
					disk_slot = slot
				end
			end
		end
		--Checks if there are the amount of turtles found satisfy the number of turtles wanting to be deployed
		if turtles_in_inv < numTurtles then
			print("Only " .. turtles_in_inv .. " turtles available...")
			io.write("Deploy all " .. turtles_in_inv .. " turtles anyways?: ")
			answer = io.read()

			if answer == "yes" then
				numTurtles = turtles_in_inv
				continue_process = true

			elseif answer == "no" then
				print("Shutting down...")
				return
			else
				print("Invalid answer, shutting down...")
				return
			end
		end

	--Code block for using a shulker holding turtles instead of command turtle inventory
	elseif use_shulker == "yes" then
		for slot=1, 16 do
			turtle.select(slot)
			local item = turtle.getItemDetail()
			if item ~= nil then
				if item.name == computercraftDiskDrive then
					found_disk_drive = true
					disk_drive_slot = slot

				elseif item.name == computercraftDisk then
					found_disk = true
					disk_slot = slot

				elseif string.find(item.name, "shulker_box") ~= nil then
					found_shulker = true
					continue_process = true

				end
			end
		end
	end

	if not turtle_found and not found_shulker then
		print("Missing needed items.")
		print("Shutting down...")
		sleep(3)
		return
	end

	payloadSetup(disk_drive_slot, disk_slot)
	return continue_process, numTurtles, found_shulker
end
--Sets up placement of payload device to send to mining turtles
function payloadSetup(disk_drive_slot, disk_slot)
	turtle.back()
	turtle.up()
	turtle.select(disk_drive_slot)
	turtle.place()
	turtle.select(disk_slot)
	turtle.drop()
	turtle.down()

end

function deployTurtles(numTurtles, found_shulker)
	local deployed_turtles = 0

	if found_shulker then
		local shulker_slots = {}
		local current_shulker = 1
		-- finds and adds slot of shulker to list
		for slot=1, 16 do
			turtle.select(slot)
			local item = turtle.getItemDetail()
			if item ~= nil then
				if string.find(item.name, "shulker_box") ~= nil then
					table.insert(shulker_slots, slot)
				end
			end
		end
		turtle.select(shulker_slots[current_shulker])
		turtle.placeUp()
		current_shulker = current_shulker + 1

		-- collects turtles until inventory full, but only until turtles to deploy have been satisfied
		while deployed_turtles < numTurtles do
			if turtle.suckUp() then
				local state, block = turtle.inspect()
				while state do
					state, block = turtle.inspect()
				end

				turtle.place()
				Turtle = peripheral.wrap("front")
				Turtle.turnOn()
				deployed_turtles = deployed_turtles + 1
				term.clear()
				term.setCursorPos(1,1)
				print("Deployed " .. deployed_turtles .. "/" .. numTurtles .. " turtles")

			elseif not turtle.suckUp() then
				turtle.digUp()
				turtle.select(shulker_slots[current_shulker])
				turtle.placeUp()
				current_shulker = current_shulker + 1
			end
		end

	elseif not turtles_in_shulker then
		for slot=1, 16 do
			turtle.select(slot)
			local slot_item = turtle.getItemDetail()
			if slot_item ~= nil then
				if string.find(slot_item.name, "turtle") ~= nil then
					local turtle_in_slot = turtle.getItemDetail()

					if turtle_in_slot.count > 1 then

						for current_turtle=1, turtle_in_slot.count do
							local state, block = turtle.inspect()
							while state == true do
								state, block = turtle.inspect()
							end
							turtle.place()
							Turtle = peripheral.wrap("front")
							Turtle.turnOn()

							--INDIVIDUAL CODE IS LOADED TO TURTLES VIA DISKDRIVE
							deployed_turtles = deployed_turtles + 1
							if deployed_turtles == numTurtles then
								break
							end
						end

					elseif turtle_in_slot.count == 1 then
						local state, block = turtle.inspect()
						while state == true do
							state, block = turtle.inspect()
						end
						turtle.place()
						Turtle = peripheral.wrap("front")
						Turtle.turnOn()

						--INDIVIDUAL CODE IS LOADED TO TURTLES VIA DISKDRIVE
						deployed_turtles = deployed_turtles + 1
					end
				end
			end

			if deployed_turtles == numTurtles then
				break
			end
		end
	end
end


function recollect(numTurtles, found_shulker)
	local not_finished = true
	local turtles_collected = 0
	local state, block = turtle.inspect()

	if found_shulker then
		turtle.select(1)
		local slot1 = turtle.getItemDetail()
		if slot1 ~= nil then
			for slot=2, 16 do
				turtle.select(slot)
				local item = turtle.getItemDetail()
				if item == nil then
					turtle.select(1)
					turtle.transferTo(slot)
					break
				end
			end
		end

		local shulker_slot_list = getItemIndex("shulker_box")
		local shulker_being_used = 1

		turtle.select(1)
		term.clear()
		term.setCursorPos(1,1)

		print("Waiting for turtles...")
		while turtles_collected < numTurtles do
			if state then
				if (block.name == computercraftTurtleName or block.name == computercraftAdvancedTurtleName) then
					turtle_dropped_load = false
					while not turtle_dropped_load do
						os.pullEvent("redstone")
						turtle_dropped_load = true
					end
					turtle.dig()
					turtles_collected = turtles_collected + 1
					term.clear()
					term.setCursorPos(1,1)
					print("Recollected: " .. turtles_collected .. "/" .. numTurtles)
					--Checks is shulker above is full, if it is, breaks and places a new one down for collection
					if not turtle.dropUp() then
						currently_equiped_slot = turtle.getSelectedSlot()
						turtle.digUp()
						turtle.select(shulker_slot_list[shulker_being_used])
						turtle.placeUp()
						turtle.select(currently_equiped_slot)
						turtle.dropUp()
						shulker_being_used = shulker_being_used + 1
					end
				end
			end
			state, block = turtle.inspect()
		end

		turtle.digUp()
		turtle.forward()

	elseif not found_shulker then
		term.clear()
		term.setCursorPos(1,1)

		print("Waiting for turtles...")

		while turtles_collected < numTurtles do
			if state == true then
				if (block.name == computercraftTurtleName or block.name == computercraftAdvancedTurtleName) then
					turtle_dropped_load = false
					while not turtle_dropped_load do
						os.pullEvent("redstone")
						turtle_dropped_load = true
					end
					turtle.dig()
					turtles_collected = turtles_collected + 1
					term.clear()
					term.setCursorPos(1,1)
					print("Recollected: " .. turtles_collected .. "/" .. numTurtles)
				end
			end
			state, block = turtle.inspect()
		end
		turtle.forward()
	end
end

function getItemIndex(item_name)
	found_item = false
	item_slot_list = {}
	for slot=1, 16 do
		turtle.select(slot)
		item_in_slot = turtle.getItemDetail()
		if item_in_slot ~= nil then
			if string.find(item_in_slot.name, item_name) ~= nil then
				table.insert(item_slot_list, slot)
				found_item = true
			end
		end
	end
	if found_item then
		return item_slot_list
	else
		return found_item
	end

end

function main()
	local start_state = determine_fuel_state()
	if start_state then
		continue_process, numTurtles, found_shulker = commandTurtle()
		if continue_process then
			deployTurtles(numTurtles, found_shulker)

			local state, block = turtle.inspect()
			while state == true do
				state, block = turtle.inspect()
			end

			turtle.forward()
			turtle.suckUp()
			turtle.digUp()
			turtle.back()
		end
	end

	recollect(numTurtles, found_shulker)

	print("---------------COMPLETED---------------")
end


main()