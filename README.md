# rcp_bmw_service_0x22
BMW OBD Servie 0x22 Script
Copyright (c) 2024 The SECRET Ingredient!
GNU General Public License v3.0

Lua script for use with RaceCapture motorsports telemetry systems. This script enables RaceCapture systems to perform OBDII Service 0x22 querries on BMW vehicles.

Additinal information available at: https://thesecretingredient.neocities.org

### Environment Setup

Make sure that you have the node module dependancies installed:

```sh
npm install
```

or

```sh
yarn install
```


### Personalization

Edit `src/pid_list.lua` to supply your specific PID list to query.

### Build Lua Script For Loading into RaceCapture Device

```sh
sh build.sh
```

if you are experiencing memory limit issues try the "tiny" option. It produces the smallest script possible, but can be very difficult to read and maintain once loaded into the RaceCapture device.

```sh
sh build.sh -t
```
