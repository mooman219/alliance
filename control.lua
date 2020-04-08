require("defines")

-- ----------------------------------------------
-- Alliance functions
-- ----------------------------------------------

-- @param player: LuaForce
-- @param other: LuaForce
local function is_enemy(player, other)
   local ceasefire = player.get_cease_fire(other)
   local friend = player.get_friend(other)
   return not ceasefire and not friend
end

-- @param player: LuaForce
-- @param other: LuaForce
local function is_neutral(player, other)
   local ceasefire = player.get_cease_fire(other)
   local friend = player.get_friend(other)
   return ceasefire and not friend
end

-- @param player: LuaForce
-- @param other: LuaForce
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

-- ----------------------------------------------
-- GUI functions
-- ----------------------------------------------

local function create_button(player)
   if (player.gui.top[ALLIANCE_BUTTON_FRAME] ~= nil) then return end

   player.gui.top.add{
      name = ALLIANCE_BUTTON_FRAME,
      type = "flow",
      style = ALLIANCE_BUTTON_FRAME_STYLE,
   }

   player.gui.top[ALLIANCE_BUTTON_FRAME].add{
      name = ALLIANCE_BUTTON,
      type = "button",
      caption = "<3",
      style = ALLIANCE_BUTTON_STYLE
   }
end

local function create_panel(player)
   if (player.gui.left[ALLIANCE_PANEL] ~= nil) then return end

   player.gui.left.add{
      type = "frame",
      name = ALLIANCE_PANEL,
      caption = {"panel_title"}
   }

   player.gui.left[ALLIANCE_PANEL].add{
      type = "table",
      name = "table",
      column_count = 4,
      style = ALLIANCE_PANEL_STYLE,
   }

   player.gui.left[ALLIANCE_PANEL].table.add{
      type = "label",
      caption={"panel_force"}
   }
   player.gui.left[ALLIANCE_PANEL].table.add{
      type = "label",
      caption = {"panel_enemy"}
   }
   player.gui.left[ALLIANCE_PANEL].table.add{
      type="label",
      caption = {"panel_neutral"}
   }
   player.gui.left[ALLIANCE_PANEL].table.add{
      type="label",
      caption = {"panel_ally"}
   }

   for _, other in pairs(game.forces) do
      if (player.force ~= other) then
         player.gui.left[ALLIANCE_PANEL].table.add{
            type = "label",
            caption = other.name
         }
         player.gui.left[ALLIANCE_PANEL].table.add{
            type = "radiobutton",
            name = ALLIANCE_ENEMY_PREFIX .. other.name,
            state = is_enemy(player.force, other)
         }
         player.gui.left[ALLIANCE_PANEL].table.add{
            type = "radiobutton",
            name = ALLIANCE_NEUTRAL_PREFIX .. other.name,
            state = is_neutral(player.force, other)
         }
         player.gui.left[ALLIANCE_PANEL].table.add{
            type = "radiobutton",
            name = ALLIANCE_ALLY_PREFIX .. other.name,
            state = is_ally(player.force, other)
         }
         ALLIANCE_ON_CHECKBOX[ALLIANCE_ENEMY_PREFIX .. other.name] = function(event)
            player.gui.left[ALLIANCE_PANEL].table[ALLIANCE_NEUTRAL_PREFIX .. other.name].state = false
            player.gui.left[ALLIANCE_PANEL].table[ALLIANCE_ALLY_PREFIX .. other.name].state = false
            set_enemy(player.force, other)
         end
         ALLIANCE_ON_CHECKBOX[ALLIANCE_NEUTRAL_PREFIX .. other.name] = function(event)
            player.gui.left[ALLIANCE_PANEL].table[ALLIANCE_ENEMY_PREFIX .. other.name].state = false
            player.gui.left[ALLIANCE_PANEL].table[ALLIANCE_ALLY_PREFIX .. other.name].state = false
            set_neutral(player.force, other)
         end
         ALLIANCE_ON_CHECKBOX[ALLIANCE_ALLY_PREFIX .. other.name] = function(event)
            player.gui.left[ALLIANCE_PANEL].table[ALLIANCE_ENEMY_PREFIX .. other.name].state = false
            player.gui.left[ALLIANCE_PANEL].table[ALLIANCE_NEUTRAL_PREFIX .. other.name].state = false
            set_ally(player.force, other)
         end
      end
   end
end

local function toggle_panel(event)
   local player_index = event.player_index
   local player = game.players[player_index]
   if (player.gui.left[ALLIANCE_PANEL] ~= nil) then
      player.gui.left[ALLIANCE_PANEL].destroy()
   else
      create_panel(player)
   end
end

local function reset_force(player)
   local force_name = "team-" .. player.name
   if (player.force.name ~= force_name) then
      if (game.forces[force_name] == nil) then
         local new_force = game.create_force(force_name)
         -- Copy over the research from the old force to the new one
         for key, tech in pairs(player.force.technologies) do
            new_force.technologies[key].researched = tech.researched
         end
         -- Helps :3
         new_force.character_build_distance_bonus = new_force.character_build_distance_bonus + 30
         new_force.character_reach_distance_bonus = new_force.character_reach_distance_bonus + 30
         new_force.character_resource_reach_distance_bonus = new_force.character_resource_reach_distance_bonus + 30
         new_force.character_inventory_slots_bonus = new_force.character_inventory_slots_bonus + 30
         -- Default is friendly to the player's old force
         set_mutual_ally(player.force, new_force)
      end
      player.force = game.forces[force_name]
      table.insert(ALLIANCE_FORCE_CHART_ALL_PENDING, player.force)
      player.print({"new_assignment", force_name})
   end
end

ALLIANCE_ON_BUTTON[ALLIANCE_BUTTON] = toggle_panel

-- ----------------------------------------------
-- Event functions
-- ----------------------------------------------

script.on_event(defines.events.on_player_joined_game, function(event)
   local player_index = event.player_index
   local player = game.players[player_index]
   create_button(player)
   reset_force(player)
end)

script.on_nth_tick(60, function ()
   local final = table.remove(ALLIANCE_FORCE_CHART_ALL_FINAL)
   if (final) then
      final.chart_all()
   end
   local pending = table.remove(ALLIANCE_FORCE_CHART_ALL_PENDING)
   if (pending) then
      table.insert(ALLIANCE_FORCE_CHART_ALL_FINAL, pending)
   end
end)

script.on_event(defines.events.on_gui_click, function(event)
   if (event.element) then
      local action = ALLIANCE_ON_BUTTON[event.element.name]
      if (action) then action(event) end
   end
end)

script.on_event(defines.events.on_gui_checked_state_changed, function(event)
   if (event.element) then
      local action = ALLIANCE_ON_CHECKBOX[event.element.name]
      if (action) then action(event) end
   end
end)