local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local Screen = game:GetObjects("rbxassetid://7563729664")[1]
Screen.Parent = CoreGui
local Window = Screen.Window
local ControlPanel = Window.ControlPanel

if not isfolder("videos") then
	makefolder("videos")
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

local Settings = {
	Playing = false,
	Sliding = false,
	Expand = false,
	DefaultSize = Window.Size,
	VideoHost = "https://alexserver.herokuapp.com/download"
}

local function UpdateLength()
	local Length = Window.Video.TimeLength
	Window.Playback.Length.Text = string.format("%02i:%02i:%02i", Length/60^2, Length/60%60, Length%60)
end

local function PlayVideo()
	Settings.Playing = not Settings.Playing
	if Settings.Playing then
		ControlPanel.Play.ImageRectOffset = Vector2.new(804,124)
		Window.Video:Play()
		UpdateLength()
	else
		ControlPanel.Play.ImageRectOffset = Vector2.new(764,244)
		Window.Video:Pause()
	end
end

local function Expand()
	Settings.Expand = not Settings.Expand
	if Settings.Expand then
		Settings.DefaultSize = Window.Size
		ControlPanel.Expand.ImageRectOffset = Vector2.new(244, 204)
		Window.Size = UDim2.new(0,Window.Video.Resolution.X + 10,0,Window.Video.Resolution.Y + 100)
		Window.Resize.Visible = false
	else
		ControlPanel.Expand.ImageRectOffset = Vector2.new(724, 204)
		Window.Size = Settings.DefaultSize
		Window.Resize.Visible = true
	end
end

local function DownloadWEBM(Url)
	local responce = syn.request({
		Url = Settings.VideoHost,
		Method = "POST",
		Body = "link=" .. Url
	})
	if responce.StatusCode == 404 then return false end
	return responce.Body
end

local function LoadVideo(Enter)
	if Enter then
        local Link = ControlPanel.LinkInput.Text
        if not isfile("videos/" .. Link .. ".webm") then
            Window.Title.Text = "Videoplayer - videos/" .. Link .. ".webm"
            ControlPanel.LinkInput.Text = ""
            ControlPanel.LinkInput.PlaceholderText = "VideoID (Loading)"
            local Video = DownloadWEBM(Link)
			if Video then
				writefile("videos/" .. Link .. ".webm", Video)
				Window.Video.Video = getsynasset("videos/" .. Link .. ".webm")
				ControlPanel.LinkInput.PlaceholderText = "VideoID"
				PlayVideo()
			else
				ControlPanel.LinkInput.PlaceholderText = "VideoID (Failed)"
			end
        else
            Window.Title.Text = "Videoplayer - videos/" .. Link .. ".webm"
            ControlPanel.LinkInput.Text = ""
            Window.Video.Video = getsynasset("videos/" .. Link .. ".webm")
            ControlPanel.LinkInput.PlaceholderText = "VideoID"
			PlayVideo()
        end
	end
end

local function Slide(Input)
	local Size = UDim2.new(math.clamp((Input.Position.X - Window.Playback.AbsolutePosition.X) / Window.Playback.AbsoluteSize.X,0,1),0,1,0)
	Window.Playback.Line.Size = Size
	local TimePosition = ((Size.X.Scale * Window.Video.TimeLength) / Window.Video.TimeLength) * (Window.Video.TimeLength - 0) + 0
	Window.Video.TimePosition = TimePosition
end

local function UpdateTime()
	local Time = Window.Video.TimePosition
	Window.Playback.Time.Text = string.format("%02i:%02i:%02i", Time/60^2, Time/60%60, Time%60)
end
local function UpdatePlayback()
	local TimePercent = Window.Video.TimePosition / Window.Video.TimeLength
	Window.Playback.Line.Size = UDim2.new(TimePercent,0,1,0)
end

ControlPanel.Play.MouseButton1Click:Connect(PlayVideo)
ControlPanel.Expand.MouseButton1Click:Connect(Expand)
ControlPanel.LinkInput.FocusLost:Connect(LoadVideo)

Window.Video.Ended:Connect(function()
	Window.Video.TimePosition = 0
	Settings.Playing = false
	ControlPanel.Play.ImageRectOffset = Vector2.new(764,244)
end)

Window.Playback.Slider.InputBegan:Connect(function(Input)
	if Input.UserInputType == Enum.UserInputType.MouseButton1 then
		Slide(Input)
		Settings.Sliding = true
	end
end)

Window.Playback.Slider.InputEnded:Connect(function(Input)
	if Input.UserInputType == Enum.UserInputType.MouseButton1 then
		Settings.Sliding = false
		Settings.Playing = true
		ControlPanel.Play.ImageRectOffset = Vector2.new(804,124)
		Window.Video:Play()
	end
end)

UserInputService.InputChanged:Connect(function(Input)
	if Settings.Sliding and Input.UserInputType == Enum.UserInputType.MouseMovement then
		Slide(Input)
	end
end)

RunService.RenderStepped:Connect(function()
	UpdateTime()
	UpdatePlayback()
end)

MakeDraggable(Window.Title,Window)
MakeResizeable(Window.Resize,Window,310,400)
