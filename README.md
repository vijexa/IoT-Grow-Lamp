# IOT Grow Lamp

Automatical lamp for plants based on ESP8266 Wi-Fi MCU and NodeMCU firmware. Can be scheduled or work depending on sunset and sunrise times.

## Installing

Firstly, you need to install nodejs packages (uploader scripts use [nodemcu-tool](https://github.com/AndiDittrich/NodeMCU-Tool)):
```
npm install
```

After that you should build NodeMCU. For example, you can use this site:

&nbsp;&nbsp;&nbsp;&nbsp;<https://nodemcu-build.com/>

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

&nbsp;&nbsp;&nbsp;&nbsp;<https://nodemcu.readthedocs.io/en/master/en/flash/>

I advice to use NodeMCU PyFlasher on windows (because you only need to download it and launch without any messing) and esptool.py on linux (because you can easily install it with pip and upload nodemcu firmware with one terminal command).

On windows you can find COM port of connected ESP8266 through device manager, on linux - using this command:
```
ls /dev/ttyUSB*
```

**!IMPORTANT BEFORE FLASHING!**

It's very easy to get confused if you use ESP8266 for the first time. You need to know some things about its bootloader. When you reset module, GPIO15 ALWAYS should be connected to ground, and GPIO2 to VCC. If you connect GPIO0 to VCC, MCU will boot in normal mode and execute your program in its flash memory. If you set it to GND, MCU will wait for firmware flashing. You need to set GPIO0 to GND ONLY when you flash firmware. When you upload program, it should be HIGH. You need to use resistors for all connections.

GPIO | Normal mode | Flashing mode
---- | ------------|--------------
15   | Low         | Low  
2    | High        | High
0    | High        | Low

You can read more about ESP8266 boot process here: 

&nbsp;&nbsp;&nbsp;&nbsp;<https://github.com/esp8266/esp8266-wiki/wiki/Boot-Process#esp-boot-modes>


It's important each time when you reset MCU. After resetting, these pins can be used as regular GPIO. You need to think about this if you have pure ESP8266 module. If you have custom board with USB like NodeMCU development kit or WeMos board, then most likely GPIO15 and GPIO2 are correctly connected internally, and GPIO0 is triggered from USB when flashing. Also on these boards can be flash button, which connects GPIO0 to LOW when pressed (so, you should press it while resetting MCU before flashing).

After firmware uploading you should launch upload_build.bat or upload_build.sh if you are using windows or linux respectively. 

#### Windows uploader

First argument must be a COM port (in windows com ports looks like COM0, COM1, COM2). Uploader supports these flags:
```
/f - formats NodeMCU filesystem 
/c - preprocesses and compiles .lua files 
```
For example:
```
upload_build.bat COM3 /f /c
```

#### Linux uploader

Uploader supports these flags and options:
```
-p <COM port>
-b <baudrate> (115200 if not specified)
-f - formats NodeMCU filesystem 
-c - preprocesses and compiles .lua files 
```
For example:
```
sudo ./upload_build.sh -p /dev/ttyUSB0 -f -c
```
-- TODO --
