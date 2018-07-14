# IOT Grow Lamp

Automatical lamp for plants based on ESP8266 Wi-Fi MCU and NodeMCU firmware. Can be scheduled or work depending on sunset and sunrise times.


## Settings

Before uploading firmware you should rename src/settings.lua-TEMPLATE to settings.lua and edit it. 

#### &nbsp;&nbsp;(string) ssid

Name of your Wi-Fi network.

#### &nbsp;&nbsp;(string) pwd 

Password of your Wi-Fi network.

#### &nbsp;&nbsp;(int) lamp_pin

Pin to which your relay/mosfet/etc is connected. Note that NodeMCU pin numbers differs from ESP8266 GPIO. More info [here](https://nodemcu.readthedocs.io/en/master/en/modules/gpio/).

#### &nbsp;&nbsp;(string) time_server

SNTP UTC (equal to GMT+0) time server (at most scenarious you don't need to touch this, time.google.com is ok).

#### &nbsp;&nbsp;(int) sleep_time 

Interval between time syncing in minutes. Lower == more accurate, because ESP8266 RTC can't provide time accurate enough.

#### &nbsp;&nbsp;(int) wait_connection_time 

Interval between failed time syncing attempts in minutes due to internet connection loss/SNTP error/etc. Lost connection means time error growth, so it's better to get connection as fast as possible.

#### &nbsp;&nbsp;(int) GMT 

Your timezone.

#### &nbsp;&nbsp;(boolean) daylight_saving

Assign this to true if your country has daylight saving time.

#### &nbsp;&nbsp;daylight_saving_period

Write in when starts and ends daylight saving time in your country. Values in template are true for Latvia.

#### &nbsp;&nbsp;toggle_time

Time, when lamp should turn on and off. Currently, `toggle_time.off` should be higher than `toggle_time.on`. These values are ignored if `use_sun_times == true` (described lower).
```lua
0 <= hour <= 23
0 <= min <= 59
```

#### &nbsp;&nbsp;(boolean) fade

Lamp smoothly turns on and off during fade_time (described lower).

#### &nbsp;&nbsp;(int) fade_time

Time, during which lamp smoothly turns on and off.

Lamp will start to turn on at `toggle_time.on` or sunrise and will be fully turned on when `fade_time` will pass.

Lamp will start to turn off at `toggle_time.off` or `sunset - fade_time` and will be fully turned off when `fade_time` will pass.

#### &nbsp;&nbsp;(int) fade_function

Human brightness perception is logarithmic due to the [Weber-Fechner law](https://en.wikipedia.org/wiki/Weber%E2%80%93Fechner_law). It means that changing brightness level from 2 to 3 (max value 1023) is a lot more visible than changing it from 1002 to 1003, so linear brightness changing is not the best solution.

Program supports three smooth brightness changing functions:

`fade_function = 1` – linear

`fade_function = 2` – parabolic

`fade_function = 3` – exponential (recommended)

Linear – blue, parabolic - red, exponential - yellow. Green lines - max value (1023).
![](https://image.ibb.co/imWJu8/BX2_R8_MZp_Cw.jpg)

#### &nbsp;&nbsp;(boolean) use_sun_times

Assign to true if you want to replace toggle_time with sunset and sunrise time for your location.

#### &nbsp;&nbsp;coordinates

Coordinates for sunset and sunrise time acquiring. You can get it from google maps. If you click somewhere on map you will see coordinates of that point presented by two numbers. First number is latitude, second – longitude. 

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

I advice to use NodeMCU PyFlasher on windows (because you only need to download it and launch without any messing) and esptool.py on linux (because you can easily install it with pip and upload nodemcu firmware with one terminal command)

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

After firmware uploading you should launch upload_build.bat or upload_build.sh if you are using windows or linux respectively. I recommend to compile code during uploading (described below).

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

## Circuit 

Just connect MOSFET gate or relay coil to `lamp_pin` (in case of using relay you shouldn't enable fading) and you are ready to go.

Example with MOSFET:

![](https://image.ibb.co/ciV6go/Easy_EDA_A_Simple_and_Powerful_Electronic_Circuit_Design_Tool_Google_Chrome.png)

Note that it's a RGB LED strip, and I've connected to MOSFET only red and blue LEDs, ignoring green. More about that in next paragraph.

## Light source 

Plants are green because they reflect green color. It's obvious, but from that we can get one important thesis - light source for growing shouldn't be white (better say - shouldn't contain green in its spectre), this just isn't effective. Plants need red and blue light spectres, and if you are making custom light system using monochrome red and blue LEDs you should note that it's better when red LEDs count is 2-4 times higher than blue ones.

There are a lot of LED strips with red and blue LEDs in correct ratio. You can even find powerful 50W modules with one violet LED crystal with correct spectre, which appears to be a good solution.

#### vijexa, 2018
