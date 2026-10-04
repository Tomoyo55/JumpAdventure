--==================================================
-- CheckpointManager
--==================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")


--==================================================
-- 設定
--==================================================

local checkpointsFolder = Workspace:FindFirstChild("Checkpoints")

-- CheckPoint2フォルダ
local checkPoint2Folder = Workspace:FindFirstChild("CheckPoint2")

-- 落下判定
local FALL_THRESHOLD = -30

-- Touchedの連続発火を防ぐ時間
local TOUCH_DEBOUNCE_TIME = 0.3

-- 復帰するとき、チェックポイントより何スタッド上に出すか
local RECOVERY_HEIGHT = 8

-- ふわっと降りる時間
local RECOVERY_DURATION = 1.2


--==================================================
-- トラップから復帰要求を受け取るためのEvent
--==================================================

local recoveryEvent =
	ReplicatedStorage:FindFirstChild("CheckpointRecoveryEvent")

if not recoveryEvent then

	recoveryEvent =
		Instance.new("BindableEvent")

	recoveryEvent.Name =
		"CheckpointRecoveryEvent"

	recoveryEvent.Parent =
		ReplicatedStorage

end


--==================================================
-- プレイヤーごとのデータ
--==================================================

-- 現在の復活ポイント
--
-- 通常：
-- [player] = CheckPointModel
--
-- CheckPoint2：
-- [player] = CheckPoint2のCheckpoint Part
--
local playerCheckpoints = {}

-- 落下復帰中かどうか
local FALL_RECOVERING = {}


--==================================================
-- CheckPointModelの中から
-- 「Checkpoint」という名前のPartを探す
--==================================================

local function getCheckpointPart(checkPointModel)

	print(
		"[Checkpoint] Checkpointを探しています:",
		checkPointModel:GetFullName()
	)

	local checkpoint =
		checkPointModel:FindFirstChild("Checkpoint")

	if checkpoint
		and checkpoint:IsA("BasePart") then

		print(
			"[Checkpoint] Checkpointを発見:",
			checkpoint:GetFullName()
		)

		return checkpoint

	end

	warn(
		"[Checkpoint] Checkpointが見つかりません:",
		checkPointModel:GetFullName()
	)

	return nil

end


--==================================================
-- チェックポイント到達エフェクト
--
-- 黄色い円
-- ＋黄色いキラキラ
--
-- ※赤いエフェクトは一切なし
--==================================================

local function playCheckpointEffect(checkpointPart)

	print("[Checkpoint] 黄色いエフェクトを開始")

	--================================================
	-- 黄色い円
	--================================================

	local circle =
		Instance.new("Part")

	circle.Name =
		"CheckpointEffect"

	circle.Shape =
		Enum.PartType.Cylinder

	circle.Size =
		Vector3.new(
			0.15,
			2,
			2
		)

	circle.Color =
		Color3.fromRGB(
			255,
			221,
			0
		)

	circle.Material =
		Enum.Material.Neon

	circle.Transparency =
		0.15

	circle.Anchored =
		true

	circle.CanCollide =
		false

	circle.CanTouch =
		false

	circle.CanQuery =
		false

	circle.CFrame =
		CFrame.new(
			checkpointPart.Position
			+ Vector3.new(0, 1.5, 0)
		)
		* CFrame.Angles(
			0,
			0,
			math.rad(90)
		)

	circle.Parent =
		Workspace


	--================================================
	-- 黄色いキラキラ
	--================================================

	for i = 1, 12 do

		local star =
			Instance.new("Part")

		star.Name =
			"CheckpointStar"

		star.Shape =
			Enum.PartType.Ball

		star.Size =
			Vector3.new(
				0.35,
				0.35,
				0.35
			)

		star.Color =
			Color3.fromRGB(
				255,
				230,
				50
			)

		star.Material =
			Enum.Material.Neon

		star.Anchored =
			true

		star.CanCollide =
			false

		star.CanTouch =
			false

		star.CanQuery =
			false

		star.Position =
			checkpointPart.Position
			+ Vector3.new(0, 1.5, 0)

		star.Parent =
			Workspace


		local direction =
			Vector3.new(
				math.random(-100, 100) / 100,
				math.random(50, 150) / 100,
				math.random(-100, 100) / 100
			)


		task.spawn(function()

			local startPosition =
				star.Position

			local endPosition =
				startPosition
				+ direction * 3

			local duration =
				0.8

			local startTime =
				os.clock()


			while os.clock() - startTime
				< duration do

				if not star
					or not star.Parent then

					return

				end


				local progress =
					(os.clock() - startTime)
					/ duration


				star.Position =
					startPosition:Lerp(
						endPosition,
						progress
					)

				star.Transparency =
					progress

				task.wait()

			end


			if star
				and star.Parent then

				star:Destroy()

			end

		end)

	end


	--================================================
	-- 円を広げる
	--================================================

	task.spawn(function()

		local duration =
			0.8

		local startTime =
			os.clock()


		while os.clock() - startTime
			< duration do

			if not circle
				or not circle.Parent then

				return

			end


			local progress =
				(os.clock() - startTime)
				/ duration


			local size =
				2 + (8 - 2) * progress


			circle.Size =
				Vector3.new(
					0.15,
					size,
					size
				)


			circle.Transparency =
				0.15
				+ (0.85 * progress)


			task.wait()

		end


		if circle
			and circle.Parent then

			circle:Destroy()

		end

	end)

end


--==================================================
-- チェックポイントを登録
--==================================================

local function registerCheckpoint(
	player,
	checkpointPart,
	checkPointID
)

	if playerCheckpoints[player]
		== checkPointID then

		print(
			"[Checkpoint] 同じチェックポイントなので更新しません:",
			checkPointID.Name
		)

		return

	end


	playerCheckpoints[player] =
		checkPointID


	print(
		"[Checkpoint] ★ チェックポイント到達！ ★"
	)

	print(
		"[Checkpoint] プレイヤー:",
		player.Name
	)

	print(
		"[Checkpoint] 復帰地点:",
		checkpointPart:GetFullName()
	)


	-- 黄色いエフェクト
	playCheckpointEffect(
		checkpointPart
	)

end


--==================================================
-- 通常のCheckPointModelを設定
--==================================================

local function setupCheckpoint(part)

	if not part:IsA("BasePart") then
		return
	end


	local checkPointModel =
		part:FindFirstAncestor(
			"CheckPointModel"
		)


	if not checkPointModel then
		return
	end


	print(
		"[Checkpoint] 監視対象を設定:",
		part:GetFullName()
	)


	local debounce = {}


	part.Touched:Connect(function(otherPart)

		local character =
			otherPart.Parent


		if not character then
			return
		end


		local humanoid =
			character:FindFirstChildOfClass(
				"Humanoid"
			)


		if not humanoid then
			return
		end


		local player =
			Players:GetPlayerFromCharacter(
				character
			)


		if not player then
			return
		end


		if debounce[player] then
			return
		end


		debounce[player] = true


		task.delay(
			TOUCH_DEBOUNCE_TIME,
			function()

				debounce[player] = nil

			end
		)


		local checkpointPart =
			getCheckpointPart(
				checkPointModel
			)


		if not checkpointPart then
			return
		end


		registerCheckpoint(
			player,
			checkpointPart,
			checkPointModel
		)

	end)

end


--==================================================
-- CheckPoint2のCheckpointを設定
--==================================================

local function setupCheckPoint2()

	if not checkPoint2Folder then

		warn(
			"[Checkpoint] WorkspaceにCheckPoint2フォルダがありません"
		)

		return

	end


	local checkpoint =
		checkPoint2Folder:FindFirstChild(
			"Checkpoint"
		)


	if not checkpoint then

		warn(
			"[Checkpoint] CheckPoint2の中にCheckpointがありません"
		)

		return

	end


	if not checkpoint:IsA("BasePart") then

		warn(
			"[Checkpoint] CheckPoint2.CheckpointがPartではありません"
		)

		return

	end


	print(
		"[Checkpoint] CheckPoint2.Checkpointを発見:",
		checkpoint:GetFullName()
	)


	local debounce = {}


	checkpoint.Touched:Connect(function(otherPart)

		local character =
			otherPart.Parent


		if not character then
			return
		end


		local humanoid =
			character:FindFirstChildOfClass(
				"Humanoid"
			)


		if not humanoid then
			return
		end


		local player =
			Players:GetPlayerFromCharacter(
				character
			)


		if not player then
			return
		end


		if debounce[player] then
			return
		end


		debounce[player] = true


		task.delay(
			TOUCH_DEBOUNCE_TIME,
			function()

				debounce[player] = nil

			end
		)


		registerCheckpoint(
			player,
			checkpoint,
			checkpoint
		)

	end)


	print(
		"[Checkpoint] CheckPoint2.Checkpointの監視を開始しました"
	)

end


--==================================================
-- プレイヤーの復活地点CFrameを取得
--==================================================

local function getRespawnCFrame(player)

	local checkPoint =
		playerCheckpoints[player]


	if not checkPoint then
		return nil
	end


	--================================================
	-- CheckPoint2の場合
	--================================================

	if checkPoint2Folder
		and checkPoint
		== checkPoint2Folder:FindFirstChild("Checkpoint") then

		return checkPoint.CFrame
			+ Vector3.new(
				0,
				RECOVERY_HEIGHT,
				0
			)

	end


	--================================================
	-- 通常のCheckPointModelの場合
	--================================================

	local checkpointPart =
		getCheckpointPart(
			checkPoint
		)


	if not checkpointPart then
		return nil
	end


	return checkpointPart.CFrame
		+ Vector3.new(
			0,
			RECOVERY_HEIGHT,
			0
		)

end


--==================================================
-- 落下後にふわっと復帰
--
-- 上空に出現
-- ↓
-- ふわっと下へ
-- ↓
-- チェックポイント付近へ
--==================================================

local function playSoftRecoveryEffect(
	character,
	respawnCFrame
)

	local rootPart =
		character:FindFirstChild(
			"HumanoidRootPart"
		)


	local humanoid =
		character:FindFirstChildOfClass(
			"Humanoid"
		)


	if not rootPart
		or not humanoid then

		return

	end


	--================================================
	-- ダウン状態を解除
	--================================================

	humanoid.PlatformStand =
		false


	--================================================
	-- チェックポイントより上空へ移動
	--================================================

	rootPart.CFrame =
		respawnCFrame


	--================================================
	-- 落下速度をリセット
	--================================================

	rootPart.AssemblyLinearVelocity =
		Vector3.zero

	rootPart.AssemblyAngularVelocity =
		Vector3.zero


	print(
		"[Checkpoint] 上空からふわっと復帰開始"
	)


	--================================================
	-- チェックポイントの少し上を目標にする
	--================================================

	local targetPosition =
		respawnCFrame.Position
	- Vector3.new(
		0,
		RECOVERY_HEIGHT,
		0
	)
		+ Vector3.new(
			0,
			3,
			0
		)


	--================================================
	-- ふわっと降りる
	--================================================

	local tweenInfo =
		TweenInfo.new(
			RECOVERY_DURATION,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out
		)


	local tween =
		TweenService:Create(
			rootPart,
			tweenInfo,
			{
				CFrame =
				CFrame.new(
					targetPosition
				)
			}
		)


	tween:Play()

	tween.Completed:Wait()


	--================================================
	-- 最後に速度をリセット
	--================================================

	if rootPart
		and rootPart.Parent then

		rootPart.AssemblyLinearVelocity =
			Vector3.zero

		rootPart.AssemblyAngularVelocity =
			Vector3.zero

	end


	print(
		"[Checkpoint] ふわっと復帰完了"
	)

end


--==================================================
-- 実際にチェックポイントへ復帰する
--
-- 落下・トラップの両方がここを使う
--==================================================

local function recoverPlayer(player)

	if FALL_RECOVERING[player] then
		return
	end


	local respawnCFrame =
		getRespawnCFrame(player)


	if not respawnCFrame then

		print(
			"[Checkpoint]",
			player.Name,
			"はまだチェックポイント未取得"
		)

		return

	end


	local character =
		player.Character


	if not character then
		return
	end


	FALL_RECOVERING[player] =
		true


	print(
		"[Checkpoint] 復帰開始:",
		player.Name
	)


	playSoftRecoveryEffect(
		character,
		respawnCFrame
	)


	task.wait(0.5)


	FALL_RECOVERING[player] =
		nil


	print(
		"[Checkpoint] 復帰完了:",
		player.Name
	)

end


--==================================================
-- トラップからの復帰要求
--==================================================

recoveryEvent.Event:Connect(function(player)

	if not player then
		return
	end


	if not player:IsA("Player") then
		return
	end


	print(
		"[Checkpoint] トラップから復帰要求:",
		player.Name
	)


	recoverPlayer(player)

end)


--==================================================
-- 落下監視
--==================================================

local function startFallDetection(player)

	task.spawn(function()

		while player.Parent do

			task.wait(0.2)


			-- すでに復帰中なら確認しない
			if FALL_RECOVERING[player] then
				continue
			end


			local character =
				player.Character


			if not character then
				continue
			end


			local rootPart =
				character:FindFirstChild(
					"HumanoidRootPart"
				)


			if not rootPart then
				continue
			end


			--================================================
			-- Y座標が-30より下なら落下
			--================================================

			if rootPart.Position.Y
				< FALL_THRESHOLD then

				print(
					"[Checkpoint] 落下を検知:",
					player.Name
				)


				recoverPlayer(player)

			end

		end

	end)

end


--==================================================
-- Checkpointsフォルダを設定
--==================================================

if checkpointsFolder then

	print(
		"[Checkpoint] Checkpointsフォルダを発見:",
		checkpointsFolder:GetFullName()
	)


	for _, object in ipairs(
		checkpointsFolder:GetDescendants()
		) do

		setupCheckpoint(object)

	end


	checkpointsFolder.DescendantAdded:Connect(
		function(object)

			setupCheckpoint(object)

		end
	)

else

	warn(
		"[Checkpoint] エラー：WorkspaceにCheckpointsフォルダがありません"
	)

end


--==================================================
-- CheckPoint2を設定
--==================================================

setupCheckPoint2()


--==================================================
-- プレイヤー設定
--==================================================

local function setupPlayer(player)

	print(
		"[Checkpoint] プレイヤー設定:",
		player.Name
	)


	playerCheckpoints[player] =
		nil

	FALL_RECOVERING[player] =
		nil


	startFallDetection(player)


	player.CharacterAdded:Connect(
		function(character)

			print(
				"[Checkpoint] キャラクター出現:",
				player.Name
			)

		end
	)


	print(
		"[Checkpoint]",
		player.Name,
		"はまだチェックポイント未取得"
	)

end


--==================================================
-- プレイヤー参加
--==================================================

Players.PlayerAdded:Connect(
	function(player)

		setupPlayer(player)

	end
)


--==================================================
-- すでにいるプレイヤー
--==================================================

for _, player in ipairs(
	Players:GetPlayers()
	) do

	setupPlayer(player)

end


--==================================================
-- プレイヤー退出時
--==================================================

Players.PlayerRemoving:Connect(
	function(player)

		playerCheckpoints[player] =
			nil

		FALL_RECOVERING[player] =
			nil

	end
)