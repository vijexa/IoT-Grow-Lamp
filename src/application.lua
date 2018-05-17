MINUTE_NS = 60*1000000 -- 60 * 1 000 000 is one minute in ns (nanoseconds)
MINUTE_MS = 60*1000    -- in ms (milliseconds)

startup_evaluated = true
lamp_pin = 2
pwm_freq = 1000
settings.toggle_time.on = settings.toggle_time.on.hour*60 + settings.toggle_time.on.min
settings.toggle_time.off = settings.toggle_time.off.hour*60 + settings.toggle_time.off.min

current_time = {}
function format_time() 
  current_time = rtctime.epoch2cal(rtctime.get())
  current_time.hour = current_time.hour + settings.GMT
  if settings.summer_time == true then current_time.hour = current_time.hour + 1 end
  if current_time.hour >= 24 then current_time.hour = current_time.hour - 24 end
  print(current_time.hour..":"..current_time.min)
  current_time = current_time.hour*60 + current_time.min
end

-- sync time
sntp.sync(settings.time_server,

  function(sec, usec, server, info)
    format_time()

    local function DIV(a,b)
      return (a - a % b) / b
    end

    local function map(x, in_min, in_max, out_min, out_max)
      return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
    end

    -- night time
    if (current_time>=settings.toggle_time.off) or (current_time<=settings.toggle_time.on) then 
      local time_left = settings.toggle_time.on-current_time
      -- if time left for sleep is less than specified sleep time then module need to sleep less
      if(time_left<=DIV(settings.sleep_time, MINUTE_NS)) and (time_left>=0) then  
        print("sleep     time left "..time_left)
        rtctime.dsleep(time_left*MINUTE_NS)
      else
        print("sleep")
        rtctime.dsleep(settings.sleep_time)
      end
    else 
      -- day time
      local function maintain_lamp()
        print("lamp on") 
        if(settings.fade) and (current_time-settings.toggle_time.on<=settings.fade_time) then
          local time_to_end = settings.toggle_time.on + settings.fade_time - current_time
          local number_of_steps = map(time_to_end, 0, settings.fade_time, 1023, 0)
          local step_time = DIV(time_to_end*MINUTE_MS, 1023-number_of_steps)
          local duty = number_of_steps
          pwm.setup(lamp_pin, pwm_freq, duty)
          pwm.start(lamp_pin)
          tmr.create():alarm(step_time, tmr.ALARM_AUTO, function(timer)
            duty = duty + 1
            print(duty)
            pwm.setduty(2, duty)
            if(duty >= 1023) then
              pwm.stop(lamp_pin)
              pwm.close(lamp_pin)
              gpio.write(lamp_pin, gpio.HIGH)
              timer:stop()
              timer:unregister()
            end
          end)
        elseif (settings.fade) and (settings.toggle_time.off-current_time<=settings.fade_time) then
          local time_to_end = settings.toggle_time.off - current_time
          local number_of_steps = map(time_to_end, 0, settings.fade_time, 0, 1023)
          local step_time = DIV(time_to_end*MINUTE_MS, number_of_steps)
          local duty = number_of_steps
          pwm.setup(lamp_pin, pwm_freq, duty)
          pwm.start(lamp_pin)
          tmr.create():alarm(step_time, tmr.ALARM_AUTO, function(timer)
            duty = duty - 1
            print(duty)
            pwm.setduty(2, duty)
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
            time_left = settings.toggle_time.off-settings.fade_time-current_time
          else 
            time_left = settings.toggle_time.off-current_time
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
    
  end,

  function()
   print('failed!')
  end
) 