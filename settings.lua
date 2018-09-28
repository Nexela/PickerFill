-- Picker Autodeconstruct
data:extend {
    {
        type = 'bool-setting',
        name = 'picker-autodeconstruct',
        setting_type = 'runtime-global',
        default_value = true,
        order = 'picker-autodeconstruct-a'
    },
    {
        type = 'bool-setting',
        name = 'picker-autodeconstruct-target',
        setting_type = 'runtime-global',
        default_value = true,
        order = 'picker-autodeconstruct-b'
    }
}

-- Picker Auto Fill
data:extend {
    {
        type = 'bool-setting',
        name = 'picker-fill-entity',
        setting_type = 'runtime-per-user',
        default_value = true,
        order = 'picker-fill-a'
    },
    {
        type = 'bool-setting',
        name = 'picker-fill-ghost',
        setting_type = 'runtime-per-user',
        default_value = true,
        order = 'picker-fill-b'
    }
}
