local Event = require('__stdlib__/stdlib/event/event')
local Player = require('__stdlib__/stdlib/event/player')
local Position = require('__stdlib__/stdlib/area/position')
local Iter = require('__stdlib__/stdlib/utils/iter')
local table = require('__stdlib__/stdlib/utils/table')
local Sets = require('scripts/auto-fill-sets')

local function new_pdata()
    local pdata = {
        enabled = true,
        sets = {
            fill_sets = {},
            item_sets = {}
        },
        use_groups = true,
        use_limits = true
    }
    Sets.load_player_metatables(pdata.sets)
    return pdata
end
Player.additional_data(new_pdata)

local function init()
    global.enabled = true

    local fuel, module, ammo = Sets.build_item_sets()

    global.sets = {
        fill_sets = {},
        item_sets = {
            fuel = fuel,
            module = module,
            ammo = ammo
        }
    }

    Sets.load_global_metatables(global.sets)
end
Event.register(Event.core_events.init, init)

local function load()
    for _, player in pairs(global.players) do
        Sets.load_player_metatables(player.sets)
    end
    Sets.load_global_metatables(global.sets)
end
Event.register(Event.core_events.load, load)

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

local function fly_msg(player, line, pos, color)
    color = color or defines.color.red
    line = line or ''
    pos = pos or player.position
    return player.create_local_flying_text {position = pos, text = line, color = color}
end

local function get_item_counts(item_name, ...)
    local invs = {...}
    local total = 0
    for _, inv in pairs(invs) do
        total = total + (type(inv) == 'table' and inv.get_item_count(item_name) or 0)
    end
    return total
end

local function autofill(event)
    local entity = event.created_entity
    local player, pdata = Player.get(event.player_index)
    local settings = player.mod_settings

    local ghost, set, color
    if entity.name == 'entity-ghost' then
        if settings['picker-fill-ghost'] then
            ghost = true
            set = global.enabled and pdata.enabled and pdata.sets.fill_sets[entity.ghost_name]
        else
            return
        end
    elseif settings['picker-fill-entity'] then
        ghost = false
        set = global.enabled and pdata.enabled and pdata.sets.fill_sets[entity.name]
    else
        return
    end

    if set then
        local min, max, floor, ceil = math.min, math.max, math.floor, math.ceil
        --Increment y position everytime text_pos is called
        local text_pos = Position(entity.position):increment(0, 1)

        --local fuel_slots = pcall(#entity.get_inventory(defines.inventory.fuel))
        -- local duplicate_counts = {}

        --Get inventories
        local mi = player.get_main_inventory()
        local vi = player.vehicle and player.vehicle.get_inventory(defines.inventory.car_trunk)

        local slot_counts = {}
        --further divide amongst same type slot counts
        for _, slot in ipairs(set.slots) do
            slot_counts[slot.category] = slot_counts[slot.category] or 0 + 1
        end

        --Loop through each slot in the set.
        for _, slot in ipairs(set.slots) do
            local item = false -- The item to insert
            local item_count = 0 -- Total count of item in inventory and car inventory
            local insert_count = 0 -- Count of items to insert
            local group_count = 1 -- Num of items in the group. (Hand + Quickbar)

            --verify or set existing priority
            local priority = priorities[slot.priority] or 'qty'

            --(( Start Item Count ))--
            local plist = pdata.sets.item_sets[slot.type] and pdata.sets.item_sets[slot.type][slot.category] or {}
            local glist = global.sets.item_sets[slot.type] and global.sets.item_sets[slot.type][slot.category] or {}
            local item_list = table.dictionary_merge(plist, glist)

            --No item list or item list is not a table.
            if not type(item_list) == 'table' then
                fly_msg(player, {'autofill.invalid-category'}, text_pos())
                return
            end

            if player.cheat_mode then
                item = get_highest_value(item_list)
                item_count = 32000000
            elseif priority == 'qty' or ghost then
                for item_name, _ in pairs(item_list) do
                    if game.item_prototypes[item_name] then
                        local total = get_item_counts(item_name, mi, vi)
                        if (total > 0 and total > item_count) then
                            item = item_name
                            item_count = total
                        end
                    end
                    if not item and ghost then
                        item, item_count = get_highest_value(item_list)
                    end
                end
            elseif priority == 'max' then
                for item_name, _ in Iter.spairs(item_list, _sort_max) do
                    if game.item_prototypes[item_name] then
                        local total = get_item_counts(item_name, mi, vi)
                        if total > 0 then
                            item = item_name
                            item_count = total
                            break
                        end
                    end
                end
            elseif priority == 'min' then
                for item_name, _ in Iter.spairs(item_list, _sort_min) do
                    if game.item_prototypes[item_name] then
                        local total = get_item_counts(item_name, mi, vi)
                        if total > 0 then
                            item = item_name
                            item_count = total
                            break
                        end
                    end
                end
            end
            --)) END Item Count ((-- We now have an item, and a count of the amount of items we have.

            if not ghost then
                if not item or item_count < 1 then
                    local key_table = table.keys(item_list)
                    if key_table[1] ~= nil and game.item_prototypes[key_table[1]] then
                        fly_msg(player, {'autofill.out-of-item', slot.type}, text_pos())
                    elseif key_table[1] ~= nil then
                        fly_msg(player, {'autofill.invalid-itemname', key_table[1]}, text_pos())
                    end
                    return
                end

                --(( START Groups ))-- Divide stack between group items (only items in quickbar and hand are part of the group)
                if (set.group and pdata.use_groups) then
                    if player.cursor_stack.valid_for_read then
                        group_count = group_count + player.cursor_stack.count
                    end
                    for entity_name, set_table in pairs(pdata.sets) do
                        if type(set_table) == 'table' and set_table.group == set.group then
                            group_count = group_count + qb.get_item_count(entity_name)
                        end
                    end
                end
            --)) END Groups ((--
            end

            local slot_count = slot_counts[slot.category] or 1 - 1
            if slot_count < 1 then
                slot_count = 1
            end

            local stack_size = game.item_prototypes[item].stack_size
            -- How many to insert
            -- Min of item_count or stack_size
            -- cheat_mode == stack.size
            insert_count = insert_count + min(max(1, min(item_count, floor(item_count / ceil(group_count / slot_count)))), min(pdata.use_limits and slot.limit or stack_size, stack_size))

            --game.print(insert_count)
            --(( START inesertion ))--
            if ghost then
                local requests = entity.item_requests or {}
                requests[item] = (requests[item] or 0) + insert_count
                entity.item_requests = requests
            else
                local removed, inserted
                inserted =
                    entity.insert {
                    name = item,
                    count = insert_count
                }
                if inserted > 0 then
                    if vi then
                        removed = vi.remove {name = item, count = inserted}
                        if inserted > removed then
                            mi.remove {name = item, count = inserted - removed}
                        end
                    else
                        mi.remove {name = item, count = inserted}
                    end

                    if inserted < stack_size then
                        color = defines.color.yellow
                    elseif insert_count >= stack_size then
                        color = defines.color.green
                    end

                    if removed then
                        local msg = {
                            'autofill.insertion-from-vehicle',
                            inserted,
                            game.item_prototypes[item].localised_name,
                            removed,
                            game.entity_prototypes[player.vehicle.name].localised_name
                        }
                        fly_msg(player, msg, text_pos(), color)
                    else
                        fly_msg(player, {'autofill.insertion', inserted, game.item_prototypes[item].localised_name}, text_pos(), color)
                    end
                end
            end
            --)) END insertion ((--
        end
    end
end
Event.register(defines.events.on_built_entity, autofill)

return autofill
