-- RCP BMW Servie 0x22 Query Optimization Script
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

-- Get Next Secheduled Query
-- Uses the Same Scheduling Method as the 
-- RaceCapture Device OBDII Query Scheduler
function getQuery()

  -- Test for Active Query in Progress
  if (getUptime() - g_lst_qry > gc_timeout) then

    -- Test for Delay in Tx after Rx
    if (getUptime() - gc_delay > g_lst_rsp) then

      -- Initialize Scheduled Key, Factor and Max Factor
      local sch_key, factor, max_factor = nil, 0, 0

      -- Process Channel Priority
      for key, table in pairs(gc_list) do

        -- Update Channel Priority (Increment by Sample Rate)
        table[13] = table[13] + table[3]

        -- Calculate Schedule Factor (Schedule Passes Since Last Selection)
        factor = table[13] / table[3]

        -- Evaluate Scheduling Critera
        -- Priority > Maximum Sample Rate (Trigger Threshold)
        -- Most Schedule Passes for Channels Above Trigger Threshold
        if (table[13] > g_smp_max and factor > max_factor) then 
          sch_key, max_factor = key, factor 
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
