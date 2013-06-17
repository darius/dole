-- Glossary:
--   t   text
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

function text_make() 
   return {head   = 0, 
           gap    = 0,
           length = 0,
           marks  = {}}
end

local function clip(t, p)
   return math.max(0, math.min(p, t.length))
end

local function clip_range(t, p, span)
   local q = clip(t, p)
   return q, clip(t, p + math.max(0, span)) - q
end

nowhere = -1

backward = -1
forward = 1

-- Return the position in `t` before the instance of `cs` closest to
-- `p` in direction `d`.  (If there's none, return `nowhere`.)
function text_find_char_set(t, p, dir, cs)
   local head, gap, length = t.head, t.gap, t.length
   p = clip(t, p)
   if t == forward then
      while p < head do
         if char_set_has(cs, t[p+1]) then return p end
         p = p + 1
      end
      while p < length do
         if char_set_has(cs, t[gap+p+1]) then return p end
         p = p + 1
      end
   else
      assert(t == backward)
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
function text_get(t, p, span)
   p, span = clip_range(t, p, span)
   local head, gap, length = t.head, t.gap, t.length

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

local function memmove(array, dst, src, len)
   if dst <= src then
      for i = 0, len-1 do
         array[dst+i] = array[src+i]
      end
   else
      for i = len-1, 0, -1 do
         array[dst+i] = array[src+i]
      end
   end
end

-- Replace the `span` characters after `p` by `replacement`.
function text_replace(t, p, span, replacement)
   p, span = clip_range(t, p, span)
   local head, gap, length = t.head, t.gap, t.length

   -- Make position p start the tail:
   if p <= head then
      memmove(t, gap + p+1, p+1, head - p)
   else
      memmove(t, head+1, head + gap, p - head)
   end
   head = p

   -- Delete the next `span` characters:
   gap = gap + span
   length = length - span

   -- Grow the array so `replacement` fits in the gap:
   if gap < #replacement then
      local tail, size = length - head, length + gap
      size = size + math.floor(size/2) + #replacement
      memmove(t, size - tail + 1, head + gap + 1, tail)
      gap = size - length
   end
   t.gap = gap

   -- Insert `replacement`:
   for i = 1, #replacement do
      t[head+i] = replacement:byte(i)
   end
   t.head = head + #replacement
   t.length = length + #replacement
end
