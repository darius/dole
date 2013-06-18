local term = require('ansi_term')

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

local function read_key()
   return io.read(1)
end

local function ctrl(ch)
   return string.char(ch:byte(1) - 64)
end

local function meta(ch)
   return '\27' .. ch
end

local buffer = ''

local function insert(ch)
    buffer = buffer .. ch
end

local function redisplay()
   io.write(term.home)
   local fixed = buffer:gsub('\n', '\r\n')
   io.write(fixed)
end

local function reacting()
   io.write(term.clear_screen)
   while true do
      redisplay()
      ch = read_key()
      if ch == '' or ch == ctrl('Q') then break end
      if ch == '\r' then ch = '\n' end
      insert(ch)
   end
end

function main()
   with_stty('raw -echo', reacting)
   io.write('\n')
end

main()
