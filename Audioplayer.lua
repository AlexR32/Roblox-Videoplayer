local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local InsertService = game:GetService("InsertService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local PlayerService = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local Debug,LocalPlayer = false,PlayerService.LocalPlayer
local AssetFolder = Debug and ReplicatedStorage.VideoPlayer
or InsertService:LoadLocalAsset("rbxassetid://7563729664")

local RobloxPanel = CoreGui.ThemeProvider.TopBarFrame.LeftFrame

local Request = request
or (http and http.request)
or (syn and syn.request)

local GetAsset = getcustomasset or getsynasset

local PanelButton = AssetFolder.VideoButton
local Screen = AssetFolder.Videoplayer
local Window = Screen.Window
local ControlPanel = Window.ControlPanel

PanelButton.Name = HttpService:GenerateGUID(false)
PanelButton.Parent = RobloxPanel
Screen.Name = HttpService:GenerateGUID(false)
Screen.Parent = CoreGui

-- Videoplayer to Audioplayer
Window.Video.Visible = false
Window.Resize.Visible = false
Window.Title.Text = "Audioplayer"
ControlPanel.Expand.Visible = false
Window.Size = UDim2.new(0,310,0,105)

local Audio = Instance.new("Sound")
Audio.Parent = Window


if not isfolder("audios") then
	makefolder("audios")
end

local Settings = {Playing = false,
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

local function RequestVideo(VideoId)
	local Responce = Request({Method = "POST",
		Url = Settings.Domain .. "yt/audio?videoId=" .. VideoId,
	})
	if Responce.StatusCode == 404 then return false end
	return Responce.Body
end

local function ChangeTimePosition()
	--local Length = Audio.TimeLength
	local Size = UDim2.new(math.clamp((UserInputService:GetMouseLocation().X - Window.Playback.AbsolutePosition.X) / Window.Playback.AbsoluteSize.X,0,1),0,1,0)
	local TimePosition = Audio.TimeLength / Size.X.Scale --((Size.X.Scale * Length) / Length) * Length
	ControlPanel.Play.ImageRectOffset = Vector2.new(804,124)
	Audio.TimePosition = TimePosition
	Window.Playback.Line.Size = Size
	Settings.Playing = true Audio:Play()
end

local function UpdateTime()
	local TimePosition = Audio.TimePosition
	Window.Playback.Time.Text = string.format(
		"%02i:%02i:%02i",
		TimePosition/60^2,
		TimePosition/60%60,
		TimePosition%60
	)
end

local function UpdateLength()
	local TimeLength = Audio.TimeLength
	Window.Playback.Length.Text = string.format(
		"%02i:%02i:%02i",
		TimeLength/60^2,
		TimeLength/60%60,
		TimeLength%60
	)
end

local function UpdatePlayback()
	local TimePosition = Audio.TimePosition
	local TimeLength = Audio.TimeLength
	local TimePercent = TimePosition / TimeLength
	Window.Playback.Line.Size = UDim2.new(TimePercent,0,1,0)
end

local function PlayAudio(Toggle)
	Settings.Playing = Toggle
	if Settings.Playing then
		ControlPanel.Play.ImageRectOffset = Vector2.new(804,124)
		Audio:Play()
	else
		ControlPanel.Play.ImageRectOffset = Vector2.new(764,244)
		Audio:Pause()
	end
end

local function LoadAudio(Enter)
	if Enter then
		local VideoId = ControlPanel.LinkInput.Text
		if not isfile("audios/" .. VideoId .. ".mp3") then
			ControlPanel.LinkInput.PlaceholderText = "VideoID (Loading)"
			ControlPanel.LinkInput.Text = ""
			local Video = RequestVideo(VideoId)
			if Video then
				writefile("audios/" .. VideoId .. ".mp3", Video)
				Audio.SoundId = GetAsset("audios/" .. VideoId .. ".mp3")
				Window.Title.Text = "Audioplayer - audios/" .. VideoId .. ".mp3"
				ControlPanel.LinkInput.PlaceholderText = "VideoID"
				PlayAudio(true)
			else
				ControlPanel.LinkInput.PlaceholderText = "VideoID (Failed)"
				Window.Title.Text = "Audioplayer"
				Audio.SoundId = ""
				PlayAudio(false)
			end
		else
			ControlPanel.LinkInput.Text = ""
			Audio.SoundId = GetAsset("audios/" .. VideoId .. ".mp3")
			Window.Title.Text = "Audioplayer - audios/" .. VideoId .. ".mp3"
			ControlPanel.LinkInput.PlaceholderText = "VideoID"
			PlayAudio(true)
		end
	end
end

Window.Playback.Slider.MouseButton1Click:Connect(ChangeTimePosition)
ControlPanel.LinkInput.FocusLost:Connect(LoadAudio)
ControlPanel.Play.MouseButton1Click:Connect(function()
	PlayAudio(not Settings.Playing)
end)

Audio.Loaded:Connect(UpdateLength)
Audio.Ended:Connect(function()
	PlayAudio(false) Window.Video.TimePosition = 0
end)
PanelButton.Icon.MouseButton1Click:Connect(function()
	Window.Visible = not Window.Visible
end)

RunService.RenderStepped:Connect(function()
	UpdateTime() UpdatePlayback()
end)

MakeDraggable(Window.Title,Window)
