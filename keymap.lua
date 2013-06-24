-- Binding keys to commands

local function ctrl(ch)
   return string.char(ch:byte(1) - 64)
end

local function meta(ch)
   return '\27' .. ch
end

-- Return a new keymap.
-- XXX this seems heavyweight
local function make(default_command)
   local keys = {}

   local function get(key)
      if key == nil then        -- key might be nil on EOF
         return 'exit'
      else
         return keys[key] or default_command
      end
   end

   local function bind(key, command)
      keys[key] = command
   end

   return {
      bind = bind,
      get  = get,
   }
end

return {
   ctrl = ctrl,
   make = make,
   meta = meta,
}
