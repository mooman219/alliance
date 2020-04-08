require("defines")

local function toggle_ceasefire(player, other)
   local status = player.force.get_cease_fire(other.force)
   player.force.set_cease_fire(other.force, not status)
   if (status) then
      player.print({"", "[", game.tick, "]", {"alliance_end_ceasefire"}, other.force.name})
   else
      player.print({"", "[", game.tick, "]", {"alliance_start_ceasefire"}, other.force.name})
   end
end

local function toggle_friendly(player, other)
   local status = player.force.get_friend(other.force)
   player.force.set_friend(other.force, not status)
   if (status) then
      player.print({"", "[", game.tick, "]", {"alliance_end_friend"}, other.force.name})
   else
      player.print({"", "[", game.tick, "]", {"alliance_start_friend"}, other.force.name})
   end
end

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
      caption = {ALLIANCE_PANEL .. "_caption"}
   }

   player.gui.left[ALLIANCE_PANEL].add{
      type = "table",
      name = "table",
      column_count = 3,
      style = ALLIANCE_PANEL_STYLE,
   }

   player.gui.left[ALLIANCE_PANEL].table.add{
      type = "label",
      caption={ALLIANCE_PANEL .. "_force"}
   }
   player.gui.left[ALLIANCE_PANEL].table.add{
      type = "label",
      caption = {ALLIANCE_PANEL .. "_ceasefire"}
   }
   player.gui.left[ALLIANCE_PANEL].table.add{
      type="label",
      caption = {ALLIANCE_PANEL .. "_friend"}
   }

   for _, other in pairs(game.players) do
      if (player.force ~= other.force) then
         player.gui.left[ALLIANCE_PANEL].table.add{
            type = "label",
            caption = other.name
         }
         player.gui.left[ALLIANCE_PANEL].table.add{
            type = "checkbox",
            name = ALLIANCE_CEASE_PREFIX .. other.name,
            state = player.force.get_cease_fire(other.force)
         }
         player.gui.left[ALLIANCE_PANEL].table.add{
            type = "checkbox",
            name = ALLIANCE_FRIEND_PREFIX .. other.name,
            state = player.force.get_friend(other.force)
         }
         ALLIANCE_ON_CHECKBOX[ALLIANCE_CEASE_PREFIX .. other.name] = function(event)
            toggle_ceasefire(player, other)
         end
         ALLIANCE_ON_CHECKBOX[ALLIANCE_FRIEND_PREFIX .. other.name] = function(event)
            toggle_friendly(player, other)
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
         new_force.set_cease_fire(player.force)
         new_force.set_friend(player.force)
         player.force.set_cease_fire(new_force)
         player.force.set_friend(new_force)
      end
      player.force = game.forces[force_name]
      player.print("You have been assigned to " .. force_name)
   end
end

ALLIANCE_ON_BUTTON[ALLIANCE_BUTTON] = toggle_panel

script.on_event(defines.events.on_player_joined_game, function(event)
    local player_index = event.player_index
    local player = game.players[player_index]
    create_button(player)
    reset_force(player)
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