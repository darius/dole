-- A buffer is a text with a current point of editing, a display, and
-- a keymap.

local charset_m = require 'charset'
local display_m = require 'display'
local keymap_m  = require 'keymap'
local text_m    = require 'text'

-- Return the smallest i in [lo..hi) where ok(i).
-- Pre: lo and hi are ints, lo < hi
-- and not ok(j) for j in [lo..i)
-- and     ok(j) for j in [i..hi)  (for some i).
local function search(lo, hi, ok)
   if ok(lo) then return lo end
   local L, H = lo, hi
   while L+1 < H do
      -- Inv: (not ok(j)) for j in [L..i) for some i, L<i<=H
      --  and      ok(j)  for j in [i..H].
      local mid = math.floor((L + H) / 2)
      if ok(mid) then
         assert(mid < H)
         H = mid
      else
         assert(L < mid)
         L = mid
      end
   end
   return H
end

-- Return a new buffer.
local function make()
   local text = text_m.make()
   local point = 0              -- TODO: make this a mark
   local origin = 0  -- display origin. XXX keep in a window object?

   local function clear()
      text = text_m.make()
      point = 0
   end

   local function visit(filename)
      -- XXX deal with error gracefully
      local file, openerr = io.open(filename, 'r')
      if file == nil then error(openerr) end
      local contents, readerr = file:read('*a')
      if contents == nil then error(readerr) end
      file:close() -- XXX check for error
      clear()
      text.insert(0, contents)
   end

   local function update_origin()
      local rendering = display_m.render(text, origin, point)
      if not rendering.cursor_is_visible then
         local function has_point(o)
            return display_m.render(text, o, point).cursor_is_visible
         end
         local screen_size = display_m.rows * display_m.cols
         origin = search(text.clip(point - screen_size), point, has_point)
      end
   end

   local function redisplay()
      update_origin()
      display_m.render(text, origin, point).show()
   end

   local function insert(ch)
      text.insert(point, ch)
      point = point + #ch
   end

   local function move_char(offset)
      point = text.clip(point + offset)
   end

   local function backward_delete_char()
      text.delete(point - 1, 1)
      move_char(-1)
   end

   local function forward_delete_char()
      text.delete(point, 1)
   end

   local newline = charset_m.singleton('\n')

   local function find_line(p, dir)
      return text.clip(text.find_char_set(p, dir, newline))
   end

   local function beginning_of_line()
      point = find_line(point, -1)
   end

   local function end_of_line()
      point = text.clip(find_line(point, 1) - 1)
   end

   -- TODO: preserve goal column; respect formatting, such as tabs;
   -- treat long lines as defined by display
   local function previous_line()
      local start = find_line(point, -1)
      local offset = point - start
      local prev_start = find_line(start-1, -1)
      point = math.min(prev_start + offset, text.clip(start-1))
   end

   local function next_line()
      local start = find_line(point, -1)
      local offset = point - start
      local next_start = find_line(start, 1)
      local next_end = find_line(next_start, 1)
      point = math.min(next_start + offset, text.clip(next_end-1))
      -- XXX this can wrap around since text.clip moves `nowhere` to 0.
   end

   -- TODO: more reasonable/emacsy behavior. This interacts quite badly
   -- with the dumb update_origin() logic.
   local function previous_page()
      -- update_origin()
      -- point = origin
      for i = 1, display_m.rows do
         previous_line()
      end
   end

   local function next_page()
      -- update_origin()
      -- point = origin
      for i = 1, display_m.rows do
         next_line()
      end
   end

   return {
      backward_delete_char = backward_delete_char,
      beginning_of_line    = beginning_of_line,
      end_of_line          = end_of_line,
      forward_delete_char  = forward_delete_char,
      insert               = insert,
      keymap               = keymap_m.make(insert),
      move_char            = move_char,
      next_line            = next_line,
      previous_line        = previous_line,
      next_page            = next_page,
      previous_page        = previous_page,
      redisplay            = redisplay,
      visit                = visit,
   }
end

return {
   make = make,
}
