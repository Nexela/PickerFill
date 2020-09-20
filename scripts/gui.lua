local Gui = require('__stdlib__/stdlib/event/gui')
local Event = require('__stdlib__/stdlib/event/event')
local Player = require('__stdlib__/stdlib/event/player')
local Table = require('__stdlib__/stdlib/utils/table')

local priority = {
    max = 1,
    min = 2,
    qty = 3,
}


local filters = {
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

local function build_tab(player, pdata, tabbed, caption, set, rows, admin)
    local is_ignored = (type(admin) == 'boolean' and not admin) or false

    local tab = tabbed.add {type = 'tab', caption = caption}
    local scroll = tabbed.add {type = 'scroll-pane'}
    scroll.style.horizontally_stretchable = true

    tabbed.add_tab(tab, scroll)
    local table = scroll.add {type = 'table', column_count = 4, ignored_by_interaction = is_ignored}
    for name, data in pairs(set) do
        local button = table.add {type = 'choose-elem-button', elem_type = 'entity', entity = name, elem_filters = filters}
        button.style.height = 64
        button.style.width = 64
        table.add {type = 'checkbox', state = get_default_true(data.enabled)}
        table.add {type = 'textfield', text = data.group,}
        local slots = table.add {type = 'table', column_count = 5}

        for i=1, #data.slots do
            local cat_set = item_sets[data.slots[i].type]
            local category, index = get_categories(data.slots[i])
            slots.add{type = 'drop-down', items = map.types,  selected_index =cat_set.index} --type
            slots.add{type = 'drop-down', items = category, selected_index = index} --category
            slots.add{type = 'drop-down', items = {'max', 'min', 'qty'}, selected_index = priority[data.slots[i].priority]} --priority
            slots.add{type = 'textfield', text = data.slots[i].limit}.style.width = 60 --limit
            slots.add{type = 'textfield', text = "todo"}.style.width = 60 --ignore
        end
    end
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

    local frame = screen.add {type = 'frame', name = 'picker-autofill-frame', caption = 'Picker Fill'}
    frame.style.natural_width = 1080
    frame.style.maximal_height = 600
    local tabbed = frame.add {type = 'tabbed-pane', caption = 'Picker Fill Tab'}

    build_tab(player, pdata, tabbed, 'Global Entity List', global.entity_sets, 50, player.admin)
    build_tab(player, pdata, tabbed, 'Player Entity List', pdata.entity_sets, 99)
end
Event.register('picker-toggle-autofill-gui', picker_toggle_autofill_gui)
