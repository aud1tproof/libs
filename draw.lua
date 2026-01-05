local coreGui = game:GetService('CoreGui')
-- objects
local camera = workspace.CurrentCamera
local drawingUI = Instance.new('ScreenGui')
drawingUI.Name = 'Drawing'
drawingUI.IgnoreGuiInset = true
drawingUI.DisplayOrder = 0x7fffffff
drawingUI.Parent = coreGui

-- watermark
local watermark = Instance.new('TextLabel')
watermark.Name = 'Watermark'
watermark.BackgroundTransparency = 1
watermark.TextColor3 = Color3.new(1, 1, 1)
watermark.TextStrokeTransparency = 0.5
watermark.TextStrokeColor3 = Color3.new(0, 0, 0)
watermark.Text = 'Version: 0.28C1'
watermark.Font = Enum.Font.SourceSans
watermark.TextSize = 14
watermark.AnchorPoint = Vector2.new(0, 1)
watermark.Position = UDim2.new(0, 10, 1, -10)
watermark.ZIndex = 1000
watermark.Parent = drawingUI

-- variables
local drawingIndex = 0
local baseDrawingObj = setmetatable({
    Visible = true,
    ZIndex = 0,
    Transparency = 1,
    Color = Color3.new(),
    Remove = function(self)
        setmetatable(self, nil)
    end,
    Destroy = function(self)
        setmetatable(self, nil)
    end,
}, {
    __add = function(t1, t2)
        local result = table.clone(t1)
        for index, value in t2 do
            result[index] = value
        end
        return result
    end,
})
local drawingFontsEnum = {
    [0] = Font.fromEnum(Enum.Font.Roboto),
    [1] = Font.fromEnum(Enum.Font.Legacy),
    [2] = Font.fromEnum(Enum.Font.SourceSans),
    [3] = Font.fromEnum(Enum.Font.RobotoMono),
}

-- function
local function getFontFromIndex(fontIndex: number): Font
    return drawingFontsEnum[fontIndex] or drawingFontsEnum[0] -- Fallback to default
end

local function convertTransparency(transparency: number): number
    return math.clamp(1 - transparency, 0, 1)
end

-- main
local DrawingLib = {}
DrawingLib.Fonts = {
    ['UI'] = 0,
    ['System'] = 1,
    ['Plex'] = 2,
    ['Monospace'] = 3,
}

function DrawingLib.new(drawingType)
    drawingIndex += 1
    if drawingType == 'Line' then
        local lineObj = (
            {
                From = Vector2.zero,
                To = Vector2.zero,
                Thickness = 1,
            } + baseDrawingObj
        )
        local lineFrame = Instance.new('Frame')
        lineFrame.Name = tostring(drawingIndex) -- Use string for name to avoid potential issues
        lineFrame.AnchorPoint = Vector2.new(0.5, 0.5)
        lineFrame.BorderSizePixel = 0
        lineFrame.BackgroundColor3 = lineObj.Color
        lineFrame.Visible = lineObj.Visible
        lineFrame.ZIndex = lineObj.ZIndex
        lineFrame.BackgroundTransparency =
            convertTransparency(lineObj.Transparency)
        lineFrame.Size = UDim2.new()
        lineFrame.Parent = drawingUI
        return setmetatable({}, {
            __newindex = function(_, index, value)
                if lineObj[index] == nil then
                    return
                end
                if index == 'From' or index == 'To' then
                    local from = (index == 'From' and value or lineObj.From)
                    local to = (index == 'To' and value or lineObj.To)
                    local direction = to - from
                    local center = (to + from) * 0.5
                    local distance = direction.Magnitude
                    local theta = math.deg(math.atan2(direction.Y, direction.X))
                    lineFrame.Position = UDim2.fromOffset(center.X, center.Y)
                    lineFrame.Rotation = theta
                    lineFrame.Size =
                        UDim2.fromOffset(distance, lineObj.Thickness)
                elseif index == 'Thickness' then
                    local distance = (lineObj.To - lineObj.From).Magnitude
                    lineFrame.Size = UDim2.fromOffset(distance, value)
                elseif index == 'Visible' then
                    lineFrame.Visible = value
                elseif index == 'ZIndex' then
                    lineFrame.ZIndex = value
                elseif index == 'Transparency' then
                    lineFrame.BackgroundTransparency =
                        convertTransparency(value)
                elseif index == 'Color' then
                    lineFrame.BackgroundColor3 = value
                end
                lineObj[index] = value
            end,
            __index = function(self, index)
                if index == 'Remove' or index == 'Destroy' then
                    return function()
                        lineFrame:Destroy()
                        lineObj.Remove(self)
                    end
                end
                return lineObj[index]
            end,
            __tostring = function()
                return 'Drawing'
            end,
        })
    elseif drawingType == 'Text' then
        local textObj = (
            {
                Text = '',
                Font = DrawingLib.Fonts.UI,
                Size = 0,
                Position = Vector2.zero,
                Center = false,
                Outline = false,
                OutlineColor = Color3.new(),
            } + baseDrawingObj
        )
        local textLabel = Instance.new('TextLabel')
        local uiStroke = Instance.new('UIStroke')
        textLabel.Name = tostring(drawingIndex)
        textLabel.AnchorPoint = Vector2.new(0.5, 0.5)
        textLabel.BorderSizePixel = 0
        textLabel.BackgroundTransparency = 1
        textLabel.Visible = textObj.Visible
        textLabel.TextColor3 = textObj.Color
        textLabel.TextTransparency = convertTransparency(textObj.Transparency)
        textLabel.ZIndex = textObj.ZIndex
        textLabel.FontFace = getFontFromIndex(textObj.Font)
        textLabel.TextSize = textObj.Size
        uiStroke.Thickness = 1
        uiStroke.Enabled = textObj.Outline
        uiStroke.Color = textObj.Color
        textLabel.Parent = drawingUI
        uiStroke.Parent = textLabel
        local boundsConnection = textLabel
            :GetPropertyChangedSignal('TextBounds')
            :Connect(function()
                local textBounds = textLabel.TextBounds
                local offset = textBounds * 0.5
                textLabel.Size = UDim2.fromOffset(textBounds.X, textBounds.Y)
                textLabel.Position = UDim2.fromOffset(
                    textObj.Position.X
                        + (textObj.Center == false and offset.X or 0),
                    textObj.Position.Y + offset.Y
                )
            end)
        return setmetatable({}, {
            __newindex = function(_, index, value)
                if textObj[index] == nil then
                    return
                end
                if index == 'Text' then
                    textLabel.Text = value
                elseif index == 'Font' then
                    textLabel.FontFace =
                        getFontFromIndex(math.clamp(value, 0, 3))
                elseif index == 'Size' then
                    textLabel.TextSize = value
                elseif index == 'Position' then
                    local offset = textLabel.TextBounds * 0.5
                    textLabel.Position = UDim2.fromOffset(
                        value.X + (textObj.Center == false and offset.X or 0),
                        value.Y + offset.Y
                    )
                elseif index == 'Center' then
                    local offset = textLabel.TextBounds * 0.5
                    textLabel.Position = UDim2.fromOffset(
                        textObj.Position.X + (value == false and offset.X or 0),
                        textObj.Position.Y + offset.Y
                    )
                elseif index == 'Outline' then
                    uiStroke.Enabled = value
                elseif index == 'OutlineColor' then
                    uiStroke.Color = value
                elseif index == 'Visible' then
                    textLabel.Visible = value
                elseif index == 'ZIndex' then
                    textLabel.ZIndex = value
                elseif index == 'Transparency' then
                    local transparency = convertTransparency(value)
                    textLabel.TextTransparency = transparency
                    uiStroke.Transparency = transparency
                elseif index == 'Color' then
                    textLabel.TextColor3 = value
                end
                textObj[index] = value
            end,
            __index = function(self, index)
                if index == 'Remove' or index == 'Destroy' then
                    return function()
                        boundsConnection:Disconnect()
                        textLabel:Destroy()
                        textObj.Remove(self)
                    end
                elseif index == 'TextBounds' then
                    return textLabel.TextBounds
                end
                return textObj[index]
            end,
            __tostring = function()
                return 'Drawing'
            end,
        })
    elseif drawingType == 'Circle' then
        local circleObj = (
            {
                Radius = 150,
                Position = Vector2.zero,
                Thickness = 0.7,
                Filled = false,
            } + baseDrawingObj
        )
        local circleFrame = Instance.new('Frame')
        local uiCorner = Instance.new('UICorner')
        local uiStroke = Instance.new('UIStroke')
        circleFrame.Name = tostring(drawingIndex)
        circleFrame.AnchorPoint = Vector2.new(0.5, 0.5)
        circleFrame.BorderSizePixel = 0
        circleFrame.BackgroundTransparency = (
            circleObj.Filled and convertTransparency(circleObj.Transparency) or 1
        )
        circleFrame.BackgroundColor3 = circleObj.Color
        circleFrame.Visible = circleObj.Visible
        circleFrame.ZIndex = circleObj.ZIndex
        uiCorner.CornerRadius = UDim.new(1, 0)
        circleFrame.Size =
            UDim2.fromOffset(circleObj.Radius * 2, circleObj.Radius * 2)
        uiStroke.Thickness = circleObj.Thickness
        uiStroke.Enabled = not circleObj.Filled
        uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        circleFrame.Parent = drawingUI
        uiCorner.Parent = circleFrame
        uiStroke.Parent = circleFrame
        return setmetatable({}, {
            __newindex = function(_, index, value)
                if circleObj[index] == nil then
                    return
                end
                if index == 'Radius' then
                    local diameter = value * 2
                    circleFrame.Size = UDim2.fromOffset(diameter, diameter)
                elseif index == 'Position' then
                    circleFrame.Position = UDim2.fromOffset(value.X, value.Y)
                elseif index == 'Thickness' then
                    uiStroke.Thickness = math.clamp(value, 0.6, 0x7fffffff)
                elseif index == 'Filled' then
                    circleFrame.BackgroundTransparency = (
                        value
                            and convertTransparency(circleObj.Transparency)
                        or 1
                    )
                    uiStroke.Enabled = not value
                elseif index == 'Visible' then
                    circleFrame.Visible = value
                elseif index == 'ZIndex' then
                    circleFrame.ZIndex = value
                elseif index == 'Transparency' then
                    local transparency = convertTransparency(value)
                    circleFrame.BackgroundTransparency = (
                        circleObj.Filled and transparency or 1
                    )
                    uiStroke.Transparency = transparency
                elseif index == 'Color' then
                    circleFrame.BackgroundColor3 = value
                    uiStroke.Color = value
                end
                circleObj[index] = value
            end,
            __index = function(self, index)
                if index == 'Remove' or index == 'Destroy' then
                    return function()
                        circleFrame:Destroy()
                        circleObj.Remove(self)
                    end
                end
                return circleObj[index]
            end,
            __tostring = function()
                return 'Drawing'
            end,
        })
    elseif drawingType == 'Square' then
        local squareObj = (
            {
                Size = Vector2.zero,
                Position = Vector2.zero,
                Thickness = 0.7,
                Filled = false,
            } + baseDrawingObj
        )
        local squareFrame = Instance.new('Frame')
        local uiStroke = Instance.new('UIStroke')
        squareFrame.Name = tostring(drawingIndex)
        squareFrame.BorderSizePixel = 0
        squareFrame.BackgroundTransparency = (
            squareObj.Filled and convertTransparency(squareObj.Transparency) or 1
        )
        squareFrame.ZIndex = squareObj.ZIndex
        squareFrame.BackgroundColor3 = squareObj.Color
        squareFrame.Visible = squareObj.Visible
        uiStroke.Thickness = squareObj.Thickness
        uiStroke.Enabled = not squareObj.Filled
        uiStroke.LineJoinMode = Enum.LineJoinMode.Miter
        squareFrame.Parent = drawingUI
        uiStroke.Parent = squareFrame
        return setmetatable({}, {
            __newindex = function(_, index, value)
                if squareObj[index] == nil then
                    return
                end
                if index == 'Size' then
                    squareFrame.Size = UDim2.fromOffset(value.X, value.Y)
                elseif index == 'Position' then
                    squareFrame.Position = UDim2.fromOffset(value.X, value.Y)
                elseif index == 'Thickness' then
                    uiStroke.Thickness = math.clamp(value, 0.6, 0x7fffffff)
                elseif index == 'Filled' then
                    squareFrame.BackgroundTransparency = (
                        value
                            and convertTransparency(squareObj.Transparency)
                        or 1
                    )
                    uiStroke.Enabled = not value
                elseif index == 'Visible' then
                    squareFrame.Visible = value
                elseif index == 'ZIndex' then
                    squareFrame.ZIndex = value
                elseif index == 'Transparency' then
                    local transparency = convertTransparency(value)
                    squareFrame.BackgroundTransparency = (
                        squareObj.Filled and transparency or 1
                    )
                    uiStroke.Transparency = transparency
                elseif index == 'Color' then
                    uiStroke.Color = value
                    squareFrame.BackgroundColor3 = value
                end
                squareObj[index] = value
            end,
            __index = function(self, index)
                if index == 'Remove' or index == 'Destroy' then
                    return function()
                        squareFrame:Destroy()
                        squareObj.Remove(self)
                    end
                end
                return squareObj[index]
            end,
            __tostring = function()
                return 'Drawing'
            end,
        })
    elseif drawingType == 'Image' then
        local imageObj = (
            {
                Data = '',
                DataURL = 'rbxassetid://0',
                Size = Vector2.zero,
                Position = Vector2.zero,
            } + baseDrawingObj
        )
        local imageFrame = Instance.new('ImageLabel')
        imageFrame.Name = tostring(drawingIndex)
        imageFrame.BorderSizePixel = 0
        imageFrame.ScaleType = Enum.ScaleType.Stretch
        imageFrame.BackgroundTransparency = 1
        imageFrame.Visible = imageObj.Visible
        imageFrame.ZIndex = imageObj.ZIndex
        imageFrame.ImageTransparency =
            convertTransparency(imageObj.Transparency)
        imageFrame.ImageColor3 = imageObj.Color
        imageFrame.Parent = drawingUI
        return setmetatable({}, {
            __newindex = function(_, index, value)
                if imageObj[index] == nil then
                    return
                end
                if index == 'DataURL' then
                    imageFrame.Image = value
                elseif index == 'Size' then
                    imageFrame.Size = UDim2.fromOffset(value.X, value.Y)
                elseif index == 'Position' then
                    imageFrame.Position = UDim2.fromOffset(value.X, value.Y)
                elseif index == 'Visible' then
                    imageFrame.Visible = value
                elseif index == 'ZIndex' then
                    imageFrame.ZIndex = value
                elseif index == 'Transparency' then
                    imageFrame.ImageTransparency = convertTransparency(value)
                elseif index == 'Color' then
                    imageFrame.ImageColor3 = value
                end
                imageObj[index] = value
            end,
            __index = function(self, index)
                if index == 'Remove' or index == 'Destroy' then
                    return function()
                        imageFrame:Destroy()
                        imageObj.Remove(self)
                    end
                elseif index == 'Data' then
                    return nil -- TODO: add error if needed
                end
                return imageObj[index]
            end,
            __tostring = function()
                return 'Drawing'
            end,
        })
    elseif drawingType == 'Quad' then
        local quadObj = (
            {
                Thickness = 1,
                PointA = Vector2.zero,
                PointB = Vector2.zero,
                PointC = Vector2.zero,
                PointD = Vector2.zero,
                Filled = false,
            } + baseDrawingObj
        )
        local pointA = DrawingLib.new('Line')
        local pointB = DrawingLib.new('Line')
        local pointC = DrawingLib.new('Line')
        local pointD = DrawingLib.new('Line')
        return setmetatable({}, {
            __newindex = function(_, index, value)
                if index == 'Thickness' then
                    pointA.Thickness = value
                    pointB.Thickness = value
                    pointC.Thickness = value
                    pointD.Thickness = value
                elseif index == 'PointA' then
                    pointA.From = value
                    pointB.To = value
                elseif index == 'PointB' then
                    pointB.From = value
                    pointC.To = value
                elseif index == 'PointC' then
                    pointC.From = value
                    pointD.To = value
                elseif index == 'PointD' then
                    pointD.From = value
                    pointA.To = value
                elseif index == 'Visible' then
                    pointA.Visible = value
                    pointB.Visible = value
                    pointC.Visible = value
                    pointD.Visible = value
                elseif index == 'Color' then
                    pointA.Color = value
                    pointB.Color = value
                    pointC.Color = value
                    pointD.Color = value
                elseif index == 'ZIndex' then
                    pointA.ZIndex = value
                    pointB.ZIndex = value
                    pointC.ZIndex = value
                    pointD.ZIndex = value
                elseif index == 'Transparency' then
                    pointA.Transparency = value
                    pointB.Transparency = value
                    pointC.Transparency = value
                    pointD.Transparency = value
                end -- Filled not implemented, as per original
                quadObj[index] = value
            end,
            __index = function(self, index)
                if index == 'Remove' or index == 'Destroy' then
                    return function()
                        pointA:Remove()
                        pointB:Remove()
                        pointC:Remove()
                        pointD:Remove()
                        quadObj.Remove(self)
                    end
                end
                return quadObj[index]
            end,
            __tostring = function()
                return 'Drawing'
            end,
        })
    elseif drawingType == 'Triangle' then
        local triangleObj = (
            {
                PointA = Vector2.zero,
                PointB = Vector2.zero,
                PointC = Vector2.zero,
                Thickness = 1,
                Filled = false,
            } + baseDrawingObj
        )
        local lineA = DrawingLib.new('Line')
        local lineB = DrawingLib.new('Line')
        local lineC = DrawingLib.new('Line')
        return setmetatable({}, {
            __newindex = function(_, index, value)
                if index == 'PointA' then
                    lineA.From = value
                    lineB.To = value
                elseif index == 'PointB' then
                    lineB.From = value
                    lineC.To = value
                elseif index == 'PointC' then
                    lineC.From = value
                    lineA.To = value
                elseif
                    index == 'Thickness'
                    or index == 'Visible'
                    or index == 'Color'
                    or index == 'ZIndex'
                    or index == 'Transparency'
                then
                    lineA[index] = value
                    lineB[index] = value
                    lineC[index] = value
                end -- Filled not implemented
                triangleObj[index] = value
            end,
            __index = function(self, index)
                if index == 'Remove' or index == 'Destroy' then
                    return function()
                        lineA:Remove()
                        lineB:Remove()
                        lineC:Remove()
                        triangleObj.Remove(self)
                    end
                end
                return triangleObj[index]
            end,
            __tostring = function()
                return 'Drawing'
            end,
        })
    end
end
getgenv().drawing = DrawingLib
