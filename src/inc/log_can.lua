-- CAN Bus Data Logging Script
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

-- Output CAN Bus Data to Info Log
function logCANData(bus, id, ext, data)

  -- Scope Variables
  local y, m, d, h, mi, s, ms = getDateTime()

  -- Build Output String
  local output = string.format("%04d-%02d-%02d %02d:%02d:%02d.%03d %9d", y, m, d, h, mi, s, ms, getUptime())
  output = output .. string.format(" %1d " .. (ext == 1 and "%10d 0x%08X" or "%4d 0x%03X") .." %02d", bus + 1, id, id, #data)
  output = output .. string.format(string.rep(" 0x%02X", #data), unpack(data))
  
  -- Send Output to Log
  println(output)

end
