--INDIVIDUAL TURTLE MINERS
local cobblestone = "minecraft:cobblestone"
local blackListedItems = {
	"minecraft:stone",
	"minecraft:cobblestone",
	"minecraft:netherrack", 
	"minecraft:diorite", 
	"minecraft:granite", 
	"minecraft:gravel", 
	"minecraft:dirt", 
	"minecraft:andesite",
}
local gravity_blocks = {
	"minecraft:gravel",
	"minecraft:sand",
	"the_extractinator:silt"
}
local fluids = {
	"minecraft:lava",
	"minecraft:water"
}


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
	if state then
		if string.find(block.name, "turtle") == nil then
			turtle.dig()
		else
			while state do
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
	local blocks_from_initial_chest = 0
	local blocks_from_initial_wall = 0

	--find wall to start mining at
	local state, block = turtle.inspect()
	sleep(.2)
	while block.name ~= cobblestone do
		if state then
			if string.find(block.name, "turtle") ~= nil then
				while state do
					state, block = turtle.inspect()
					sleep(.2)
				end
			end
		end
		turtle.forward()
		sleep(.2)
		state, block = turtle.inspect()
		blocks_from_initial_chest = blocks_from_initial_chest + 1
	end

	-- look for suitable wall to start
	while true do
		if block.name == cobblestone then
			skip_and_check_next()

		elseif state == false then
			skip_and_check_next()

		elseif state == true then
			for i = 0, #fluids do
				if block.name == fluids[i] then
					skip_and_check_next()
				end
			end

			if string.find(block.name, "turtle") ~= nil then
				skip_and_check_next()

			else
				break
			end
		end
		blocks_from_initial_wall = blocks_from_initial_wall + 1
		state, block = turtle.inspect()
		
	end

	return blocks_from_initial_chest, blocks_from_initial_wall
end


function EXCAVATION(blocks_from_initial_chest, blocks_from_initial_wall)
	local current_fuel = turtle.getFuelLevel()
	--Only allow turtles to mine 100 blocks max as it could enter unloaded chunk past that
	if current_fuel > 200 then
		amount_to_mine = 100
	else
		amount_to_mine = (current_fuel/2)-(blocks_from_initial_chest+blocks_from_initial_wall)
	end

	for current_step=1, amount_to_mine do
		local state, block = turtle.inspect()

		if state then
			if (block.name == "minecraft:gravel" or block.name=="minecraft:sand" or block.name == "the_extractinator:silt") then
				dig_gravity_blocks(block.name)

				mine_procedure()

			elseif (block.name == "minecraft:water" or block.name == "minecraft:lava") then
				turtle.forward()

			else
				turtle.dig()
				local state, block = turtle.inspect()
				if (block.name == "minecraft:gravel" or block.name=="minecraft:sand" or block.name == "the_extractinator:silt") then
					dig_gravity_blocks(block.name)
				end
				mine_procedure()
			end

		elseif not state then
			mine_procedure()
			
		end
		--Every 20 steps, turtle will purge its inventory
		if math.fmod(current_step, 20) == 0 then
			purgeInventory()
		end
	end

	turtle.digUp()
	turtle.digDown()
	--Purges inventory one last time before return
	purgeInventory()

	return amount_to_mine

end


function mine_procedure()
	turtle.digUp()
	turtle.digDown()
	turtle.forward()
end

function dig_gravity_blocks(block)
	turtle.dig()
	--Waits for gravel/sand to completely fall
	sleep(.3)
	local state, block = turtle.inspect()
	if state then
		while (block.name == "minecraft:gravel" or block.name=="minecraft:sand" or block.name == "the_extractinator:silt") do
			turtle.dig()
			sleep(.3)
			state, block = turtle.inspect()
		end
	end
end


--Itereates through inventory and drops items that are in the blacklisted array
function purgeInventory()
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
	for step=1, blocks_to_retrace do
		local state, block = turtle.inspect()
		while state do
			--If fluid, breaks and moves forward
			if (block.name == "minecraft:lava" or block.name == "minecraft:water") then
				break

			--If gravel/sand, will dig it out then moves forward
			elseif (block.name == "minecraft:gravel" or block.name == "minecraft:sand" or block.name == "the_extractinator:silt") then
				dig_gravity_blocks(block.name)

			--If a turtle in front, wait for turtle to move out the way
			elseif string.find(block.name, "turtle") ~= nil then
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
		while state do
			--Will only be true state if a turtle in front and moving foward or sitting
			state, block = turtle.inspect()
			sleep(1)
		end
		turtle.forward()
	end

	turtle.turnLeft()

	--WALK BACK TO BE ON TOP OF CHEST
	for step_chest=1, blocks_from_initial_chest do
		--Checks if on top of chest first, as could be command turtle in front instead of normal miner turtle
		local chest_check_state, chest_block = turtle.inspectDown()
		if chest_check_state == true then
			if string.find(chest_block.name, "chest") ~= nil then
				break
			end
		end
		--If not on top of chest, checks if turtle in front, this turtle could still be in line
		local state, block = turtle.inspect()
		while state do
			state, block = turtle.inspect()
			sleep(1)
		end

		turtle.forward()
	end
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
	
	if not not_dropped then
		print("Sending signal for recollection")
		while true do
			redstone.setOutput("front", true)
			sleep(1)
		end
	end

end


function main()
	refuel()
	local blocks_from_initial_chest, blocks_from_initial_wall = find_wall()
	local blocks_to_retrace = EXCAVATION(blocks_from_initial_chest, blocks_from_initial_wall)
	retraceSteps(blocks_from_initial_chest, blocks_from_initial_wall, blocks_to_retrace)
	sleep(1)
	dropLoad()

end


main()