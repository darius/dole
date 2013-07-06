-- Glossary:
--   p   coordinate (position between characters in text, or `nowhere`)
--   dir direction
--   cs  charset

-- A text is a sequence of characters. We say the characters are at
-- positions 1..length, but coordinates denote the spaces *between*
-- character positions, in [0..length]. The coordinate before the
-- first character is 0, then after the first character and before the
-- second is 1, and so on, until the coordinate after the last
-- character is `length`.
-- 
-- We store the characters at integer indices in the table (starting
-- at index 1) in two chunks which we call the head and the tail,
-- separated by the gap. The fields `head` and `gap` (and `tail` if it
-- weren't implicit) denote the lengths of these spans.  `length`
-- denotes head+tail, i.e. the total length of text. The whole array
-- is of size length+gap, i.e. head+gap+tail.
--
-- (The gap lets us insert or delete text by moving the gap instead
-- of the whole tail; if there's locality, this will be cheaper.)
--
-- If you're wondering why there's no `tail` field, it's because
-- `length` is needed more often, and I prefer irredundant
-- representations. (This Lua version actually is a bit redundant:
-- t.length == #t - t.gap)  TODO get rid of length field after all
-- 
-- TODO: should coords be 1..length+1 instead? would that be nicer?
-- TODO: marks
-- TODO: attributes or something
-- TODO: for space efficiency the array ought to hold strings of up to
-- say 64 bytes, instead of single characters. Or does Lua have some
-- byte-array type?
-- TODO: statistically predict whether the next insertion will be
-- to the left or the right of the current one, and place the current
-- one on the opposite side of the gap, to reduce copying.
-- TODO: we want a nowhere_before and a nowhere_after, such that 
--  text.clip move to 0/length respectively

-- A coordinate that's never an actual text position.
local nowhere = -1

-- Directions from a coordinate.
local backward, forward = -1, 1

local dbg, loud = false, false

-- Make a text object.
local function make() 
   local t = {}   -- The storage for the head, gap, and tail. TODO rename?
   local head = 0
   local gap = 0
   local length = 0

   local ideal = ''

   local function contents()
      local result = ''
      for i = 1, head do
         result = result .. t[i]
      end
      for i = head+1, length do
         result = result .. t[gap+i]
      end
      return result
   end

   local function self_check()
      if dbg then
         assert(0 <= head)
         assert(0 <= gap)
         assert(head <= length)
         if loud then
            print('check')
            print(contents())
            print(ideal)
         end
         assert(ideal == contents())
      end
   end

   local function dump(caption)
      if loud then
         if caption then
            io.stderr:write(caption, ' / ')
         end
         io.stderr:write('#t: [')
         for i = 1, #t do
            io.stderr:write(' ', string.byte(t[i]))
         end
         io.stderr:write('] head:', head, ' gap:', gap, ' length:', length)
         io.stderr:write('\n')
      end
   end

   -- Return coordinate p clipped to the text's actual range.
   local function clip(p)
      return math.max(0, math.min(p, length))
   end

   local function clip_range(p, span)
      local q = clip(p)
      return q, clip(p + math.max(0, span)) - q
   end

   -- Return the position after the instance of `cs` closest to `p`
   -- in direction `d`. (If there's none, return `nowhere`.)
   local function find_char_set(p, dir, cs)
      p = clip(p)
      if dir == forward then
         while p < head do
            if cs.has(t[p+1]) then return p+1 end
            p = p + 1
         end
         while p < length do
            if cs.has(t[gap+p+1]) then return p+1 end
            p = p + 1
         end
      else
         assert(dir == backward)
         while head < p do
            if cs.has(t[gap+p]) then return p end
            p = p - 1
         end
         while 0 < p do
            if cs.has(t[p]) then return p end
            p = p - 1
         end
      end
      return nowhere
   end

   -- Return the `span` characters after `p` as a string.
   local function get(p, span)
      p, span = clip_range(p, span)
      self_check()
      --dump('get '..p..', '..span)
      local expected = ideal:sub(p+1, p+span)

      local result = ''
      while p < head and #result < span do
         p = p + 1
         result = result .. t[p]
      end
      while p < length and #result < span do
         p = p + 1
         result = result .. t[gap+p]
      end

      assert(result == expected)
      return result
   end

   local function memmove(dst, src, len)
      if dst <= src then
         for i = 0, len-1 do
            if loud then
               print('t[', dst+i, '] = [', src+i, '] ', t[src+i])
            end
            t[dst+i] = t[src+i]
         end
      else
         for i = len-1, 0, -1 do
            if loud then
               print('t[', dst+i, '] = [', src+i, '] ', t[src+i])
            end
            t[dst+i] = t[src+i]
         end
      end
   end

   -- Replace the `span` characters after `p` by `replacement`.
   local function replace(p, span, replacement)
      p, span = clip_range(p, span)
      dump()
      self_check()
      local new_ideal = ideal:sub(1, p) .. replacement .. ideal:sub(p+span+1)

      -- Make position p start the tail:
      if p <= head then
         memmove(gap + p+1, p+1, head - p)
      else
         memmove(head+1, gap + head+1, p - head)
      end
      head = p
      dump()
      self_check()

      -- Delete the next `span` characters:
      gap = gap + span
      length = length - span

      ideal = ideal:sub(1, p) .. ideal:sub(p+span+1)
      dump()
      self_check()

      -- Grow the array so `replacement` fits in the gap:
      if gap < #replacement then
         local tail, size = length - head, length + gap
         size = size + math.floor(size/2) + #replacement
         memmove(size - tail + 1, head + gap + 1, tail)
         gap = size - length
      end
      dump()
      self_check()

      -- Insert `replacement`:
      for i = 1, #replacement do
         --dump('replace '..i..' '..string.byte(replacement:sub(i, i)))
         t[head+i] = replacement:sub(i, i)
      end
      head = head + #replacement
      gap = gap - #replacement
      length = length + #replacement

      ideal = new_ideal
      dump()
      self_check()
   end

   local function delete(p, span)
      replace(p, span, '')
   end

   local function insert(p, insertion)
      replace(p, 0, insertion)
   end

   return {
      clip          = clip,
      delete        = delete,
      find_char_set = find_char_set,
      get           = get,
      insert        = insert,
      length        = function() return length end,
      replace       = replace,
   }
end

return {
   backward = backward,
   forward  = forward,
   make     = make,
   nowhere  = nowhere,
}
