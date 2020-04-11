require("defines")

-- ----------------------------------------------
-- Global force functions
-- ----------------------------------------------

local function initialize_global()
   -- global.forces = {force.name : LuaForceSpecification}
   global.forces = global.forces or {}
   -- global.force_name_map = {force.name : player.name}
   global.force_name_map = global.force_name_map or {}

   -- global.chart_all_pending = [force.name]
   global.chart_all_pending = global.forces or {}
   -- global.chart_all_final = [force.name]
   global.chart_all_final = global.forces or {}

   -- global.button_relationship_target = {button.name : force.name}
   global.ally_table_target = global.ally_table_target or {}
end

local function tick_force_chart()
   local final = table.remove(global.chart_all_final)
   if (final and game.forces[final]) then game.forces[final].chart_all() end
   local pending = table.remove(global.chart_all_pending)
   if (pending) then table.insert(global.chart_all_final, pending) end
end

-- @param force: LuaForce
local function force_chart(force)
   table.insert(global.chart_all_pending, force.name)
end

-- @param force: LuaForce
-- @return bool
local function is_alliance_force(force)
   return global.forces[force.name] ~= nil
end

-- @param force: LuaForce
-- @return string
local function get_alliance_force_name(force)
   return global.force_name_map[force.name]
end

-- @param player: LuaPlayer
-- @return LuaForce
local function create_alliance_force(player)
   local force_name = GLOBAL_FORCE_NAME .. player.name
   local new_force = game.create_force(force_name)
   global.forces[force_name] = new_force
   global.force_name_map[force_name] = player.name
   global.ally_table_target[ALLY_TABLE_ENEMY .. force_name] = force_name
   global.ally_table_target[ALLY_TABLE_NEUTRAL .. force_name] = force_name
   global.ally_table_target[ALLY_TABLE_ALLY .. force_name] = force_name
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
   player.print({"set_enemy", game.tick, get_alliance_force_name(other)})
end

-- @param player: LuaForce
-- @param other: LuaForce
local function set_neutral(player, other)
   player.set_cease_fire(other, true)
   player.set_friend(other, false)
   player.print({"set_neutral", game.tick, get_alliance_force_name(other)})
end

-- @param player: LuaForce
-- @param other: LuaForce
local function set_ally(player, other)
   player.set_cease_fire(other, true)
   player.set_friend(other, true)
   player.print({"set_ally", game.tick, get_alliance_force_name(other)})
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

-- @param force: LuaForce
local function apply_solo_bonus(force)
   force.character_build_distance_bonus = force.character_build_distance_bonus + 30
   force.character_reach_distance_bonus = force.character_reach_distance_bonus + 30
   force.character_resource_reach_distance_bonus = force.character_resource_reach_distance_bonus + 30
   force.character_inventory_slots_bonus = force.character_inventory_slots_bonus + 30
   force.manual_mining_speed_modifier = force.manual_mining_speed_modifier + 1
end

-- @param player: LuaPlayer
-- @return LuaForce
local function mark_solo(player)
   if (not is_solo(player)) then
      local force_name = GLOBAL_FORCE_NAME .. player.name
      if (game.forces[force_name] == nil) then
         local new_force = create_alliance_force(player)
         -- Give a solo bonus
         apply_solo_bonus(new_force)
         -- Copy over the research from the old force to the new one
         for key, tech in pairs(player.force.technologies) do
            new_force.technologies[key].researched = tech.researched
         end
         -- Default is friendly to the player's old force
         set_mutual_ally(player.force, new_force)
         -- Have the previous force share vision with the world
         player.force.share_chart = true
      end
      player.force = game.forces[force_name]
      force_chart(player.force)
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

   -- Declaring independence
   if (not is_solo(player)) then
      settings_frame.add{
         type = "button",
         name = SETTINGS_SOLO,
         caption={"settings_table_solo"},
      }
      return
   end

   local settings_table = settings_frame.add{
      type = "table",
      column_count = 2,
      name = ALLY_TABLE_NAME,
      style = ALLY_TABLE_STYLE,
   }

   -- Vision broadcast
   settings_table.add{
      type = "label",
      caption={"settings_table_broadcast"}
   }
   settings_table.add{
      type = "checkbox",
      name = SETTINGS_BROADCAST,
      state = player.force.share_chart
   }

   -- Spawn setting and resetting
   settings_table.add{
      type = "button",
      name = SETTINGS_SPAWN_SET,
      caption={"settings_tale_spawn_set"},
   }
   settings_table.add{
      type = "button",
      name = SETTINGS_SPAWN_RESET,
      caption={"settings_tale_spawn_reset"},
   }

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

   -- Alliance table
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
         local alliance_ally_table_enemy = ALLY_TABLE_ENEMY .. other.name
         local alliance_ally_table_neutral = ALLY_TABLE_NEUTRAL .. other.name
         local alliance_ally_table_ally = ALLY_TABLE_ALLY .. other.name
         table.add{
            type = "flow",
            name = alliance_ally_table_enemy,
            style = CONTAINER_FLOW_STYLE,
         }.add{
            type = "radiobutton",
            name = ALLY_TABLE_ENEMY,
            state = is_enemy(player.force, other)
         }
         table.add{
            type = "flow",
            name = alliance_ally_table_neutral,
            style = CONTAINER_FLOW_STYLE,
         }.add{
            type = "radiobutton",
            name = ALLY_TABLE_NEUTRAL,
            state = is_neutral(player.force, other)
         }
         table.add{
            type = "flow",
            name = alliance_ally_table_ally,
            style = CONTAINER_FLOW_STYLE,
         }.add{
            type = "radiobutton",
            name = ALLY_TABLE_ALLY,
            state = is_ally(player.force, other)
         }
      end
   end
   if (count == 0) then
      table.add{
         type = "label",
         caption={"ally_table_empty"}
      }
   end
end

-- ----------------------------------------------
-- Event functions
-- ----------------------------------------------

ON_BUTTON[SETTINGS_SOLO] = function (event, player)
   mark_solo(player)
   destroy_left(player)
end

ON_BUTTON[BUTTON_NAME] = function(event, player)
    if (exists_left(player)) then
      destroy_left(player)
    else
      create_left(player)
    end
end

ON_CHECKBOX[SETTINGS_BROADCAST] = function(event, player)
   local new_state = event.element.state
   player.force.share_chart = new_state
   if (new_state) then
      player.force.print({"settings_table_broadcast_on", game.tick})
   else
      player.force.print({"settings_table_broadcast_off", game.tick})
   end
end

ON_BUTTON[SETTINGS_SPAWN_SET] = function(event, player)
   player.force.set_spawn_position(player.position, player.surface)
   player.force.print({"settings_tale_spawn_set_msg", game.tick})
end

ON_BUTTON[SETTINGS_SPAWN_RESET] = function(event, player)
   player.force.set_spawn_position({0, 0}, player.surface)
   player.force.print({"settings_tale_spawn_reset_msg", game.tick})
end

ON_CHECKBOX[ALLY_TABLE_ENEMY] = function(event, player)
   local other_force_name = global.ally_table_target[event.element.parent.name]
   local other = game.forces[other_force_name]
   event.element.parent.parent[ALLY_TABLE_NEUTRAL .. other.name].children[1].state = false
   event.element.parent.parent[ALLY_TABLE_ALLY .. other.name].children[1].state = false
   set_enemy(player.force, other)
end

ON_CHECKBOX[ALLY_TABLE_NEUTRAL] = function(event, player)
   local other_force_name = global.ally_table_target[event.element.parent.name]
   local other = game.forces[other_force_name]
   event.element.parent.parent[ALLY_TABLE_ENEMY .. other.name].children[1].state = false
   event.element.parent.parent[ALLY_TABLE_ALLY .. other.name].children[1].state = false
   set_neutral(player.force, other)
end

ON_CHECKBOX[ALLY_TABLE_ALLY] = function(event, player)
   local other_force_name = global.ally_table_target[event.element.parent.name]
   local other = game.forces[other_force_name]
   event.element.parent.parent[ALLY_TABLE_ENEMY .. other.name].children[1].state = false
   event.element.parent.parent[ALLY_TABLE_NEUTRAL .. other.name].children[1].state = false
   set_ally(player.force, other)
end

-- Creates the top button for new players.
script.on_event(defines.events.on_player_created, function(event)
   local player = game.players[event.player_index]
   create_top(player)
end)

-- Creates the top button if it's mising.
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
script.on_nth_tick(64, function ()
   tick_force_chart()
end)


script.on_event(defines.events.on_gui_click, function(event)
   if (event.element) then
      local action = ON_BUTTON[event.element.name]
      if (action) then
         local player = game.players[event.player_index]
         action(event, player)
      end
   end
end)

script.on_event(defines.events.on_gui_checked_state_changed, function(event)
   if (event.element) then
      local action = ON_CHECKBOX[event.element.name]
      if (action) then
         local player = game.players[event.player_index]
         action(event, player)
      end
   end
end)

script.on_init(function()
   initialize_global()
end)

script.on_configuration_changed(function(data)
   initialize_global()

   local alliance = data.mod_changes["Alliance"]
   if (alliance) then
       if alliance.old_version == "0.1.4" then
         for _, force in pairs(game.forces) do
            local player = force.players[1]
            if player and force.name == player.name then
               local old_force = player.force;
               mark_solo(player)
               local new_force = player.force;
               game.merge_forces(old_force, new_force)
            end
         end
       end
   end
end)