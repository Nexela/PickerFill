require('__stdlib__/stdlib/core')

local Player = require('__stdlib__/stdlib/event/player')
local Force = require('__stdlib__/stdlib/event/force')
Player.register_events(true)
Force.register_events(true)

--(( Scripts ))--
require('scripts/auto-fill')
require('scripts/auto-deconstruct')
--)) scripts ((--

remote.add_interface(script.mod_name, require('__stdlib__/stdlib/scripts/interface'))