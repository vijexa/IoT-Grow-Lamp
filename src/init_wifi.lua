-- load credentials, 'SSID' and 'PASSWORD' declared and initialize in there
dofile("settings.lua")

-- debug
log_file = nil;

local _print = print;
local print = nil

if(settings.write_log) then
  print = function(input)
    _print(input)
    if(input) then
      local stat = file.stat(".log")
      if (stat and stat.size > 3000000) then 
        file.remove(".log")
      end
      log_file = file.open(".log", "a+")
      if (log_file) then 
        log_file:writeline(input)
        log_file:close()
      end
    end
  end
  print("\n")
else
  print = _print;
end

shared_obj = {}
shared_obj.print = print

startup_evaluated = false

function startup()
  -- the actual application is stored in 'application.lua'
  dofile("application.lua")
end

-- Define WiFi station event callbacks 
wifi_connect_event = function(T) 
  print(T.SSID.." connected")
  if disconnect_ct ~= nil then disconnect_ct = nil end  
end

wifi_got_ip_event = function(T) 
  -- Note: Having an IP address does not mean there is internet access!
  -- Internet connectivity can be determined with net.dns.resolve().    
  print("IP: "..T.IP.." "..wifi.sta.getmac())
  if (not startup_evaluated) then 
    _print("Startup will resume momentarily, you have 1 second to abort.")
    _print("Waiting...") 
    tmr.create():alarm(1000, tmr.ALARM_SINGLE, startup)
  end
end

wifi_disconnect_event = function(T)
  if T.reason == wifi.eventmon.reason.ASSOC_LEAVE then 
    --the station has disassociated from a previously connected AP
    return 
  end
  -- total_tries: how many times the station will attempt to connect to the AP. Should consider AP reboot duration.
  local total_tries = 75
  print("\nWiFi connection to AP("..T.SSID..") has failed!")

  for key,val in pairs(wifi.eventmon.reason) do
    if val == T.reason then
      print("Disconnect reason: "..val.."("..key..")")
      break
    end
  end

  if disconnect_ct == nil then 
    disconnect_ct = 1 
  else
    disconnect_ct = disconnect_ct + 1 
  end
  if disconnect_ct < total_tries then 
    print("Retrying connection...(attempt "..(disconnect_ct+1).." of "..total_tries..")")
  else
    wifi.sta.disconnect()
    print("Aborting connection to AP!")
    disconnect_ct = nil  
  end
end

-- Register WiFi Station event callbacks
wifi.eventmon.register(wifi.eventmon.STA_CONNECTED, wifi_connect_event)
wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, wifi_got_ip_event)
wifi.eventmon.register(wifi.eventmon.STA_DISCONNECTED, wifi_disconnect_event)

_print("Connecting to WiFi access point: "..sta_cred["ssid"])
wifi.setmode(wifi.STATION)
wifi.sta.config(sta_cred)
wifi.sta.sleeptype(wifi.MODEM_SLEEP)