local CollectionService = game:GetService("CollectionService")

local CONVEYOR_TAG = "Conveyor"
local DEFAULT_CONVEYOR_SPEED = 10

-- Direction colors (distinct for each world-space direction)
local COLOR_POSITIVE_X = Color3.fromRGB(0, 150, 255)   -- Blue  (+X)
local COLOR_NEGATIVE_X = Color3.fromRGB(255, 100, 50)  -- Orange (-X)
local COLOR_POSITIVE_Z = Color3.fromRGB(0, 255, 100)   -- Green  (+Z)
local COLOR_NEGATIVE_Z = Color3.fromRGB(255, 50, 200)  -- Pink   (-Z)

local function getDirectionColor(dir: Vector3): Color3
	local absX, absZ = math.abs(dir.X), math.abs(dir.Z)
	if absX > absZ then
		return dir.X > 0 and COLOR_POSITIVE_X or COLOR_NEGATIVE_X
	else
		return dir.Z > 0 and COLOR_POSITIVE_Z or COLOR_NEGATIVE_Z
	end
end

local function setupConveyor(conveyor: Instance)
	if not conveyor:IsA("BasePart") then
		return
	end

	local speed = conveyor:GetAttribute("Speed") or DEFAULT_CONVEYOR_SPEED
	conveyor.Anchored = true

	-- Calculate velocity direction in world space
	local velocityDir = conveyor.CFrame:VectorToWorldSpace(Vector3.zAxis * -1)
	conveyor.AssemblyLinearVelocity = velocityDir * speed

	-- Set color based on movement direction
	conveyor.Color = getDirectionColor(velocityDir)

	-- Show and update the arrow indicator on the SurfaceGui
	local surfaceGui = conveyor:FindFirstChildWhichIsA("SurfaceGui")
	if surfaceGui then
		surfaceGui.Enabled = true

		local textLabel = surfaceGui:FindFirstChildWhichIsA("TextLabel")
		if textLabel then
			-- SurfaceGui on Top face: right = local -Z (LookVector), up = local -X (-RightVector)
			local guiRight = conveyor.CFrame.LookVector
			local guiUp = -conveyor.CFrame.RightVector

			-- Angle from guiRight toward guiUp
			local dotRight = velocityDir:Dot(guiRight)
			local dotUp = velocityDir:Dot(guiUp)
			local angle = math.deg(math.atan2(dotUp, dotRight))

			-- "▲" points up by default; rotate so it aligns with velocity
			textLabel.Text = "▲"
			textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
			textLabel.TextStrokeTransparency = 0
			textLabel.Rotation = 90 - angle
		end
	end
end

-- Setup all existing conveyors
for _, conveyor in CollectionService:GetTagged(CONVEYOR_TAG) do
	setupConveyor(conveyor)
end

-- Setup new conveyors as they are added
CollectionService:GetInstanceAddedSignal(CONVEYOR_TAG):Connect(setupConveyor)
