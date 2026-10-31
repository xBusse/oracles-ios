-- Cheats: each one is a toggle in Mods > Mod settings while playing, remembered between sessions.
-- Addresses are the disassembly's (src/hooks/ram_syms.txt). Counts are BCD: 0x99 shows as 99.

local seasons = oracles.game() == "seasons"
local A = seasons and {
  health = 0xc6a2, max_health = 0xc6a3, rupees = 0xc6a5, bombs = 0xc6aa, max_bombs = 0xc6ab,
  bombchus = 0xc6ad, satchel = 0xc6ae, seeds = 0xc6b5, ore = 0xc6a7,
} or {
  health = 0xc6aa, max_health = 0xc6ab, rupees = 0xc6ad, bombs = 0xc6b0, max_bombs = 0xc6b1,
  bombchus = 0xc6b3, satchel = 0xc6b4, seeds = 0xc6b9,
}

-- A toggle whose last value is kept with oracles.store, so it survives restarts.
local toggles = {}
local function toggle(name, key)
  local saved = oracles.load(key)
  local get = oracles.setting(name, saved == true)
  toggles[#toggles + 1] = {get = get, key = key, last = saved == true}
  return get
end

local hearts   = toggle("Infinite hearts", "hearts")
local rupees   = toggle("999 rupees", "rupees")
local bombs    = toggle("Full bombs", "bombs")
local seeds    = toggle("Full seeds", "seeds")
local ore      = seasons and toggle("999 ore chunks", "ore")

local function set(addr, value)
  if oracles.rd(addr) ~= value then oracles.wr(addr, value) end
end

-- satchel level 1/2/3 holds 20/50/99 of each seed (BCD)
local SATCHEL_MAX = {[1] = 0x20, [2] = 0x50, [3] = 0x99}

oracles.on_frame(function()
  for _, t in ipairs(toggles) do
    local v = t.get()
    if v ~= t.last then oracles.store(t.key, v); t.last = v end
  end

  -- no save file running yet (title, file select): touch nothing
  local max_health = oracles.rd(A.max_health)
  if max_health == 0 then return end

  if hearts() then set(A.health, max_health) end

  if rupees() then
    set(A.rupees, 0x99)
    set(A.rupees + 1, 0x09)
  end

  if bombs() then
    local max_bombs = oracles.rd(A.max_bombs)
    if max_bombs > 0 then set(A.bombs, max_bombs) end
    -- bombchus have no capacity byte: top up only once you own some
    if oracles.rd(A.bombchus) > 0 then set(A.bombchus, 0x20) end
  end

  if seeds() then
    local cap = SATCHEL_MAX[oracles.rd(A.satchel)]
    if cap then
      for i = 0, 4 do set(A.seeds + i, cap) end   -- ember, scent, pegasus, gale, mystery
    end
  end

  if ore and ore() then
    set(A.ore, 0x99)
    set(A.ore + 1, 0x09)
  end
end)
