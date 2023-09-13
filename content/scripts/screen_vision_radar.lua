
color_white = color8(255, 255, 255, 255)

c_input_left = 0
c_input_right = 1

g_breakout = {
    rows = {},

    remaining = -1,

    row_dy = 10,

    ball_x = -1,
    ball_y = -1,

    ball_dy = 1,
    ball_dx = 2,

    paddle_x = 0,
    paddle_y = 0,
    paddle_w = 16,

    paddle_dx = 0,
}


function parse()

end

function begin()
    begin_load()
end

function check_hit_block()
    local bx = g_breakout.ball_x
    local by = g_breakout.ball_y

    if by < 40 then
        for i = 1, #g_breakout.rows do
            for j = 1, #g_breakout.rows[i] do
                local block = g_breakout.rows[i][j]
                if block == 1 then
                    local x1 = (12 * j) - 4
                    local x2 = (x1 + 9) + 4
                    local y1 = (g_breakout.row_dy * i) - 1
                    local y2 = y1 + 4

                    if by >= y1 and by <= y2 then
                        if bx >= x1 and bx <= x2 then
                            -- hit, delete the block
                            g_breakout.rows[i][j] = 0
                            return true
                        end
                    end
                end
            end
        end
    end

    return false
end

function update(screen_w, screen_h, ticks)
    local st, err = pcall(function()
        _update(screen_w, screen_h, ticks)
    end)
    if not st then
        print(err)
    end
end

function do_reset()
    g_breakout.rows = {
        {1,1,1,1,1,1,1,1,1},
        {1,1,1,1,1,1,1,1,1},
    }
end

function _update(screen_w, screen_h, ticks)
    -- check reset
    if g_breakout.remaining <= 0 then
        do_reset()
    end

    -- move the ball
    g_breakout.ball_x = g_breakout.ball_x + g_breakout.ball_dx
    g_breakout.ball_y = g_breakout.ball_y + g_breakout.ball_dy

    if g_breakout.ball_y < 0 then
        g_breakout.ball_y = screen_h
    end
    if g_breakout.ball_x < 0 or g_breakout.ball_x > screen_w then
        g_breakout.ball_dx = g_breakout.ball_dx * -1
        beep()
    --elseif g_breakout.ball_x > screen_w then
      --  g_breakout.ball_dx =  g_breakout.ball_dx * -1
    end

    if g_breakout.ball_y < 1 then
        g_breakout.ball_dy =  g_breakout.ball_dy * -1
        if g_breakout.ball_dy > 5 then
            g_breakout.ball_dy = 5
        end
        beep()
    end

    if g_breakout.ball_y > (screen_h + 10) then
        g_breakout.ball_dy = g_breakout.ball_dy * -1
    end

    g_breakout.paddle_y = screen_h - 10

    -- detect paddle hit ball
    if g_breakout.ball_dy > 0 then
        local d_paddle_x = math.abs(g_breakout.paddle_x - g_breakout.ball_x)

        local d_paddle_y = math.abs(g_breakout.paddle_y - g_breakout.ball_y)

        if d_paddle_y < 1 then
            if d_paddle_x < g_breakout.paddle_w then
                g_breakout.ball_dy = g_breakout.ball_dy * -1
                print(d_paddle_x)
                if d_paddle_x < 5 then
                    g_breakout.ball_dx = g_breakout.ball_dx * 0.7
                    g_breakout.ball_dy = g_breakout.ball_dy * 1.3
                end
            end
        end
    end

    if check_hit_block() then
        beep2()
        g_breakout.ball_dy = g_breakout.ball_dy * -1
    end

    -- move paddle
    g_breakout.paddle_x = g_breakout.paddle_x + g_breakout.paddle_dx

    if g_breakout.paddle_x < 1 then
        g_breakout.paddle_x = 1
    elseif g_breakout.paddle_x > screen_w then
        g_breakout.paddle_x = screen_w
    end

    -- draw the paddle
    update_ui_rectangle(g_breakout.paddle_x - math.floor(g_breakout.paddle_w / 2), g_breakout.paddle_y, g_breakout.paddle_w, 2, color_white)

    -- draw the ball
    update_ui_rectangle(g_breakout.ball_x -2, g_breakout.ball_y -2, 4, 4, color_white)

    -- draw the blocks
    g_breakout.remaining = 0
    for i = 1, #g_breakout.rows do
        for j = 1, #g_breakout.rows[i] do
            local block = g_breakout.rows[i][j]
            if block == 1 then
                g_breakout.remaining = g_breakout.remaining + 1
                update_ui_rectangle(12 * j, g_breakout.row_dy * i, 9, 6, color_white)
            end
        end
    end
end

function input_event(event, action)
    if action == e_input_action.press then
        if event == e_input.back then
            update_set_screen_state_exit()
        else
            if event == c_input_left then
                g_breakout.paddle_dx = -4
            elseif event == c_input_right then
                g_breakout.paddle_dx = 4
            end
            print(string.format("input + %s", event))
        end
    elseif action == e_input_action.release then
        if event ~= e_input.back then
            print(string.format("input - %s", event))
            g_breakout.paddle_dx = 0
        end
    end
end

function input_axis(x, y, z, w)
    -- print(string.format("axis x=%d y=%d z=%d w=%d", x, y, z, w))
end

function input_pointer(is_hovered, x, y)
    print(string.format("pointer x=%d y=%d", x, y))
end

function input_scroll(dy)
    print(string.format("scroll dy=%d", dy))
end

function beep()
    update_play_sound(9)
end

function beep2()
    update_play_sound(7)
end

