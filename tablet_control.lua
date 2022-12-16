function main()
	
	local run = true
	while run do
		rednet.open("back")
		io.write(">> ")
		local wireless_command = io.read()
		if wireless_command == "quit" then
			break
		
		elseif wireless_command == "excavate" then
			rednet.broadcast(wireless_command)

			local sender, msg, protocol = rednet.receive()
			io.write(msg)
			local numTurtles = io.read()
			rednet.broadcast(numTurtles)

			sender, msg, protocol = rednet.receive()
			io.write(msg)
			local use_shulkers = io.read()
			rednet.broadcast(use_shulkers)

			while true do
				sender, msg, protocol = rednet.receive()

				if msg == "Run has completed." then
					break

				else
					term.clear()
					term.setCursorPos(1,1)
					print(msg)
				end

			end
		end
	end
end


main()
