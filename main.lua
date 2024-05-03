---@diagnostic disable: lowercase-global
if arg[#arg] == "vsc_debug" then require("lldebugger").start() end

gameState = {}
function love.load()
    -- Screen setup
    screen = {}
    screen.width = 800
    screen.height = 600
    love.window.setMode(screen.width, screen.height)

    -- Game Board Initial Setup
    initialSettings = {}
    initialSettings.circle_radius = 10
    initialSettings.circles_num = 20
    
    -- First initialization of the gameState
    gameState.circles_num = initialSettings.circles_num
    circles = {}
    score = 0
    gameFont = love.graphics.newFont(40)
    mouseDown = false

    -- add 6 colors to the colors table
    colors = {}
    table.insert(colors, {values = {1, 0, 0}, name = "red"})
    table.insert(colors, {values = {1, 1, 0}, name = "yellow"})
    table.insert(colors, {values = {1, 0.5, 0}, name = "orange"})
    table.insert(colors, {values = {0, 1, 0}, name = "green"})
    table.insert(colors, {values = {0, 0, 1}, name = "blue"})
    table.insert(colors, {values = {1, 0, 1}, name = "purple"})

    updateRunMode('init')
end

function love.update(dt)
    -- Record the passage of time
    gameState.dtSum = gameState.dtSum + dt

    if gameState._runMode == 'init' then
        circles = init(circles)
        updateRunMode('play')

    elseif gameState._runMode == 'play' then
        -- Pass

    elseif gameState._runMode == 'win' then
        shrinkCircles(dt)

    elseif gameState._runMode == 'lose' then
        shrinkCircles(dt)

    else
        -- Throw an exception
        error('Invalid game state')
    end
end

function love.draw()
    drawCirclesGameStates = {play = true, win = true, lose = true}
    if drawCirclesGameStates[gameState._runMode] then
        -- Draw every circle from circles
        for i = 1, #circles do
            -- print the circle 
            love.graphics.setColor(circles[i].color.values)
            love.graphics.circle("fill", circles[i].x, circles[i].y, circles[i].radius)
        end

        -- Print which color is the most common
        love.graphics.setColor(1,1,1)
        love.graphics.setFont(gameFont)
        love.graphics.print(string.format('Score: %s', score), 50, 50)
    end
end

function love.mousepressed(x, y, button, istouch, presses)
    -- If mouse clicks on a target colored circle, turn gamestate to init and add 1 to score
    if button == 1 and gameState._runMode == 'play' then
        maxColor = colors[getMaxCircles(circles)]
        for i = 1, #circles do
            if math.sqrt((circles[i].x - x)^2 + (circles[i].y - y)^2) < circles[i].radius then
                if circles[i].color == maxColor then
                    score = score + 1
                    gameState.circles_num = gameState.circles_num + 1
                    updateRunMode('win')
                    break
                else
                    score = 0
                    gameState.circles_num = initialSettings.circles_num
                    updateRunMode('lose')
                end
            end
        end
        mouseDown = true
    elseif button == 1 and (gameState._runMode == 'lose' or gameState._runMode == 'win') then
        updateRunMode('init')
    end
end

function love.mousereleased(x, y, button, istouch, presses)
    if button == 1 then
        mouseDown = false
    end
end

function updateRunMode(newState)
    gameState.dtSum = 0
    gameState._runMode = newState
    print('Game state: ' .. gameState._runMode)
end

function addCircle(circles, radius, color)
    local x, y

    -- Find an empty spot
    while true do
        x = math.random(initialSettings.circle_radius, screen.width  - initialSettings.circle_radius)
        y = math.random(initialSettings.circle_radius, screen.height - initialSettings.circle_radius)

        -- If x and y are more than 2*circle_radius removed from another circle in the circles table, break
        local valid = true
        for i = 1, #circles do
            if math.sqrt((circles[i].x - x)^2 + (circles[i].y - y)^2) < 2*initialSettings.circle_radius then
                valid = false
                break
            end
        end
        if valid then
            break
        end
    end
    table.insert(
        circles,
        {
            x = x,
            y = y,
            radius = radius,
            color = color,
        }
    )
end

function shrinkCircles(dt)
    for i = 1, #circles do
        circles[i].radius = circles[i].radius - (1.9 * circles[i].radius) * dt
        if circles[i].radius < 0 then
            circles[i].radius = 0
        end
    end
end

-- circles: table
function init(circles)

    gameState._runMode = 'init'
    gameState.dtSum = 0
    -- Reset circles
    for k in pairs(circles) do
        circles[k] = nil
    end

    -- insert random colored circles
    for i = 1, gameState.circles_num do
        addCircle(circles, initialSettings.circle_radius, colors[math.random(1, 6)])
    end

    -- Count every color
    local colorCount = {}
    for i = 1, 6 do
        colorCount[i] = 0
    end
    for i = 1, #circles do
        for j = 1, 6 do
            if circles[i].color == colors[j] then
                colorCount[j] = colorCount[j] + 1
            end
        end
    end

    -- Set the color with the largest number of circles
    local maxCount = 0
    for i = 1, 6 do
        if colorCount[i] > maxCount then
            maxCount = colorCount[i]
            maxColor = i
        end
    end

    -- Check if there is only 1 color which has the largest number of circles
    local tie = false
    for i = 1, 6 do
        if i ~= maxColor and colorCount[i] == maxCount then
            tie = true
            break
        end
    end

    addCircle(circles, initialSettings.circle_radius, colors[maxColor])

    return circles
end

function getMaxCircles(circles)
    local colorCount = {}
    for i = 1, 6 do
        colorCount[i] = 0
    end

    -- Count every color
    for i = 1, #circles do
        for j = 1, #colors do
            if circles[i].color.name == colors[j].name then
                colorCount[j] = colorCount[j] + 1
            end
        end
    end

    -- Set the color with the largest number of circles
    local maxCount = 0
    local maxColor = 0
    for i = 1, 6 do
        if colorCount[i] > maxCount then
            maxCount = colorCount[i]
            maxColor = i
        end
    end

    return maxColor
end