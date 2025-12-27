-- ============================================================================
-- !Koality-of-Life: Theme Editor Module
-- ============================================================================
-- Interactive UI for creating and editing themes
-- ============================================================================

local KOL = KoalityOfLife
local UIFactory = KOL.UIFactory

-- ============================================================================
-- Theme Editor Module
-- ============================================================================

KOL.ThemeEditor = {}
local ThemeEditor = KOL.ThemeEditor

-- Editor state
local editorFrame = nil
local currentTheme = nil
local colorPickers = {}

-- ============================================================================
-- Color Picker Helper Functions
-- ============================================================================

local function CreateColorPicker(parent, colorPath, initialColor, onChange)
    local picker = CreateFrame("Frame", nil, parent)
    picker:SetWidth(200)
    picker:SetHeight(30)
    
    -- Color preview box
    local preview = CreateFrame("Frame", nil, picker)
    preview:SetWidth(30)
    preview:SetHeight(20)
    preview:SetPoint("LEFT", 0, 0)
    preview:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    preview:SetBackdropColor(initialColor.r, initialColor.g, initialColor.b, initialColor.a)
    preview:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    -- Color label
    local label = picker:CreateFontString(nil, "OVERLAY")
    label:SetPoint("LEFT", preview, "RIGHT", 8, 0)
    label:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    label:SetText(colorPath)
    label:SetTextColor(1, 1, 1, 1)
    
    -- RGB sliders
    local rSlider = CreateFrame("Slider", nil, picker, "OptionsSliderTemplate")
    rSlider:SetWidth(100)
    rSlider:SetHeight(15)
    rSlider:SetPoint("LEFT", label, "RIGHT", 10, 0)
    rSlider:SetMinMaxValues(0, 1)
    rSlider:SetValue(initialColor.r)
    rSlider:SetValueStep(0.01)
    
    local gSlider = CreateFrame("Slider", nil, picker, "OptionsSliderTemplate")
    gSlider:SetWidth(100)
    gSlider:SetHeight(15)
    gSlider:SetPoint("TOP", rSlider, "BOTTOM", 0, -2)
    gSlider:SetMinMaxValues(0, 1)
    gSlider:SetValue(initialColor.g)
    gSlider:SetValueStep(0.01)
    
    local bSlider = CreateFrame("Slider", nil, picker, "OptionsSliderTemplate")
    bSlider:SetWidth(100)
    bSlider:SetHeight(15)
    bSlider:SetPoint("TOP", gSlider, "BOTTOM", 0, -2)
    bSlider:SetMinMaxValues(0, 1)
    bSlider:SetValue(initialColor.b)
    bSlider:SetValueStep(0.01)
    
    -- Update function
    local function UpdateColor()
        local r = rSlider:GetValue()
        local g = gSlider:GetValue()
        local b = bSlider:GetValue()
        local a = initialColor.a or 1
        
        preview:SetBackdropColor(r, g, b, a)
        
        if onChange then
            onChange(colorPath, {r = r, g = g, b = b, a = a})
        end
    end
    
    rSlider:SetScript("OnValueChanged", UpdateColor)
    gSlider:SetScript("OnValueChanged", UpdateColor)
    bSlider:SetScript("OnValueChanged", UpdateColor)
    
    -- Store references
    picker.preview = preview
    picker.rSlider = rSlider
    picker.gSlider = gSlider
    picker.bSlider = bSlider
    picker.colorPath = colorPath
    
    return picker
end

-- ============================================================================
-- Theme Editor UI Creation
-- ============================================================================

local function CreateThemeEditorFrame()
    if editorFrame then
        return editorFrame
    end
    
    -- Main frame using UI Factory
    local frame = UIFactory:CreateStyledFrame(UIParent, "KOL_ThemeEditor", 800, 600, {
        movable = true,
        closable = true
    })
    frame:SetPoint("CENTER")
    
    -- Title bar
    local titleBar, title, closeButton = UIFactory:CreateTitleBar(frame, 24, "Theme Editor", {
        showCloseButton = true
    })
    
    -- Content area
    local content = UIFactory:CreateContentArea(frame, {top = 30, bottom = 50, left = 10, right = 10})
    
    -- Theme selector
    local themeSelector = CreateFrame("Frame", nil, content)
    themeSelector:SetHeight(40)
    themeSelector:SetPoint("TOPLEFT", 10, -10)
    themeSelector:SetPoint("TOPRIGHT", -10, -10)
    
    local selectorLabel = themeSelector:CreateFontString(nil, "OVERLAY")
    selectorLabel:SetPoint("LEFT", 0, 0)
    selectorLabel:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    selectorLabel:SetText("Theme:")
    selectorLabel:SetTextColor(1, 1, 1, 1)
    
    -- Theme dropdown (simplified - using buttons for now)
    local themeDropdown = CreateFrame("Frame", nil, themeSelector)
    themeDropdown:SetWidth(200)
    themeDropdown:SetHeight(25)
    themeDropdown:SetPoint("LEFT", selectorLabel, "RIGHT", 10, 0)
    themeDropdown:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    themeDropdown:SetBackdropColor(0.2, 0.2, 0.2, 1)
    themeDropdown:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    local dropdownText = themeDropdown:CreateFontString(nil, "OVERLAY")
    dropdownText:SetPoint("CENTER", 0, 0)
    dropdownText:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    dropdownText:SetText("Select Theme")
    dropdownText:SetTextColor(1, 1, 1, 1)
    
    -- Color editing area
    local colorArea = CreateFrame("ScrollFrame", nil, content, "UIPanelScrollFrameTemplate")
    colorArea:SetPoint("TOPLEFT", 10, -60)
    colorArea:SetPoint("BOTTOMRIGHT", -10, 10)
    
    local colorChild = CreateFrame("Frame", nil, colorArea)
    colorChild:SetWidth(colorArea:GetWidth() - 20)
    colorChild:SetHeight(1)
    colorArea:SetScrollChild(colorChild)
    
    -- Buttons
    local saveButton = UIFactory:CreateStyledButtonEnhanced(frame, 100, 25, "Save Theme", {
        onClick = function()
            ThemeEditor:SaveCurrentTheme()
        end
    })
    saveButton:SetPoint("BOTTOMLEFT", 10, 10)
    
    local newButton = UIFactory:CreateStyledButtonEnhanced(frame, 100, 25, "New Theme", {
        onClick = function()
            ThemeEditor:CreateNewTheme()
        end
    })
    newButton:SetPoint("LEFT", saveButton, "RIGHT", 5, 0)
    
    local applyButton = UIFactory:CreateStyledButtonEnhanced(frame, 100, 25, "Apply", {
        onClick = function()
            ThemeEditor:ApplyCurrentTheme()
        end
    })
    applyButton:SetPoint("LEFT", newButton, "RIGHT", 5, 0)
    
    -- Store references
    frame.content = content
    frame.colorArea = colorArea
    frame.colorChild = colorChild
    frame.themeDropdown = themeDropdown
    frame.dropdownText = dropdownText
    
    editorFrame = frame
    return frame
end

-- ============================================================================
-- Theme Editor Functions
-- ============================================================================

function ThemeEditor:Show()
    local frame = CreateThemeEditorFrame()
    frame:Show()
    self:RefreshThemeList()
end

function ThemeEditor:Hide()
    if editorFrame then
        editorFrame:Hide()
    end
end

function ThemeEditor:Toggle()
    if editorFrame and editorFrame:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end

function ThemeEditor:RefreshThemeList()
    if not editorFrame then return end
    
    -- Clear existing color pickers
    for _, picker in pairs(colorPickers) do
        if picker and picker.SetParent then
            picker:SetParent(nil)
            picker:Hide()
        end
    end
    colorPickers = {}
    
    -- Get current theme
    currentTheme = KOL.Themes:GetTheme()
    if not currentTheme then
        KOL:PrintTag("No theme selected")
        return
    end
    
    -- Update dropdown text
    if editorFrame.dropdownText then
        editorFrame.dropdownText:SetText(currentTheme.name or "Unknown Theme")
    end
    
    -- Create color pickers for all theme colors
    local yOffset = 0
    local colorChild = editorFrame.colorChild
    
    if currentTheme.colors then
        for colorPath, colorValue in pairs(currentTheme.colors) do
            local colorPicker = CreateColorPicker(colorChild, colorPath, colorValue, function(path, newColor)
                self:UpdateThemeColor(path, newColor)
            end)
            
            colorPicker:SetPoint("TOPLEFT", 10, -yOffset)
            yOffset = yOffset + 80
            
            table.insert(colorPickers, colorPicker)
        end
    end
    
    -- Update scroll child height
    colorChild:SetHeight(math.max(yOffset + 20, editorFrame.colorArea:GetHeight()))
end

function ThemeEditor:UpdateThemeColor(colorPath, newColor)
    if not currentTheme or not currentTheme.colors then return end
    
    currentTheme.colors[colorPath] = newColor
    KOL:DebugPrint("Updated theme color: " .. colorPath, 3)
end

function ThemeEditor:SaveCurrentTheme()
    if not currentTheme then
        KOL:PrintTag("No theme to save")
        return
    end
    
    -- Save to database
    if KOL.Themes.SaveTheme then
        KOL.Themes:SaveTheme(currentTheme.name, currentTheme.colors)
        KOL:PrintTag("Theme saved: " .. (currentTheme.name or "Unknown"))
    else
        KOL:PrintTag("Theme saving not available")
    end
end

function ThemeEditor:CreateNewTheme()
    -- Simple implementation - create a copy of current theme
    local newThemeName = "Custom Theme " .. date("%H%M%S")
    local baseTheme = KOL.Themes:GetTheme()
    
    if baseTheme and baseTheme.colors then
        -- Create new theme with copied colors
        local newColors = {}
        for path, color in pairs(baseTheme.colors) do
            newColors[path] = {
                r = color.r,
                g = color.g,
                b = color.b,
                a = color.a or 1
            }
        end
        
        KOL.Themes:RegisterTheme(newThemeName, newColors)
        KOL.Themes:SetTheme(newThemeName)
        
        KOL:PrintTag("Created new theme: " .. newThemeName)
        self:RefreshThemeList()
    else
        KOL:PrintTag("Failed to create new theme")
    end
end

function ThemeEditor:ApplyCurrentTheme()
    if not currentTheme then
        KOL:PrintTag("No theme to apply")
        return
    end
    
    -- This would trigger a UI refresh across all components
    KOL:PrintTag("Theme applied: " .. (currentTheme.name or "Unknown"))
    
    -- TODO: Implement UI refresh system
    -- For now, just reload the UI to see changes
    ReloadUI()
end

-- ============================================================================
-- Slash Command Integration
-- ============================================================================

KOL:RegisterSlashCommand("themeeditor", function()
    ThemeEditor:Toggle()
end, "Open the theme editor interface")

KOL:RegisterSlashCommand("themes", function()
    ThemeEditor:Show()
end, "Open the theme editor interface")

-- ============================================================================
-- Module Loaded
-- ============================================================================

KOL:DebugPrint("Theme Editor module loaded", 1)