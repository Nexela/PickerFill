local function set_priority(set, category, name, priority)
    local current = set[category] and set[category]
    if current and current[name] then
        current[name] = priority
        return true
    end
end

local counter = {
    fuel = 0,
    ammo = 0,
    module = 0,
}
local function create_category(type)
    counter[type] = counter[type] + 1
    return { index = counter[type] }
end

local function build_default_item_sets()
    local set = {
        fuel = { index = 1 },
        ammo = { index = 2 },
        module = { index = 3 }
    }

    --Get Ammo's and Fuels
    for _, item in pairs(game.item_prototypes) do
        --Build fuel tables
        if item.fuel_value > 0 then
            set["fuel"][item.fuel_category] = set["fuel"][item.fuel_category] or create_category("fuel")
            set["fuel"][item.fuel_category or "chemical"][item.name] = item.fuel_value / 1000000
        end

        --Build Ammo Category tables
        local ammo = item.type == "ammo" and item.get_ammo_type()
        if ammo then
            set["ammo"][ammo.category] = set["ammo"][ammo.category] or create_category("ammo")
            set["ammo"][ammo.category][item.name] = 1
        end

        local module = item.type == "module" and item
        if module then
            set["module"][module.category] = set["module"][module.category] or create_category("module")
            set["module"][module.category][module.name] = tonumber(module.name:match("%d+$")) or 1
        end
    end

    -- increase priority of vanilla bullets:
    -- TODO interface to set level
    set_priority(set.ammo, "bullet", "piercing-rounds-magazine", 10)
    set_priority(set.ammo, "bullet", "uranium-rounds-magazine", 20)
    set_priority(set.ammo, "rocket", "explosive-rocket", 10)
    set_priority(set.ammo, "rocket", "atomic-bomb", 20)

    return set
end
return build_default_item_sets
