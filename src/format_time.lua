local print = shared_obj.print

if (settings.check_heap) then print("\n////format_time.lua heap "..node.heap()) end

function format_time() 
	current_time = rtctime.epoch2cal(rtctime.get())
	current_time.hour = current_time.hour + settings.GMT
	if (settings.daylight_saving) and (check_daylight_saving()) then current_time.hour = current_time.hour + 1 end
	if (current_time.hour >= 24) then current_time.hour = current_time.hour - 24 end
	print(current_time.hour..":"..current_time.min)
	current_time.time = current_time.hour * 60 + current_time.min
	-- debugging things
	if(settings.day_pass.pass) then 
		print("real  "..current_time.time)
		while (current_time.time >= settings.toggle_time.off + 3) do
			current_time.time = current_time.time - settings.day_pass.back_in_time;
		end
	end
	print("formatted  "..current_time.time)
	print("on "..settings.toggle_time.on.." off "..settings.toggle_time.off)
end