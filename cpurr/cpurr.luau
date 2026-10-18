--!nonstrict
-- cpurr - a cat that runs in your bar based on CPU usage.
--
-- The busier the CPU, the faster it runs; after a few idle cycles in a row it
-- curls up and sleeps. Pose frames and timing are ported from Carlo Cattano's
-- waycat (catloop.sh) - https://github.com/CarloCattano/waycat
--
--   frame delay = clamp(1000 / (4 + cpu%), 30, 250) ms

local TICK_MS = 16

local RUN_FRAMES = { "A", "B", "C", "D", "E" }
local SLEEP_FRAMES = { "G", "H", "I", "J", "K", "L", "M", "N" }

-- catloop.sh defaults
local SLEEP_THRESHOLD = 2 -- percent
local SLEEP_AFTER = 4 -- consecutive low-usage frames

local MIN_DELAY_MS = 30
local MAX_DELAY_MS = 250

local DEFAULT_SIZE = 32

local size = tonumber(noctalia.getConfig("size")) or DEFAULT_SIZE

local catFont = noctalia.loadFont("fonts/Waycat.ttf")
if catFont == nil then
  noctalia.log("cpurr: fonts/Waycat.ttf is missing - run install.sh to fetch it")
end

local frameIndex = 1
local elapsedMs = 0
local lowCycles = 0

local function cpuPercent()
  local stats = noctalia.systemStats()
  if stats ~= nil and stats.cpu ~= nil then
    return stats.cpu.usagePercent
  end
  return 0
end

local function draw(frame)
  local label = {
    text = frame,
    fontSize = size,
    baseline = "pictographic",
  }
  if catFont ~= nil then
    label.fontFamily = catFont
  end
  -- One control tall: a row on horizontal bars, a column on side bars.
  local container = if barWidget.isVertical() then ui.column else ui.row
  barWidget.render(container({ align = "center" }, { ui.label(label) }))
end

function update()
  local usage = cpuPercent()

  local delay = 1000 / (4 + usage)
  if delay < MIN_DELAY_MS then
    delay = MIN_DELAY_MS
  elseif delay > MAX_DELAY_MS then
    delay = MAX_DELAY_MS
  end

  elapsedMs += TICK_MS
  if elapsedMs < delay then
    return
  end
  elapsedMs = 0

  if usage < SLEEP_THRESHOLD then
    lowCycles += 1
  else
    lowCycles = 0
  end

  local frames = if lowCycles >= SLEEP_AFTER then SLEEP_FRAMES else RUN_FRAMES
  frameIndex = (frameIndex % #frames) + 1
  draw(frames[frameIndex])
end

noctalia.setUpdateInterval(TICK_MS)
draw(RUN_FRAMES[1])
