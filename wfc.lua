--!strict
---@class WaveFunctionCollapse
---@field WIDTH number
---@field HEIGHT number
---@field START_STATE STATE | nil
---@field CURRENT_STATE STATE
---@field RULES RULE_SET
---@field SEED number
local WaveFunctionCollapse = {}

---@class STATE
---@field state number[][]
---@field possibilities number[][][]
---@field entropies number[][]
---@field affectedPoints {i : number, j : number}[]
local STATE = {}
STATE.__index = STATE

---@class RULE
---@field WEIGHTS number[]
local RULE = {}
RULE.__index = RULE

---@class RULE_SET
---@field RULES RULE[]
local RULE_SET = {}
RULE_SET.__index = RULE_SET

---@param WIDTH number
---@param HEIGHT number
---@param START_STATE STATE | nil
---@param RULES RULE_SET
---@param SEED number
function WaveFunctionCollapse.new(WIDTH, HEIGHT, START_STATE, RULES, SEED)
  local self = setmetatable({}, { __index = WaveFunctionCollapse })
  self.WIDTH = WIDTH
  self.HEIGHT = HEIGHT
  self.START_STATE = START_STATE
  self.CURRENT_STATE = {}
  if self.START_STATE == nil then
    self.CURRENT_STATE.state = WaveFunctionCollapse.__createEmptyGrid(WIDTH, HEIGHT)
  else
    assert(START_STATE)
    self.CURRENT_STATE.state = START_STATE
  end
  self.RULES = RULES
  self.SEED = SEED
  math.randomseed(SEED)
  return self
end

---creates an empty grid for the current state on initiliaze
---@param WIDTH number
---@param HEIGHT number
function WaveFunctionCollapse.__createEmptyGrid(WIDTH, HEIGHT)
  local grid = {}
  for i = 1, HEIGHT, 1 do
    grid[i] = {}
    for j = 1, WIDTH, 1 do
      -- -1 is the symbol for an unfilled cell
      grid[i][j] = -1
    end
  end
  return grid
end

---Creates a border in the grid
---@param grid number[][]
---@param fill number
---@return number[][]
function WaveFunctionCollapse.__createBorder(grid, fill)
  local height = #grid
  local width = #grid[1]

  -- Top and bottom borders
  for x = 1, width do
      grid[1][x] = fill
      grid[height][x] = fill
  end

  -- Left and right borders
  for y = 1, height do
      grid[y][1] = fill
      grid[y][width] = fill
  end
  return grid
end


---@param grid STATE
---@param index1 number
---@param index2 number
---@return {i : number, j : number}[]
local function GetNeigbors(grid, index1, index2)
  local HEIGHT = #grid
  local WIDTH = #grid[1]

  -- check up valid
  local up = index1 > 1
  local down = index1 < HEIGHT
  local right = index2 > 1
  local left = index2 < WIDTH

  local neighbors = {}

  if up then table.insert(neighbors, {i = index1-1, j = index2}) end
  if down then table.insert(neighbors, {i = index1+1, j = index2}) end
  if left then table.insert(neighbors, {i = index1, j = index2+ 1}) end
  if right then table.insert(neighbors, {i = index1, j = index2- 1}) end
  return neighbors
end

-- returns a table that is filled with ones to the length
---@param length number
---@return number[]
local function oneFilledTable(length)
  local tabl = {}
  for i = 1, length, 1 do
    table.insert(tabl, 1)
  end
  return tabl
end

---uses taylor series for a fast approximation of ln between 0 and 1
---@param a number
---@return number
local function fastLn(a)
  local N = 5
  local res = 0

  for i = 1, N, 1 do
    res = res + (-1)^(N%2-1)*((a-1)^N)/N
  end
  return res
end

---determine entropy
---@param probabilities number[]
---@returns number
local function entropyDeterminer(probabilities)
  --if #probabilities == 0 then return -math.huge end
  local entropy = 0
  for _, p in pairs(probabilities) do
    entropy = entropy - p*fastLn(p)
  end
  return entropy
end

--- run the update method
function WaveFunctionCollapse:init()
  self.CURRENT_STATE.affectedPoints = {}
  for i = 1, self.HEIGHT, 1 do
    for j = 1, self.WIDTH, 1 do
      table.insert(self.CURRENT_STATE.affectedPoints, {i = i, j = j})
    end
  end
  local possibilities = {}
  local entropies = {}
  for i = 1, self.HEIGHT, 1 do
    entropies[i] = {}
    possibilities[i] = {}
    for j = 1, self.WIDTH, 1 do
      possibilities[j] = {}
    end
  end
  self.CURRENT_STATE.possibilities = possibilities
  self.CURRENT_STATE.entropies = entropies

end

---updates the possibilities of what entropies can be and probabilities
function WaveFunctionCollapse:updatePossibilities()
  
  for _, point in pairs(self.CURRENT_STATE.affectedPoints) do
    local i = point.i
    local j = point.j
    local entropy = math.huge
    if self.CURRENT_STATE.state[i][j] == -1 then
      local possible = oneFilledTable(#self.RULES.RULES)
      local probabilities = {}

      -- get neighbors
      local neighbors = GetNeigbors(self.CURRENT_STATE.state, i, j)

      local weights = {}
      local weightTotal = 0

      for _, v in pairs(neighbors) do 
        local value = self.CURRENT_STATE.state[v.i][v.j]
        if value ~= -1 then
          -- multiply each weight
          for rule, weight in pairs(self.RULES.RULES[value]) do
            possible[rule] = possible[rule] * weight
          end
        end
      end

      -- remove zero weights because they mess with entropy calculation and are unimportant
      for index, v in pairs(possible) do
        if v ~= 0 then
          weights[index] = v
          weightTotal = weightTotal + v
        end
      end

      for index, v in pairs(weights) do
        probabilities[index] = v / weightTotal
      end
      self.CURRENT_STATE.possibilities[i][j] = probabilities
      entropy = entropyDeterminer(probabilities)
    end
    self.CURRENT_STATE.entropies[i][j] = entropy
  end
end

---Finds Lowest Entropy
---@return {i : number, j : number} | nil
function WaveFunctionCollapse:findLowestEntropy()
  local lowestValue = math.huge
  local iI = -1
  local jI = -1
  for i = 1, self.HEIGHT, 1 do
    for j = 1, self.WIDTH, 1 do
      if self.CURRENT_STATE.entropies[i][j] < lowestValue and self.CURRENT_STATE.state[i][j] < 0 then lowestValue = self.CURRENT_STATE.entropies[i][j]; iI = i; jI = j; end
    end
  end
  if lowestValue == -math.huge or iI < 0 then
    return nil
  end
  return {i = iI, j = jI}
end

---Make Update
---@param point {i : number, j : number}
function WaveFunctionCollapse:MakeUpdate(point)
  local randomNumber = math.random()
  local possible = self.CURRENT_STATE.possibilities[point.i][point.j]

  local su = 0
  local index = 0
  
  for i, v in pairs(possible) do
    su = su + v
    index = i
    if su > randomNumber then break end
  end
  if index == 0 then return "FAILED" end
  self.CURRENT_STATE.state[point.i][point.j] = index
  self.CURRENT_STATE.affectedPoints = GetNeigbors(self.CURRENT_STATE.state, point.i, point.j)
end

---check state
---@return "FAILED" | "FILLED" | "NOTFILLED"
function WaveFunctionCollapse:checkState()
  local filled = true
  for _, v in pairs(self.CURRENT_STATE.state) do 
    for _, d in pairs(v) do
      if d == -1 then filled = false; break end
    end
  end
  if filled then return "FILLED" end
  return "NOTFILLED"
end


---Performs one step of the algrothirim
function WaveFunctionCollapse:performStep()
  -- update possibilities
  self:updatePossibilities()
  -- find lowest entropy
  local point = self:findLowestEntropy()
  if point == nil then return "FAILED" end
  -- make choice based on random variable by seed
  local state = self:MakeUpdate(point)
  if state == "FAILED" then return "FAILED" end
  -- return if the map is filled, not filled, or failed
  return self:checkState()
end

return WaveFunctionCollapse