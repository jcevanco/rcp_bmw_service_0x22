-- RCP BMW Servie 0x22 Script
-- Copyright (c) 2023 The SECRET Ingredient!
-- GNU General Public License v3.0
--
-- This is free software: you can redistribute it and/or modify it
-- under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
-- 
-- This software is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
-- 
-- See the GNU General Public License for more details. You should
-- have received a copy of the GNU General Public License along with
-- this code. If not, see <http://www.gnu.org/licenses/>.
--
-- Select BMW OBD Service 0x22 PID Maps Available at
-- https://thesecretingredient.neocities.org
-- https://github.com/jcevanco/rcp_bmw_service_0x22.git
--

-- The OBD Service 0x22 PID List is configured in Lua Key-Table Pairs as follows.
-- 
-- [  KEY   ] = {                     TABLE                          },         
-- [ 0x4201 ] = {0x12, 'AAP', 1, 1, nil, nil, 'kPa', 'u', 10, 2560, 0},
-- 
-- [  KEY   ] - OBD Service 0x22 PID in hex notation
-- 
-- List of Table Data Items by Index
--
--  1  - Destination ECU Module Address in hex notation
--
--  RaceCapture Virtual Channel Configuration
--
--  2  - RaceCapture Channel Name (12 Character Maximum)
--  3  - Priority (low - 1, 5, 10, 25, 50 - high) 
--  4  - Precision (Number of decimals to display)
--  5  - Minimum Value [optional - can be nil] 
--  6  - Maximum Value [optional - can be nil]
--  7  - Engineering Units (8 Character Maximum)
--
--  Raw Message Data Processing and Scaling
--
--  8  - Data Type ( 'u' = unsigned, 's' = signed )
--  9  - Multiply
--  10 - Divide
--  11 - Add
--
--  Channel Status Data used by Script.
--
--  12 - RaceCapture Virtual Channel ID
--  13 - Channel Priority (used by Query Scheduler)
--  14 - Query Count (total number of querries)
--  15 - Last Update (timestamp of last update)
--  16 - Average Update Rate (ms)
--  17 - Average Network Latency (ms)
--

-- Sample PID Configuration. One PID for each data type supported.
--

local gc_list = {
  -- char data type (8-Bit Integer)
  [ 0x5512 ] = {0x12, 'AmbientTemp',  1, 1, 0, 200,    'F',     'u', 0.9, 1, -40},
  [ 0x59FA ] = {0x12, 'Ign_Angle',   25, 1, nil, nil,  '*',     's', 0.75, 1, 0},

  -- integer data type (16-Bit Ingeter)
  [ 0x4205 ] = {0x12, 'Boost_Press', 25, 2, 0, 30,     'kPa',   'u', 20, 2560, 0},
  [ 0x4300 ] = {0x12, 'Engine_Temp',  1, 1, 0, 300,    'F',     's', 1.35, 1, -54.4},

  -- long data type (32-Bit Ingeter)
  [ 0x558F ] = {0x12, 'FPDM_Hours',   1,  1, nil, nil, 'hours', 'u', 0.5, 1, 0},
  [ 0x558E ] = {0x12, 'FPDM_Miles',   1,  1, nil, nil, 'miles', 's', 0.62, 1, 0},
}

