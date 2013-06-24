-- Set, save, and restore terminal settings.

local function unwind_protect(thunk, on_unwind)
   local ok, result = pcall(thunk)
   on_unwind()
   if ok then
      return result -- N.B. this leaves out any extra results from thunk
   else
      -- XXX *weird* without the following line it seems to fail silently
      -- (that is, not show the error we just caught -- it seems the output
      -- to stderr gets cleared away or the buffer isn't flushed or who knows). 
      print('') 
      error(result)
   end
end

-- Call thunk after setting stty with args; on unwind, restore settings.
local function with_stty(args, thunk)
   local settings = io.popen('stty -g'):read()
   os.execute('stty ' .. args)
   unwind_protect(thunk, function()
                     os.execute('stty ' .. settings)  -- XXX this stopped happening on error?
   end)
end

return {
   with_stty = with_stty,
}
