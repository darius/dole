-- Main program

-- ugh to _m name
local buffer_m = require 'buffer'
local key_m    = require 'key'
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

local function insert(ch)
   buffer.insert(ch)
end

local function ctrl(ch)
   return string.char(ch:byte(1) - 64)
end

local function meta(ch)
   return '\27' .. ch
end

local keybindings = {}

keybindings[ctrl('B')] = function() buffer.move_char(-1) end
keybindings[ctrl('F')] = function() buffer.move_char(1) end
keybindings[ctrl('Q')] = 'exit'

keybindings['\r'] = function() insert('\n') end
keybindings[string.char(127)] = buffer.backward_delete_char
keybindings['del'] = buffer.forward_delete_char

local function reacting()
   io.write(term_m.clear_screen)
   while true do
      buffer.redisplay()
      local ch = key_m.read_key()
      if ch == nil or keybindings[ch] == 'exit' then break end
      (keybindings[ch] or insert)(ch)
   end
end

function main()
   with_stty('raw -echo', reacting)
   io.write('\n')
end

main()
