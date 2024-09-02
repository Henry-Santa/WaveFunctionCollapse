local wfc = require("wfc")
GRID_HEIGHT = 100
GRID_WIDTH = 100
CELL_SIZE = 10
local ruleSet = { RULES = {
    {
        3, -- sand
        10,
        0,
        0.5,
    },
    {
        2, -- grass
        8,
        3,
        0,
    },
    {
        0, -- mountain
        20,
        0,
        0,
    },
    {
        4, -- water
        0,
        0,
        19,
    },
}
}
local ruleSetTWO = {
    RULES = {
        {
            5, -- sand
            4,
            0,
            1,
            0.5,
        },
        {
            3, -- grass
            9,
            2,
            0,
            1,
        },
        {
            0, -- mountain
            20,
            0,
            0,
            2,
        },
        {
            4, -- water
            0,
            0,
            13,
            0.5,
        },
        {
            3, -- village
            5,
            0,
            2,
            30,
        },
    }
}
local colors = {
    [-1] = {0.5,0.5,0.5},
    {1,1,0},
    {0,1,0},
    {1,1,1},
    {0,0,1},
    {1,0,1},
}
local wfcInstance = wfc.new(GRID_HEIGHT, GRID_WIDTH, nil, ruleSet, os.time())
wfcInstance.CURRENT_STATE.state = wfc.__createBorder(wfcInstance.CURRENT_STATE.state, 1)
local not_filled = true

wfcInstance:init()

function love.load()
    love.window.setMode(1024, 768, {resizable=true, vsync=false, minwidth=800, minheight=600})

    while not_filled do
        local res = wfcInstance:performStep()
        if res == "FILLED" then
            not_filled = false
        end
    end

end

function love.draw()
    
    

    for y = 1, GRID_HEIGHT do
        for x = 1, GRID_WIDTH do
            local value = wfcInstance.CURRENT_STATE.state[x][y]
            local color = colors[value]
            love.graphics.setColor(color)
            love.graphics.rectangle("fill", (x-1) * CELL_SIZE, (y-1) * CELL_SIZE, CELL_SIZE, CELL_SIZE)
        end
    end
end