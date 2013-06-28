-- Sets of characters
-- (stub)

local function singleton(char)
   local function has(ch)
      return char == ch
   end

   return {
      has = has,
   }
end

return {
   singleton = singleton,
}
