#!/bin/bash

if [ -d "/opt/system/Tools/PortMaster/" ]; then
  controlfolder="/opt/system/Tools/PortMaster"
elif [ -d "/opt/tools/PortMaster/" ]; then
  controlfolder="/opt/tools/PortMaster"
else
  controlfolder="/roms/ports/PortMaster"
fi

source $controlfolder/control.txt
[ -f "${controlfolder}/mod_${CFW_NAME}.txt" ] && source "${controlfolder}/mod_${CFW_NAME}.txt"
get_controls

# Variables
GAMEDIR=/$directory/ports/fieldsofmistria

# CD and set permissions
cd $GAMEDIR
> "$GAMEDIR/log.txt" && exec > >(tee "$GAMEDIR/log.txt") 2>&1
$ESUDO chmod +x -R $GAMEDIR/*

# Display loading splash
if [ -f "$GAMEDIR/patchlog.txt" ]; then
    [ "$CFW_NAME" == "muOS" ] && $ESUDO $GAMEDIR/splash "splash.png" 1
    $ESUDO $GAMEDIR/splash "splash.png" 30000 & 
fi

# Exports
export PATCHER_FILE="$GAMEDIR/patch/patchscript"
export PATCHER_GAME="$(basename "${0%.*}")" # This gets the current script filename without the extension
export PATCHER_TIME="1 to 3 minutes"

export SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig"
export WINEPREFIX=~/.wine64
export WINEDEBUG=-all

# Install dependencies
if ! winetricks list-installed | grep -q "^vcrun2022$"; then
    pm_message "vcrun2022 is not installed. Installing now."
    winetricks --unattended --no-isolate vcrun2022
else
    pm_message "vcrun2022 is already installed. Skipping installation."
fi

# Config Setup
mkdir -p $GAMEDIR/config
bind_directories "$WINEPREFIX/drive_c/users/root/AppData/Local/FieldsOfMistria" "$GAMEDIR/config"

# Check if patchlog.txt to skip patching
if [ ! -f patchlog.txt ]; then
    if [ -f "$controlfolder/utils/patcher.txt" ]; then
        source "$controlfolder/utils/patcher.txt"
        $ESUDO kill -9 $(pidof gptokeyb)
    else
        pm_message "This port requires the latest version of PortMaster."
    fi
else
    pm_message "Patching process already completed. Skipping."
fi

# Run the game
$GPTOKEYB "FieldsOfMistria.exe" -c "./mistria.gptk" &
$GAMEDIR/box64 wine64 "./data/FieldsOfMistria.exe"

# Kill processes
wineserver -k
pm_finish