local Event = require('__stdlib__/stdlib/event/event')
local Player = require('__stdlib__/stdlib/event/player')
local Position = require('__stdlib__/stdlib/area/position')
local Iter = require('__stdlib__/stdlib/utils/iter')
local Table = require('__stdlib__/stdlib/utils/table')

local build_default_entity_sets = require('sets/build-default-entity-sets')
local build_default_item_sets = require('sets/build-default-item-sets')

local min, max, floor, ceil = math.min, math.max, math.floor, math.ceil
local priorities = {['qty'] = 'qty', ['max'] = 'max', ['min'] = 'min'}

local function _sort_max(t, a, b)
    return t[b] < t[a]
end

local function _sort_min(t, a, b)
    return t[b] > t[a]
end

local function get_highest_value(tbl)
    for item in Iter.spairs(tbl, _sort_max) do
        local proto = game.item_prototypes[item]
        if proto then
            return item, proto.stack_size
        end
    end
    return nil, 0
end

local function flying_text(player, line, pos, color)
    color = color or defines.color.red
    line = line or ''
    pos = pos or player.position
    return player.create_local_flying_text {position = pos, text = line, color = color}
end

local function get_inv_count(item_name, invs)
    local total = 0
    for _, inv in pairs(invs) do
        total = total + inv.get_item_count(item_name)
    end
    return total
end

local function is_ignored(item_name, ignore_list)
    ignore_list = ignore_list or {}
    for i = 1, #ignore_list do
        if ignore_list[i] == item_name then
            return true
        end
    end
    return false
end

local function get_item_and_counts(player, invs, slot, item_list, is_ghost)
    local priority = is_ghost and 'qty' or priorities[slot.priority] or 'qty'

    -- Remove items from the list that are not valid or ignored
    for item_name in pairs(item_list) do
        if not game.item_prototypes[item_name] or is_ignored(item_name, slot.ignore) then
            item_list[item_name] = nil
        end
    end

    if player.cheat_mode then
        return get_highest_value(item_list), 32000000
    elseif priority == 'qty' then
        local item
        local item_count = 0
        for item_name, _ in pairs(item_list) do
            local total = get_inv_count(item_name, invs)
            if (total > 0 and total > item_count) then
                item = item_name
                item_count = total
            end
        end
        if not item and is_ghost then
            return get_highest_value(item_list)
        end
        return item, item_count
    elseif priority == 'max' then
        for item_name, _ in Iter.spairs(item_list, _sort_max) do
            local total = get_inv_count(item_name, invs)
            if total > 0 then
                return item_name, total
            end
        end
    elseif priority == 'min' then
        for item_name, _ in Iter.spairs(item_list, _sort_min) do
            local total = get_inv_count(item_name, invs)
            if total > 0 then
                return item_name, total
            end
        end
    end
    return nil, 0
end

local function get_group_counts(player, invs, set, pdata)
    local group_count = 1
    if (set.group and pdata.use_groups) then
        if player.cursor_stack.valid_for_read then
            group_count = group_count + player.cursor_stack.count
        end
        local counted = {}
        for entity_name, set_table in pairs(pdata.entity_sets) do
            if set_table.group == set.group then
                group_count = group_count + get_inv_count(entity_name, invs)
                counted[entity_name] = true
            end
        end
        for entity_name, set_table in pairs(global.entity_sets) do
            if set_table.group == set.group and not counted[entity_name] then
                group_count = group_count + get_inv_count(entity_name, invs)
            end
        end
    end
    return group_count
end

local function insert_items(player, vehicle, entity, insert_count, mi, vi, item, stack_size, text_pos)
    local inserted = entity.insert {name = item, count = insert_count}

    if inserted > 0 then
        local removed_from_vehicle
        if vi then
            removed_from_vehicle = vi.remove {name = item, count = inserted}
            if inserted > removed_from_vehicle then
                mi.remove {name = item, count = inserted - removed_from_vehicle}
            end
        else
            mi.remove {name = item, count = inserted}
        end

        local color
        if inserted < stack_size then
            color = defines.color.yellow
        elseif insert_count >= stack_size then
            color = defines.color.green
        end

        if removed_from_vehicle then
            local msg = {
                'autofill.insertion-from-vehicle',
                inserted,
                game.item_prototypes[item].localised_name,
                removed_from_vehicle,
                vehicle.localised_name
            }
            flying_text(player, msg, text_pos(), color)
        else
            flying_text(player, {'autofill.insertion', inserted, game.item_prototypes[item].localised_name}, text_pos(), color)
        end
    end
end

local function fill_entity(player, entity, is_ghost)
    local name = is_ghost and entity.ghost_name or entity.name
    local pdata = global.players[player.index]
    local set = pdata.entity_sets[name]

    if not set then
        return
    end

    if type(set.enabled) == 'boolean' and not set.enabled then
        return
    end

    --Increment y position everytime text_pos is called
    local text_pos = Position(entity.position):increment(0, 1)

    --Get inventories
    local mi = player.get_main_inventory()
    local vehicle = player.vehicle
    local vi = vehicle and vehicle.get_inventory(defines.inventory.car_trunk)
    local invs = {mi, vi or nil}

    local slot_counts = {}
    for _, slot in ipairs(set.slots) do
        slot_counts[slot.category] = (slot_counts[slot.category] or 0) + 1
    end

    --Loop through each slot in the set.
    for _, slot in ipairs(set.slots) do
        local item_list = pdata.item_sets[slot.type] and Table.deep_copy(pdata.item_sets[slot.type][slot.category])
        if not type(item_list) == 'table' then
            flying_text(player, {'autofill.invalid-category'}, text_pos())
            return
        end
        local item, item_count = get_item_and_counts(player, invs, slot, item_list, is_ghost)

        if not is_ghost then
            if not item or item_count < 1 then
                local key = next(item_list)
                if key and game.item_prototypes[key] then
                    return flying_text(player, {'autofill.out-of-item', slot.type}, text_pos())
                elseif key then
                    return flying_text(player, {'autofill.invalid-itemname', key}, text_pos())
                else
                    return
                end
            end
        end

        local group_count = is_ghost and 1 or get_group_counts(player, invs, set, pdata)
        --- This shouldn't be nescecarry
        local slot_count = slot_counts[slot.category] - 1
        slot_count = slot_count < 1 and 1 or slot_count

        local stack_size = game.item_prototypes[item].stack_size
        local insert_count = min(max(1, min(item_count, floor(item_count / ceil(group_count / slot_count)))), min(pdata.use_limits and slot.limit or stack_size, stack_size))

        if is_ghost then
            local requests = entity.item_requests or {}
            requests[item] = (requests[item] or 0) + insert_count
            entity.item_requests = requests
            return
        else
            insert_items(player, vehicle, entity, insert_count, mi, vi, item, stack_size, text_pos)
        end
    end
end

local function on_built_entity(event)
    local entity = event.created_entity
    local player = game.get_player(event.player_index)

    if entity.name == 'entity-ghost' then
        if player.is_shortcut_toggled('toggle-picker-autofill-ghost') then
            return fill_entity(player, entity, true)
        end
    elseif player.is_shortcut_toggled('toggle-picker-autofill-entity') then
        return fill_entity(player, entity, false)
    end
end
Event.register(defines.events.on_built_entity, on_built_entity)

local function player_on_init()
    return {
        entity_sets = setmetatable({}, {__index = global.entity_sets}),
        item_sets = {
            fuel = setmetatable({}, {__index = global.item_sets.fuel}),
            ammo = setmetatable({}, {__index = global.item_sets.ammo}),
            modules = setmetatable({}, {__index = global.item_sets.modules})
        },
        use_groups = true,
        use_limits = true
    }
end
Player.additional_data(player_on_init)

local function on_load()
    for _, player in pairs(global.players) do
        setmetatable(player.entity_sets, {__index = global.entity_sets})
        setmetatable(player.item_sets.fuel, {__index = global.item_sets.fuel})
        setmetatable(player.item_sets.ammo, {__index = global.item_sets.ammo})
        setmetatable(player.item_sets.modules, {__index = global.item_sets.modules})
    end
end
Event.on_load(on_load)

local function on_init()
    global.entity_sets = build_default_entity_sets()
    global.item_sets = build_default_item_sets()
    Player.init()
end
Event.on_init(on_init)
