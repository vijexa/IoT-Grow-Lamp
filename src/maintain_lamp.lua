if (settings.check_heap) then print("\n////maintain_lamp heap "..node.heap()) end

function maintain_lamp()
    print("lamp on") 

    -- turning lamp on
    if(settings.fade) and (current_time.time - settings.toggle_time.on <= settings.fade_time) then
        local time_to_end = settings.toggle_time.on + settings.fade_time - current_time.time
        local number_of_steps = math.floor(map(time_to_end, 0, settings.fade_time, 1023, 0))
        local step_time = DIV(time_to_end * MINUTE_MS, 1023 - number_of_steps)
        local duty = number_of_steps
        pwm.setup(settings.lamp_pin, pwm_freq, duty)
        pwm.start(settings.lamp_pin)
        tmr.create():alarm(step_time, tmr.ALARM_AUTO, function(timer)
            duty = duty + 1
            print(fade_functions[settings.fade_function](duty).." - "..duty)
            pwm.setduty(settings.lamp_pin, fade_functions[settings.fade_function](duty))
            if(duty >= 1023) then
                pwm.stop(settings.lamp_pin)
                pwm.close(settings.lamp_pin)
                gpio.write(settings.lamp_pin, gpio.HIGH)
                timer:stop()
                timer:unregister()
            end
        end)

    -- turning lamp off
    elseif (settings.fade) and (settings.toggle_time.off - current_time.time <= settings.fade_time) then
        local time_to_end = settings.toggle_time.off - current_time.time
        local number_of_steps = map(time_to_end, 0, settings.fade_time, 0, 1023)
        local step_time = DIV(time_to_end * MINUTE_MS, number_of_steps)
        local duty = number_of_steps
        pwm.setup(settings.lamp_pin, pwm_freq, duty)
        pwm.start(settings.lamp_pin)
        tmr.create():alarm(step_time, tmr.ALARM_AUTO, function(timer)
            duty = duty - 1
            print(fade_functions[settings.fade_function](duty).." - "..duty)
            pwm.setduty(lamp_pin, fade_functions[settings.fade_function](duty))
            if(duty <= 0) then
                pwm.stop(settings.lamp_pin)
                pwm.close(settings.lamp_pin)
                gpio.write(settings.lamp_pin, gpio.LOW)
                timer:stop()
                timer:unregister()
                rtctime.dsleep(1)
            end
        end)
    else
        gpio.write(settings.lamp_pin, gpio.HIGH)
    end
end