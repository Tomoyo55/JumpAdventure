local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local BOUNCE_PAD_TAG = "BouncePad"
local DEFAULT_BOUNCE_IMPULSE = 200
local COOLDOWN = 0.3

local lastBounce = {}

local function setupBouncePad(bouncePad: Instance)
	if not bouncePad:IsA("BasePart") then
		return
	end

	-- ジャンプ台自体は固定する
	bouncePad.Anchored = true

	-- パッド自身に速度を与えない
	bouncePad.AssemblyLinearVelocity = Vector3.zero

	-- パッドに触れたプレイヤーを上に跳ね飛ばす
	bouncePad.Touched:Connect(function(hit)
		local character = hit.Parent
		if not character then
			return
		end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local rootPart = character:FindFirstChild("HumanoidRootPart")

		if not humanoid or not rootPart then
			return
		end

		local player = Players:GetPlayerFromCharacter(character)

		if not player then
			return
		end

		-- 連続で何度も発動しないようにする
		if lastBounce[player] then
			return
		end

		lastBounce[player] = true

		-- BounceImpulse属性があればその値を使う
		local impulse = bouncePad:GetAttribute("BounceImpulse") or DEFAULT_BOUNCE_IMPULSE

		-- プレイヤーを真上に跳ね飛ばす
		rootPart.AssemblyLinearVelocity = Vector3.new(
			0,
			impulse,
			0
		)

		task.delay(COOLDOWN, function()
			lastBounce[player] = nil
		end)
	end)

	-- BounceIndicatorがあれば非表示
	local bounceIndicator = bouncePad:FindFirstChildWhichIsA("SurfaceGui")
	if bounceIndicator then
		bounceIndicator.Enabled = false
	end
end

-- すでに存在するBouncePadを設定
for _, bouncePad in CollectionService:GetTagged(BOUNCE_PAD_TAG) do
	setupBouncePad(bouncePad)
end

-- 新しくBouncePadタグが付いたものも設定
CollectionService:GetInstanceAddedSignal(BOUNCE_PAD_TAG):Connect(setupBouncePad)