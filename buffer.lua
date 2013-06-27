-- A buffer is a text with a current point of editing, a display, and
-- a keymap.

local display_m = require 'display'
local keymap_m  = require 'keymap'
local text_m    = require 'text'

-- Return a new buffer.
local function make()
   local text = text_m.make()
   local point = 0              -- TODO: make this a mark

   local function redisplay()
      display_m.redisplay(text, 0, point)
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
   }
end

return {
   make = make,
}
