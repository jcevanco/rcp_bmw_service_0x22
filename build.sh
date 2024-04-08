#!/bin/sh
# RCP BMW Servie 0x22 Script
# Copyright (c) 2024 The SECRET Ingredient!
# GNU General Public License v3.0
#

# Process Command Line Options
tiny='0'
while true
do
	# Test Parameters
	case $1 in 
		('-h')
			echo \
'
      Usage: build.sh [-h|-t]
      Where: -h : prints this help message, then exits
             -t : builds final script with minimal header comments,
                  full minimization and no post processing for script
                  readability. Used to make the script as small (tiny) 
                  as possible when experiencing memory limit issues 
                  with RaceCapture hardware devices.

Description: Builds the projct Lua script for loading into a RaceCapture
             device. 

       NOTE: This script has node module development environment 
             dependancies. Run [npm insall] or [yarn install] to install
             development environment dependancies.
'
			exit
			;;

		('') 
			break
			;;

		('-t') 
			tiny='1'
			shift
			;;
	esac
done

# Get Project Name and Version
project_name=`sed -n -e '/name/ { s/.*: "\(.*\)",/\1/p
                                  q
                                }' package.json`
project_version=`sed -n -e '/version/ { s/.*: "\(.*\)",/\1/p
                                        q
                                      }' package.json`

# Set Project Root Directory
project_root=$(cd $(dirname $0); pwd)

# Set Project Directories
project_source=$project_root/src
project_include=$project_root/src/inc
project_resource=$project_root/res
project_make=$project_root/make
project_build=$project_root/bin

# Display Environment Settings
echo "PROJECT_NAME     = "$project_name
echo "PROJECT_VERSION  = "$project_version
echo "PROJECT_ROOT     = "$project_root
echo
echo "PROJECT_SOURCE   = "$project_source
echo "project_INCLUDE  = "$project_include
echo "PROJECT_RESOURCE = "$project_resource
echo "PROJECT_MAKE     = "$project_make
echo "PROJECT_BUID     = "$project_build
echo

# Clean Make and Build Directory
node_modules/.bin/rimraf $project_make $project_build

# Create Make and Build Directory
mkdir $project_make
mkdir $project_build

# Start Build With Comment Header
echo "Building Project"
case $tiny in
	('0')
    cat $project_resource/head.lua > $project_make/make.out
    ;;
	('1')
		head -n 4 $project_resource/head.lua > $project_make/make.out
		;;
esac

# Import Required Modules
echo
echo "Import Required Modules"

# Get List of Required Modules
cat $project_source/main.lua > $project_make/require.out
sed -n -e '/require/s/.*require (\(.*\)).*/\1/p' $project_make/require.out | while read i
do
    # Import Required Module
    echo "Module: $i.lua"
    sed -e "/($i)/ { r $project_include/$i.lua
                   d
                 }" -i'.sed' $project_make/require.out
done

# Minimize Function Names
echo
echo "Process Script Functions"
cat $project_make/require.out > $project_make/functions.out

# Get List of Function Names
sed -n -e '/function/s/.* \(.*\)(.*/\1/p' $project_make/functions.out | \
sed -e '/onTick/d' | \
while read i
do
    # Minimize Function Name in Script
    j=`echo "$i" | sed -n -e 's/\([a-z]\).*\([A-Z]\).*/_\1\2/p'`
    echo "Function: $i\t-> $j"
    sed -e "s/$i(/$j(/g" -i'.sed' $project_make/functions.out
done

# Minimize Script with Luamin
luamin_ver=`node_modules/.bin/luamin -v`
echo
echo "Minimize Lua Script - luamin, $luamin_ver"
node_modules/.bin/luamin -f $project_make/functions.out >> $project_make/make.out

# Post Processing
case $tiny in
	('0')
    # Get sed Script for Post Processing
    SED_SCRIPT=`sed -e '/^#/d' $project_resource/sed.md`

    # Run sed Commands to Adjust Layout
    sed -e "$SED_SCRIPT" -i'.sed' $project_make/make.out
    ;;
	('1')
    ;;
esac

# Pruduce Assebmled Lua Script
cat $project_make/make.out | sed -e "s/<version>/$project_version/g" > "$project_build/$project_name.lua"

echo
echo "Build Complete: $project_name, v.$project_version"
echo
