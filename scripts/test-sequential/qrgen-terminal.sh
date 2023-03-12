#!/bin/bash

## QRGen Terminal Script 

# 1) get a list of all apps
# 2) get argument with the working folder path
# 3) execute sequentially all the apps invoking the command for the visualizer (remember 10 seconds cooldown for the last one and then exit!)

# CHANGE THIS IF NEEDED
qrgendir=$(realpath ../../tools/QRCodeGenerator)
qrfuzzdir=$(realpath ../../tools/QRCodeFuzzer)


# Do not edit under here

function echoerr {
    echo -e "\e[31m$1\e[39m"
}

function echosuc {
    echo -e "\e[32m$1\e[39m"
}

timestamp=$(date +%s)

function echolog {
    printf '[%s] %s\n' "$(date +%F_%H-%M-%S)" "$1" >> log-qrgen-terminal-"$timestamp".txt
}

bo=$(tput bold)
no=$(tput sgr0)

echosuc "[ QRCodeGenerator Terminal ]"
echo "[?] Checking script arguments"

# Usage text
text_version="\t QRCodeGenerator Terminal \n"
text_usage="${bo}USAGE${no}\n"
text_usage+="\t ./qrgen-terminal.sh [ARGUMENTS]\n"
text_usage+="${bo}APP${no} \n"
text_usage+="$text_version \n"
text_usage+="${bo}ARGUMENTS${no} \n"
text_usage+="\t -p <position> {left, right, center} \t (REQUIRED) Set the position of the QR Code Visualizer Window \n"
text_usage+="\t -f <path_text_file> \t\t\t\t (REQUIRED) Set path to a text file with app list to test (for each line, one app) \n"
text_usage+="\t -s <start_position> \t\t\t Set the position number to start from \n"
text_usage+="\t --use-standard \t\t\t Enable standard QR code generation \n"
usage=$(printf "$text_usage \n")

standard=""; position=""; apps=""; start="";

# Check Arguments
while [[ $# -gt 0 ]]; do
    case "${1}" in
        '-f')
            apps="${2}"; shift 2 ;;
        '-s')
            start="${2}"; shift 2 ;;
        '-p')
            position="${2}"; shift 2 ;;
        '--use-standard')
            standard="--standard"; shift 1 ;;
        *)
            echo "$usage"; echoerr "[Error] Invalid flag ${1}"; exit 1 ;;
    esac
done

# Check App arguments
if [ -z "$apps" ]
then
    echo "$usage"
    echoerr "[Error] Path to text file with app list (-f) is required"
    exit 1
fi

# Check position arguments
case "$position" in
  left|right|center)
    echosuc "The window will be positioned on the: $position"
    ;;
  *)
    echo "$usage"; echoerr "[Error] Please, the -p argument is required and must be {left, right, center}"
    exit 1
esac

# Check start arguments
if [ -z "$start" ]
then
    start=0
fi


# Load apps 
filename="$apps"
IFS=$'\n' read -d '' -r -a app < "$filename"

echosuc "[OK] ${#app[@]} apps loaded:"
echosuc "${app[*]}"

echo "[?] Executing the qr gen sequentially"
echo "[?] Be aware that after the end of each script, the QrGen sleeps for 10 seconds"

echolog "QRGen Terminal Script started"
echolog "-- CONFIGURATION"
echolog "Position of the window: $position"
echolog "Number of apps loaded: ${#app[@]}"
echolog "List of apps loaded: ${app[*]}"
echolog "Starting QR from: $start"
echolog "Extra parameters: $standard"
echolog "-- EXECUTION"

for i in "${app[@]}"
do
    echolog "Current analysis: $i"
	echosuc "----------- NOW EXECUTING $i -------------"
    dir="$qrfuzzdir/data-tests/$i"
    if [[ ! -e $dir ]]; then
        mkdir "$dir"
        mkdir "$dir/screen"
        mkdir "$dir/logs"
        touch "$dir/fuzzer.json"
        touch "$dir/qrcodes-logs.csv"
        touch "$dir/qrcodes-payloads.txt"
        echolog "Folder exists: No, just created at $dir"
        echosuc "[OK] Creating folders and files because $dir did not existed"
    else 
        echolog "Folder exists: Yes, at $dir"
        echosuc "[?] Folder $dir already exists"
    fi
    echolog "Python script START for $i"
    echo "[?] Starting python script..."

    if [ $standard ]
    then
        echo "[?] STANDARD QR Codes"
        python "$qrgendir"/main.py -a "$i" -j "$dir" -p "$position" -sf "$start" --standard
    else
        echo "[?] AD-HOC QR Codes"
        python "$qrgendir"/main.py -a "$i" -j "$dir" -p "$position" -sf "$start"
    fi
    
    echosuc "----------- END $i -------------"
    echo "[?] Sleeping for 10s"
    echolog "Python script FINISH for $i"
    sleep 5
done

echolog "QRGen Terminal Script exited"
