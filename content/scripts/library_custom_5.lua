-- common functions
c_input_left = 0
c_input_right = 1
color_white = color8(255, 255, 255, 255)

function beep()
    update_play_sound(9)
end

function beep2()
    update_play_sound(7)
end

-- base class for game app
local App = {}
App.__index = App
AppBase = App
function App.new()
    local self = setmetatable({}, App)
    self.name = ""
    self.screen_w = 320
    self.screen_h = 240
    self.update_func = nil
    self.input_axis_func = nil
    self.input_event_func = nil
    self.input_scroll_func = nil
    self.input_pointer_func = nil
    return self
end
function App:update(screen_w, screen_h, t)
    self.screen_w = screen_w
    self.screen_h = screen_h
    if self.update_func then
        self.update_func(self.screen_w, self.screen_h, t)
    end
end
function App:reset()
end

function App:input_event(a, b)
    if self.input_event_func then
        self.input_event_func(a, b)
    end
end

function App:input_axis(x, y, z, w)
    if self.input_axis_func then
        self.input_axis(x, y, z, w)
    end
end

function App:input_pointer(is_hovered, x, y)
    if self.input_pointer_func then
        self.input_pointer_func(is_hovered, x, y)
    end
end

function App:input_scroll(dy)
    if self.input_scroll_func then
        self.input_scroll_func(dy)
    end
end

function App:draw_explosion(expl, tick)
    local ex_col = color8(220, 130 + tick % 32, 23 + tick % 38, 96)
    update_ui_circle(expl.x, expl.y, expl.ttl + (tick % 3), 5 + (tick % 2), ex_col)
end

-- game selector
local Selector = {}
Selector.__index = AppBase
setmetatable(Selector, AppBase)
function Selector.new()
    local self = setmetatable({}, {__index = Selector})
    self.ui = lib_imgui:create_ui()
    return self
end

function Selector:update(w, h, t)
    self.screen_w = w
    self.screen_h = h
    self.ui:begin_ui()
    self.ui:begin_window("Select App", 10, 10, w - 20, h - 20, nil, true, 0, true, true)
    self.ui:header("Apps")

    for k, app in pairs(g_apps) do
        if app.name then
            if self.ui:button(app.name, true, 1) then
                g_current_app = k
            end
        end
    end

    self.ui:end_window()
    self.ui:end_ui()
end

function Selector:input_event(e, a)
    self.ui:input_event(e, a)
end

function Selector:input_pointer(h, x, y)
    self.ui:input_pointer(h, x, y)
end


if begin then
    old_begin = begin
end

default_begin_load = begin_load
default_update = nil

g_apps = {}
g_app_load_err = nil
g_current_app = "selector"

function game_begin()
    if default_update == nil then
        default_update = update
        default_input_scroll = input_scroll
        default_input_event = input_event
        default_input_axis = input_axis
        default_input_pointer = input_pointer
    end

    if g_tut_is_carrier_selected ~= nil and g_app_load_err == nil then
        -- this is a control screen, install our game selector
        update = wrapped_update
        input_event = wrapped_input_event
        input_pointer = wrapped_input_pointer
    end
end

function begin_load()
    default_begin_load()
    game_begin()
end

g_last_power = g_is_on

function wrapped_update(screen_w, screen_h, ticks)
    if g_is_on ~= g_last_power then
        g_last_power = g_is_on
        if g_is_on then
            g_apps[g_current_app]:reset()
            -- powered off and back on
            g_current_app = "selector"
        end
    end

    if g_apps["selector"] == nil then
        g_apps["selector"] = Selector:new()
        g_apps["control_screen"] = App:new()
        g_apps["control_screen"].name = "Vehicle Control"
        g_apps["control_screen"].update_func = default_update
        g_apps["control_screen"].input_scroll_func = default_input_scroll
        g_apps["control_screen"].input_event_func = default_input_event
        g_apps["control_screen"].input_axis_func = default_input_axis
        g_apps["control_screen"].input_pointer_func = default_input_pointer
        print("apps loaded")
    end
    local app = g_apps[g_current_app]
    local st, err = pcall(function()
        if app ~= nil then
            app:update(screen_w, screen_h, ticks)
        else
            update = default_update
        end
    end)
    if not st then
        print(err)
        update = default_update
    end
end

function wrapped_input_event(e, a)
    local app = g_apps[g_current_app]
    app:input_event(e, a)
end
function wrapped_input_pointer(is_hovered, x, y)
    local app = g_apps[g_current_app]
    app:input_pointer(is_hovered, x, y)
end
function wrapped_input_scroll(dy)
    local app = g_apps[g_current_app]
    app:input_scroll(dy)
end