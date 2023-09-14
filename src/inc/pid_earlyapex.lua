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

local gc_list = {
    [ 0x442C ] = {0x12, 'OilLevel',     1, 1, nil, nil, 'mm',  'u', 1, 1, 0}, 
    [ 0x4650 ] = {0x12, 'TransTemp',    1, 1, 0, 300,   'F',   'u', 1.35, 1, -54.4},
    [ 0x4A2D ] = {0x12, 'MAP',         25, 1, 0, 300,   'kPa', 'u', 20, 2560, 0},
    [ 0x4A49 ] = {0x12, 'IgnTiming1',  25, 1, nil, nil, '*',   's', 1, 10, 0},
    [ 0x4A4A ] = {0x12, 'IgnTiming2',  25, 1, nil, nil, '*',   's', 1, 10, 0},
    [ 0x4A4C ] = {0x12, 'IgnTiming3',  25, 1, nil, nil, '*',   's', 1, 10, 0},
    [ 0x4A4D ] = {0x12, 'IgnTiming4',  25, 1, nil, nil, '*',   's', 1, 10, 0},
    [ 0x4A4E ] = {0x12, 'IgnTiming5',  25, 1, nil, nil, '*',   's', 1, 10, 0},
    [ 0x4A4F ] = {0x12, 'IgnTiming6',  25, 1, nil, nil, '*',   's', 1, 10, 0},
    [ 0x4A6C ] = {0x12, 'STFT',        25, 2, -25, 25,  '%',   's', 1, 1000, 0},
    [ 0x580F ] = {0x12, 'IAT',         10, 1, 0, 200,   'F',   'u', 1.35, 1, -54.4},
    [ 0x5813 ] = {0x12, 'LoadActual',  25, 1, nil, nil, '%',   'u', 0.75, 1, 0},
    [ 0x480C ] = {0x12, 'LoadTarget',  25, 1, nil, nil, '%',   'u', 0.75, 32, 0}, 	
    [ 0x586F ] = {0x12, 'OilPress',    10, 1, 0, 100,   'psi', 's', 14.696, 1013.25, 0}, 
    [ 0x5889 ] = {0x12, 'Lambda',      25, 2, 0, 2,     '',    'u', 16, 65535, 0}, 
    [ 0x5890 ] = {0x12, 'CoolantOut',  10, 1, 0, 300,   'F',   'u', 1.35, 1, -54.4},
    [ 0x59FA ] = {0x12, 'IgnTiming',   25, 1, nil, nil, '*',   's', 0.75, 1, 0},
}
