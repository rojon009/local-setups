-- Location: ~/.hammerspoon.init.lua
-- install: brew install --cask hammerspoon

local hyper = {"cmd", "alt", "ctrl", "shift"}

-- Enable Spotlight support for app name searches (allows finding apps by alternate names)
hs.application.enableSpotlightForNameSearches(true)

-- Function to toggle app or cycle through windows
function toggleAppOrCycleWindows(appName)
    local app = hs.application.get(appName)
    
    if not app then
        -- App is not running, launch it
        hs.application.launchOrFocus(appName)
    else
        -- App is running
        local focusedApp = hs.application.frontmostApplication()
        
        if focusedApp:bundleID() == app:bundleID() then
            -- App is already focused, cycle through windows
            local windows = app:allWindows()
            local visibleWindows = {}
            
            -- Filter to only visible windows
            for _, win in ipairs(windows) do
                if win:isStandard() and win:isVisible() then
                    table.insert(visibleWindows, win)
                end
            end
            
            if #visibleWindows > 1 then
                -- Find the current frontmost window
                local currentWindow = app:focusedWindow()
                local currentIndex = 1
                
                for i, win in ipairs(visibleWindows) do
                    if win == currentWindow then
                        currentIndex = i
                        break
                    end
                end
                
                -- Cycle to next window
                local nextIndex = (currentIndex % #visibleWindows) + 1
                visibleWindows[nextIndex]:focus()
            end
        else
            -- App is running but not focused, focus it
            app:activate()
        end
    end
end

-- Key bindings
hs.hotkey.bind(hyper, "c", function()
    toggleAppOrCycleWindows("Google Chrome")
end)

hs.hotkey.bind(hyper, "s", function()
    toggleAppOrCycleWindows("Slack")
end)

hs.hotkey.bind(hyper, "t", function()
    toggleAppOrCycleWindows("Warp")
end)

hs.hotkey.bind(hyper, "f", function()
    toggleAppOrCycleWindows("Firefox")
end)

hs.hotkey.bind(hyper, "r", function()
    toggleAppOrCycleWindows("Cursor")
end)

hs.hotkey.bind(hyper, "w", function()
    toggleAppOrCycleWindows("WhatsApp")
end)

hs.hotkey.bind(hyper, "d", function()
    toggleAppOrCycleWindows("DBeaver")
end)
