local UserInputService = game:GetService("UserInputService")
local InsertService = game:GetService("InsertService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local AssetFolder = InsertService:LoadLocalAsset("rbxassetid://7563729664")
local Request = request or (http and http.request) or (syn and syn.request)
local GetAsset = getcustomasset or getsynasset

local RobloxPanel = CoreGui.ThemeProvider.TopBarFrame.LeftFrame
local PanelButton = AssetFolder.VideoButton
local Screen = AssetFolder.Videoplayer

local Window = Screen.Window
local ControlPanel = Window.ControlPanel

PanelButton.Name = HttpService:GenerateGUID(false)
PanelButton.Parent = RobloxPanel
Screen.Name = HttpService:GenerateGUID(false)
Screen.Parent = CoreGui

if not isfolder("videos") then
	makefolder("videos")
end

local Settings = {
	Playing = false,
	Expand = false,
	Size = Window.Size,
	Position = Window.Position,
	Domain = "https://parvus.fun/"
}

local function MakeDraggable(Dragger,Object,Callback)
	local StartPosition,StartDrag = nil,nil

	Dragger.InputBegan:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 then
			StartPosition = UserInputService:GetMouseLocation()
			StartDrag = Object.AbsolutePosition
		end
	end)
	UserInputService.InputChanged:Connect(function(Input)
		if StartDrag and Input.UserInputType == Enum.UserInputType.MouseMovement then
			local Mouse = UserInputService:GetMouseLocation()
			local Delta = Mouse - StartPosition
			StartPosition = Mouse
			Object.Position = Object.Position + UDim2.new(0,Delta.X,0,Delta.Y)
		end
	end)
	Dragger.InputEnded:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 then
			StartPosition,StartDrag = nil,nil
			if Callback then
				Callback(Object.Position)
			end
		end
	end)
end

local function MakeResizeable(Dragger,Object,MinSize,Callback)
	local StartPosition,StartSize = nil,nil

	Dragger.InputBegan:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 then
			StartPosition = UserInputService:GetMouseLocation()
			StartSize = Object.AbsoluteSize
		end
	end)
	UserInputService.InputChanged:Connect(function(Input)
		if StartPosition and Input.UserInputType == Enum.UserInputType.MouseMovement then
			local Mouse = UserInputService:GetMouseLocation()
			local Delta = Mouse - StartPosition

			local Size = StartSize + Delta
			local SizeX = math.max(MinSize.X,Size.X)
			local SizeY = math.max(MinSize.Y,Size.Y)
			Object.Size = UDim2.fromOffset(SizeX,SizeY)
		end
	end)
	Dragger.InputEnded:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 then
			StartPosition,StartSize = nil,nil
			if Callback then
				Callback(Object.Size)
			end
		end
	end)
end

local function RequestVideo(VideoId)
	local Responce = Request({Method = "POST",
		Url = Settings.Domain .. "yt/video?videoId=" .. VideoId,
	})
	if Responce.StatusCode == 404 then return false end
	return Responce.Body
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
	Window.Playback.Time.Text = string.format(
		"%02i:%02i:%02i",
		TimePosition/60^2,
		TimePosition/60%60,
		TimePosition%60
	)
end

local function UpdateLength()
	local TimeLength = Window.Video.TimeLength
	Window.Playback.Length.Text = string.format(
		"%02i:%02i:%02i",
		TimeLength/60^2,
		TimeLength/60%60,
		TimeLength%60
	)
end

local function UpdatePlayback()
	local TimePosition = Window.Video.TimePosition
	local TimeLength = Window.Video.TimeLength
	local TimePercent = TimePosition / TimeLength
	Window.Playback.Line.Size = UDim2.new(TimePercent,0,1,0)
end

local function PlayVideo(Toggle)
	Settings.Playing = Toggle
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
			Window.Size = UDim2.new(0,Window.Video.Resolution.X + 10,0,Window.Video.Resolution.Y + 110)
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
		local VideoId = ControlPanel.LinkInput.Text
		if not isfile("videos/" .. VideoId .. ".webm") then
			ControlPanel.LinkInput.Text = ""
			ControlPanel.LinkInput.PlaceholderText = "VideoID (Loading)"
			local Video = RequestVideo(VideoId)
			if Video then
				writefile("videos/" .. VideoId .. ".webm", Video)
				Window.Video.Video = GetAsset("videos/" .. VideoId .. ".webm")
				Window.Title.Text = "Videoplayer - videos/" .. VideoId .. ".webm"
				ControlPanel.LinkInput.PlaceholderText = "VideoID"
				PlayVideo(true)
			else
				ControlPanel.LinkInput.PlaceholderText = "VideoID (Failed)"
				Window.Title.Text = "Videoplayer"
				Window.Video.Video = ""
				PlayVideo(false)
			end
		else
			ControlPanel.LinkInput.Text = ""
			Window.Video.Video = GetAsset("videos/" .. VideoId .. ".webm")
			Window.Title.Text = "Videoplayer - videos/" .. VideoId .. ".webm"
			ControlPanel.LinkInput.PlaceholderText = "VideoID"
			PlayVideo(true)
		end
	end
end

Window.Playback.Slider.MouseButton1Click:Connect(ChangeTimePosition)
ControlPanel.Expand.MouseButton1Click:Connect(Expand)
ControlPanel.LinkInput.FocusLost:Connect(LoadVideo)
ControlPanel.Play.MouseButton1Click:Connect(function()
	PlayVideo(not Settings.Playing)
end)

Window.Video.Loaded:Connect(UpdateLength)
Window.Video.Ended:Connect(function()
	PlayVideo(false) Window.Video.TimePosition = 0
end)
PanelButton.Icon.MouseButton1Click:Connect(function()
	Window.Visible = not Window.Visible
end)

RunService.RenderStepped:Connect(function()
	UpdateTime() UpdatePlayback()
end)

MakeDraggable(Window.Title,Window)
MakeResizeable(Window.Resize,Window,Vector2.new(310,400))
