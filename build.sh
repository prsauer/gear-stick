#!/bin/bash

WOW_VERSION="110100"
ADDON_VERSION=$(date '+%Y.%m.%d.%H')

rm -rf dist

echo "## Interface: $WOW_VERSION" > GearStick.toc
echo "## Title: GearStick" >> GearStick.toc
echo "## Author: Armsperson" >> GearStick.toc
echo "## Version: $ADDON_VERSION" >> GearStick.toc
echo "## SavedVariables: GearStickSettings" >> GearStick.toc
echo "## X-Curse-Project-ID: 937058" >> GearStick.toc
echo " " >> GearStick.toc
echo "Gearing2v2.lua" >> GearStick.toc
echo "Gearing3v3.lua" >> GearStick.toc
echo "GearingPvE.lua" >> GearStick.toc
echo "Loadouts.lua" >> GearStick.toc
echo "Talents.lua" >> GearStick.toc
echo "GearStick.lua" >> GearStick.toc

yarn compile
