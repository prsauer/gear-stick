#!/bin/bash

WOW_VERSION="100200"
ADDON_VERSION=$(date '+%Y.%m.%d')

rm -rf dist

echo "## Interface: $WOW_VERSION" >> GearStick.toc
echo "## Title: GearingTool" >> GearStick.toc
echo "## Author: Armsperson" >> GearStick.toc
echo "## Version: $ADDON_VERSION" >> GearStick.toc
echo " " >> GearStick.toc
echo "Gearing2v2.lua" >> GearStick.toc
echo "GearingPvE.lua" >> GearStick.toc
echo "GearStick.lua" >> GearStick.toc

yarn compile
