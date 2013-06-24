-- Main program

-- ugh to _m name
local buffer_m = require 'buffer'
local key_m    = require 'key'
local keymap_m = require 'keymap'
local term_m   = require 'ansi_term'
local stty_m   = require 'stty'

local buffer = buffer_m.make()

local keymap = keymap_m.make(buffer.insert)
local C = keymap_m.ctrl

keymap.bind(C('B'),      function() buffer.move_char(-1) end)
keymap.bind(C('F'),      function() buffer.move_char(1) end)
keymap.bind(C('Q'),      'exit')

keymap.bind('\r',        function() buffer.insert('\n') end)
keymap.bind('backspace', buffer.backward_delete_char)
keymap.bind('del',       buffer.forward_delete_char)

local function reacting()
   io.write(term_m.clear_screen)
   while true do
      buffer.redisplay()
      local ch = key_m.read_key()
      local command = keymap.get(ch)
      if command == 'exit' then break end
      command(ch)
   end
end

function main()
   stty_m.with_stty('raw -echo', reacting)
   io.write('\n')
end

main()
