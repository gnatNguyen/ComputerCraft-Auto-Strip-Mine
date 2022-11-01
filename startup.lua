--COMMAND TURTLE CODE
--WIRELESS VERSION
--NEEDS A MOBILE TABLET ITEM
function determine_fuel_state()
	local able_to_start = true
	local fuel_amt = turtle.getFuelLevel()
	if fuel_amt == 0 then
		able_to_start = false
		print("This turtle does not have any fuel")
	end
	return able_to_start
end


function commandTurtle(num_turtles_to_use, use_shulker)
	local normal_chest = "minecraft:chest" 
	local iron_chest = "ironchest:iron_chest"
	local gold_chest = "ironchest:gold_chest"
	local diamond_chest = "ironchest:diamond_chest"

	local continue_process = false
	local fuel_amt = turtle.getFuelLevel()
	print("Fuel: " .. (fuel_amt/turtle.getFuelLimit())*100 .. "%")

	local chest_with_fuel = false
	local state, block = turtle.inspectDown()
	if (block.name == normal_chest or block.name == iron_chest or block.name == gold_chest or block.name == diamond_chest) then
		chest_with_fuel = true
	end
	while chest_with_fuel == false do
		print("Please place a chest with fuel under me")
		print("Checking in 3 seconds")
		sleep(1)
		print("Checking in 2 seconds")
		sleep(1)
		print("Checking in 1 second")
		sleep(1)
		state, block = turtle.inspectDown()
		if block.name == diamond_chest then
			chest_with_fuel = true
		end
	end

	local numTurtles = num_turtles_to_use
	local use_shulker = use_shulker

	if numTurtles == 0 then
		return
	end

	local turtles_in_shulker = false
	local found_disk_drive = false
	local found_disk = false
	local turtle_found = false
	local found_shulker = false

	local turtles_in_inv = 0

	if use_shulker == "no" then

		for slot=1, 16 do
			turtle.select(slot)
			local item = turtle.getItemDetail()
			if item ~= nil then
				if (item.name == "computercraft:turtle_normal" or item.name == "computercraft:turtle_advanced") then
					local amt = item.count
					turtle_found = true

					turtles_in_inv = turtles_in_inv + amt

				elseif item.name == "computercraft:disk_drive" then
					found_disk_drive = true
					disk_drive_slot = slot

				elseif item.name == "computercraft:disk" then
					found_disk = true
					disk_slot = slot
				end
			end
		end

		if turtles_in_inv < numTurtles then
			print("I only have " .. turtles_in_inv .. " turtles")
			io.write("Deploy all " .. turtles_in_inv .. " turtles anyways?: ")
			answer = io.read()

			if answer == "yes" then
				numTurtles = turtles_in_inv

			elseif answer == "no" then
				print("Quitting program")
				return

			else
				print("Invalid answer, quitting program")
				return
			end
		end

	elseif use_shulker == "yes" then
		
		for slot=1, 16 do
			turtle.select(slot)
			local item = turtle.getItemDetail()
			if item ~= nil then
				if item.name == "computercraft:disk_drive" then
					found_disk_drive = true
					disk_drive_slot = slot

				elseif item.name == "computercraft:disk" then
					found_disk = true
					disk_slot = slot

				elseif string.find(item.name, "shulker_box") ~= nil then
					found_shulker = true

				end
			end
		end
		turtle_found = true
	end

	if turtle_found == false then
		print("I do not have any turtles")
		print("Please place some in my inventory")
		return

	elseif turtle_found and found_disk_drive and found_disk and not found_shulker then
		payloadSetup(disk_drive_slot, disk_slot)

		continue_process = true

	elseif found_shulker and found_disk_drive and found_disk then
		payloadSetup(disk_drive_slot, disk_slot)

		continue_process = true
		turtles_in_shulker = true

	else
		print("Needed items not found, exiting")
		return

	end

	return continue_process, numTurtles, turtles_in_shulker
end

function payloadSetup(disk_drive_slot, disk_slot)
	turtle.back()
	turtle.up()
	turtle.select(disk_drive_slot)
	turtle.place()
	turtle.select(disk_slot)
	turtle.drop()
	turtle.down()

end

function deployTurtles(numTurtles, turtles_in_shulker)
	local deployed_turtles = 0

	if turtles_in_shulker then
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
			if turtle.suckUp() == true then
				local state, block = turtle.inspect()
				while state == true do
					state, block = turtle.inspect()
				end

				turtle.place()
				Turtle = peripheral.wrap("front")
				Turtle.turnOn()
				deployed_turtles = deployed_turtles + 1
				term.clear()
				term.setCursorPos(1,1)
				rednet.broadcast("Deployed " .. deployed_turtles .. "/" .. numTurtles .. " turtles")

			elseif turtle.suckUp() == false then
				turtle.digUp()
				turtle.select(shulker_slots[current_shulker])
				turtle.placeUp()
				current_shulker = current_shulker + 1
			end
		end

	elseif turtles_in_shulker == false then
		for slot=1, 16 do
			turtle.select(slot)
			local slot_item = turtle.getItemDetail()
			if slot_item ~= nil then
				if (slot_item.name == "computercraft:turtle_normal" or slot_item.name == "computercraft:turtle_advanced") then
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


function recollect(numTurtles, turtles_in_shulker)
	local not_finished = true
	local turtles_collected = 0
	local state, block = turtle.inspect()

	if turtles_in_shulker then

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
			if state == true then
				if (block.name == "computercraft:turtle_normal" or block.name == "computercraft:turtle_advanced") then
					turtle_dropped_load = false
					while turtle_dropped_load == false do
						local event = os.pullEvent("redstone")
						turtle_dropped_load = true
					end
					turtle.dig()
					turtles_collected = turtles_collected + 1
					term.clear()
					term.setCursorPos(1,1)
					rednet.broadcast("Recollected: " .. turtles_collected .. "/" .. numTurtles)
					if turtle.dropUp() == false then
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

	elseif turtles_in_shulker == false then
		term.clear()
		term.setCursorPos(1,1)

		rednet.broadcast("Waiting for turtles...")

		while turtles_collected < numTurtles do
			if state == true then
				if (block.name == "computercraft:turtle_normal" or block.name == "computercraft:turtle_advanced") then
					turtle_dropped_load = false
					while turtle_dropped_load == false do
						local event = os.pullEvent("redstone")
						turtle_dropped_load = true
					end
					turtle.dig()
					turtles_collected = turtles_collected + 1
					term.clear()
					term.setCursorPos(1,1)
					rednet.broadcast("Recollected: " .. turtles_collected .. "/" .. numTurtles)
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


function main(num_turtles_to_use, use_shulker)
	local start_state = determine_fuel_state()
	if start_state then
		continue_process, numTurtles, turtles_in_shulker = commandTurtle(num_turtles_to_use, use_shulker)
		if continue_process then
			deployTurtles(numTurtles, turtles_in_shulker)

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

	recollect(numTurtles, turtles_in_shulker)

	rednet.broadcast("Run has completed.")
	return
end


function wirelessReceiver()
	
	local run = true
	while run do
		rednet.open("left")
		print("Waiting for command")
		local sender, msg, protocol = rednet.receive()
		if msg == "excavate" then
			print("msg recieved")
			rednet.broadcast("Number of turtles to deploy: ")
			sender, msg, protocol = rednet.receive()
			local num_turtles_to_use = tonumber(msg)

			rednet.broadcast("Use shulkers?: ")
			sender, msg, protocol = rednet.receive()
			local use_shulker = msg

			main(num_turtles_to_use, use_shulker)
		end
	end

end


wirelessReceiver()