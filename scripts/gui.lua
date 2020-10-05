
local Event = require('__stdlib__/stdlib/event/event')
local Player = require('__stdlib__/stdlib/event/player')
local Table = require('__stdlib__/stdlib/utils/table')
require('scripts/gui-events')

local priority = {
    max = 1,
    min = 2,
    qty = 3
}

local entity_filters = {
    {
        filter = 'flag',
        flag = 'placeable-player'
    },
    {
        filter = 'blueprintable',
        mode = 'and'
    },
    {
        filter = 'flag',
        flag = 'hidden',
        invert = true,
        mode = 'and'
    },
    {
        filter = 'vehicle'
    }
}

local function get_default_true(state)
    if state ~= nil then
        return state
    end
    return true
end

local map = {}
local item_sets

local function get_categories(slot)
    return map[slot.type], item_sets[slot.type][slot.category].index
end

local function build_scroll_tab(tabbed_pane, caption)
local tab = tabbed_pane.add {type = 'tab', caption = caption}
    -- local frame = tabbed_pane.add{type = 'frame'}
    local scroll = tabbed_pane.add {type = 'scroll-pane'}
    scroll.style.maximal_height = 600
    tabbed_pane.add_tab(tab, scroll)
    return scroll
end

local function build_row(table, name, data, is_ignored, is_global)
    local ent =
        table.add {
        type = 'choose-elem-button',
        elem_type = 'entity',
        entity = name,
        elem_filters = entity_filters,
        enabled = false,
        ignored_by_interaction = is_ignored
    }
    local group =
        table.add {
        type = 'choose-elem-button',
        elem_type = 'item',
        item = game.item_prototypes[data.group] and data.group or nil,
        ignored_by_interaction = is_ignored
    }
    ent.style.width = 48
    ent.style.height = 48
    group.style.width = 48
    group.style.height = 48

    local slots = table.add {type = 'table', column_count = 4, ignored_by_interaction = is_ignored}
    for i = 1, #data.slots do
        local cat_set = item_sets[data.slots[i].type]
        local category, index = get_categories(data.slots[i])
        slots.add {type = 'drop-down', items = map.types, selected_index = cat_set.index} --type
        slots.add {type = 'drop-down', items = category, selected_index = index}.style.width = 150 --category
        slots.add {type = 'drop-down', items = {'max', 'min', 'qty'}, selected_index = priority[data.slots[i].priority]} --priority

        local slider_table = slots.add {type = 'table', column_count = 2}
        local suffix = (is_global and 'global-' or 'player-') .. name .. '-' .. i
        slider_table.add {
            type = 'slider',
            name = 'picker-stack-slider-' .. suffix,
            minimum_value = 0,
            maximum_value = 100,
            value = tonumber(data.slots[i].limit) or 0,
            value_step = 1,
            discrete_slider = true,
            discrete_values = true
        }
        slider_table.add {
                type = 'textfield',
                name = 'picker-stack-text-' .. suffix,
                text = tonumber(data.slots[i].limit) or 0,
                numeric = true,
                allow_decimal = false,
                allow_negative = false
            }.style.width = 60 --ignore
    end
    table.add {type = 'switch', switch_state = get_default_true(data.enabled) and 'right' or 'left', ignored_by_interaction = is_ignored}
    table.add {type = 'button', caption = 'Copy', ignored_by_interaction = false}
end

local function build_entity_tab(player, pdata, tabbed, caption, set, rows, admin, is_global)
    local is_ignored = not admin

    local scroll = build_scroll_tab(tabbed, caption)

    local table =
        scroll.add {
        type = 'table',
        column_count = 5,
        style = 'bordered_table'
    }

    --Build header Row
    table.add {type = 'label', caption = 'Entity'}
    table.add {type = 'label', caption = 'Group'}
    table.add {type = 'label', caption = 'Slots'}
    table.add {type = 'label', caption = 'Enabled'}
    table.add {type = 'label', caption = is_global and 'Copy' or 'Remove'}

    for name, data in pairs(set) do
        build_row(table, name, data, is_ignored, is_global)
    end

    -- Create row for adding a new entity
end

local function build_item_tab(player, pdata, tabbed, caption, set, rows, admin, is_global)
    build_scroll_tab(tabbed, caption)
end

local function picker_toggle_autofill_gui(event)
    local player, pdata = Player.get(event.player_index)
    local screen = player.gui.screen

    if screen['picker-autofill-frame'] then
        screen['picker-autofill-frame'].destroy()
        return
    end

    item_sets = global.item_sets
    map.types = Table.keys(item_sets)
    map.fuel = Table.keys(item_sets['fuel'])
    table.remove(map.fuel, 1)
    map.ammo = Table.keys(item_sets['ammo'])
    table.remove(map.ammo, 1)
    map.module = Table.keys(item_sets['module'])
    table.remove(map.module, 1)

    local frame_pane =
        screen.add {
        type = 'frame',
        name = 'picker-autofill-frame',
        caption = 'Picker Fill'
    }.add {
        type = 'frame',
        name = 'picker-tab-frame',
        style = 'inside_deep_frame_for_tabs',
        direction = 'vertical'
    }

    local tabbed_pane = frame_pane.add {
        type = 'tabbed-pane',
        name = 'picker-tabbed-pane'
    }

    build_entity_tab(player, pdata, tabbed_pane, 'Global Entity List', global.entity_sets, 50, player.admin, true)
    build_entity_tab(player, pdata, tabbed_pane, 'Player Entity List', pdata.entity_sets, 99, false, false)
    build_item_tab(player, pdata, tabbed_pane, 'Global Item List', global.item_sets, 50, player.admin, true)
    build_item_tab(player, pdata, tabbed_pane, 'Player Item List', pdata.item_sets, 50, false, false)

    frame_pane.add{type = 'button', caption = 'ok'}
end
Event.register('picker-toggle-autofill-gui', picker_toggle_autofill_gui)
