-- RCP BMW Servie 0x22 Script
-- Copyright (c) 2024 The SECRET Ingredient!
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

-- Receive Single Frame Response Message
function recvMessage(index)

  -- Retrieve Message From CAN Bus
  local id, ext, data = rxCAN(gc_can, gc_timeout)

  -- Validate Message Received
  if id ~= nil then

    -- Log CAN Message Frame if Logging is Enabled
    if gc_log == true then logCANData(gc_can, id, data) end

    -- Check CAN-TP Header for Single Frame Response
    if bit.band(data[2], 0xF0) == 0x00 then

      -- Return Single Frame Response
      return id, data

    -- Send Abort for Multi Frame Response  
    else

      -- Prepare Flow Control Message
      -- 0x32 - Abort
      data = {bit.band(id, gc_send_msk), 0x32, 0x00, 0x00}

      -- Send Flow Control Message
      sendMessage(gc_can, gc_send_id, data)

    end

  end

end
