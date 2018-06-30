if (settings.check_heap) then print("\n////check_daylight_saving.lua heap "..node.heap()) end

local daylight_saving = nil

-- checking if it is daylight saving time now
function check_daylight_saving()
	if(daylight_saving == nil) then
		local months = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31}

		local days_start = 0
		for i = 1, settings.daylight_saving_period.start.month - 1, 1 do
			days_start = days_start + months[i]
			if(i == 2) and (current_time.year % 4 == 0) then days_start = days_start + 1 end
		end
		days_start = days_start + settings.daylight_saving_period.start.month_day

		local days_end = 0
		for i = 1, settings.daylight_saving_period._end.month - 1, 1 do
			days_end = days_end + months[i]
			if(i == 2) and (current_time.year % 4 == 0) then days_end = days_end + 1 end
		end
		days_end = days_end + settings.daylight_saving_period._end.month_day

		print("saving start "..days_start.." end "..days_end)
		daylight_saving = (current_time.yday > days_start) and (current_time.yday < days_end)
	end
	return daylight_saving
end