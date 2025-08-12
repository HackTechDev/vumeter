local patterns = dofile(minetest.get_modpath("vumeter") .. "/pattern.lua")

for i = 1, 10 do
  minetest.register_node("vumeter:level_" .. i, {
    description = "Vu-meter Level " .. i,
    tiles = {"vumeter_level_" .. i .. ".png"},
    light_source = i + 2,
    groups = {cracky = 3},
  })
end

minetest.register_node("vumeter:off", {
  description = "Vu-meter Off",
  tiles = {"vumeter_off.png"},
  light_source = 0,
  groups = {cracky = 3},
})

minetest.register_node("vumeter:player", {
  description = "Vu-Meter Player",
  tiles = {"vumeter_player.png"},
  groups = {cracky = 2},

  on_construct = function(pos)
    local meta = minetest.get_meta(pos)
    meta:set_string("infotext", "Clic pour démarrer le Vu-Meter")
    meta:set_string("state", "stopped")
    meta:set_int("index", 1)
  end,

  on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
    local meta = minetest.get_meta(pos)
    local state = meta:get_string("state")

    if state == "stopped" then
      meta:set_int("index", 1)
      meta:set_string("state", "playing")
      meta:set_string("infotext", "Vu-Meter en cours...")

      local handle = minetest.sound_play("son", {
        pos = pos,
        gain = 1.0,
        max_hear_distance = 20,
      })
      meta:set_int("sound_handle", handle or -1)
      minetest.get_node_timer(pos):start(0.1)

    elseif state == "playing" then
      local handle = meta:get_int("sound_handle")
      if handle and handle ~= -1 then
        minetest.sound_stop(handle)
      end
      meta:set_string("state", "stopped")
      meta:set_string("infotext", "Vu-Meter arrêté.")
      minetest.get_node_timer(pos):stop()
    end
  end,

  on_timer = function(pos, elapsed)
    local meta = minetest.get_meta(pos)
    if meta:get_string("state") ~= "playing" then return false end

    local index = meta:get_int("index") or 1
    local width = 10
    local height = 10
    local done = true

    for dx = 0, width - 1 do
      local pattern = patterns[dx + 1]
      local step = pattern and pattern[index]

      if step then
        done = false
        for dy = 0, height - 1 do
          local p = vector.add(pos, {x = dx - 5, y = dy + 1, z = 0})
          local node_name = (dy < step) and "vumeter:level_" .. (dy + 1) or "vumeter:off"
          minetest.set_node(p, {name = node_name})
        end
      end
    end

    if done then
      meta:set_string("state", "stopped")
      meta:set_string("infotext", "Vu-Meter terminé.")
      return false
    end

    meta:set_int("index", index + 1)
    return true
  end,
})
