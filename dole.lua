-- ugh to _m name
local term_m    = require('ansi_term')
local display_m = require('display')
local text_m    = require('text')

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

local function read_key()
   return io.read(1)
end

local function buffer_make()
   local text = text_m.make()
   local point = 0              -- TODO: make this a mark

   local function redisplay_me()
      display_m.redisplay(text, 0, point)
   end

   local function insert(ch)
      text.replace(point, 0, ch)
      point = point + #ch
   end

   local function move_char(offset)
      point = text.clip(point + offset)
   end

   local function backward_delete_char()
      text.replace(point-1, 1, '')
      move_char(-1)
   end

   return {
      backward_delete_char = backward_delete_char,
      insert = insert,
      move_char = move_char,
      redisplay = redisplay_me,
   }
end

local buffer = buffer_make()

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

local function reacting()
   io.write(term_m.clear_screen)
   while true do
      buffer.redisplay()
      ch = read_key()
      if ch == nil or keybindings[ch] == 'exit' then break end
      (keybindings[ch] or insert)(ch)
   end
end

function main()
   with_stty('raw -echo', reacting)
   io.write('\n')
end

main()
