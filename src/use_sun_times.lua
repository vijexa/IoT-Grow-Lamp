if (settings.check_heap) then print("\n////use_sun_times.lua heap "..node.heap()) end

print("current time "..current_time.time)
local FNAME = "sun_times.json"
file.open(FNAME, "r")
local sun_times = file.read()
file.close()
sun_times = sjson.decode(sun_times)
if(current_time.yday == sun_times.day) then
    settings.toggle_time.on = sun_times.sunrise
    settings.toggle_time.off = sun_times.sunset
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
            val = (val + (string.match(raw_time, " (.+)") == "PM" and 12 or 0)) * 60
            return val + tonumber(string.match(raw_time, ":(.-):"))
        end
        data.sunrise = convert(raw_data.results.sunrise)
        data.sunset = convert(raw_data.results.sunset)
        data.day = current_time.yday
        raw_data = sjson.encode(data)
        file.open(FNAME, "w")
        file.write(raw_data)
        file.close()
        settings.toggle_time.on = data.sunrise
        -- adding settings.fade_time to ensure that lamp will start to turning off on sunset time 
        settings.toggle_time.off = data.sunset + (settings.fade and settings.fade_time or 0) 
        print("on "..settings.toggle_time.on)
        print("off "..settings.toggle_time.off)
        routine()
    end)
end
print("\n")