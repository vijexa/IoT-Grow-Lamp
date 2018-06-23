# IOT Grow Lamp

Automatical lamp for plants based on ESP8266 Wi-Fi MCU and NodeMCU firmware. Can be scheduled or work depending on sunset and sunrise times.

## Installing

Firstly, you need to build NodeMCU. For example, you can use this site:
```
https://nodemcu-build.com/
```
Modules, that you need to include in your build: 
* file
* GPIO
* HTTP
* net
* node
* PWM 
* RTC time
* SJSON
* SNTP
* timer 
* UART
* WiFi

You need to get version with float numbers.
After you downloaded firmware, you need to flash it on your ESP8266. There are a lot of tools for our purposes: 
```
https://nodemcu.readthedocs.io/en/master/en/flash/
```
I advice to use NodeMCU PyFlasher because it's more user-friendly and platform-independent.

**!IMPORTANT BEFORE FLASHING!**

It's very easy to get confused if you use ESP8266 for the first time. You need to know some things about its bootloader. When you reset module, GPIO15 ALWAYS should be connected to ground, and GPIO2 to VCC. If you connect GPIO0 to VCC, MCU will boot in normal mode and execute your program in its flash memory. If you set it to GND, MCU will wait for firmware flashing. You need to set GPIO0 to GND ONLY when you flash firmware. When you upload program, it should be HIGH. You need to use resistors for all connections.

GPIO | Normal mode | Flashing mode
---- | ------------|--------------
15   | Low         | Low  
2    | High        | High
0    | High        | Low

You can read more about ESP8266 boot process here: 
```
https://github.com/esp8266/esp8266-wiki/wiki/Boot-Process#esp-boot-modes
```

It's important each time when you reset MCU. After resetting, these pins can be used as regular GPIO. You need to think about this if you have pure ESP8266 module. If you have custom board with USB like NodeMCU development kit or WeMos board, then most likely GPIO15 and GPIO2 are correctly connected internally, and GPIO0 is triggered from USB when flashing. Also on these boards can be flash button, which connects GPIO0 to LOW when pressed (so, you should press it while resetting MCU before flashing).

-- TODO --
