#!/bin/bash

WOW_VERSION="110002"
ADDON_VERSION=$(date '+%Y.%m.%d')

rm -rf dist

echo "## Interface: $WOW_VERSION" > GearStick.toc
echo "## Title: GearingTool" >> GearStick.toc
echo "## Author: Armsperson" >> GearStick.toc
echo "## Version: $ADDON_VERSION" >> GearStick.toc
echo "## SavedVariables: GearStickSettings" >> GearStick.toc
echo "## X-Curse-Project-ID: 937058" >> GearStick.toc
echo " " >> GearStick.toc
echo "Gearing2v2.lua" >> GearStick.toc
echo "Gearing3v3.lua" >> GearStick.toc
echo "GearingPvE.lua" >> GearStick.toc
echo "GearStick.lua" >> GearStick.toc

yarn compile
