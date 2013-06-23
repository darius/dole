local term = require('ansi_term')
local text_module = require('text')  -- ugh to this name

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

local rows, cols = io.popen('stty size'):read():match('(%d+) (%d+)')
local screen_rows, screen_cols = 0+rows, 0+cols

local function with_stty(args, thunk)
   local settings = io.popen('stty -g'):read()
   os.execute('stty ' .. args)
   unwind_protect(thunk, function()
                     os.execute('stty ' .. settings)
   end)
end

local buffer = text_module.make()

local function insert(ch)
   buffer.replace(buffer.length(), 0, ch)
end

local function redisplay()
   io.write(term.home)
   local fixed = buffer.get(0, buffer.length()):gsub('\n', '\r\n')
   io.write(fixed)
end

local function read_key()
   return io.read(1)
end

local function ctrl(ch)
   return string.char(ch:byte(1) - 64)
end

local function meta(ch)
   return '\27' .. ch
end

local keybindings = {}

keybindings[ctrl('Q')] = 'exit'

keybindings['\r'] = function() insert('\n') end

local function reacting()
   io.write(term.clear_screen)
   while true do
      redisplay()
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
