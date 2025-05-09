-- special skill - drone, take control and freeze everything else, and run around shooting for X time

function love.load()
  local r, g, b = love.math.colorFromBytes(75, 40, 109)
  love.graphics.setBackgroundColor(r, g, b)
  win_width, win_height, win_flags = love.window.getMode()
  border_width = win_width * 0.05
  if love.filesystem.getInfo("FiraCode-VariableFont_wght.ttf") then
    font = love.graphics.newFont("FiraCode-VariableFont_wght.ttf", 12)
    love.graphics.setFont(font)
  else
    font = love.graphics.getFont()
  end
  font_height = font:getHeight(font)
  target_width = 15
  target_height = 20
  target_x = 50
  target_y = 50
  listOfTargets = {}
  target_kills = 0
  lost_targets = 0
  target_hits = 0
  missed_shots = 0
  shots_fired = 0
  -- PLAYER
  player = {
    width = 5,
    height = 6,
    x = win_width / 2,
    y = win_height - 10,
    speed = 100,
    xp = 0,
    xp_modifier = 1.0,
    xp_needed = 100,
    level = 0
  }
  player.x1 = player.x
  player.y1 = player.y
  player.x2 = player.x1 + player.width
  player.y2 = player.y
  player.x3 = player.x1 + (player.width / 2)
  player.y3 = player.y - player.height
  listOfPlayerBullets = {}
  -- END PLAYER
  spawnCooldown = 2
  timeSinceLastSpawn = 0
end

function checkCollision(index,bullet)
  if #listOfTargets > 0 then
    for i, v in ipairs(listOfTargets) do
      local rel_x = bullet.x - v.x3
      local hit_y = 0
      if (math.abs(rel_x) <= (v.base_width / 2)) then
        if bullet.x >= v.x1 and bullet.x <= v.x3 then
          hit_y = math.abs(v.slope_right * (bullet.x - v.x1))
          --hit_y = v.y3 + v.slope_left --* rel_x
        elseif bullet.x >= v.x3 and bullet.x <= v.x2 then
          --hit_y = v.y3 + v.slope_right --* rel_x
          hit_y = math.abs(v.slope_left * (bullet.x - v.x2))
        end
        love.graphics.setColor(1,0,0)
        love.graphics.circle("fill", bullet.x, hit_y + v.y1, 3, 8)
        love.graphics.setColor(1,1,1)
        local distance = bullet.y - (hit_y + v.y1)
        if distance < bullet.radius then
          table.remove(listOfPlayerBullets, index)
          v.health = v.health - bullet.health
          target_hits = target_hits + 1
          if v.health < 1 then
            table.remove(listOfTargets, i)
            target_kills = target_kills + 1
            player.xp = player.xp + v.start_health
          end
        end
        love.graphics.print("distance: " .. math.floor(distance), bullet.x + 9,bullet.y)  
      end
    end
  end
end

function createBullet()
  local x = player.x3
  local y = player.y3
  local r = 5
  local bullet = {
    x = x, y = y, 
    radius = r, 
    speed = 150,
    health = 1
  }
  table.insert(listOfPlayerBullets, bullet)
  shots_fired = shots_fired + 1
end

function createTarget()
  love.math.setRandomSeed(love.timer.getTime())
  local x1 = math.random(25, win_width-25)
  local y1 = target_y
  local x2 = x1 + target_width
  local y2 = target_y
  local x3 = x1 + (target_width/2)
  local y3 = target_y + target_height
  local base_width = target_width
  local slope_right = (y2 - y3) / (x2 - x3)
  local slope_left = (y1 - y3) / (x1 - x3)
  local target = {
    x1 = x1, y1 = y1,
    x2 = x2, y2 = y2,
    x3 = x3, y3 = y3,
    speed = 10,
    start_health = 5,
    base_width = base_width,
    slope_left = slope_left,
    slope_right = slope_right,
    relative_x = x2 - x3,
    relative_y = y3 - y1
  }
  target.health = target.start_health
  table.insert(listOfTargets, target)
end
function drawground()
  love.graphics.setColor(118/255,170/255,0)
  local ellipse_x_radius = win_width / 2
  local ellipse_y_radius = win_height * .1
  local ellipse_center_x = win_width / 2
  local ellipse_center_y = win_height + 30
  love.graphics.ellipse("fill", ellipse_center_x, ellipse_center_y, ellipse_x_radius, ellipse_y_radius)
  love.graphics.setColor(1,1,1)
end

-- TODO: Clean this function up
function drawXPbar()
  love.graphics.setColor(197 / 255, 197 / 255, 197 / 255)
  local xp_percent = player.xp / player.xp_needed
  -- -- XP BAR BACKGROUND -- --
  local xp_bar_width = border_width / 4
  local xp_bar_height = win_height - (border_width / 2)
  local xp_bar_x = win_width - (border_width * 0.50)
  local xp_bar_y = xp_bar_width
  love.graphics.rectangle("fill", xp_bar_x, xp_bar_y, xp_bar_width, xp_bar_height)
  -- -- END XP BAR BACKGROUND -- --
  love.graphics.setColor(84 / 255, 84 / 255, 84 / 255) -- darker gray for xp bar fill
    -- -- -- XP FILL BAR -- -- --
  local xp_pad = xp_bar_width * 0.1
  local xp_full_height = xp_bar_height - (xp_pad * 2)
  local xp_pad = xp_bar_width * .1
  local xp_actual_in_pixels = xp_full_height * xp_percent
  love.graphics.rectangle("fill", xp_bar_x + xp_pad, win_height - xp_bar_width - xp_pad - xp_actual_in_pixels, xp_bar_width - (xp_pad * 2), xp_actual_in_pixels)
  -- -- -- END XP FILL BAR -- -- --
  local display_xp = string.format("%.f%%", xp_percent * 100)
  love.graphics.print("xp: " .. player.xp .. ", needed: " .. player.xp_needed, win_width * 0.05 + 10, 15)
  love.graphics.print(display_xp, win_width * 0.05 + 10, 30)
  love.graphics.print("XP height: " .. xp_full_height .. "XP in pixels: " .. xp_actual_in_pixels, win_width * 0.05 + 10, 45)
  love.graphics.setColor(1, 1, 1)
end

--
--*******love.update
--
function love.update(dt)
  timeSinceLastSpawn = timeSinceLastSpawn + dt
  
  if love.keyboard.isDown("left") then
    player.x1 = player.x1 - player.speed * dt
    player.x2 = player.x2 - player.speed * dt
    player.x3 = player.x3 - player.speed * dt
  elseif love.keyboard.isDown("right") then
    player.x1 = player.x1 + player.speed * dt
    player.x2 = player.x2 + player.speed * dt
    player.x3 = player.x3 + player.speed * dt
  end
  
  if timeSinceLastSpawn >= spawnCooldown then
    createTarget()
    timeSinceLastSpawn = 0
  end
  for _, v in ipairs(listOfPlayerBullets) do
    v.y = v.y - v.speed * dt
  end
  
  for _, v in ipairs(listOfTargets) do
    v.y1 = v.y1 + v.speed * dt
    v.y2 = v.y2 + v.speed * dt
    v.y3 = v.y3 + v.speed * dt
  end
end
-- 
--
-- ****** love.draw
--
function love.draw()
  -- -- -- boarders -- -- -- 
  love.graphics.setColor(60/255, 32/255, 87/255)
  love.graphics.rectangle("fill", border_width, 0, win_width * 0.9, win_height)
  -- -- --  ground  -- -- --
  drawground()
  -- -- -- -- -- -- -- -- --
  -- -- DRAW PLAYER -- --
  love.graphics.setColor(84/255, 84/255, 84/255)
  love.graphics.polygon("line", player.x1,player.y1, player.x2,player.y2, player.x3, player.y3)
  love.graphics.setColor(1, 1, 1)
  -- -- DRAW XP BAR -- --
  drawXPbar()
  -- -- DRAW AIM ASSIST -- --
  love.graphics.setColor(76,255,0,1)
  love.graphics.line(player.x3,player.y3,player.x3,0)
  love.graphics.setColor(255,255,255,1)
  -- -- END DRAW AIM ASSIST -- --
  -- -- DRAW UI STATS -- --
  love.graphics.print("    Targets: " .. tostring(#listOfTargets), win_width*0.05 + 10, win_height - 120)
  love.graphics.print("      Kills: " .. tostring(target_kills), win_width*0.05 + 10, win_height - 105)
  love.graphics.print("   Got Away: " .. tostring(lost_targets), win_width*0.05 + 10, win_height - 90)
  love.graphics.print("    Bullets: " .. tostring(#listOfPlayerBullets), win_width*0.05 + 10,win_height - 75)
  love.graphics.print("       Hits: " .. tostring(target_hits), win_width*0.05 + 10, win_height - 60)
  love.graphics.print("     Misses: " .. tostring(missed_shots), win_width*0.05 + 10, win_height - 45)
  love.graphics.print("shots fired: " .. tostring(shots_fired), win_width*0.05 + 10,win_height - 30)
  if shots_fired == 0 then
    shot_accuracy = 0
  else
    shot_accuracy = (target_hits / shots_fired) * 100
  end
  local display_accuracy = "   Accuracy: " .. string.format("%.f%%",shot_accuracy)
  love.graphics.print(display_accuracy,  win_width*0.05 + 10,win_height - 15)
  -- -- END DRAW UI STATS -- --
  -- -- DRAW TARGETS -- --
  for i, v in ipairs(listOfTargets) do
    local text = tostring(v.health)
    local font_width = font:getWidth(text)
    love.graphics.print(text, v.x1 + (target_width / 2), v.y1 - 14, 0, 1, 1, font_width / 2, 0)
    love.graphics.polygon("fill", v.x1,v.y1, v.x2,v.y2, v.x3,v.y3)
    if v.y1 > win_height - 5 then
      table.remove(listOfTargets, i)
      lost_targets = lost_targets + 1
    end
  end
  -- -- END DRAW TARGETS -- --
  -- -- DRAW BULLETS -- --
  for i = #listOfPlayerBullets, 1, -1 do
    local v = listOfPlayerBullets[i]
    love.graphics.circle("fill", v.x, v.y, v.radius, 8)
    checkCollision(i,v)
    if v.y < 5 then
      table.remove(listOfPlayerBullets, i)
      missed_shots = missed_shots + 1
    end
  end
  -- -- END DRAW BULLETS -- --
end

function love.keypressed(key, scancode, isrepeat)
  if key == "escape" then
    love.event.quit()
  elseif key == "space" then
    createBullet()
  end
end