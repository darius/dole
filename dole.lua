local term = require('ansi_term')

local rows, cols = io.popen('stty size'):read():match('(%d+) (%d+)')
local screen_rows, screen_cols = 0+rows, 0+cols

local function with_stty(args, thunk)
   local settings = io.popen('stty -g'):read()
   os.execute('stty ' .. args)
   pcall(thunk)  -- XXX want to reraise any error, after stty
   os.execute('stty ' .. settings)
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
