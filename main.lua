---@diagnostic disable: lowercase-global
if arg[#arg] == "vsc_debug" then require("lldebugger").start() end


function love.load()
    target = {}
    target.x = 200
    target.y = 200
    target.radius = 10

    screen = {}
    screen.width = 800
    screen.height = 600
    circle_radius = 10
    love.window.setMode(screen.width, screen.height)

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

    gameState = 'init'
end

function love.update(dt)
   if gameState == 'init' then
        circles = init(circles)
        gameState = 'play'
    elseif gameState == 'play' then
        -- Pass
    end
end

function love.draw()
    if gameState == 'play' then
        -- Draw every circle from circles
        for i = 1, #circles do
            -- print the circle 
            love.graphics.setColor(circles[i].color.values)
            love.graphics.circle("fill", circles[i].x, circles[i].y, circles[i].radius)
        end

        -- Print which color is the most common
        love.graphics.setColor(1,1,1)
        love.graphics.setFont(gameFont)
        local i_maxCircle = getMaxCircles(circles)
        love.graphics.print(string.format('Score: %s', score), 50, 50)

        if mouseDown then
            target.x = love.mouse.getX()
            target.y = love.mouse.getY()
        end
    end
end

function love.mousepressed(x, y, button, istouch, presses)
    -- If mouse clicks on a target colored circle, turn gamestate to init and add 1 to score
    if button == 1 then
        maxColor = colors[getMaxCircles(circles)]
        for i = 1, #circles do
            if math.sqrt((circles[i].x - x)^2 + (circles[i].y - y)^2) < circles[i].radius then
                if circles[i].color == maxColor then
                    score = score + 1
                    gameState = 'init'
                    break
                else
                    score = 0
                end
            end
        end
        mouseDown = true
    end
end

function love.mousereleased(x, y, button, istouch, presses)
    if button == 1 then
        mouseDown = false
    end
end

-- circles: table
function init(circles)
    -- Reset circles
    circles = {}

    -- insert random colored circles
    for i = 1, 30 do
        table.insert(circles, {x = math.random(circle_radius, screen.width-circle_radius), y = math.random(circle_radius, screen.height-circle_radius), radius = circle_radius, color = colors[math.random(1, 6)]})
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

    table.insert(circles, {x = math.random(circle_radius, screen.width-circle_radius), y = math.random(circle_radius, screen.height-circle_radius), radius = circle_radius, color = colors[maxColor]})

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