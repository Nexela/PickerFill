-------------------------------------------------------------------------------
--[[Sets.lua: Defines all set and table data]]
-------------------------------------------------------------------------------
--game.print(global.players[1].Sets.fill_sets["stone-furnace"].group)

local Sets = {}

local interface = require('__stdlib__/stdlib/scripts/interface')

local function set_priority(set, category, name, priority)
    local current = set[category] and set[category]
    if current and current[name] then
        current[name] = priority
        return true
    end
end

function Sets.build_item_sets()
    local set = {
        fuel = {},
        ammo = {},
        module = {}
    }

    --Get Ammo's and Fuels
    for _, item in pairs(game.item_prototypes) do
        --Build fuel tables
        if item.fuel_value > 0 then
            set['fuel'][item.fuel_category] = set['fuel'][item.fuel_category] or {}
            set['fuel'][item.fuel_category or 'chemical'][item.name] = item.fuel_value / 1000000
        end

        --Build Ammo Category tables
        local ammo = item.type == 'ammo' and item.get_ammo_type()
        if ammo then
            set['ammo'][ammo.category] = set['ammo'][ammo.category] or {}
            set['ammo'][ammo.category][item.name] = 1
        end

        local module = item.type == 'module' and item
        if module then
            set['module'][module.category] = set['module'][module.category] or {}
            set['module'][module.category][module.name] = tonumber(module.name:match('%d+$')) or 1
        end
    end

    -- increase priority of vanilla bullets:
    -- TODO interface to set level
    set_priority(set.ammo, 'bullet', 'piercing-rounds-magazine', 10)
    set_priority(set.ammo, 'bullet', 'uranium-rounds-magazine', 20)

    return set.fuel, set.ammo, set.module
end

--(( Build Defaults ))
Sets.sets = {
    fill_sets = prequire('sets/default-fill-sets') or {}
} --))

--(( Metatable Loader functions ))--
function Sets.load_player_metatables(sets)
    setmetatable(sets.fill_sets, {__index = global.sets.fill_sets})
end

function Sets.load_global_metatables(sets)
    setmetatable(sets.fill_sets, {__index = Sets.sets.fill_sets})
end

interface.write_sets = function()
    game.write_file(script.mod_name..'/default-sets.lua', inspect(Sets.sets), false)
end

return Sets
