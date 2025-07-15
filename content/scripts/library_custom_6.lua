-- Breakout game
local GameBreakout = {}
GameBreakout.__index = AppBase
setmetatable(GameBreakout, AppBase)
function GameBreakout.new()
    local self = setmetatable({}, {__index = GameBreakout})
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

function GameBreakout:draw_explosion(x, y, ttl)

end

function GameBreakout:update(screen_w, screen_h, ticks)
    -- check reset
    self.screen_w = screen_w - self.mx * 2
    self.screen_h = screen_h - self.my * 2
    if self.remaining <= 0 then
        self:reset()
    end
    --update_ui_push_alpha(32)
    update_ui_push_offset(self.mx, self.my)
    -- update_ui_push_clip(0, 0, screen_w - 20, screen_h - 30)
    --update_ui_push_scale(2)

    -- move the ball
    self.ball_x = self.ball_x + self.ball_dx
    self.ball_y = self.ball_y + self.ball_dy

    if self.ball_x < 0 or self.ball_x > screen_w - self.mx * 2 then
        self.ball_dx = self.ball_dx * -1
        beep()
    --elseif self.ball_x > screen_w then
      --  self.ball_dx =  self.ball_dx * -1
    end

    if self.ball_y < 1 then
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
                end
            end
        end
    end
    local tick = update_get_logic_tick()

    if self:check_hit_block() then
        beep2()
        self.ball_dy = self.ball_dy * -1
        self.ball_dx = self.ball_dx - 2 + tick % 2
        local blast = {x=self.ball_x, y=self.ball_y, ttl=20, ay=0.3, dy=0}
        table.insert(self.explosions, 1 + #self.explosions, blast)
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
                local r = (i * 137) % 253
                local g = (j * 45) % 201
                local b = (j * i * 3) % 255
                local color = color8(r, g, b, 255)
                update_ui_rectangle(
                        (self.col_dx + self.block_w) * j - self.block_w / 2,
                        (self.row_dy + self.block_h) * i, self.block_w, self.block_h, color)
            end
        end
    end

    -- draw explosions

    for i = 1, #self.explosions do
        local expl = self.explosions[i]
        if expl then
            if expl.ttl > 0 then
                local ex_col = color8(220, 130 + tick % 32, 23 + tick % 38, 96)
                update_ui_circle(expl.x, expl.y, expl.ttl + (tick % 3), 5 + (tick % 2), ex_col)
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