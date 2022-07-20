local Data = require("__stdlib__/stdlib/data/data")

Data {
    type = "shortcut",
    name = "toggle-picker-autofill-entity",
    order = "c[toggles]-z[toggle-picker-autofill-entity]",
    action = "lua",
    toggleable = true,
    localised_name = { "shortcut.toggle-picker-autofill-entity" },
    associated_control_input = nil,
    technology_to_unlock = nil,
    icon = {
        filename = "__PickerFill__/graphics/shortcuts/autofill-entity.png",
        priority = "extra-high-no-scale",
        size = 32,
        scale = 1,
        mipmap_count = 0,
        flags = { "gui-icon" }
    }
}

Data {
    type = "shortcut",
    name = "toggle-picker-autofill-ghost",
    order = "c[toggles]-z[toggle-picker-autofill-ghost]",
    action = "lua",
    toggleable = true,
    localised_name = { "shortcut.toggle-picker-autofill-ghost" },
    associated_control_input = nil,
    technology_to_unlock = nil,
    icon = {
        filename = "__PickerFill__/graphics/shortcuts/autofill-ghost.png",
        priority = "extra-high-no-scale",
        size = 32,
        scale = 1,
        mipmap_count = 0,
        flags = { "gui-icon" }
    }
}
