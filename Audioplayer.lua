-- Repeat On = rbxassetid://6026666994
-- Repeat Off = rbxassetid://6026666998
-- Play = rbxassetid://6026663699
-- Pause = rbxassetid://6026663719
-- Menu = rbxassetid://6031097225

local UserInputService = game:GetService("UserInputService")
local InsertService = game:GetService("InsertService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local AssetFolder = InsertService:LoadLocalAsset("rbxassetid://11312132580")
local Request = request or (http and http.request) or (syn and syn.request)
local GetAsset = getcustomasset or getsynasset

local RobloxPanel = CoreGui.ThemeProvider.TopBarFrame.LeftFrame
local PanelButton = AssetFolder.AudioPlayer:Clone()
local Screen = AssetFolder.Screen:Clone()

PanelButton.Name = HttpService:GenerateGUID(false)
PanelButton.Parent = RobloxPanel

Screen.Name = HttpService:GenerateGUID(false)
Screen.Parent = CoreGui

local Window = Screen.Window
local Audio = Window.Sound
local Title = Window.Title
local Playback = Window.Playback
local ControlPanel = Window.ControlPanel

local VSActive,PSActive = false,false
local Domain = "https://parvus.fun/"
if not isfolder("audios") then
	makefolder("audios")
end local Playing = false

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

local function RequestVideo(VideoId)
	local Responce = Request({Method = "POST",
		Url = Domain .. "yt/audio?videoId=" .. VideoId
	}) if Responce.StatusCode == 404 then return false end
	return Responce.Body
end

local function UpdateTime()
	local TimePosition = Audio.TimePosition
	Playback.Time.Text = string.format(
		"%02i:%02i:%02i",
		TimePosition/60^2,
		TimePosition/60%60,
		TimePosition%60
	)
end

local function UpdateLength()
	local TimeLength = Audio.TimeLength
	Playback.Length.Text = string.format(
		"%02i:%02i:%02i",
		TimeLength/60^2,
		TimeLength/60%60,
		TimeLength%60
	)
end

local function UpdatePlayback()
	Playback.Line.Size = UDim2.new(Audio.TimePosition / Audio.TimeLength,0,1,0)
end

local function UpdateVS(Input)
	local XScale = math.clamp((Input.Position.X - ControlPanel.VolSlider.AbsolutePosition.X) / ControlPanel.VolSlider.AbsoluteSize.X,0,1)
	local SliderPrecise = math.round(math.clamp(XScale * (200 - 0) + 0,0,200))

	ControlPanel.VolSlider.Title.Text = tostring(SliderPrecise) .. "%"
	ControlPanel.VolSlider.Line.Size = UDim2.new((SliderPrecise - 0) / (200 - 0),0,1,0)
	Audio.Volume = SliderPrecise / 100
end

local function UpdatePS(Input)
	local Position = math.clamp((Input.Position.X - Playback.AbsolutePosition.X) / Playback.AbsoluteSize.X,0,1)
	Audio.TimePosition = math.clamp(Audio.TimeLength * Position,0,Audio.TimeLength) UpdateTime() UpdatePlayback()
end

local function AudioMode(Mode)
	if Mode == "Play" then Audio.TimePosition = 0 Audio:Play()
		ControlPanel.Play.Image = "rbxassetid://6026663719"
		PanelButton.Icon.Image = "rbxassetid://6026663719"
	elseif Mode == "Resume" then Audio:Resume()
		ControlPanel.Play.Image = "rbxassetid://6026663719"
		PanelButton.Icon.Image = "rbxassetid://6026663719"
	elseif Mode == "Stop" then Audio:Stop()
		ControlPanel.Play.Image = "rbxassetid://6026663699"
		PanelButton.Icon.Image = "rbxassetid://6026663699"
	elseif Mode == "Pause" then Audio:Pause()
		ControlPanel.Play.Image = "rbxassetid://6026663699"
		PanelButton.Icon.Image = "rbxassetid://6026663699"
	elseif Mode == "LoopOn" then Audio.Looped = true
		ControlPanel.Repeat.Image = "rbxassetid://6026666994"
	elseif Mode == "LoopOff" then Audio.Looped = false
		ControlPanel.Repeat.Image = "rbxassetid://6026666998"
	end
end

local function LoadAudio(Enter)
	if Enter then
		local VideoId = ControlPanel.VIDInput.Text
		ControlPanel.VIDInput.PlaceholderText = "Video ID (Loading)"
		ControlPanel.VIDInput.Text = ""

		if not isfile("audios/" .. VideoId .. ".mp3") then
			local Video = RequestVideo(VideoId) if Video then
				writefile("audios/" .. VideoId .. ".mp3", Video)
				Audio.SoundId = GetAsset("audios/" .. VideoId .. ".mp3")
				Title.Text = "Audio Player - audios/" .. VideoId .. ".mp3"
				ControlPanel.VIDInput.PlaceholderText = "Video ID"
				AudioMode("Play") Playing = Audio.Playing
			else
				ControlPanel.VIDInput.PlaceholderText = "Video ID (Failed)"
				Window.Title.Text = "Audio Player"
				AudioMode("Stop") Playing = Audio.Playing
			end
		else
			ControlPanel.VIDInput.PlaceholderText = "Video ID"
			Audio.SoundId = GetAsset("audios/" .. VideoId .. ".mp3")
			Window.Title.Text = "Audio Player - audios/" .. VideoId .. ".mp3"
			AudioMode("Play") Playing = Audio.Playing
		end
	end
end

ControlPanel.VolSlider.InputBegan:Connect(function(Input)
	if Input.UserInputType == Enum.UserInputType.MouseButton1 then
		UpdateVS(Input) VSActive = true
	end
end)
ControlPanel.VolSlider.InputEnded:Connect(function(Input)
	if Input.UserInputType == Enum.UserInputType.MouseButton1 then
		VSActive = false
	end
end)

Playback.Slider.InputBegan:Connect(function(Input)
	if Input.UserInputType == Enum.UserInputType.MouseButton1 then
		AudioMode("Pause") UpdatePS(Input) PSActive = true
	end
end)

Playback.Slider.InputEnded:Connect(function(Input)
	if Input.UserInputType == Enum.UserInputType.MouseButton1 then
		if Playing then AudioMode("Resume") end
		PSActive = false
	end
end)

UserInputService.InputChanged:Connect(function(Input)
	if Input.UserInputType == Enum.UserInputType.MouseMovement then
		if VSActive then UpdateVS(Input) end
		if PSActive then UpdatePS(Input) end
	end
end)


ControlPanel.VIDInput.FocusLost:Connect(LoadAudio)
ControlPanel.Play.MouseButton1Click:Connect(function()
	AudioMode(not Audio.Playing and "Resume" or "Pause")
	Playing = Audio.Playing
end) ControlPanel.Repeat.MouseButton1Click:Connect(function()
	AudioMode(Audio.Looped and "LoopOff" or "LoopOn")
end) RunService.RenderStepped:Connect(function()
	if Audio.Playing then UpdateTime() UpdatePlayback() end
end) PanelButton.Icon.MouseButton1Click:Connect(function()
	Window.Visible = not Window.Visible
end) Audio.Loaded:Connect(UpdateLength)
MakeDraggable(Title,Window)
