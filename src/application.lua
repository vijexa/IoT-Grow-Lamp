MINUTE_NS = 60*1000000 -- 60 * 1 000 000 is one minute in ns (nanoseconds)
MINUTE_MS = 60*1000    -- in ms (milliseconds)

startup_evaluated = true
lamp_pin = 2
pwm_freq = 1000
settings.toggle_time.on = settings.toggle_time.on.hour*60 + settings.toggle_time.on.min
settings.toggle_time.off = settings.toggle_time.off.hour*60 + settings.toggle_time.off.min
daylight_saving = nil
current_time = {}

-- checking if it is daylight saving time now
function check_daylight_saving()
  if(daylight_saving == nil) then
    local months = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31}

    local days_start = 0
    for i=1, settings.daylight_saving_period.start.month-1, 1 do
      days_start = days_start + months[i]
      if(i == 2) and (current_time.year % 4 == 0) then days_start = days_start + 1 end
    end
    days_start = days_start + settings.daylight_saving_period.start.month_day

    local days_end = 0
    for i=1, settings.daylight_saving_period._end.month-1, 1 do
      days_end = days_end + months[i]
      if(i == 2) and (current_time.year % 4 == 0) then days_end = days_end + 1 end
    end
    days_end = days_end + settings.daylight_saving_period._end.month_day

    print("saving start "..days_start.." end "..days_end)
    print((current_time.yday>days_start) and (current_time.yday<days_end))
    daylight_saving = (current_time.yday>days_start) and (current_time.yday<days_end)
  end
  return daylight_saving
end

function format_time() 
  current_time = rtctime.epoch2cal(rtctime.get())
  current_time.hour = current_time.hour + settings.GMT
  if (settings.daylight_saving == true) and (check_daylight_saving()) then current_time.hour = current_time.hour + 1 end
  if current_time.hour >= 24 then current_time.hour = current_time.hour - 24 end
  print(current_time.hour..":"..current_time.min)
  current_time.time = current_time.hour*60 + current_time.min
end

function DIV(a,b)
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
      -- night time
      if (current_time.time>=settings.toggle_time.off) or (current_time.time<settings.toggle_time.on) then 
        local time_left = settings.toggle_time.on-current_time.time
        -- if time left for sleep is less than specified sleep time then module need to sleep less
        if(time_left<=DIV(settings.sleep_time, MINUTE_NS)) and (time_left>=0) then  
          print("sleep     time left "..time_left)
          rtctime.dsleep(time_left*MINUTE_NS)
        else
          print("sleep")
          rtctime.dsleep(settings.sleep_time)
        end
      else 
        fade_functions = {
          -- linear
          function(x)
            return x
          end,
          -- parabola
          function(x) 
            return math.floor((1/1024)*(x^2)+1 + 0.5)
          end,
          -- exponent
          function(x)
            return math.floor(2^(x*0.0097738) + 0.5)
          end
        }
        -- day time
        local function maintain_lamp()
          print("lamp on") 
          if(settings.fade) and (current_time.time-settings.toggle_time.on<=settings.fade_time) then
            local time_to_end = settings.toggle_time.on + settings.fade_time - current_time.time
            local number_of_steps = math.floor(map(time_to_end, 0, settings.fade_time, 1023, 0))
            local step_time = DIV(time_to_end*MINUTE_MS, 1023-number_of_steps)
            local duty = number_of_steps
            pwm.setup(lamp_pin, pwm_freq, duty)
            pwm.start(lamp_pin)
            tmr.create():alarm(step_time, tmr.ALARM_AUTO, function(timer)
              duty = duty + 1
              print(fade_functions[settings.fade_function](duty).." - "..duty)
              pwm.setduty(lamp_pin, fade_functions[settings.fade_function](duty))
              if(duty >= 1023) then
                pwm.stop(lamp_pin)
                pwm.close(lamp_pin)
                gpio.write(lamp_pin, gpio.HIGH)
                timer:stop()
                timer:unregister()
              end
            end)
          elseif (settings.fade) and (settings.toggle_time.off-current_time.time<=settings.fade_time) then
            local time_to_end = settings.toggle_time.off - current_time.time
            local number_of_steps = map(time_to_end, 0, settings.fade_time, 0, 1023)
            local step_time = DIV(time_to_end*MINUTE_MS, number_of_steps)
            local duty = number_of_steps
            pwm.setup(lamp_pin, pwm_freq, duty)
            pwm.start(lamp_pin)
            tmr.create():alarm(step_time, tmr.ALARM_AUTO, function(timer)
              duty = duty - 1
              print(fade_functions[settings.fade_function](duty).." - "..duty)
              pwm.setduty(lamp_pin, fade_functions[settings.fade_function](duty))
              if(duty <= 0) then
                pwm.stop(lamp_pin)
                pwm.close(lamp_pin)
                gpio.write(lamp_pin, gpio.LOW)
                timer:stop()
                timer:unregister()
                rtctime.dsleep(1)
              end
            end)
          else
            gpio.write(lamp_pin, gpio.HIGH)
          end
        end

        maintain_lamp()

        tmr.create():alarm(settings.sleep_time/1000, tmr.ALARM_SEMI, function(timer) 
          sntp.sync(settings.time_server, function()
            format_time()
            local time_left
            if(settings.fade) then
              time_left = settings.toggle_time.off-settings.fade_time-current_time.time
            else 
              time_left = settings.toggle_time.off-current_time.time
            end
            -- if time left for waiting is less than specified sleep time then module need to wait less
            if(time_left<=DIV(settings.sleep_time, MINUTE_NS)) and (time_left>=0) then
              print("waiting     time left "..time_left)
              timer:unregister()
              tmr.create():alarm(time_left*MINUTE_MS, tmr.ALARM_SINGLE, function()
                format_time()
                maintain_lamp()
              end) 
            else
              print("waiting")
              timer:start()
            end
          end)
        end)
      end
    end

    if(settings.use_twilight) then
      print(current_time.time)
      local FNAME = "twilight_times.json"
      file.open(FNAME, "r")
      local twilight_times = file.read()
      file.close()
      twilight_times = sjson.decode(twilight_times)
      if(current_time.yday == twilight_times.day) then
        settings.toggle_time.on = twilight_times.twilight_begin
        settings.toggle_time.off = twilight_times.twilight_end
        print("on "..settings.toggle_time.on)
        print("off "..settings.toggle_time.off)
        routine()
      else 
        local url = "http://api.sunrise-sunset.org/json?lat="
        url = url..tostring(settings.coordinates.latitude)
        url = url.."&lng="
        url = url..tostring(settings.coordinates.longitude)
        print(url)
        http.get(url, nil, function(code, raw_data)
          print(raw_data)
          raw_data = sjson.decode(raw_data)
          local data = {}
          local function convert(raw_time)
            local val = tonumber(string.match(raw_time, "(.-):")) + settings.GMT + (check_daylight_saving() and 1 or 0)
            val = (val + (string.match(raw_time, " (.+)") == "PM" and 12 or 0))*60
            return val + tonumber(string.match(raw_time, "(.-):"))
          end
          data.twilight_begin = convert(raw_data.results.civil_twilight_begin)
          data.twilight_end = convert(raw_data.results.civil_twilight_end)
          raw_data = sjson.encode(data)
          file.open(FNAME, "w")
          file.write(raw_data)
          file.close()
          settings.toggle_time.on = data.twilight_begin
          settings.toggle_time.off = data.twilight_end
          print("on "..settings.toggle_time.on)
          print("off "..settings.toggle_time.off)
          routine()
        end)
      end
    else
      routine()
    end
    
  end,

  function()
   print('failed!')
  end
) 