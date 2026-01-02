#!/bin/bash

WOW_VERSION="110200"
ADDON_VERSION=$(date '+%Y.%m.%d.%H')

rm -rf dist

echo "## Interface: $WOW_VERSION" > GearStick.toc
echo "## Title: GearStick" >> GearStick.toc
echo "## Author: Armsperson" >> GearStick.toc
echo "## Version: $ADDON_VERSION" >> GearStick.toc
echo "## SavedVariables: GearStickSettings" >> GearStick.toc
echo "## X-Curse-Project-ID: 937058" >> GearStick.toc
echo " " >> GearStick.toc
echo "BracketNames.lua" >> GearStick.toc
for file in $(find . -name "Gearing*.lua" -o -name "shuffle-*.lua"); do
    echo "${file#./}" >> GearStick.toc
done
echo "SlotGear.lua" >> GearStick.toc
echo "SlotGearIndexes.lua" >> GearStick.toc
echo "Enchants.lua" >> GearStick.toc
echo "EnchantsIndexes.lua" >> GearStick.toc
echo "BracketUtils.lua" >> GearStick.toc
echo "Loadouts.lua" >> GearStick.toc
echo "ItemUtils.lua" >> GearStick.toc
echo "Talents.lua" >> GearStick.toc
echo "EnchantsUI.lua" >> GearStick.toc
echo "SummaryUI.lua" >> GearStick.toc
echo "DiffUtils.lua" >> GearStick.toc
echo "DiffUI.lua" >> GearStick.toc
echo "ConfigUI.lua" >> GearStick.toc
echo "Logging.lua" >> GearStick.toc
echo "GearStick.lua" >> GearStick.toc

npm run compile
