-- Read the keyboard

local fancy_keys = {['\27[3~'] = 'del'}
local key_prefixes = {}
for key, name in pairs(fancy_keys) do
   for i = 1, #key-1 do
      key_prefixes[string.sub(key, 1, i)] = true
   end
end

-- Wait for a key to be typed, and return it. Most keys we represent
-- by the obvious one-character string; others get names in fancy_keys,
-- above. For multibyte escape sequences not in that table, but that
-- share a prefix with a table entry, we return a multibyte string,
-- at least for now. XXX revisit that
-- TODO: echo to the screen when there's a bare Esc key, as Emacs does.
local function read_key()
   local key = io.read(1)
   while key_prefixes[key] do
      local k1 = io.read(1)
      if k1 == '' then break end
      key = key .. k1
   end
   return fancy_keys[key] or key
end

return {
   read_key = read_key,
}
