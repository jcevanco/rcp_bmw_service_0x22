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

-- Receive Multi Frame Response Message
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

    -- Handle Multi Frame Response  
    else

      -- Check CAN-TP Header For Multi Frame Response - First Frame
      if bit.band(data[2], 0xF0) == 0x10 then

        -- Remove Flow Control Byte and Unpack Frame Data into Response Message
        local message = {data[1], unpack(data, 3)}

        -- Calculate the Number of Consecutive Frames
        -- ( Response Length - ( Received Frame Length - Frame Header ) ) / Data Bytes per Consecutive Frame
        local frames = math.ceil(((bit.lshift(bit.band(data[2], 0x0F), 8) + data[3]) - (#data - 3)) / 6)
        
        -- Prepare Flow Control Message
        -- 0x30     - Continue To Send
        -- frames   - Send Remaining Frames for This Response
        -- gc_delay - Configured Minimum Frame Delay.
        data = {bit.band(id, gc_send_msk), 0x30, frames, gc_delay}

        -- Send Flow Control Message
        if sendMessage(gc_send_id, data) == 1 then 
          
          -- Test & Initialize Optional Parameters
          if index == nil then index = 0 end

          -- Receive All Remaining Consecutive Frames
          repeat 

            -- Increment Frame Index and Receive Next Frame
            index = index + 1; id, data = recvMessage(index)

            -- Verify Frame Received
            if id ~= nil then 
              
              -- Append Frame Data to Message Data
              -- TODO: Is there a table method to do this better?
              for i = 1, #data do message[#message + 1] = data[i] end 

              -- Return After Last Consecutive Frame is Received
              if index >= frames then return id, message end

            end

          until id == nil 

        end

      -- Check CAN-TP Header For Multi Frame Response - Consecutive Frame
      elseif ( bit.band(data[2], 0xF0) == 0x20 ) and ( bit.band(data[2], 0x0F) == bit.band(index, 0x0F) ) then
      
        -- Unpack Data From Multi Frame Response
        return id, {unpack(data, 3)}

      -- Bad Frame Continuity
      else

        -- Prepare Flow Control Message
        -- 0x32 - Abort
        data = {bit.band(id, gc_send_msk), 0x32, 0x00, 0x00}

        -- Send Flow Control Message
        sendMessage(gc_can, gc_send_id, data)

      end

    end

  end

end
