local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local Screen = game:GetObjects("rbxassetid://7563729664")[1]

Screen.Parent = CoreGui
local Window = Screen.Window
local MenuWindow = Window.MenuWindow
local ControlPanel = Window.ControlPanel

if not isfolder("videos") then
	makefolder("videos")
end

local Settings = {
	Playing = false,
	Expand = false,
	DefaultSize = Window.Size,
	Domain = "https://alexserver.herokuapp.com"
}

local function Request(videoId)
	local responce = syn.request({
		Url = Settings.Domain .. "/youtube",
		Method = "POST",
		Headers = {
			["Content-Type"] = "application/json"
		},
		Body = HttpService:JSONEncode({
			["videoId"] = videoId,
		})
	})
	if responce.StatusCode == 404 then return false end
	return responce.Body
end

local function MakeDraggable(ClickObject, Object)
	local Dragging = nil
	local DragInput = nil
	local DragStart = nil
	local StartPosition = nil

	ClickObject.InputBegan:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
			Dragging = true
			DragStart = Input.Position
			StartPosition = Object.Position

			Input.Changed:Connect(function()
				if Input.UserInputState == Enum.UserInputState.End then
					Dragging = false
				end
			end)
		end
	end)

	ClickObject.InputChanged:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then
			DragInput = Input
		end
	end)

	UserInputService.InputChanged:Connect(function(Input)
		if Input == DragInput and Dragging then
			local Delta = Input.Position - DragStart
			Object.Position = UDim2.new(StartPosition.X.Scale, StartPosition.X.Offset + Delta.X, StartPosition.Y.Scale, StartPosition.Y.Offset + Delta.Y)
		end
	end)
end

local function MakeResizeable(ClickObject,Object,MinSizeX,MinSizeY)
	local Moving = false
	local MouseOldPosition = Vector2.new(0,0)
	ClickObject.InputBegan:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
			local Mouse = UserInputService:GetMouseLocation()
			Moving = true
			MouseOldPosition = Mouse
		end
	end)
	UserInputService.InputChanged:Connect(function(Input)
		if Moving and (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch) then
			local Mouse = UserInputService:GetMouseLocation()
			local Delta = Mouse - MouseOldPosition
			Object.Size += UDim2.new(0,Delta.X,0,Delta.Y)

			if Object.Size.X.Offset <= MinSizeX then
				Object.Size = UDim2.new(0,MinSizeX,0,Object.Size.Y.Offset)
			end
			if Object.Size.Y.Offset <= MinSizeY then
				Object.Size = UDim2.new(0,Object.Size.X.Offset,0,MinSizeY)
			end
			MouseOldPosition = Mouse
		end
	end)
	ClickObject.InputEnded:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
			Moving = false
		end
	end)
end

local function ChangeTimePosition()
	local Length = Window.Video.TimeLength
	local Size = UDim2.new(math.clamp((UserInputService:GetMouseLocation().X - Window.Playback.AbsolutePosition.X) / Window.Playback.AbsoluteSize.X,0,1),0,1,0)
	local TimePosition = ((Size.X.Scale * Length) / Length) * (Length - 0) + 0
	Window.Playback.Line.Size = Size
	Window.Video.TimePosition = TimePosition
	Settings.Playing = true
	ControlPanel.Play.ImageRectOffset = Vector2.new(804,124)
	Window.Video:Play()
end

local function UpdateTime()
	local TimePosition = Window.Video.TimePosition
	Window.Playback.Time.Text = string.format("%02i:%02i:%02i", TimePosition/60^2, TimePosition/60%60, TimePosition%60)
end

local function UpdateLength()
	local TimeLength = Window.Video.TimeLength
	Window.Playback.Length.Text = string.format("%02i:%02i:%02i", TimeLength/60^2, TimeLength/60%60, TimeLength%60)
end

local function UpdatePlayback()
	local TimePosition = Window.Video.TimePosition
	local TimeLength = Window.Video.TimeLength
	local TimePercent = TimePosition / TimeLength
	Window.Playback.Line.Size = UDim2.new(TimePercent,0,1,0)
end

local function PlayVideo()
	Settings.Playing = not Settings.Playing
	if Settings.Playing then
		ControlPanel.Play.ImageRectOffset = Vector2.new(804,124)
		Window.Video:Play()
	else
		ControlPanel.Play.ImageRectOffset = Vector2.new(764,244)
		Window.Video:Pause()
	end
end

local function Expand()
	if Window.Video.Resolution.X >= 300 and Window.Video.Resolution.Y >= 300 then
		Settings.Expand = not Settings.Expand
		if Settings.Expand then
			Settings.DefaultSize = Window.Size
			ControlPanel.Expand.ImageRectOffset = Vector2.new(244, 204)
			Window.Size = UDim2.new(0,Window.Video.Resolution.X + 10,0,Window.Video.Resolution.Y + 115)
			Window.Resize.Visible = false
		else
			ControlPanel.Expand.ImageRectOffset = Vector2.new(724, 204)
			Window.Size = Settings.DefaultSize
			Window.Resize.Visible = true
		end
	end
end

local function LoadVideo(Enter)
	if Enter then
        local VideoId = MenuWindow.LinkInput.Text
        if not isfile("videos/" .. VideoId .. ".webm") then
            MenuWindow.LinkInput.Text = ""
            MenuWindow.LinkInput.PlaceholderText = "VideoID (Loading)"
            local Video = Request(VideoId)
			if Video then
				writefile("videos/" .. VideoId .. ".webm", Video)
				Window.Video.Video = getsynasset("videos/" .. VideoId .. ".webm")
				Window.Title.Text = "Videoplayer - videos/" .. VideoId .. ".webm"
				MenuWindow.LinkInput.PlaceholderText = "VideoID"

				Settings.Playing = true
				ControlPanel.Play.ImageRectOffset = Vector2.new(804,124)
				Window.Video:Play()
			else
				MenuWindow.LinkInput.PlaceholderText = "VideoID (Failed)"
				Window.Title.Text = "Videoplayer"
				Window.Video.Video = ""
			end
        else
            MenuWindow.LinkInput.Text = ""
            Window.Video.Video = getsynasset("videos/" .. VideoId .. ".webm")
			Window.Title.Text = "Videoplayer - videos/" .. VideoId .. ".webm"
            MenuWindow.LinkInput.PlaceholderText = "VideoID"

			Settings.Playing = true
			ControlPanel.Play.ImageRectOffset = Vector2.new(804,124)
			Window.Video:Play()
        end
	end
end
Window.Playback.Slider.MouseButton1Click:Connect(ChangeTimePosition)
ControlPanel.Play.MouseButton1Click:Connect(PlayVideo)
ControlPanel.Expand.MouseButton1Click:Connect(Expand)
MenuWindow.LinkInput.FocusLost:Connect(LoadVideo)
Window.Video.Loaded:Connect(UpdateLength)
Window.Video.Ended:Connect(function()
	Settings.Playing = false
	Window.Video.TimePosition = 0
	ControlPanel.Play.ImageRectOffset = Vector2.new(764,244)
end)

Window.Menu.MouseButton1Click:Connect(function()
	if MenuWindow.Visible then
		MenuWindow.Visible = false
	else
		MenuWindow.Visible = true
	end
end)

RunService.RenderStepped:Connect(function()
	UpdateTime()
	UpdatePlayback()
end)

MakeDraggable(Window.Title,Window)
MakeResizeable(Window.Resize,Window,310,400)
