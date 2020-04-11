require("defines")

-- ----------------------------------------------
-- Global force functions
-- ----------------------------------------------

local function initialize_global()
   if global[GLOBAL_FORCES] == nil then
      global[GLOBAL_FORCES] = {}
   end
   
   if global[GLOBAL_FORCE_NAME_MAP] == nil then
      global[GLOBAL_FORCE_NAME_MAP] = {}
   end
end

-- @param force: LuaForce
-- @return bool
local function is_alliance_force(force)
   initialize_global()
   return global[GLOBAL_FORCES][force.name] ~= nil
end

-- @param force: LuaForce
-- @return string
local function get_alliance_force_name(force)
   initialize_global()
   return global[GLOBAL_FORCE_NAME_MAP][force.name]
end

-- @param player: LuaPlayer
-- @return LuaForce
local function create_alliance_force(player)
   initialize_global()
   local force_name = GLOBAL_FORCE_NAME .. player.name
   local new_force = game.create_force(force_name)
   global[GLOBAL_FORCES][force_name] = new_force
   global[GLOBAL_FORCE_NAME_MAP][force_name] = player.name
   return new_force
end

-- ----------------------------------------------
-- Alliance functions
-- ----------------------------------------------

-- @param player: LuaForce
-- @param other: LuaForce
-- @return bool
local function is_enemy(player, other)
   local ceasefire = player.get_cease_fire(other)
   local friend = player.get_friend(other)
   return not ceasefire and not friend
end

-- @param player: LuaForce
-- @param other: LuaForce
-- @return bool
local function is_neutral(player, other)
   local ceasefire = player.get_cease_fire(other)
   local friend = player.get_friend(other)
   return ceasefire and not friend
end

-- @param player: LuaForce
-- @param other: LuaForce
-- @return bool
local function is_ally(player, other)
   local ceasefire = player.get_cease_fire(other)
   local friend = player.get_friend(other)
   return friend
end

-- @param player: LuaPlayer
-- @param other: LuaForce
local function set_enemy(player, other)
   player.set_cease_fire(other, false)
   player.set_friend(other, false)
   player.print({"set_enemy", game.tick, other.name})
end

-- @param player: LuaForce
-- @param other: LuaForce
local function set_neutral(player, other)
   player.set_cease_fire(other, true)
   player.set_friend(other, false)
   player.print({"set_neutral", game.tick, other.name})
end

-- @param player: LuaForce
-- @param other: LuaForce
local function set_ally(player, other)
   player.set_cease_fire(other, true)
   player.set_friend(other, true)
   player.print({"set_ally", game.tick, other.name})
end

-- @param player: LuaForce
-- @param other: LuaForce
local function set_mutual_ally(player, other)
   player.set_cease_fire(other, true)
   player.set_friend(other, true)
   other.set_cease_fire(player, true)
   other.set_friend(player, true)
end

-- @param player: LuaForce
-- @param other: LuaForce
local function is_whitelisted_force_pair(player, other)
   return player ~= other and is_alliance_force(other)
end

-- ----------------------------------------------
-- Force functions
-- ----------------------------------------------

-- @param player: LuaPlayer
-- @return bool
local function is_solo(player)
   return is_alliance_force(player.force)
end

-- @param player: LuaPlayer
local function mark_solo(player)
   if (not is_solo(player)) then
      local force_name = GLOBAL_FORCE_NAME .. player.name
      if (game.forces[force_name] == nil) then
         local new_force = create_alliance_force(player)
         -- Copy over the research from the old force to the new one
         for key, tech in pairs(player.force.technologies) do
            new_force.technologies[key].researched = tech.researched
         end
         -- Solo player buff
         new_force.character_build_distance_bonus = new_force.character_build_distance_bonus + 30
         new_force.character_reach_distance_bonus = new_force.character_reach_distance_bonus + 30
         new_force.character_resource_reach_distance_bonus = new_force.character_resource_reach_distance_bonus + 30
         new_force.character_inventory_slots_bonus = new_force.character_inventory_slots_bonus + 30
         new_force.manual_mining_speed_modifier = new_force.manual_mining_speed_modifier + 1
         -- Default is friendly to the player's old force
         set_mutual_ally(player.force, new_force)
         -- Have the previous force share vision with the world
         player.force.share_chart = true
      end
      player.force = game.forces[force_name]
      table.insert(FORCE_CHART_ALL_PENDING, player.force)
      player.print({"new_assignment", force_name})
   end
end

-- ----------------------------------------------
-- GUI functions
-- ----------------------------------------------

-- @param player: LuaPlayer
-- @return bool
local function exists_top(player)
   return player.gui.top[TOP_FLOW] ~= nil
end

-- @param player: LuaPlayer
-- @return bool
local function exists_left(player)
   return player.gui.left[LEFT_FLOW] ~= nil
end

-- @param player: LuaPlayer
local function destroy_left(player)
   player.gui.left[LEFT_FLOW].destroy()
end

-- @param player: LuaPlayer
local function create_top(player)
   local flow = player.gui.top.add{
      type = "flow",
      name = TOP_FLOW,
      style = TOP_FLOW_STYLE,
   }

   flow.add{
      type = "button",
      caption = "<3",
      name = BUTTON_NAME,
      style = BUTTON_STYLE,
   }
end

-- @param player: LuaPlayer
local function create_left(player)
   local flow = player.gui.left.add{
      type = "flow",
      direction = "vertical",
      name = LEFT_FLOW,
      style = LEFT_FLOW_STYLE,
   }

   local settings_frame = flow.add{
      type = "frame",
      caption = {"settings_frame_title"},
      name = SETTINGS_FRAME_NAME,
   }

   if (not is_solo(player)) then
      local alliance_settings_solo = SETTINGS_SOLO .. player.name
      settings_frame.add{
         type = "button",
         name = alliance_settings_solo,
         caption={"settings_table_solo"},
      }
      ON_BUTTON[alliance_settings_solo] = function (event)
         mark_solo(player)
         destroy_left(player)
      end
      return
   end

   local settings_table = settings_frame.add{
      type = "table",
      column_count = 2,
      draw_horizontal_line_after_headers = true,
      name = ALLY_TABLE_NAME,
      style = ALLY_TABLE_STYLE,
   }

   settings_table.add{
      type = "label",
      caption={"settings_table_broadcast"}
   }

   local alliance_settings_broadcast = SETTINGS_BROADCAST .. player.name
   settings_table.add{
      type = "checkbox",
      name = alliance_settings_broadcast,
      state = player.force.share_chart
   }
   ON_CHECKBOX[alliance_settings_broadcast] = function(event)
      local new_state = event.element.state
      player.force.share_chart = new_state
      if (new_state) then
         player.force.print({"settings_table_broadcast_on", game.tick})
      else
         player.force.print({"settings_table_broadcast_off", game.tick})
      end
   end

   local ally_frame = flow.add{
      type = "frame",
      caption = {"ally_frame_title"},
      name = ALLY_FRAME_NAME,
   }

   local table = ally_frame.add{
      type = "table",
      column_count = 4,
      draw_horizontal_line_after_headers = true,
      name = ALLY_TABLE_NAME,
      style = ALLY_TABLE_STYLE,
   }

   table.add{
      type = "label",
      caption={"ally_table_force"}
   }
   table.add{
      type = "label",
      caption = {"ally_table_enemy"}
   }
   table.add{
      type="label",
      caption = {"ally_table_neutral"}
   }
   table.add{
      type="label",
      caption = {"ally_table_ally"}
   }

   local count = 0
   for _, other in pairs(game.forces) do
      if (is_whitelisted_force_pair(player.force, other)) then
         count = count + 1
         table.add{
            type = "label",
            caption = get_alliance_force_name(other)
         }
         local alliance_ally_table_enemy = player.name .. ALLY_TABLE_ENEMY .. other.name
         local alliance_ally_table_neutral = player.name .. ALLY_TABLE_NEUTRAL .. other.name
         local alliance_ally_table_ally = player.name .. ALLY_TABLE_ALLY .. other.name
         table.add{
            type = "radiobutton",
            name = alliance_ally_table_enemy,
            state = is_enemy(player.force, other)
         }
         table.add{
            type = "radiobutton",
            name = alliance_ally_table_neutral,
            state = is_neutral(player.force, other)
         }
         table.add{
            type = "radiobutton",
            name = alliance_ally_table_ally,
            state = is_ally(player.force, other)
         }
         ON_CHECKBOX[alliance_ally_table_enemy] = function(event)
            table[alliance_ally_table_neutral].state = false
            table[alliance_ally_table_ally].state = false
            set_enemy(player.force, other)
         end
         ON_CHECKBOX[alliance_ally_table_neutral] = function(event)
            table[alliance_ally_table_enemy].state = false
            table[alliance_ally_table_ally].state = false
            set_neutral(player.force, other)
         end
         ON_CHECKBOX[alliance_ally_table_ally] = function(event)
            table[alliance_ally_table_enemy].state = false
            table[alliance_ally_table_neutral].state = false
            set_ally(player.force, other)
         end
      end
   end
   if (count == 0) then
      table.add{
         type = "label",
         caption={"ally_table_empty"}
      }
   end
end

ON_BUTTON[BUTTON_NAME] = function(event)
   local player_index = event.player_index
   local player = game.players[player_index]
    if (exists_left(player)) then
      destroy_left(player)
    else
      create_left(player)
    end
end

-- ----------------------------------------------
-- Event functions
-- ----------------------------------------------

-- Creates the top button if it's mising, and resets that player's force if they're not on the
-- correct team.
script.on_event(defines.events.on_player_joined_game, function(event)
   local player = game.players[event.player_index]
   if not exists_top(player) then create_top(player) end
end)

-- Remove the left panel if it's visible. Iteracting with it can cause a desync if it's left on
-- after a disconnect.
script.on_event(defines.events.on_player_left_game, function(event)
   local player = game.players[event.player_index]
   if exists_left(player) then destroy_left(player) end
end)

-- Handles charting for new forces on a delay.
script.on_nth_tick(60, function ()
   local final = table.remove(FORCE_CHART_ALL_FINAL)
   if (final) then
      final.chart_all()
   end
   local pending = table.remove(FORCE_CHART_ALL_PENDING)
   if (pending) then
      table.insert(FORCE_CHART_ALL_FINAL, pending)
   end
end)

script.on_event(defines.events.on_gui_click, function(event)
   if (event.element) then
      local action = ON_BUTTON[event.element.name]
      if (action) then action(event) end
   end
end)

script.on_event(defines.events.on_gui_checked_state_changed, function(event)
   if (event.element) then
      local action = ON_CHECKBOX[event.element.name]
      if (action) then action(event) end
   end
end)

script.on_configuration_changed(function(data)
   local alliance = data.mod_changes["Alliance"]
   if (alliance) then
       if alliance.old_version == "0.1.4" then
         for _, force in pairs(game.forces) do
            local player = force.players[1]
            if player and force.name == player.name then
               local new_force = create_alliance_force(player)
               game.merge_forces(player.force, new_force)
            end
         end
       end
   end
end)