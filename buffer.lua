-- A buffer is a text with a current point of editing, a display, and
-- a keymap.

local display_m = require 'display'
local keymap_m  = require 'keymap'
local text_m    = require 'text'

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

   local function redisplay()
      if not display_m.redisplay(text, origin, point) then
         local screen_size = display_m.rows * display_m.cols
         for o = math.max(0, point - screen_size), point do
            if display_m.redisplay(text, o, point) then
               origin = o
               break
            end
         end
      end
   end

   local function insert(ch)
      text.insert(point, ch)
      point = point + #ch
   end

   local function move_char(offset)
      point = text.clip(point + offset)
   end

   local function backward_delete_char()
      text.delete(point-1, 1)
      move_char(-1)
   end

   local function forward_delete_char()
      text.delete(point, 1)
   end

   return {
      backward_delete_char = backward_delete_char,
      forward_delete_char  = forward_delete_char,
      insert               = insert,
      keymap               = keymap_m.make(insert),
      move_char            = move_char,
      redisplay            = redisplay,
      visit                = visit,
   }
end

return {
   make = make,
}
