-- Breakout game
local GameBreakout = {}
GameBreakout.__index = AppBase
setmetatable(GameBreakout, AppBase)
function GameBreakout.new()
    local self = setmetatable({}, {__index = GameBreakout})
    self.name = "Breakout"
    self.score = 0
    self.paddle_dx = 0
    self.paddle_x = 0
    self.paddle_y = 0
    self.paddle_w = 24
    self.ball_y = 0
    self.ball_x = 0
    self.ball_dy = 3
    self.ball_dx = -2 + math.random(0, 2)
    self.row_dy = 8
    self.col_dx = 4
    self.block_h = 8
    self.block_w = 16
    self.rows = {}
    self.explosions = {}
    self.remaining = -1
    -- margins
    self.mx = 10
    self.my = 10
    self:reset()
    return self
end

function GameBreakout:input_event(event, action)
    if action == e_input_action.press then
        if event == e_input.back then
            update_set_screen_state_exit()
        else
            if event == c_input_left then
                self.paddle_dx = -5
            elseif event == c_input_right then
                self.paddle_dx = 5
            end
        end
    elseif action == e_input_action.release then
        if event ~= e_input.back then
            self.paddle_dx = 0
        end
    end
end

function GameBreakout:reset()
    self.score = 0
    self.rows = {
        {1,1,1,1,1,1,1,1,1,1,1},
        {1,1,1,1,1,1,1,1,1,1,1},
        {1,1,1,1,1,1,1,1,1,1,1},
    }
    self.explosions = {}
    self.remaining = -1
    self.ball_y = self.screen_h
end

function GameBreakout:check_hit_block()
    local bx = self.ball_x
    local by = self.ball_y

    if by < self.screen_h / 2 then
        for i = 1, #self.rows do
            for j = 1, #self.rows[i] do
                local block = self.rows[i][j]
                if block == 1 then
                    local x1 = ((self.col_dx + self.block_w) * j) - self.block_w / 2
                    local x2 = x1 + self.block_w
                    local y1 = ((self.row_dy + self.block_h) * i) - 1
                    local y2 = y1 + self.block_h

                    if by >= y1 and by <= y2 then
                        if bx >= x1 and bx <= x2 then
                            -- hit, delete the block
                            self.rows[i][j] = 0
                            return true
                        end
                    end
                end
            end
        end
    end

    return false
end

function GameBreakout:draw_block(i, j)
    local r = (i * 137) % 253
    local g = (j * 45) % 201
    local b = (j * i * 3) % 255
    local color = color8(r, g, b, 255)
    local x = (self.col_dx + self.block_w) * j - self.block_w / 2
    local y = (self.row_dy + self.block_h) * i
    update_ui_rectangle(x, y, self.block_w, self.block_h, color)
    color = color8(r, g, b, 128)
    update_ui_line(x + 1, y + self.block_h, x + self.block_w -1, y + self.block_h, color)
    update_ui_line(x + 2, 1 + y + self.block_h, x + self.block_w -2, 1 + y + self.block_h, color)
end

function GameBreakout:update(screen_w, screen_h, ticks)
    -- check reset
    self.screen_w = screen_w - self.mx * 2
    self.screen_h = screen_h - self.my * 2
    if self.remaining <= 0 then
        score = self.score
        self:reset()
        self.score = score
    end
    --update_ui_push_alpha(32)
    update_ui_push_offset(self.mx, self.my)
    -- update_ui_push_clip(0, 0, screen_w - 20, screen_h - 30)
    --update_ui_push_scale(2)
    if self.score < 0 then
        self.score = 0
    end
    update_ui_text(screen_w / 2 - self.mx * 2, 0, string.format("%04d", self.score), 60, 0, color_white, 0)

    -- move the ball
    self.ball_x = self.ball_x + self.ball_dx
    self.ball_y = self.ball_y + self.ball_dy

    if self.ball_dy > 0 then
        if self.ball_dy < 1 then
            self.ball_dy = 1
        end
    end

    if self.ball_x < 0 or self.ball_x > screen_w - self.mx * 2 then
        self.ball_dx = self.ball_dx * -1
        beep()
    --elseif self.ball_x > screen_w then
      --  self.ball_dx =  self.ball_dx * -1
    end

    if self.ball_y < 1 then
        self.ball_dx = self.ball_dx + math.random(0, 1)
        self.ball_y = 1
        self.ball_dy = self.ball_dy * -0.9
        self.ball_dx = self.ball_dx * 0.9
        if self.ball_dy > 5 then
            self.ball_dy = 5
        end
        beep()
    end

    if self.ball_y > (screen_h + 10) then
        self.ball_dy = self.ball_dy * -1
        self.ball_dx = self.ball_dx * 0.8
        self.score = self.score - 25
    end
    self.paddle_y = math.floor(screen_h * 0.8)

    -- detect paddle hit ball
    if self.ball_dy > 0 then
        -- moving down
        local d_paddle_x = math.abs(self.paddle_x - self.ball_x)

        local d_paddle_y = math.abs(self.paddle_y - self.ball_y)

        if d_paddle_y < 5 then
            if d_paddle_x < self.paddle_w then
                self.ball_dy = self.ball_dy * -1
                if d_paddle_x < 5 then
                    self.ball_dx = self.ball_dx * 0.7
                    self.ball_dy = self.ball_dy * 1.3
                    beep()
                end
            end
        end
    end
    local tick = update_get_logic_tick()
    math.randomseed(tick)

    if self:check_hit_block() then
        beep2()
        self.ball_dy = self.ball_dy * -1
        self.ball_dx = self.ball_dx - 2 + tick % 2
        local blast = {x=self.ball_x, y=self.ball_y, ttl=20, ay=0.3, dy=0}
        table.insert(self.explosions, 1 + #self.explosions, blast)
        self.score = self.score + 10
    end

    -- move paddle
    self.paddle_x = self.paddle_x + self.paddle_dx

    if self.paddle_x < 0 then
        self.paddle_x = 1
    elseif self.paddle_x > screen_w - (2 * self.mx) then
        self.paddle_x = screen_w - (2 * self.mx)
    end

    -- draw the paddle
    update_ui_rectangle(self.paddle_x - math.floor(self.paddle_w / 2), self.paddle_y, self.paddle_w, 2, color_white)

    -- draw the ball
    update_ui_rectangle(self.ball_x -2, self.ball_y -2, 4, 4, color_white)

    -- draw the blocks
    self.remaining = 0
    for i = 1, #self.rows do
        for j = 1, #self.rows[i] do
            local block = self.rows[i][j]
            if block == 1 then
                self.remaining = self.remaining + 1
                self:draw_block(i, j)
            end
        end
    end

    -- draw explosions

    for i = 1, #self.explosions do
        local expl = self.explosions[i]
        if expl then
            if expl.ttl > 0 then
                self:draw_explosion(expl, tick)
                expl.ttl = expl.ttl - 1
                expl.dy = expl.dy + expl.ay
                expl.y = expl.y + expl.dy
            else
                table.remove(self.explosions, i)
            end
        end
    end
end

g_apps["breakout"] = GameBreakout:new()

-- Razor Bird - flappy bird clone

local RBird = {}
RBird.__index = AppBase
setmetatable(RBird, AppBase)
function RBird.new()
    local self = setmetatable({}, {__index = RBird})
    self.name = "Razor Bird"
    self.heli_w = 15
    self.heli_h = 15
    self.heli_x = 65
    self.heli_y = 65
    self.heli_vy = -1
    self.gravity = 0.1
    self.heli_ay = self.gravity

    self.smoke = {}
    self.explosions = {}
    self.obstacles = {}
    self.vx = 2
    self.distance = 0
    self.last_score = 0
    self.smoke_col = color8(32, 32, 49, 18)
    self.leaves_col = color8(0, 64, 12, 255)
    self.dark_leaves_col = color8(0, 32, 8, 255)
    self.darker_green = color8(0, 8, 0, 255)
    self.brown = color8(32, 32, 0, 255)
    self.ground_h = 22
    self.objects = {}
    self.pause = true

    self.died = function(this)
        local blast = {x=self.heli_x, y=self.heli_y, ttl=20, ay=0.3, dy=0}
        table.insert(self.explosions, 1 + #self.explosions, blast)
        self.pause = true
        self.last_score = self.distance
        self.distance = 0
        self.heli_y = 65
        self.heli_vy = -1.5

    end

    self.add_object = function(this, x, y, z, type, value)
        table.insert(self.objects, {x=x, y=y, z=z, type=type, value=value})
    end

    self.draw_objects = function(this)
        for i, o in pairs(self.objects) do
            if o then
                if o.type == "tree" then
                    local w = o.value.w
                    local s = o.value.s
                    update_ui_line(o.x, o.y, o.x, o.y - 4 + o.z , self.brown)
                    update_ui_circle(o.x, o.y - 7 + o.z, w, s, self.leaves_col)
                end
            end
        end
    end

    self.update_objects = function(this)
        for i, o in pairs(self.objects) do
            if o then
                local v = self.vx - o.z
                o.x = o.x - v
                if o.x < -10 then
                    table.remove(self.objects, i)
                end
            end
        end
    end

    self.update = function(this, w, h, t)
        update_set_screen_background_type(0)
        local tick = update_get_logic_tick()
        self.screen_w = w
        self.screen_h = h

        update_ui_rectangle(0, 0, w, 80, color_grey_dark)
        update_ui_rectangle(0, h - self.ground_h * 4, w, self.ground_h * 4, self.darker_green)
        update_ui_rectangle(0, h - self.ground_h * 3, w, self.ground_h * 3, self.dark_leaves_col)
        update_ui_rectangle(0, h - self.ground_h, w, self.ground_h, self.leaves_col)
        self.draw_objects()
        self.draw_heli(self.heli_x, self.heli_y, tick)

        for i, smoke in pairs(self.smoke) do
            if smoke then
                if not self.pause then
                    smoke.ttl = smoke.ttl - 1
                end
                if smoke.ttl < 1 then
                    table.remove(self.smoke, i)
                else
                    smoke.x = smoke.x - self.vx
                    self:draw_smoke(smoke)
                end
            end
        end

        for i = 1, #self.explosions do
            local expl = self.explosions[i]
            if expl then
                if expl.ttl > 0 then
                    self:draw_explosion(expl, tick)
                    if not self.pause then
                        expl.ttl = expl.ttl - 1
                    end
                else
                    table.remove(self.explosions, i)
                end
            end
        end

       for i = 1, #self.obstacles do
            local o = self.obstacles[i]
            if o then
                if o.x > -1 * o.w then
                    self:draw_obstacle(o, tick)
                    if not self.pause then
                        o.x = o.x - self.vx
                    end
                else
                    table.remove(self.obstacles, i)
                end
            end
        end
        local score = self.distance
        if self.pause then
            score = self.last_score
        end
        update_ui_text(25, h - 32, string.format("%dm", score), 48, 0, color_white, 0)

        if self.pause then
            return
        end

        self.heli_y = self.heli_y + self.heli_vy
        self.heli_vy = self.heli_vy + self.heli_ay

        -- check obstacles
        for i = 1, #self.obstacles do
            local o = self.obstacles[i]
            if o then
                if o.x > self.heli_x and o.x < self.heli_x + self.heli_w then
                    if self.heli_y > self.screen_h - o.h then
                        self:died()
                    end
                end
            end
        end

        -- check ground
        if self.heli_y > h - 10 then
            -- hit ground
            self:died()
        elseif self.heli_y < 10 then
            self.heli_y = 10
            self.heli_vy = self.heli_vy * 0.9
        end
        self.distance = self.distance + self.vx

        if self.distance % 65 == 0 then
            if math.random(0, 4) > 1 then
                -- add an obstacle
                local o = {x=w + 2,
                           w=math.random(24, 48),
                           h=math.random(30, math.floor(h * 0.65))}
                table.insert(self.obstacles, o)
            end
        end

        if tick % 4 == 0 then
            -- add a smoke every 4 ticks
            table.insert(self.smoke, {y=self.heli_y + 6, x=self.heli_x, ttl=20, n=math.random(3, 5)})
        end

        if self.heli_ay < 0 then
            -- engine on, add a smoke
            table.insert(self.smoke, {y=self.heli_y + 6, x=self.heli_x, ttl=20, n=math.random(3, 5)})
        end

        if tick % 30 == 0 then
            if math.random(1, 4) == 3 then
                -- add a vfar tree
                self:add_object(w + 2, h - 60, 1.3,"tree" , {w=math.random(2, 3), s=math.random(5,6)})
            end

            if math.random(1, 4) == 3 then
                -- add a far tree
                self:add_object(w + 2, h - 50, 1,"tree" , {w=math.random(3, 4), s=math.random(5,6)})
            end
            if math.random(1, 5) == 3 then
                -- add a near tree
                self:add_object(w + 2, h - 20, 0,"tree" , {w=math.random(4, 7), s=math.random(5,6)})
            end
        end

        self:update_objects()

    end

    self.draw_smoke = function(this, smoke)
        update_ui_circle(smoke.x, smoke.y, 4, smoke.n, self.smoke_col)
    end

    self.draw_obstacle = function(this, o)
        update_ui_rectangle(o.x, self.screen_h - o.h, o.w, o.h, color_grey_mid)
    end

    self.draw_heli = function(hx, hy, tick)
        local x = hx - self.heli_w / 2
        local y = hy - self.heli_h / 2
        local rotor_w = 18
        local rotor_y = y
        update_ui_rectangle(x, y + 3, self.heli_w, 2, color_grey_mid)
        update_ui_rectangle(x + 6, y + 2, 8, 7, color_white)
        update_ui_rectangle(x -1, y, 1, 7, color_grey_mid)
        update_ui_rectangle(x + 7, y + 4, 4, 4, color_grey_mid)
        update_ui_line(x + 5, y + 11, x + 13, y + 11, color_grey_mid)  -- skis
        update_ui_line(1 + x + rotor_w / 2, y, 1 + x + rotor_w / 2, y + 2, color_grey_dark)
        -- rotor blade

        if tick % 2 == 0 then
            rotor_y = rotor_y - 1
        end

        update_ui_line(x + 1, rotor_y, x + rotor_w, rotor_y, color_white)
    end

    self.input_event = function(this, event, action)
        if action == e_input_action.press then
            if event == e_input.back then
                update_set_screen_state_exit()
            else
                self.pause = false
                self.heli_ay = -0.2
                if self.heli_vy < -1 then
                    self.heli_vy = -1
                elseif self.heli_vy > 1 then
                    self.heli_vy = 1
                end

            end
        elseif action == e_input_action.release then
            if event ~= e_input.back then
                self.heli_ay = self.gravity
            end
        end
    end

    return self
end





g_apps["razorbird"] = RBird:new()