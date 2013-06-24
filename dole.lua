-- Main program

local buffer_m   = require 'buffer'
local keyboard_m = require 'keyboard'
local keymap_m   = require 'keymap'
local stty_m     = require 'stty'

local C = keymap_m.ctrl

local buffer = buffer_m.make()

buffer.keymap.bind(C('B'),      function() buffer.move_char(-1) end)
buffer.keymap.bind(C('F'),      function() buffer.move_char(1) end)
buffer.keymap.bind(C('Q'),      'exit')
buffer.keymap.bind('\r',        function() buffer.insert('\n') end)
buffer.keymap.bind('backspace', buffer.backward_delete_char)
buffer.keymap.bind('del',       buffer.forward_delete_char)

local function reacting()
   while true do
      buffer.redisplay()
      local ch = keyboard_m.read_key()
      local command = buffer.keymap.get(ch)
      if command == 'exit' then break end
      command(ch)
   end
end

function main()
   stty_m.with_stty('raw -echo', reacting)
   io.write('\n')
end

main()
