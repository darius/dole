-- Glossary:
--   p   coordinate (position between characters in text)
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

nowhere = -1

backward, forward = -1, 1

function text_make() 
   local t = {}   -- The storage for the head, gap, and tail. TODO rename?
   local head = 0
   local gap = 0
   local length = 0

   local function clip(p)
      return math.max(0, math.min(p, length))
   end

   local function clip_range(p, span)
      local q = clip(p)
      return q, clip(p + math.max(0, span)) - q
   end

   -- Return the position before the instance of `cs` closest to `p`
   -- in direction `d`. (If there's none, return `nowhere`.)
   local function find_char_set(p, dir, cs)
      p = clip(p)
      if dir == forward then
         while p < head do
            if char_set_has(cs, t[p+1]) then return p end
            p = p + 1
         end
         while p < length do
            if char_set_has(cs, t[gap+p+1]) then return p end
            p = p + 1
         end
      else
         assert(dir == backward)
         while head < p do
            if char_set_has(cs, t[gap+p]) then return p-1 end
            p = p - 1
         end
         while 0 < p do
            if char_set_has(cs, t[p]) then return p-1 end
            p = p - 1
         end
      end
      return nowhere
   end

   -- Return the `span` characters after `p` as a string.
   local function get(p, span)
      p, span = clip_range(p, span)

      local result = ''
      while p < head and #result < span do
         p = p + 1
         result = result .. t[p]
      end
      while p < length and #result < span do
         p = p + 1
         result = result .. t[gap+p]
      end
      return result
   end

   local function memmove(dst, src, len)
      if dst <= src then
         for i = 0, len-1 do
            t[dst+i] = t[src+i]
         end
      else
         for i = len-1, 0, -1 do
            t[dst+i] = t[src+i]
         end
      end
   end

   -- Replace the `span` characters after `p` by `replacement`.
   local function replace(p, span, replacement)
      p, span = clip_range(p, span)

      -- Make position p start the tail:
      if p <= head then
         memmove(gap + p+1, p+1, head - p)
      else
         memmove(head+1, head + gap, p - head)
      end
      head = p

      -- Delete the next `span` characters:
      gap = gap + span
      length = length - span

      -- Grow the array so `replacement` fits in the gap:
      if gap < #replacement then
         local tail, size = length - head, length + gap
         size = size + math.floor(size/2) + #replacement
         memmove(size - tail + 1, head + gap + 1, tail)
         gap = size - length
      end

      -- Insert `replacement`:
      for i = 1, #replacement do
         t[head+i] = replacement:sub(i, i)
      end
      head = head + #replacement
      length = length + #replacement
   end

   return {
      find_char_set = find_char_set,
      get           = get,
      replace       = replace,
      length        = function() return length end,
   }
end
