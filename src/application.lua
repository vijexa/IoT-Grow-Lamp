if (settings.check_heap) then 
	print("\n////app launched heap "..node.heap()) 
	print("////"..node.heap())
end

MINUTE_NS = 60 * 1000000 -- 60 * 1 000 000 is one minute in ns (nanoseconds)
MINUTE_MS = 60 * 1000    -- in ms (milliseconds)

startup_evaluated = true
pwm_freq = 1000
settings.toggle_time.on = settings.toggle_time.on.hour * 60 + settings.toggle_time.on.min
settings.toggle_time.off = settings.toggle_time.off.hour * 60 + settings.toggle_time.off.min
current_time = {}

local print = shared_obj.print

if (settings.daylight_saving) then dofile("check_daylight_saving.lua") end

dofile("format_time.lua")

function DIV(a, b)
	return (a - a % b) / b
end

function map(x, in_min, in_max, out_min, out_max)
	return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
end

-- sync time
sntp.sync(settings.time_server,
	function(sec, usec, server, info)
		format_time()

		function routine()

			-- NIGHT TIME --
			if (current_time.time >= settings.toggle_time.off) or (current_time.time < settings.toggle_time.on) then 
				local time_left = settings.toggle_time.on - current_time.time
				-- if time left for sleep is less than specified sleep time then module need to sleep less
				if(time_left <= settings.sleep_time) and (time_left >= 0) then  
					print("sleep     time left "..time_left)
					print("------------------------------")
					rtctime.dsleep(time_left * MINUTE_NS)
				else
					print("sleep")
					print("------------------------------")
					rtctime.dsleep(settings.sleep_time * MINUTE_NS)
				end
			else 
				-- DAY TIME --

				fade_functions = {
					-- linear
					function(x)
						return x
					end,
					-- parabola
					function(x) 
						return math.floor((1 / 1024) * (x ^ 2) + 1 + 0.5)
					end,
					-- exponent
					function(x)
						return math.floor(2 ^ (x * 0.0097738) + 0.5)
					end
				}

				dofile("maintain_lamp.lua")

				maintain_lamp()

				-- check if it's time for turning lamp off
				function daylight_wait(timer)
					format_time()
					local time_left
					if(settings.fade) then
						time_left = settings.toggle_time.off - settings.fade_time - current_time.time
					else 
						time_left = settings.toggle_time.off - current_time.time
					end
					-- if time left for waiting is less than specified sleep time then module needs to wait less
					if(time_left <= settings.sleep_time) and (time_left >= 0) then
						print("waiting     time left "..time_left)
						print("------------------------------")
						timer:unregister()
						tmr.create():alarm(time_left * MINUTE_MS, tmr.ALARM_SINGLE, function()
							format_time()
							maintain_lamp()
						end) 
					else
						print("waiting\n")
						print("------------------------------")
						timer:start()
					end
				end

				-- we don't need to check time while lamp is turning on
				local first_wait_time
				if (current_time.time < settings.toggle_time.on + settings.fade_time) then 
					first_wait_time = settings.toggle_time.on + settings.fade_time - current_time.time
				else 
					first_wait_time = settings.sleep_time
				end
				-- time checking loop for daytime
				tmr.create():alarm(first_wait_time * MINUTE_MS, tmr.ALARM_SEMI, function(timer) 
					sntp.sync(settings.time_server, function()
						timer:interval(settings.sleep_time * MINUTE_MS)
						daylight_wait(timer)
					end,
					-- if syncing has failed esp will use internal RTC, but it'll check time with smaller intervals 
					-- specified by settings.wait_connection_time until succesful sync 
					function(err, info) 
						print("\n<ERR>")
						print("error: ")
						print(err)
						print("while sntp.sync(): ")
						print(info)
						print("</ERR>")
						print("waiting for conn\n")
						timer:interval(settings.wait_connection_time * MINUTE_MS)
						daylight_wait(timer)
					end)
				end)
			end
		end

		if(settings.use_sun_times) then
			dofile("use_sun_times.lua")
		else
			routine()
		end
		
	end,

	function()
	print('failed!')
	end
) 