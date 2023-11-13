#!/bin/bash

WOW_VERSION="100200"
ADDON_VERSION=$(date '+%Y.%m.%d')

rm -rf build
rm -rf dist

mkdir build
mkdir build/GearStick

echo "## Interface: $WOW_VERSION" >> build/GearStick/GearStick.toc
echo "## Title: GearingTool" >> build/GearStick/GearStick.toc
echo "## Author: Armsperson" >> build/GearStick/GearStick.toc
echo "## Version: $ADDON_VERSION" >> build/GearStick/GearStick.toc
echo " " >> build/GearStick/GearStick.toc
echo "Gearing2v2.lua" >> build/GearStick/GearStick.toc
echo "GearingPvE.lua" >> build/GearStick/GearStick.toc
echo "GearStick.lua" >> build/GearStick/GearStick.toc

yarn compile

cp src/GearStick.lua build/GearStick

cd build
zip -r GearStick_$ADDON_VERSION.zip GearStick
cd ..
