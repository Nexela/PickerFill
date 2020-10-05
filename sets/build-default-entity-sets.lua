--[[
    These are available globaly for everyone.
    If there is not a set by the same name in the player, force or global table then sets from default are used.

    group (string):
    a group is a string representation of a group, when placed all entities that are in the same group in your hand and quickbar
    will be counted for autofilling resources.

    slots (array):
    an arrary containing tables of slot definitions

        type (string):
        currently only fuel, ammo or module

        category (string):
        the fuel/ammo/module category to use

        limit (number):
        the maximum amount of the item to put in this slot

        priority (string):
        "max" = use the item with the highest value in your main inventory that is in the category table for the set.
        "min" = use the item with the lowest value in your main inventory that is in the category table for the set.
        "qty" = use the item you have the most of in your main inventory that is in the category table for the set.

        {car = {group = nil, slots = {{type = 'fuel', category = 'chemical', priority = 'min'}, {type = 'ammo', category = 'bullet', limit = 20}}}
--]]
local function fuel_with_limit()
    return {type = 'fuel', category = 'chemical', priority = 'max', limit = 5}
end
local function fuel_max()
    return {type = 'fuel', category = 'chemical', priority = 'max'}
end
local function ammo_bullet_qty()
    return {type = 'ammo', category = 'bullet', priority = 'qty', limit = 20}
end
local function ammo_rocket_max()
    return {type = 'ammo', category = 'rocket', priority = 'max', ignore = {'atomic-bomb'}}
end

local function build_default_entity_sets()
    local fill_sets = {
        ['car'] = {slots = {fuel_max(), ammo_bullet_qty()}},
        ['spidertron'] = {slots = {ammo_rocket_max(), ammo_rocket_max(), ammo_rocket_max(), ammo_rocket_max()}},
        ['tank'] = {
            group = nil,
            slots = {
                {type = 'fuel', category = 'chemical', priority = 'min'},
                {type = 'fuel', category = 'chemical', priority = 'min'},
                {type = 'ammo', category = 'bullet', priority = 'qty'},
                {type = 'ammo', category = 'cannon-shell', priority = 'qty'}
            }
        },
        ['locomotive'] = {group = 'train-stop', slots = {fuel_max()}},
        ['artillery-wagon'] = {
            group = 'artillery-turret',
            slots = {{type = 'ammo', category = 'artillery-shell', priority = 'qty', limit = 5}}
        },
        ['boiler'] = {group = 'burner-mining-drill', slots = {fuel_with_limit()}},
        ['burner-inserter'] = {group = 'burner-mining-drill', slots = {fuel_with_limit()}},
        ['burner-mining-drill'] = {group = 'burner-mining-drill', slots = {fuel_with_limit()}},
        ['stone-furnace'] = {group = 'stone-furnace', slots = {fuel_with_limit()}},
        ['steel-furnace'] = {group = 'stone-furnace', slots = {fuel_with_limit()}},
        ['gun-turret'] = {group = 'gun-turret', slots = {ammo_bullet_qty()}},
        ['artillery-turret'] = {group = 'artillery-turret', slots = {{type = 'ammo', category = 'artillery-shell', priority = 'qty', limit = 5}}},
        ['beacon'] = {
            group = 'beacon',
            slots = {
                {type = 'module', category = 'speed', priority = 'max', limit = 1},
                {type = 'module', category = 'speed', priority = 'max', limit = 1}
            }
        }
    }
    return fill_sets
end
return build_default_entity_sets
