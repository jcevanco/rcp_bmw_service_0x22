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
-- Minification of the script has been tested and verified using luamin. 
-- Minification can be performed by executing the build script from a
-- command line at the project root directory: sh build.sh
-- 
-- The Central Gateway Module will not simultaneously process Service 0x01
-- and Service 0x22 queries. In order for Service 0x22 queries to return
-- any useful data, OBD-II must be disabled in the RaccCapture device 
-- configuration. Channel mappings can exist, but OBD-II must be disabled.
--
-- Observed average CAN latency for single frame response queries is 14-17 ms.
-- Observed average CAN latency for multi frame response queries is 20-23 ms.
--
-- The OBDII query scheduler used in this script uses the same scheduling
-- method and algorithm as the RaceCapture device firmware. The algorithm uses
-- a bubble up method where each PID rises to the top of the query stack at a rate
-- that is based on the PID configured priority (Sample Rate) and the number of number
-- of times the scheduler has run without selecting the PID.

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

-- Import Required Module (PID Configuration)
require (pid_supra)

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
local gc_log = false

-- Enable/Disable PID Statistical Logging
-- true = Enabled
-- false = Disabled
local gc_stats = true

--
-- END OF USER CONFIGURATION OPTIONS
--

-- Set Tick Rate for Continuous Tick
setTickRate(1000)

-- Define Global Message Variables
local g_pri_max, g_lst_qry, g_lst_rsp = 0, 0, 0

-- Garbage Collection
local g_garbage = 0

-- Set CAN Bus Filter for OBD Service 0x22 Messages
setCANfilter(gc_can, 0, 0, gc_resp_id, gc_resp_msk)

-- Build RaceCapture Virtual Channels
for key, table in pairs(gc_list) do

  -- Create RaceCapture Virtual Channel and Set Initial Chanel Statistics
  table[2], table[7] = string.sub(table[2], 1, 11), string.sub(table[7], 1, 7)
  table[12] = addChannel(unpack(table, 2, 7))
  table[13], table[14], table[15], table[16], table[17] = 0, 0, 0, 0, 0

  -- Set Max Priority (Used by Query Scheduler)
  g_pri_max = math.max(g_pri_max, table[3])

end

-- Send Query Messages
function sendQuery()
  
  -- Get The Next Scheduled Query
  local key = getQuery()

  -- Verify A Query is Scheduled
  if (key ~= nil) then
  
    -- Send Query Message and Update Channel Statistics
    if sendMessage(gc_send_id, {gc_list[key][1], 0x03, 0x22, bit.band(bit.rshift(key, 8), 0xFF), bit.band(key, 0xFF)}) == 1 then
      
      -- Set Last Query Timestamp
      g_lst_qry = getUptime()

      -- Update Channel Query Count
      gc_list[key][14] = gc_list[key][14] + 1

      -- Receive Response to Query
      recvResponse()

    end
    
  end

end

-- Get th Next Secheduled Query
function getQuery()

  -- Test for Active Query in Progress
  if (getUptime() - g_lst_qry > gc_timeout) then

    -- Test for Delay in Tx after Rx
    if (getUptime() - gc_delay > g_lst_rsp) then

      -- Initialize Scheduled Key, Count and Max Count
      local sch_key, count, max_count = nil, 0, 0

      -- Process Channel Priority
      for key, table in pairs(gc_list) do

        -- Update Channel Query Stack Position (Increment by Priority)
        table[13] = table[13] + table[3]

        -- Calculate Schedule Pass Count (Schedule Passes Since Last Selection)
        count = table[13] / table[3]

        -- Evaluate Scheduling Critera
        -- Position > Maximum Priority (Trigger Threshold)
        -- Most Schedule Passes for Channels Above Trigger Threshold
        if (table[13] > g_pri_max and count > max_count) then 
          sch_key, max_count = key, count 
        end	

      end

      -- Test for Valid Schedule Key
      if (sch_key ~= nil) then

        -- Reset Priority for Scheduled Channel
        gc_list[sch_key][13] = 0

        -- Return Scheduled Channel Key
        return sch_key

      end

    end

  end

end

-- Send Query Message
function sendMessage(id, data)
  
  -- Send Message
  if txCAN(gc_can, id, 0, data, gc_timeout) == 1 then

    -- Log CAN Messages if Logging is Enabled
    if gc_log == true then logCANData(gc_can, id, data) end 

    -- Return Success
    return 1 

  end

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

-- Import Required Module (Receive Message)
-- Module Options are:
-- recv_message_multi - Enables Multi Frame Responses (required for long data types)
-- recv_message_single - Disables Multi Frame Resposes (skips/rejects responses for long data types)
require (recv_message_single)

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

      -- Apply Value Scaling - ( raw_value * mul / div + add )
      value = value * gc_list[key][9] / gc_list[key][10] + gc_list[key][11]

      -- Apply Configured Limits
      value = ( gc_list[key][5] ~= nil and math.max(value, gc_list[key][5]) or value )
      value = ( gc_list[key][6] ~= nil and math.min(value, gc_list[key][6]) or value )
      
      -- Update Channel Value
      setChannel(gc_list[key][12], value)

      -- Log PID Statistics if Logging is Enabled
      if gc_stats == true then
      
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
  
-- Output CAN Bus Data to Info Log
function logCANData(bus, id, data)

  -- Scope Variables
  local y, m, d, h, mi, s, ms = getDateTime()

  -- Build Output String
  local output = string.format("%04d-%02d-%02d %02d:%02d:%02d.%03d %9d", y, m, d, h, mi, s, ms, getUptime())
  output = output .. string.format(" %1d %4d 0x%03X %02d", bus + 1, id, id, #data)
  output = output .. string.format(string.rep(" 0x%02X", #data), unpack(data))
  
  -- Send Output to Log
  println(output)

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