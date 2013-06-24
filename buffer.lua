local display_m = require('display')
local text_m    = require('text')

local function make()
   local text = text_m.make()
   local point = 0              -- TODO: make this a mark

   local function redisplay_me()
      display_m.redisplay(text, 0, point)
   end

   local function insert(ch)
      text.replace(point, 0, ch)
      point = point + #ch
   end

   local function move_char(offset)
      point = text.clip(point + offset)
   end

   local function backward_delete_char()
      text.replace(point-1, 1, '')
      move_char(-1)
   end

   return {
      backward_delete_char = backward_delete_char,
      insert = insert,
      move_char = move_char,
      redisplay = redisplay_me,
   }
end

return {
   make = make,
}
