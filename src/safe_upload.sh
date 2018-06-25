#!/bin/bash

dir="${0%/*}"
nodemcu-tool -p $1 -b 115200 reset
sleep 2
nodemcu-tool -p $1 -b 115200 remove init.lua
nodemcu-tool -p $1 -b 115200 reset
sleep 2
nodemcu-tool -p $1 -b 115200 upload $2
nodemcu-tool -p $1 -b 115200 upload $dir/init.lua
nodemcu-tool -p $1 -b 115200 reset 
nodemcu-tool -p $1 -b 115200 terminal