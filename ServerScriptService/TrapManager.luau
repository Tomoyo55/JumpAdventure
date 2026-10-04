local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TRAP_PART_TAG = "TrapPart"
local DOWN_DURATION = 2.0 -- ゆっくり崩れ落ちる時間
local MESSAGE_DELAY = 1.0 -- 崩れ落ちてから励ましメッセージを表示するまでの待ち時間

-- チェックポイントマネージャーのイベントを取得
local recoveryEvent = ReplicatedStorage:WaitForChild("CheckpointRecoveryEvent")

-- 重複発火防止
local downedCharacters = {}

-- 頭上に励ましメッセージを表示
local function showMessage(character: Model, text: string, duration: number)
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "TrapMessage"
	billboard.Size = UDim2.new(0, 350, 0, 80)
	billboard.StudsOffset = Vector3.new(0, 4, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 120

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(255, 230, 80)
	label.TextStrokeTransparency = 0.3
	label.TextStrokeColor3 = Color3.fromRGB(40, 40, 40)
	label.Parent = billboard

	billboard.Parent = hrp

	task.delay(duration, function()
		if billboard.Parent then
			billboard:Destroy()
		end
	end)
end

local function onTrapTouched(hit: BasePart)
	if not hit or not hit.Parent then return end

	local character = hit.Parent
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end

	if downedCharacters[character] then return end
	downedCharacters[character] = true

	-- トラップ中は落下検知を無視させる
	local player = Players:GetPlayerFromCharacter(character)
	if player then
		player:SetAttribute("DiedFromTrap", true)
	end

	-- 速度を止めてダウン状態にする
	humanoid.PlatformStand = true
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if hrp then
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
	end

	-- 崩れ落ちてから少し遅れて励ましメッセージを表示
	task.delay(MESSAGE_DELAY, function()
		if character and character.Parent and humanoid and humanoid.Parent then
			showMessage(character, "Yeah! Try again!", DOWN_DURATION - MESSAGE_DELAY + 0.5)
		end
	end)

	-- DOWN_DURATION秒後にチェックポイント管理側に復帰を任せる
	task.delay(DOWN_DURATION, function()
		if player and player.Parent then
			-- ダウン状態を解除
			if humanoid and humanoid.Parent then
				humanoid.PlatformStand = false
				humanoid.Health = humanoid.MaxHealth -- 体力を念のため全回復
			end

			-- ★ チェックポイントマネージャーのBindableEventを発火させてプレイヤーを復帰させる
			recoveryEvent:Fire(player)
		end

		-- 少しだけ待ってから次のトラップ判定を許可
		task.wait(0.5)
		downedCharacters[character] = nil
	end)
end

local function setupTrapPart(trapPart: Instance)
	if not trapPart:IsA("BasePart") then
		return
	end
	trapPart.Touched:Connect(onTrapTouched)
end

-- 既存のトラップに接続
for _, trapPart in CollectionService:GetTagged(TRAP_PART_TAG) do
	setupTrapPart(trapPart)
end

-- 新しく追加されたトラップに接続
CollectionService:GetInstanceAddedSignal(TRAP_PART_TAG):Connect(setupTrapPart)