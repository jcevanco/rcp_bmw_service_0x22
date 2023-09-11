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
-- Due to the size of this script and memory limitations of the RaceCapture
-- hardware, this script must be pre-processed by a Lua script minifier prior 
-- to being loaded into the RaceCapture Device. 
--
-- Failure to minify this script will produce the following error message(s):
--
-- [lua] Memory ceiling hit: ##### > 51200
-- [lua] Startup script error: (not enough memory)
-- [lua] Failure: Failed to load script
-- 
-- Minificaion of the script has been tested and verified using luamin. 
-- https://github.com/mathiasbynens/luamin.git
-- 
-- The Central Gateway Module will not simultaneously process Service 0x01
-- and Service 0x22 queries. In order for Service 0x22 queries to return
-- any useful data, OBD-II must be disabled in the RaccCapture device 
-- configuration. Channel mappings can exist, but OBD-II must be disabled.
--
-- Observed average CAN latency for single frame response queries is 15-20 ms.
-- Observed average CAN latency for multi frame response queries is 20-25 ms.
--
-- The OBDII query scheduler used in this script uses the same scheduling
-- method and algorythm as the RaceCapture device firmware.

-- Define OBD Service 0x22 PID List to poll in Key-Table Pairs
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
--  3  - Sample Rate in Hz
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
  -- char data type (8-Bit Integer)
  [ 0x5512 ] = {0x12, 'AmbientTemp',   1, 1, 0, 200,    'F',     'u', 0.9, 1, -40},
  [ 0x59FA ] = {0x12, 'Ign_Angle',    25, 1, nil, nil,  '*',     's', 0.75, 1, 0},

  -- integer data type (16-Bit Ingeter)
  [ 0x4205 ] = {0x12, 'Boost_Press',  25, 2, 0, 30,     'kPa',   'u', 20, 2560, 0},
  [ 0x4300 ] = {0x12, 'Engine_Temp',   1, 1, 0, 300,    'F',     's', 1.35, 1, -54.4},

  -- long data type (32-Bit Ingeter)
  [ 0x558F ] = {0x12, 'FPDM_Hours',    1,  1, nil, nil, 'hours', 'u', 0.5, 1, 0},
  [ 0x558E ] = {0x12, 'FPDM_Miles',    1,  1, nil, nil, 'miles', 's', 0.62, 1, 0},
}

-- Define Battery Voltage threshold for Polling.
-- Service 0x22 PID Requestes will not be sent if the
-- Battery Voltage is below this threshold
local gc_threshold = 13.5

-- BMW Service 0x22 Messaging
local gc_send_id  = 0X6F1
local gc_send_msk = 0x0FF
local gc_resp_id  = 0x600
local gc_resp_msk = 0xF00

-- CAN Bus to Use
-- 0 - CAN Bus 1
-- 1 - CAN BUS 2
local gc_can = 0

-- CAN Bus Frame Timeout (ms)
local gc_timeout = 100

-- CAN Bus Minimum Frame Delay (ms)
local gc_delay = 2

-- Enable/Disable CAN Bus Logging
-- true = Enabled
-- false = Disabled
local gc_log = true

--
-- END OF USER CONFIGURATION OPTIONS
--

-- Set Tick Rate for Continuous Tick
setTickRate(1000)

-- Define Global Message Variables
local g_smp_max, g_lst_qry, g_lst_rsp = 0, 0, 0

-- Garbage Collection
local g_garbage = 0

-- Set CAN Bus Filter for OBD Service 0x22 Messages
setCANfilter(gc_can, 0, 0, gc_resp_id, gc_resp_msk)

-- Build RaceCapture Virtual Channels
-- TODO: Check For and Implement Size Limit for Enginering Units
for key, table in pairs(gc_list) do

  -- Create RaceCapture Virtual Channel and Set Initial Chanel Statistics
  table[12] = addChannel(string.sub(table[2], 1, 11), unpack(table, 3, 6), string.sub(table[7], 1, 7))
  table[13], table[14], table[15], table[16], table[17] = 0, 0, 0, 0, 0

  -- Set Max Sample Rate (Used by Query Scheduler)
  g_smp_max = math.max(g_smp_max, table[3])

end

-- Required Modules
require (get_query)
require (recv_message_multi)
require (log_can)

-- Send Query Messages
function sendQuery()
  
  -- Get Scheduled Query
  local key = getQuery()

  -- Verify Scheduled Query
  if (key ~= nil) then
  
    -- Send Message and Update Channel Statistics
    if sendMessage(gc_send_id, {gc_list[key][1], 0x03, 0x22, bit.band(bit.rshift(key, 8), 0xFF), bit.band(key, 0xFF)}) == 1 then
      
      -- Set Last Query Timestamp
      g_lst_qry = getUptime()

      -- Update Channel Query Count
      gc_list[key][14] = gc_list[key][14] + 1

      -- Query Sent
      recvResponse()

    end
    
  end

end

-- Send Request Message
function sendMessage(id, message)
  
  -- Scope Variables
  local success = txCAN(gc_can, id, 0, message, gc_timeout)

  -- Log CAN Messages if Logging is Enabled
  if success == 1 and gc_log == true then logCANData(gc_can, id, nil, message) end 

  -- Return Data
  return success 

end

function recvResponse()

  -- Receive Response
  local id, data = recvMessage()

  -- Verify Message Received 
  -- Verify Active Query in Progress
  -- Verify Message Destination ECU Address
  -- Verfiy Service 0x22 Query Response (0x62)
  if id ~= nil and 
     g_lst_qry ~= 0 and 
     bit.band(gc_send_id, gc_send_msk) == data[1] and
     data[3] == 0x62 then
    
    -- Process Received Data
    if processData(id, data) == 1 then

      -- Update Query Processing Timestamps
      g_lst_qry = 0
      g_lst_rsp = getUptime()

    end

  end

end

-- Process Payload Data
function processData(id, data)

  -- Extract PID From Message Payload - ( Byte 4 and Byte 5 )
  local key = bit.lshift(data[4], 8) + data[5]

  -- Check Message Key-Table Pair for PID
  if gc_list[key] then
    
    -- Verify Responding ECU Module Addresses and Correct Service Code
    if bit.band(id, gc_send_msk) == gc_list[key][1] then

      -- Extract PID Data Value
      local value = 0
      for i = 6, (data[2] + 2) do 
        value = value + bit.lshift(data[i], 8 * ((data[2] + 2) - i))
      end

      -- Check for and Process Signed Data Type
      if gc_list[key][8] == 's' then 
        value = signedInteger(value, (data[2] - 3))
      end

      -- Apply Configured Limits
      if gc_list[key][5] ~= nil then value = math.max(value, gc_list[key][5]) end
      if gc_list[key][6] ~= nil then value = math.min(value, gc_list[key][6]) end
      
      -- Update Channel Value
      setChannel(gc_list[key][12], (value * gc_list[key][9] / gc_list[key][10] + gc_list[key][11]))

      -- Log Channel Statistics
      if gc_log == true then

        -- Update Channel Statistics
        local ts = getUptime()
        gc_list[key][16] = ( gc_list[key][15] ~= 0 and ( ( gc_list[key][14] * gc_list[key][16] ) + ( ts - gc_list[key][15] ) ) /  ( gc_list[key][14] + 1 ) or 0 )
        gc_list[key][17] = ( gc_list[key][15] ~= 0 and ( ( gc_list[key][14] * gc_list[key][17] ) + ( ts - g_lst_qry ) ) / ( gc_list[key][14] + 1 ) or 0 )

        -- Send Channel Statistics to Log
        println(string.format("[0x%04X] - TS:[%d] QC:[%d] LU:[%d] AR:[%d] AL:[%d]", key, ts, unpack(gc_list[key], 14)))

        -- Updte Channel Last Update Timestamp
        gc_list[key][15] = ts

      end

      -- Return Success
      return 1

    end

  end

end

-- Convert Unsigned Integer to Signed Integer
function signedInteger(data, size) 
  return (data >= math.pow(2, (size * 8 - 1)) and data - math.pow(2, (size * 8 ))) or data 
end
  
-- Process Tick Events 
function onTick()

  -- Gollect Garbage
  if ((getUptime() - g_garbage) >= 1000) then 
    collectgarbage() 
    g_garbage = getUptime() 
  end

  -- Check For Vehicle Running and Send PID Requests
  if (getChannel("Battery") ~= nil) and (getChannel("Battery") >= gc_threshold) then
    sendQuery()
  end

end