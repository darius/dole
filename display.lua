-- Update what's shown on the screen.

local term = require 'ansi_term'

local stty_rows, stty_cols = io.popen('stty size'):read():match('(%d+) (%d+)')
local rows, cols = 0+stty_rows, 0+stty_cols

local function render(ch, x)
   local b = string.byte(ch)
   if b < 32 or 126 < b then
      return string.format('\\%03o', b)
   else
      return ch
   end
end

-- Update the screen to show `text` from coordinate `start` with
-- cursor at `point`. Return true iff point turns out to be visible.
local function redisplay(text, start, point, write)
   write(term.hide_cursor .. term.home)
   local p, x, y = start, 0, 0
   local found_point = false
   while y < rows do
      if p == point then
         found_point = true
         write(term.save_cursor_pos)
      end
      local ch = text.get(p, 1)
      p = p + 1
      if ch == '' or ch == '\n' then
         x, y = 0, y+1
         write(term.clear_to_eol)
         if y < rows then write('\r\n') end
      else
         local glyphs = render(ch, x)
         for i = 1, #glyphs do
            write(glyphs:sub(i, i))
            x = x + 1
            if x == cols then
               x, y = 0, y+1    -- XXX assumes wraparound
               if y == rows then break end
            end
         end
      end
   end
   if found_point then
      write(term.show_cursor .. term.restore_cursor_pos)
   end
   return found_point
end

return {
   cols      = cols,
   redisplay = redisplay,
   rows      = rows,
}
