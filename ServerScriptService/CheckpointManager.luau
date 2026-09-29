local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local checkpointsFolder = Workspace:FindFirstChild("Checkpoints")
local playerCheckpoints = {} -- [player] = BasePart

local function setupCheckpoint(part)
	if not part:IsA("BasePart") or not part:GetAttribute("CheckpointIndex") then return end

	local debounce = {}

	part.Touched:Connect(function(otherPart)
		local character = otherPart.Parent
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health <= 0 then return end

		local player = Players:GetPlayerFromCharacter(character)
		if not player or debounce[player] then return end

		debounce[player] = true
		task.delay(1, function() debounce[player] = nil end)

		local index = part:GetAttribute("CheckpointIndex")
		local current = playerCheckpoints[player]
		local currentIndex = current and current:GetAttribute("CheckpointIndex") or 0

		if index > currentIndex then
			playerCheckpoints[player] = part
		end
	end)
end

local function setupPlayer(player)
	player.CharacterAdded:Connect(function(character)
		local checkpoint = playerCheckpoints[player]
		if not checkpoint then return end

		local hrp = character:WaitForChild("HumanoidRootPart", 5)
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not hrp or not humanoid then return end

		task.wait(0.1)

		-- チェックポイントの上に立たせる
		local offset = checkpoint.Size.Y / 2 + humanoid.HipHeight + hrp.Size.Y / 2 + 1
		character:PivotTo(checkpoint.CFrame + Vector3.new(0, offset, 0))
	end)
end

-- 既存のチェックポイントを設定
if checkpointsFolder then
	for _, part in ipairs(checkpointsFolder:GetChildren()) do
		setupCheckpoint(part)
	end
	checkpointsFolder.ChildAdded:Connect(setupCheckpoint)
end

-- 既存・新規プレイヤーの設定
for _, player in ipairs(Players:GetPlayers()) do
	setupPlayer(player)
end
Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(function(player)
	playerCheckpoints[player] = nil
end)