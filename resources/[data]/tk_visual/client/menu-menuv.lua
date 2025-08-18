if Config.Menu == "menuv" then
    if MenuV then
        Config.mainMenu = MenuV:CreateMenu("tk_visual", "Main Menu", "centerright", 31, 255, 34, "size-150", "default", "menuv", "tk_visual_main_menu", "default")
        Config.fpsMenu = MenuV:CreateMenu("tk_visual", "FPS Booster Menu", "centerright", 31, 255, 34, "size-150", "default", "menuv", "tk_visual_fps_menu", "default")
        Config.visualMenu = MenuV:CreateMenu("tk_visual", "Visual Modifier Menu", "centerright", 31, 255, 34, "size-150", "default", "menuv", "tk_visual_visual_menu", "default")
        Config.lightsMenu = MenuV:CreateMenu("tk_visual", "Vehicle Lights Menu", "centerright", 31, 255, 34, "size-150", "default", "menuv", "tk_visual_light_menu", "default")
        Config.dayLightsMenu = MenuV:CreateMenu("tk_visual", "Vehicle Lights Menu (DAY)", "centerright", 31, 255, 34, "size-150", "default", "menuv", "tk_visual_day_light_menu", "default")
        Config.nightLightsMenu = MenuV:CreateMenu("tk_visual", "Vehicle Lights Menu (NIGHT)", "centerright", 31, 255, 34, "size-150", "default", "menuv", "tk_visual_night_light_menu", "default")

        -- FPS Booster Menu
        Config.mainMenu:AddButton({ icon = "🆙", label = "FPS Booster Menu", value = Config.fpsMenu })
        local function setUpFpsBoosterButtons(menuToSet)
            for index = 1, #Config.fpsBoosterTypes do
                menuToSet:AddButton({ icon = Config.fpsBoosterTypes[index].icon or "❇", label = Config.fpsBoosterTypes[index].name, description = Config.fpsBoosterTypes[index].description, value = "", select = function()
                    BoostFPS(index)
                end })
            end
            menuToSet:AddButton({ icon = "🔁", label = "Reset", value = "", select = function()
                BoostFPS()
            end })
        end
        do setUpFpsBoosterButtons(Config.fpsMenu) end

        -- Visual Modifier Menu
        Config.mainMenu:AddButton({ icon = "👓", label = "Visual Modifier Menu", value = Config.visualMenu })
        local function setUpVisualTimecycleMenuButtons(menuToSet)
            for index = 1, #Config.visualTimecycles do
                menuToSet:AddButton({ icon = Config.visualTimecycles[index].icon or "❇", label = Config.visualTimecycles[index].name, value = "", select = function()
                    ModifyVisuals(index)
                end })
            end
            menuToSet:AddButton({ icon = "🔁", label = "Reset", value = "", select = function()
                ModifyVisuals()
            end })
        end
        do setUpVisualTimecycleMenuButtons(Config.visualMenu) end
        
        -- Vehicle Lights Menu
        Config.mainMenu:AddButton({ icon = "💡", label = "Vehicle Lights Menu", value = Config.lightsMenu })
        Config.lightsMenu:On("open", function(menu)
            menu:ClearItems()
            Config.multiplier = 1
            Config.lightsMenu:AddButton({ icon = "💡", label = "Vehicle Lights Menu (DAY)", value = Config.dayLightsMenu })
            Config.lightsMenu:AddButton({ icon = "💡", label = "Vehicle Lights Menu (NIGHT)", value = Config.nightLightsMenu })
            Config.multiplierSlider = Config.lightsMenu:AddSlider({ icon = "Ⓜ", label = "Multiplier", value = Config.multiplier, values = {
                { label = "1x", value = 1 },
                { label = "10x", value = 10 },
                { label = "100x", value = 100 },
                { label = "1000x", value = 1000 }
            }})
            Config.multiplierSlider:On("change", function(item, newValue, _) Config.multiplier = item.Values[newValue].Value end)
            Config.lightsMenu:AddButton({ icon = "💾", label = "Apply Saved Lights Settings", value = "", select = function()
                ApplySavedLightConfigurations()
            end })
            Config.lightsMenu:AddButton({ icon = "💾", label = "Save Lights Settings", value = "", select = function()
                SaveLightConfigurations()
            end })
        end)
        local function setUpLightMenuButtons(menuToSet, timeToSet)
            for name, v in pairs(Config.vehicleLightsSetting) do
                for time, light in pairs(v) do
                    if time == timeToSet then
                        light.handler = menuToSet:AddRange({ icon = "💡", label = light.name, min = light.min, max = light.max / Config.multiplier, value = (light.modifiedValue or light.defaultValue) / Config.multiplier, saveOnUpdate = false })
                        light.handler:On("change", function(_, newValue, _)
                            light.modifiedValue = newValue * Config.multiplier
                            SetVisualSettingFloat(("car.%s.%s.emissive.on"):format(name, time), light.modifiedValue + 0.0)
                        end)
                    end
                end
            end
        end
        Config.dayLightsMenu:On("open", function(menu)
            menu:ClearItems()
            setUpLightMenuButtons(Config.dayLightsMenu, "day")
        end)
        Config.nightLightsMenu:On("open", function(menu)
            menu:ClearItems()
            setUpLightMenuButtons(Config.nightLightsMenu, "night")
        end)
    else
        error("Error: MenuV resource is not properly loaded inside tk_visual!")
    end
end