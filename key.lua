local fancy_keys = {['\27[3~'] = 'del'}
local key_prefixes = {}
for key, name in pairs(fancy_keys) do
   for i = 1, #key-1 do
      key_prefixes[string.sub(key, 1, i)] = true
   end
end

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
