---@diagnostic disable: lowercase-global
if arg[#arg] == "vsc_debug" then require("lldebugger").start() end

gameState = {}
function love.load()
    -- Screen setup
    screen = {}
    screen.width = 800
    screen.height = 600
    love.window.setMode(screen.width, screen.height)
    love.window.setTitle('Computator Fabae')

    -- Game Board Initial Setup
    initialSettings = {}
    initialSettings.circle_radius = 10
    initialSettings.circles_num = 14
    initialSettings.maxDistanceFromCenter = function () return math.min(screen.height, screen.width) / 2 end
    
    -- First initialization of the gameState
    gameState.circles_num = initialSettings.circles_num
    gameState.circles = {}
    score = 0
    gameFont = love.graphics.newFont(40)
    mouseDown = false

    -- add 6 colors to the colors table
    colors = {}
    table.insert(colors, {values = {1, 0, 0}, name = "red"})
    table.insert(colors, {values = {0, 0, 0}, name = "black"})
    table.insert(colors, {values = {1, 1, 1}, name = "white"})
    table.insert(colors, {values = {0, 1, 0}, name = "green"})
    table.insert(colors, {values = {0, 0, 1}, name = "blue"})
    table.insert(colors, {values = {1, 0, 1}, name = "purple"})

    UpdateRunMode('init')
end

function love.update(dt)
    -- Record the passage of time
    gameState.dtSum = gameState.dtSum + dt

    if gameState._runMode == 'init' then
        gameState.circles = Init(gameState.circles)
        UpdateRunMode('postInit')
    
    elseif gameState._runMode == 'postInit' then
        if gameState.dtSum <= 1 then
            -- Grow gameState.circles closer and closer to initialsettings.circle_radius
            for i = 1, #gameState.circles do
                gameState.circles[i].radius = gameState.circles[i].radius + (initialSettings.circle_radius - gameState.circles[i].radius) * dt * 3
            end
        else
            -- Set all gameState.circles to default radius
            for i = 1, #gameState.circles do
                gameState.circles[i].radius = initialSettings.circle_radius
            end
            UpdateRunMode('play')
        end

    elseif gameState._runMode == 'play' then
        -- Pass

    elseif gameState._runMode == 'win' then
        ShrinkCircles(dt)
        if gameState.dtSum > 1 then
            gameState.circles_num = gameState.circles_num + 1
            UpdateRunMode('init')
        end

    elseif gameState._runMode == 'lose' then
        ShrinkCircles(dt, GetMaxCircleColor())

    else
        -- Throw an exception
        error('Invalid game state')
    end
end

function love.draw()
    -- Draw one big circle around the center
    love.graphics.setColor(1, 1, 1)
    love.graphics.circle('fill', screen.width/2, screen.height/2, initialSettings.maxDistanceFromCenter())
    love.graphics.setColor(0.1, 0.1, 0.1)
    love.graphics.circle('fill', screen.width/2, screen.height/2, initialSettings.maxDistanceFromCenter()-2)

    drawCirclesGameStates = {play = true, win = true, lose = true, postInit = true}
    if drawCirclesGameStates[gameState._runMode] then

        -- Draw every circle from gameState.circles
        for i = 1, #gameState.circles do
            -- print the circle 
            if gameState.circles[i].color.name == 'black' then
                love.graphics.setColor(1, 1, 1)
                love.graphics.circle("fill", gameState.circles[i].x, gameState.circles[i].y, gameState.circles[i].radius)
                love.graphics.setColor(0.2, 0.2, 0.2)
                love.graphics.circle("fill", gameState.circles[i].x, gameState.circles[i].y, gameState.circles[i].radius-1)
            else
                love.graphics.setColor(gameState.circles[i].color.values)
                love.graphics.circle("fill", gameState.circles[i].x, gameState.circles[i].y, gameState.circles[i].radius)
            end
        end

        -- Print which color is the most common
        love.graphics.setColor(1,1,1)
        love.graphics.setFont(gameFont)
        love.graphics.print(string.format('%s', scoreToRomanNumeral(score)), 50, 50)
    end
end

function love.mousepressed(x, y, button, istouch, presses)
    -- If mouse clicks on a target colored circle, turn gamestate to init and add 1 to score
    if button == 1 and gameState._runMode == 'play' then
        maxColor = colors[GetMaxCircleColor()]
        for i = 1, #gameState.circles do
            if math.sqrt((gameState.circles[i].x - x)^2 + (gameState.circles[i].y - y)^2) < gameState.circles[i].radius then
                if gameState.circles[i].color == maxColor then
                    score = score + 1
                    gameState.circles_num = gameState.circles_num + 1
                    UpdateRunMode('win')
                    break
                else
                    score = 0
                    gameState.circles_num = initialSettings.circles_num
                    UpdateRunMode('lose')
                end
            end
        end
        mouseDown = true
    elseif button == 1 and (gameState._runMode == 'lose' or gameState._runMode == 'win') then
        UpdateRunMode('init')
    end
end

function love.mousereleased(x, y, button, istouch, presses)
    if button == 1 then
        mouseDown = false
    end
end

function UpdateRunMode(newState)
    gameState.dtSum = 0
    gameState._runMode = newState
    print('Game state: ' .. gameState._runMode)
end

function AddCircle(circles, radius, color)
    local x, y

    -- Find an empty spot
    ::retry::
    x = math.random(initialSettings.circle_radius, screen.width  - initialSettings.circle_radius)
    y = math.random(initialSettings.circle_radius, screen.height - initialSettings.circle_radius)

    -- If x and y are too far from the center, retry
    if math.sqrt((screen.width/2 - x)^2 + (screen.height/2 - y)^2) > initialSettings.maxDistanceFromCenter() - initialSettings.circle_radius then
        goto retry
    end

    -- If x and y are more than 2*circle_radius removed from another circle in the gameState.circles table, retry
    for i = 1, #gameState.circles do
        if math.sqrt((gameState.circles[i].x - x)^2 + (gameState.circles[i].y - y)^2) < 2*initialSettings.circle_radius then
            goto retry
        end
    end

    table.insert(
        gameState.circles,
        {
            x = x,
            y = y,
            radius = radius,
            color = color,
        }
    )
end

function ShrinkCircles(dt, except)
    for i = 1, #gameState.circles do
        if except and gameState.circles[i].color.name == colors[except].name then
            goto continue
        end

        gameState.circles[i].radius = gameState.circles[i].radius - (1.9 * gameState.circles[i].radius) * dt
        if gameState.circles[i].radius < 0 then
            gameState.circles[i].radius = 0
        end
        ::continue::
    end
end

function Init(circles)

    gameState._runMode = 'init'
    gameState.dtSum = 0
    -- Reset gameState.circles
    for k in pairs(gameState.circles) do
        gameState.circles[k] = nil
    end

    -- insert an equal amount of colored gameState.circles of every kind
    for i = 1, math.floor(gameState.circles_num/6)*6 do
        AddCircle(gameState.circles, initialSettings.circle_radius/10, colors[math.fmod(i-1,6)+1])
    end
    -- insert another one so only one has a small majority
    AddCircle(gameState.circles, initialSettings.circle_radius/10, colors[math.random(1, 6)])

    return gameState.circles
end

function GetMaxCircleColor()
    -- Gets the index of the most common circle color
    local colorCount = {}
    for i = 1, 6 do
        colorCount[i] = 0
    end

    -- Count every color
    for i = 1, #gameState.circles do
        for j = 1, #colors do
            if gameState.circles[i].color.name == colors[j].name then
                colorCount[j] = colorCount[j] + 1
            end
        end
    end

    -- Set the color with the largest number of gameState.circles
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

function scoreToRomanNumeral(score)
    local romanNumerals = {
        {1000, "M"},
        {900, "CM"},
        {500, "D"},
        {400, "CD"},
        {100, "C"},
        {90, "XC"},
        {50, "L"},
        {40, "XL"},
        {10, "X"},
        {9, "IX"},
        {5, "V"},
        {4, "IV"},
        {1, "I"}
    }
    local result = ""
    for _, numeral in ipairs(romanNumerals) do
        while score >= numeral[1] do
            result = result .. numeral[2]
            score = score - numeral[1]
        end
    end
    return result
end