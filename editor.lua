-- The top-level text editor

local keyboard_m = require 'keyboard'
local stty_m     = require 'stty'

local fundamental_mode = require 'fundamental_mode'

local function edit(buffer)
   while true do
      buffer.redisplay()
      local ch = keyboard_m.read_key()
      local command = buffer.keymap.get(ch)
      if command == 'exit' then break end
      command(ch)
   end
end

local function dole(filename_opt)
   local buffer = fundamental_mode.make()
   if filename_opt then buffer.visit(filename_opt) end
   stty_m.with_stty('raw -echo', function() edit(buffer) end)
   io.write('\n')
end

return {
   dole = dole,
   edit = edit,
}
