-- Update what's shown on the screen.

local term = require 'ansi_term'

-- The screen size.
local stty_rows, stty_cols = io.popen('stty size'):read():match('(%d+) (%d+)')
local rows, cols = 0+stty_rows, 0+stty_cols

-- Track what's on the screen, to avoid redundant writes. An array of strings,
-- one per screen row.
local showing = {}

-- Return a string of glyphs representing character ch at column x.
local function render_glyph(ch, x)
   local b = string.byte(ch)
   if b < 32 or 126 < b then
      return string.format('\\%03o', b)
   else
      return ch
   end
end

-- Compute how to show `text` from coordinate `start` with cursor at
-- `point`. Return an object that can say whether the cursor is visible
-- and can show the rendering.
local function render(text, start, point)
   local p, x, y = start, 0, 0
   local lines = {''}
   local point_x, point_y = nil, nil
   while y < rows do
      if p == point then
         point_x, point_y = x, y
      end
      local ch = text.get(p, 1)
      p = p + 1
      if ch == '' or ch == '\n' then
         x, y = 0, y+1
         if y < rows then table.insert(lines, '') end  -- XXX redundant test
      else
         local glyphs = render_glyph(ch, x)
         for i = 1, #glyphs do
            lines[#lines] = lines[#lines] .. glyphs:sub(i, i)
            x = x + 1
            if x == cols then
               x, y = 0, y+1
               if y == rows then break end
               table.insert(lines, '')
            end
         end
      end
   end
   local function show()
      io.write(term.hide_cursor .. term.home)
      for i = 1, #lines do
         if lines[i] ~= showing[i] then
            io.write(term.goto(0, i-1) .. lines[i] .. term.clear_to_eol)
            showing[i] = lines[i]
         end
      end
      io.write(term.show_cursor .. term.goto(point_x, point_y))
   end
   return {
      cursor_is_visible = (point_x ~= nil),
      show = show,
   }
end

return {
   cols   = cols,
   render = render,
   rows   = rows,
}
