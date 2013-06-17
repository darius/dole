require('ansi_term')

local rows, cols = io.popen('stty size'):read():match('(%d+) (%d+)')
screen_rows, screen_cols = 0+rows, 0+cols

function main()
   with_stty('raw -echo', reacting)
   io.write('\n')
end

function with_stty(args, thunk)
   local settings = io.popen('stty -g'):read()
   os.execute('stty ' .. args)
   pcall(thunk)
   os.execute('stty ' .. settings)
end

function reacting()
   io.write(clear_screen)
   while true do
      redisplay()
      ch = read_key()
      if ch == '' or ch == ctrl('Q') then break end
      if ch == '\r' then ch = '\n' end
      insert(ch)
   end
end

function read_key()
   return io.read(1)
end

function ctrl(ch)
   return string.char(ch:byte(1) - 64)
end

function meta(ch)
   return '\27' .. ch
end

buffer = ''

function redisplay()
   io.write(home)
   local fixed = buffer:gsub('\n', '\r\n')
   io.write(fixed)
end

function insert(ch)
    buffer = buffer .. ch
end

main()
