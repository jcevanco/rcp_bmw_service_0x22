#!/bin/sh
## Copyright (c) 2023 The SECRET Ingredient!
# GNU General Public License v3.0
#

# Get Project Name and Version
project_name=`sed -n -e 's/\t//g ; s/"name":\ "\(.*\)",.*/\1/p' package.json`
project_version=`sed -n -e 's/\t//g ; s/"version":\ "\(.*\)"/\1/p' package.json`

# Set Base Directory
project_root=$(cd $(dirname $0); pwd)

# Set Project Directories
project_source=$project_root/src
project_resource=$project_root/res
project_make=$project_root/make
project_build=$project_root/bin

# Display Environment Settings
echo "PROJECT_NAME     = "$project_name
echo "PROJECT_VERSION  = "$project_version
echo "PROJECT_ROOT     = "$project_root
echo
echo "PROJECT_SOURCE   = "$project_source
echo "PROJECT_RESOURCE = "$project_resource
echo "PROJECT_MAKE     = "$project_make
echo "PROJECT_BUID     = "$project_build

# Clean Make and Bin Directory
rm $project_make/*.* >> $project_make/junk.out
rm $project_build/*.* >> $project_make/junk.out

# Start Build With Comment Header
cat $project_resource/head.lua > $project_make/make.out

# Import Required Modules
cat $project_source/main.lua > $project_make/require.out

# Minimize Script with LuaMin
luamin -f $project_make/require.out >> $project_make/make.out

# Get sed Script for Post Processing
SED_SCRIPT=`sed -e '/^#/d' $project_resource/sed.md`

# Run sed Commands to Adjust Layout
sed -i'.sed' -e "$SED_SCRIPT" $project_make/make.out

# Pruduce Assebmled Lua Script
cat $project_make/make.out | sed -e "s/<version>/$project_version/g" > $project_build/$project_name.lua

