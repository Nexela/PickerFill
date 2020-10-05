local Gui = require('__stdlib__/stdlib/event/gui')

local function on_slider_limit_changed(event)
    local text = event.element.parent.children[2]
    text.text = tonumber(event.element.slider_value)
end
Gui.on_value_changed('^picker%-stack%-slider', on_slider_limit_changed)

local function on_text_limit_changed(event)
    local slider = event.element.parent.children[1]
    slider.slider_value = tonumber(event.element.text) or 0
end
Gui.on_text_changed('^picker%-stack%-text', on_text_limit_changed)
