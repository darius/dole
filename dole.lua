-- Main program

-- ugh to _m name
local buffer_m = require 'buffer'
local key_m    = require 'key'
local keymap_m = require 'keymap'
local term_m   = require 'ansi_term'

local function unwind_protect(thunk, on_unwind)
   local ok, result = pcall(thunk)
   on_unwind()
   if ok then
      return result -- N.B. this leaves out any extra results from thunk
   else
      -- XXX *weird* without the following line it seems to fail silently
      -- (that is, not show the error we just caught -- it seems the output
      -- to stderr gets cleared away or the buffer isn't flushed or who knows). 
      print('') 
      error(result)
   end
end

local function with_stty(args, thunk)
   local settings = io.popen('stty -g'):read()
   os.execute('stty ' .. args)
   unwind_protect(thunk, function()
                     os.execute('stty ' .. settings)  -- XXX this stopped happening on error?
   end)
end

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
   with_stty('raw -echo', reacting)
   io.write('\n')
end

main()
