-- === Chargement du pattern externe ===
local pattern = dofile(minetest.get_modpath("vumeter") .. "/pattern.lua")

-- === Définition des textures de niveaux ===
local levels = {
  {name = "off", light = 0},
  {name = "green", light = 3},
  {name = "yellow", light = 6},
  {name = "orange", light = 10},
  {name = "red", light = 14}
}

for _, level in ipairs(levels) do
  minetest.register_node("vumeter:" .. level.name, {
    description = "Vu-meter " .. level.name,
    tiles = {"vumeter_" .. level.name .. ".png"},
    light_source = level.light,
    groups = {cracky = 3, oddly_breakable_by_hand = 2},
  })
end

-- === Node spécial : vumeter player ===
minetest.register_node("vumeter:player", {
  description = "Vu-Meter Player",
  tiles = {"vumeter_player.png"},
  groups = {cracky = 2},

on_construct = function(pos)
  local meta = minetest.get_meta(pos)
  meta:set_string("infotext", "Vu-Meter en cours...")
  meta:set_int("index", 1)  -- 🔁 important : réinitialiser le compteur
  minetest.get_node_timer(pos):start(0.1)
  minetest.sound_play("son", {
    pos = pos,
    gain = 1.0,
    max_hear_distance = 20,
  })
end,

on_timer = function(pos, elapsed)
  local meta = minetest.get_meta(pos)
  local index = tonumber(meta:get_int("index") or 1)

  local step = pattern[index]
  if step == nil then
    meta:set_string("infotext", "Vu-Meter terminé.")
    return false  -- ⛔ fin du timer, pattern terminé
  end

  minetest.log("action", "[VuMeter] Step " .. index .. " = " .. step)

  local max_level = #levels - 1  -- typiquement 4
  for i = 0, max_level do
    local node_name
    if i <= step then
      node_name = "vumeter:" .. levels[i + 2].name  -- i+2 car levels[1] = off
    else
      node_name = "vumeter:off"
    end
    local p = vector.add(pos, {x = 0, y = i + 1, z = 0})
    minetest.set_node(p, {name = node_name})
  end

  meta:set_int("index", index + 1)

  return true  -- ✅ redémarre le timer
end

})

