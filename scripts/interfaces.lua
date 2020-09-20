local interface = require('__stdlib__/stdlib/scripts/interface')

local function add_entity(event)
    if event.parameter then
        local ok, err =
            pcall(
            function()
                local a = load('return ' .. event.parameter)()
                assert(table_size(a) > 0)
                for k, v in pairs(a) do
                    assert(game.entity_prototypes[k], 'Entity does not exist')
                    assert(v.slots, 'Slots table does not exist')
                    for _, slot in pairs(v.slots) do
                        assert(type(slot.type) == 'string', 'Slot type must be one of fuel, ammo, module')
                        if slot.type == 'fuel' then
                            assert(game.fuel_category_prototypes[slot.category], 'Invalid fuel category')
                        elseif slot.type == 'ammo' then
                            assert(game.ammo_category_prototypes[slot.category], 'Invalid ammo category')
                        elseif slot.type == 'module' then
                            assert(game.module_category_prototypes[slot.category], 'Invalid module category')
                        end
                    end
                    global.entity_sets[k] = v
                    log('Added ' .. k .. ' to the global entity set.')
                end
            end
        )
        if not ok then
            game.print(err)
        end
    end
end
commands.add_command('PickerFill.add_global_entity_sets', '', add_entity)

remote.add_interface(script.mod_name, interface)
