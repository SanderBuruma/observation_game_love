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
    table.insert(colors, {values = {1, 0, 0}, name = "red",         border = false})
    table.insert(colors, {values = {0, 0, 0}, name = "black",       border = {1,1,1}})
    table.insert(colors, {values = {1, 1, 1}, name = "white",       border = {.8,.8,.8}})
    table.insert(colors, {values = {0, 1, 0}, name = "green",       border = false})
    table.insert(colors, {values = {0.2, 0.2, 1}, name = "blue",    border = {.9,.9,1}})
    table.insert(colors, {values = {1, 0, 1}, name = "purple",      border = false})

    math.randomseed(os.time())

    UpdateRunMode(gameState, 'init')
end

function love.update(dt)
    -- Record the passage of time
    gameState.dtSum = gameState.dtSum + dt

    if gameState._runMode == 'init' then
        gameState.circles = Init(gameState.circles, initialSettings.circle_radius, gameState)
        UpdateRunMode(gameState, 'postInit')
    
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
            UpdateRunMode(gameState, 'play')
        end

    elseif gameState._runMode == 'play' then
        -- Pass

    elseif gameState._runMode == 'win' then
        ShrinkCircles(gameState.circles, dt)
        if gameState.dtSum > 1 then
            gameState.circles_num = gameState.circles_num + 1
            UpdateRunMode(gameState, 'init')
        end

    elseif gameState._runMode == 'lose' then
        ShrinkCircles(gameState.circles, dt, GetMaxCircleColor(gameState))

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
            local c = gameState.circles[i]
            if c.color.border then
                love.graphics.setColor(c.color.border)
                love.graphics.circle("fill", c.x, c.y, c.radius)
                love.graphics.setColor(c.color.values)
                love.graphics.circle("fill", c.x, c.y, c.radius-1)
            else
                love.graphics.setColor(c.color.values)
                love.graphics.circle("fill", c.x, c.y, c.radius)
            end
        end

        love.graphics.setColor(1,1,1)
        love.graphics.setFont(gameFont)
        love.graphics.print(string.format('%s', scoreToRomanNumeral(score)), 50, 50)
    end
end

function love.mousepressed(x, y, button, istouch, presses)
    -- If mouse clicks on a target colored circle, turn gamestate to init and add 1 to score
    if button == 1 and gameState._runMode == 'play' then
        maxColor = colors[GetMaxCircleColor(gameState)]
        for i = 1, #gameState.circles do
            if math.sqrt((gameState.circles[i].x - x)^2 + (gameState.circles[i].y - y)^2) < gameState.circles[i].radius then
                if gameState.circles[i].color == maxColor then
                    score = score + 1
                    gameState.circles_num = gameState.circles_num + 1
                    UpdateRunMode(gameState, 'win')
                    break
                else
                    score = 0
                    gameState.circles_num = initialSettings.circles_num
                    UpdateRunMode(gameState, 'lose')
                end
            end
        end
        mouseDown = true
    elseif button == 1 and (gameState._runMode == 'lose') and gameState.dtSum > 2 then
        UpdateRunMode(gameState, 'init')
    elseif button == 1 and (gameState._runMode == 'win') then
        UpdateRunMode(gameState, 'init')
    end
end

function love.mousereleased(x, y, button, istouch, presses)
    if button == 1 then
        mouseDown = false
    end
end

function UpdateRunMode(gs, newState)
    gs.dtSum = 0
    gs._runMode = newState
    print('Game state: ' .. gs._runMode)
end

function AddCircle(circles, radius, color)
    local x, y
    local valid

    -- Find an empty spot
    while true do
        x = math.random(radius, screen.width  - radius)
        y = math.random(radius, screen.height - radius)

        -- If x and y are too far from the center, retry
        if math.sqrt((screen.width/2 - x)^2 + (screen.height/2 - y)^2) > initialSettings.maxDistanceFromCenter() - radius then
            valid = false
        else
            valid = true
        end

        -- If x and y are more than 2*circle_radius removed from another circle in the gameState.circles table, retry
        if valid then
            for i = 1, #circles do
                if math.sqrt((circles[i].x - x)^2 + (circles[i].y - y)^2) < 2*radius then
                    valid = false
                    break
                end
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

function ShrinkCircles(circles, dt, except)
    for i = 1, #circles do
        if not (except and circles[i].color.name == colors[except].name) then
            circles[i].radius = circles[i].radius - (1.9 * circles[i].radius) * dt
            if circles[i].radius < 0 then
                circles[i].radius = 0
            end
        end
    end
end

function Init(circles, radius, gs)

    gs._runMode = 'init'
    gs.dtSum = 0
    -- Reset gameState.circles
    for k in pairs(circles) do
        circles[k] = nil
    end

    -- insert an equal amount of colored gameState.circles of every kind
    for i = 1, math.floor(gs.circles_num/6)*6 do
        AddCircle(gs.circles, radius, colors[math.fmod(i-1,6)+1])
    end
    -- insert another one so only one has a small majority
    AddCircle(gs.circles, radius, colors[math.random(1, 6)])

    return gs.circles
end

function GetMaxCircleColor(gs)
    -- Gets the index of the most common circle color
    local colorCount = {}
    for i = 1, 6 do
        colorCount[i] = 0
    end

    -- Count every color
    for i = 1, #gs.circles do
        for j = 1, #colors do
            if gs.circles[i].color.name == colors[j].name then
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