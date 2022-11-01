--INDIVIDUAL TURTLE MINERS

local computercraftTurtleName = "computercraft:turtle_normal"

function refuel()
	local current_fuel = turtle.getFuelLevel()
	print("Current Fuel: " .. current_fuel)
	if current_fuel < 500 then
		local needed_fuel = math.ceil((500-current_fuel)/80)
		turtle.suckDown()
		turtle.refuel(needed_fuel)
		turtle.dropDown()
	else
		print("Sufficient fuel level")
	end
end

function inspect_block()
	state, block = turtle.inspect()
	if state == true then
		if block.name ~= computercraftTurtleName then
			turtle.dig()
		else
			while block.name == computercraftTurtleName do
				state, block = turtle.inspect()
			end
		end
	end
end

function skip_and_check_next()
	turtle.turnRight()
			
	inspect_block()

	turtle.forward()

	turtle.digUp()
	turtle.digDown()

	turtle.turnLeft()
end

function find_wall()
	local start_mining = false
	local cobblestone = "minecraft:cobblestone"
	local turtle_name = "computercraft:turtle_normal"
	
	local blocks_from_initial_chest = 0
	local blocks_from_initial_wall = 0

	--find wall to start mining at
	local state, block = turtle.inspect()

	while block.name ~= cobblestone do
		while block.name == computercraftTurtleName do
			state, block = turtle.inspect()
		end
		turtle.forward()
		state, block = turtle.inspect()
		blocks_from_initial_chest = blocks_from_initial_chest + 1
	end

	-- look for suitable wall to start
	while start_mining == false do
		if block.name == cobblestone then
			skip_and_check_next()

			state, block = turtle.inspect()
			blocks_from_initial_wall = blocks_from_initial_wall + 1

		elseif state == false then
			skip_and_check_next()

			state, block = turtle.inspect()
			blocks_from_initial_wall = blocks_from_initial_wall + 1

		elseif state == true then
			if block.name == "minecraft:lava" or block.name == "minecraft:water" then
				skip_and_check_next()

				state, block = turtle.inspect()
				blocks_from_initial_wall = blocks_from_initial_wall + 1

			elseif block.name == computercraftTurtleName then
				skip_and_check_next()

				state, block = turtle.inspect()
				blocks_from_initial_wall = blocks_from_initial_wall + 1

			else
				start_mining = true
			end

		end
		
	end

	return blocks_from_initial_chest, blocks_from_initial_wall
end


function EXCAVATION(blocks_from_initial_chest, blocks_from_initial_wall)
	local current_fuel = turtle.getFuelLevel()
	if current_fuel > 200 then
		amount_to_mine = 100
	else
		amount_to_mine = (current_fuel/2)-(blocks_from_initial_chest+blocks_from_initial_wall)
	end


	turtle.dig()
	turtle.forward()

	for current_step=1, amount_to_mine do
		local state, block = turtle.inspect()

		if state == true then

			if (block.name == "minecraft:gravel" or block.name == "minecraft:sand") then
				turtle.dig()
				state, block = turtle.inspect()

				while (block.name == "minecraft:gravel" or block.name=="minecraft:sand") do
					state, block = turtle.inspect()
					turtle.dig()
				end

				turtle.digUp()
				turtle.digDown()
				turtle.forward()


			elseif (block.name == "minecraft:water" or block.name == "minecraft:lava" or block.name == "pneumaticcraft:oil") then
				turtle.forward()

			else
				turtle.dig()
				turtle.digUp()
				turtle.digDown()
				turtle.forward()
			end

		elseif state == false then
			turtle.digUp()
			turtle.digDown()
			turtle.forward()
			
		end
		if math.fmod(current_step, 20) == 0 then
			purgeInventory()
		end
	end

	turtle.digUp()
	turtle.digDown()
	purgeInventory()

	return amount_to_mine

end

function purgeInventory()
	local blackListedItems = {
		"minecraft:stone",
		"minecraft:cobblestone",
		"minecraft:netherrack", 
		"minecraft:diorite", 
		"minecraft:granite", 
		"minecraft:gravel", 
		"minecraft:dirt", 
		"minecraft:andesite", 
		"byg:soapstone", 
		"byg:rocky_stone"}

	for x=1, 16 do
		turtle.select(x)
		local item = turtle.getItemDetail()
		if item ~= nil then
			for item_in_list=1, #blackListedItems do
				if item.name == blackListedItems[item_in_list] then
					turtle.drop()
				end
			end
		end
	end
	turtle.select(1)
end


function retraceSteps(blocks_from_initial_chest, blocks_from_initial_wall, blocks_to_retrace)
	turtle.turnRight()
	turtle.turnRight()

	--WALK BACK FROM STRIP MINE
	for step=0, blocks_to_retrace do
		local state, block = turtle.inspect()
		while state == true do
			if (block.name == "minecraft:lava" or block.name == "minecraft:water" or block.name == "pneumaticcraft:oil") then
				break

			elseif block.name == "minecraft:gravel" or block.name == "minecraft:sand" then
				while block.name == "minecraft:gravel" or block.name == "minecraft:sand" do
					turtle.dig()
					sleep(.5)
					state, block = turtle.inspect()
				end

			elseif block.name == computercraftTurtleName then
				sleep(5)

			else
				turtle.dig()
			end
			state, block = turtle.inspect()
		end
		turtle.forward()
	end

	turtle.turnRight()

	--WALK BACK TO WALL POSITION
	for step_wall=1, blocks_from_initial_wall do
		local state, block = turtle.inspect()
		while state == true do
			state, block = turtle.inspect()
			sleep(1)
		end
		turtle.forward()
	end

	turtle.turnLeft()


	--WALK BACK TO BE INFRONT OF CHEST
	for step_chest=1, blocks_from_initial_chest do
		local chest_check_state, chest_block = turtle.inspectDown()
		if chest_check_state == true then
			if string.find(chest_block.name, "chest") ~= nil then
				print("Retraced steps to original position")
				break
			end
		end
		local state, block = turtle.inspect()
		while state == true do
			state, block = turtle.inspect()
			sleep(1)
		end

		turtle.forward()
	end
	print("Retraced steps to original position")

end


function dropLoad()

	local not_dropped = true
	local state, block = turtle.inspectDown()
	if string.find(block.name, "chest") ~= nil then
		print(block.name .. " has been located")
		for slot=1, 16 do
			turtle.select(slot)
			if turtle.getItemDetail() ~= nil then
				turtle.dropDown()
			end
		end

		not_dropped = false
	else
		print("Storage not located, retracing may have gone wrong")
		print("Unit must be manually retrieved")
	end

	
	if not_dropped == false then
		print("Sending signal for recollection")
		while true do
			redstone.setOutput("front", true)
			sleep(1)
		end
	end

end


function main()
	refuel()
	local blocks_from_initial_chest, blocks_from_initial_wall =  find_wall()
	local blocks_to_retrace = EXCAVATION(blocks_from_initial_chest, blocks_from_initial_wall)
	retraceSteps(blocks_from_initial_chest, blocks_from_initial_wall, blocks_to_retrace)
	sleep(1)
	dropLoad()

end


main()