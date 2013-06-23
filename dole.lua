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

local function render(ch, x)
   local b = string.byte(ch)
   if b < 32 or 126 < b then
      return string.format('\\%o', b)
   else
      return ch
   end
end

local function redisplay(text, start, point)
   io.write(term.hide_cursor .. term.home)
   local p, x, y = start, 0, 0
   local found_point = false
   while y < screen_rows do
      if p == point then
         found_point = true
         io.write(term.save_cursor_pos)
      end
      local ch = buffer.get(p, 1)
      p = p + 1
      if ch == '' or ch == '\n' then
         x, y = 0, y+1
         if y < screen_rows then io.write(term.clear_to_eol .. '\r\n') end
      else
         local glyphs = render(ch, x)
         for i = 1, #glyphs do
            io.write(glyphs:sub(i, i))
            x = x + 1
            if x == screen_cols then
               x, y = 0, y+1    -- XXX assumes wraparound
               if y == screen_rows then break end
            end
         end
      end
   end
   if found_point then
      io.write(term.show_cursor .. term.restore_cursor_pos)
   end
   return found_point
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
      redisplay(buffer, 0, buffer.length())
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
