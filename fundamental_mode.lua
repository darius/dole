-- Hi, I'd like a buffer with all the usuals, please.

local buffer_m = require 'buffer'
local keymap_m = require 'keymap'

local C = keymap_m.ctrl

local function make()
   local buffer = buffer_m.make()

   buffer.keymap.bind(C('B'),      function() buffer.move_char(-1) end)
   buffer.keymap.bind(C('F'),      function() buffer.move_char(1) end)
   buffer.keymap.bind(C('N'),      buffer.next_line)
   buffer.keymap.bind(C('P'),      buffer.previous_line)
   buffer.keymap.bind(C('Q'),      'exit')
   buffer.keymap.bind('\r',        function() buffer.insert('\n') end)
   buffer.keymap.bind('backspace', buffer.backward_delete_char)
   buffer.keymap.bind('del',       buffer.forward_delete_char)
   buffer.keymap.bind('pgup',      buffer.previous_page)
   buffer.keymap.bind('pgdn',      buffer.next_page)
      
   return buffer
end

return {
   make = make,
}
