require('__stdlib__/stdlib/event/player').register_events(false)

require('scripts/auto-fill')

remote.add_interface(script.mod_name, require('__stdlib__/stdlib/scripts/interface'))
