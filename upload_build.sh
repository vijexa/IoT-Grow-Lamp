#!/bin/bash

usage() { 
    echo "Usage: $0 [-p <port>] [-b <baudrate>] [-c] [-f]" 1>&2 
    echo "-p : specifies device port (/dev/ttyUSB0 for example)" 1>&2
    echo "-b : specifies baudrate (115200 if not specified)" 1>&2
    echo "-c : compile .lua files" 1>&2
    echo "-f : format ESP8266 filesystem" 1>&2
    echo ""
    echo "ports available: "
    sudo node `dirname $0`/node_modules/nodemcu-tool/bin/nodemcu-tool.js devices
    exit 0
}

[ $# -eq 0 ] && usage

baudrate=115200
while getopts ":p:b:cfh" arg; do
    case $arg in
        p) 
            port=${OPTARG}
            ;;
        b) 
            baudrate=${OPTARG}
            ;;
        c) 
            compile="true"
            ;;
        f)
            format="true"
            ;;
        h | *) # display help
            usage
            ;;
    esac
done
[ "$port" == "" ] && usage

mkdir `dirname $0`/build_temp

cp `dirname $0`/src/*.lua `dirname $0`/build_temp/
cp `dirname $0`/src/*.json `dirname $0`/build_temp/

# changing .lua to .lc in dofiles
if [ "$compile" == "true" ]
then
    echo ""
    echo "Preprocessing..."
    for filename in `dirname $0`/build_temp/*.lua; do
        node `dirname $0`/build/luatolc.js $filename
    done
fi

# formatting fs
if [ "$format" == "true" ]
then
    echo ""
    echo "Formatting..."
    sudo node `dirname $0`/node_modules/nodemcu-tool/bin/nodemcu-tool.js -p $port -b $baudrate reset
    sleep 2
    sudo node `dirname $0`/node_modules/nodemcu-tool/bin/nodemcu-tool.js -p $port -b $baudrate remove init.lua
    sudo node `dirname $0`/node_modules/nodemcu-tool/bin/nodemcu-tool.js -p $port -b $baudrate reset
    sleep 2
    sudo node `dirname $0`/node_modules/nodemcu-tool/bin/nodemcu-tool.js -p $port -b $baudrate mkfs
fi

echo ""
echo "Uploading..."
sudo node `dirname $0`/node_modules/nodemcu-tool/bin/nodemcu-tool.js -p $port -b $baudrate reset
sleep 2
sudo node `dirname $0`/node_modules/nodemcu-tool/bin/nodemcu-tool.js -p $port -b $baudrate remove init.lua
sudo node `dirname $0`/node_modules/nodemcu-tool/bin/nodemcu-tool.js -p $port -b $baudrate reset
sleep 2
for filename in `dirname $0`/build_temp/*; do
    echo ""
    echo "$filename"
    if [ "$compile" == true ] && [ $filename != `dirname $0`/build_temp/init.lua ]
    then
        sudo node `dirname $0`/node_modules/nodemcu-tool/bin/nodemcu-tool.js -p $port -b $baudrate upload -c $filename
    else 
        sudo node `dirname $0`/node_modules/nodemcu-tool/bin/nodemcu-tool.js -p $port -b $baudrate upload $filename
    fi
    
done
rm -r build_temp

sudo node `dirname $0`/node_modules/nodemcu-tool/bin/nodemcu-tool.js -p $port -b $baudrate reset
sudo node `dirname $0`/node_modules/nodemcu-tool/bin/nodemcu-tool.js -p $port -b $baudrate terminal

exit 0