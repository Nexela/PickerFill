local Event = require('__stdlib__/stdlib/event/event')

local function on_player_created(event)
    local player = game.get_player(event.player_index)
    player.set_shortcut_toggled('toggle-picker-autofill-entity', true)
    player.set_shortcut_toggled('toggle-picker-autofill-ghost', true)
end
Event.register(defines.events.on_player_created, on_player_created)

local function on_lua_shortcut(event)
    if event.prototype_name == 'toggle-picker-autofill-entity' then
        local player = game.get_player(event.player_index)
        player.set_shortcut_toggled('toggle-picker-autofill-entity', not player.is_shortcut_toggled('toggle-picker-autofill-entity'))
    elseif event.prototype_name == 'toggle-picker-autofill-ghost' then
        local player = game.get_player(event.player_index)
        player.set_shortcut_toggled('toggle-picker-autofill-ghost', not player.is_shortcut_toggled('toggle-picker-autofill-ghost'))
    end
end
Event.register(defines.events.on_lua_shortcut, on_lua_shortcut)
