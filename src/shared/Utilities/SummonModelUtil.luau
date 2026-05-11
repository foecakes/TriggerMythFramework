--!strict
--[[
	SUMMON MODEL UTILITY
	Author: @FoeCakes

	DESCRIPTION:
		Reveals and hides Models or Folders tagged with "UnlockableModel".
		Instead of cloning templates, this operates on existing workspace instances.
		"Summoning" tweens every BasePart, Decal, and Texture from fully
		transparent and non-collidable to their original cached state, and vice-versa.

	USAGE:
		local SummonModelUtil = require(path.to.SummonModelUtil)
		SummonModelUtil.InitModel(myModel)
		SummonModelUtil.Summon("MyModelName")

	PARAMETERS:
		Varies by function. Most accept either an Instance or a string modelName.

	NOTES:
		Depends on CollectionService tags to locate unlockables.
		Weak tables are used for caching to prevent memory leaks when instances are destroyed.
]]

--//Services
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local GeneralConfig = require(ReplicatedStorage.Shared.Constants.GeneralConfig)

--//Constants
local UNLOCKABLE_TAG = GeneralConfig.Model_UnlockableTag
local TWEEN_INFO = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local STAGGER_DELAY = 0.02

--//Types
type PartSnapshot = {
	Transparency: number,
	CanCollide: boolean?,
}

type ModelCache = {
	partData: { [Instance]: PartSnapshot },
	partList: { Instance },
}

--//Constructor
local SummonModelUtil = {}

--//Cache
-->! Weak-keyed table ensures cached data is garbage collected when the instance is destroyed
local originalData: { [Instance]: ModelCache } = {}
setmetatable(originalData :: any, { __mode = "k" })

-->! Stores active tweening tasks to allow clean cancellation if a new animation is requested
local pendingTasks: { [Instance]: { thread } } = {}
setmetatable(pendingTasks :: any, { __mode = "k" })

--[[
	runningTweens – Per-part list of active tweens so overlapping animations
	can be cancelled.
]]
local runningTweens: { [Instance]: Tween } = {}
setmetatable(runningTweens :: any, { __mode = "k" })

--//Helpers
local function cancelPendingTasks(instance: Instance)
	local tasks = pendingTasks[instance]
	if tasks then
		for _, t in tasks do
			task.cancel(t)
		end
		pendingTasks[instance] = nil
	end

	-- Also cancel tweens for all parts in this model
	local cache = originalData[instance]
	if cache then
		for _, obj in cache.partList do
			local tween = runningTweens[obj]
			if tween then
				tween:Cancel()
				tween:Destroy()
				runningTweens[obj] = nil
			end
		end
	end
end

local function playTween(obj: Instance, tweenGoals: { [string]: any })
	local existing = runningTweens[obj]
	if existing then
		existing:Cancel()
		existing:Destroy()
	end

	local tween = TweenService:Create(obj, TWEEN_INFO, tweenGoals)
	runningTweens[obj] = tween

	tween.Completed:Once(function()
		if runningTweens[obj] == tween then
			runningTweens[obj] = nil
		end
		tween:Destroy()
	end)
	tween:Play()
end

--//Public methods
function SummonModelUtil.InitModel(instance: Instance)
	local data: { [Instance]: PartSnapshot } = {}
	local list: { Instance } = {}
	originalData[instance] = { partData = data, partList = list }

	local function register(obj: Instance)
		if obj:IsA("BasePart") then
			data[obj] = {
				Transparency = (obj :: BasePart).Transparency,
				CanCollide = (obj :: BasePart).CanCollide,
			}
			table.insert(list, obj)

			if instance:GetAttribute("Unlocked") ~= true then
				(obj :: BasePart).Transparency = 1
				(obj :: BasePart).CanCollide = false
			end
		elseif obj:IsA("Decal") or obj:IsA("Texture") then
			data[obj] = {
				Transparency = (obj :: Decal).Transparency,
			}
			table.insert(list, obj)

			if instance:GetAttribute("Unlocked") ~= true then
				(obj :: Decal).Transparency = 1
			end
		end
	end

	register(instance)
	for _, desc in instance:GetDescendants() do
		register(desc)
	end

	-->! Connect DescendantAdded to handle StreamingEnabled loading parts in chunks over time
	instance.DescendantAdded:Connect(register)

	if instance:GetAttribute("Unlocked") == nil then
		instance:SetAttribute("Unlocked", false)
	end

	return function()
		connection:Disconnect()
		cancelPendingTasks(instance)
		originalData[instance] = nil
	end
end

function SummonModelUtil.FindUnlockable(name: string): Instance?
	assert(name, "SummonModelUtil.FindUnlockable - name expected, got nil")

	for _, instance in CollectionService:GetTagged(UNLOCKABLE_TAG) do
		if instance.Name == name then
			return instance
		end
	end

	return nil
end

function SummonModelUtil.AppearModel(instance: Instance)
	cancelPendingTasks(instance)

	local cache = originalData[instance]
	if not cache then
		warn("SummonModelUtil.AppearModel - No cached data for: " .. instance:GetFullName())
		return
	end

	-->! Force everything hidden first to ensure tweens start from a uniform invisible state
	for _, obj in cache.partList do
		if obj:IsA("BasePart") then
			(obj :: BasePart).Transparency = 1
			(obj :: BasePart).CanCollide = false
		elseif obj:IsA("Decal") or obj:IsA("Texture") then
			(obj :: Decal).Transparency = 1
		end
	end

	if GeneralConfig.Model_AnimationsOn == true then
		local tasks: { thread } = {}
		pendingTasks[instance] = tasks

		for i, obj in ipairs(cache.partList) do
			local snapshot = cache.partData[obj]
			local delayTime = if GeneralConfig.Model_UseStaggeredAnimation then (i - 1) * STAGGER_DELAY else 0
			local handle = task.delay(delayTime, function()
				if not obj.Parent then return end

				playTween(obj, { Transparency = snapshot.Transparency })

				-->! Delay restoring collisions until the visual tween finishes
				-->! so players do not hit invisible geometry during the fade in
				if obj:IsA("BasePart") and snapshot.CanCollide then
					local colHandle = task.delay(TWEEN_INFO.Time, function()
						if obj.Parent then
							(obj :: BasePart).CanCollide = snapshot.CanCollide
						end
					end)
					table.insert(tasks, colHandle)
				end
			end)
			table.insert(tasks, handle)
		end
	else
		for _, obj in cache.partList do
			local snapshot = cache.partData[obj]
			if not snapshot then continue end

			if obj:IsA("BasePart") then
				(obj :: BasePart).Transparency = snapshot.Transparency;
				(obj :: BasePart).CanCollide = snapshot.CanCollide :: boolean
			elseif obj:IsA("Decal") or obj:IsA("Texture") then
				(obj :: Decal).Transparency = snapshot.Transparency
			end
		end
	end

	instance:SetAttribute("Unlocked", true)
end

function SummonModelUtil.DisappearModel(instance: Instance)
	cancelPendingTasks(instance)

	local cache = originalData[instance]
	if not cache then
		warn("SummonModelUtil.DisappearModel - No cached data for: " .. instance:GetFullName())
		return
	end

	if GeneralConfig.Model_AnimationsOn == true then
		local tasks: { thread } = {}
		pendingTasks[instance] = tasks

		for i, obj in ipairs(cache.partList) do
			local delayTime = if GeneralConfig.Model_UseStaggeredAnimation then (i - 1) * STAGGER_DELAY else 0
			local handle = task.delay(delayTime, function()
				if not obj.Parent then return end

				-->! Disable collision immediately before fading out
				-->! to prevent players standing on disappearing geometry
				if obj:IsA("BasePart") then
					(obj :: BasePart).CanCollide = false
				end

				playTween(obj, { Transparency = 1 })
			end)
			table.insert(tasks, handle)
		end
	else
		for _, obj in cache.partList do
			if obj:IsA("BasePart") then
				(obj :: BasePart).Transparency = 1
				(obj :: BasePart).CanCollide = false
			elseif obj:IsA("Decal") or obj:IsA("Texture") then
				(obj :: Decal).Transparency = 1
			end
		end
	end

	instance:SetAttribute("Unlocked", false)
end

function SummonModelUtil.Summon(modelName: string): Instance?
	assert(modelName, "SummonModelUtil.Summon - modelName expected, got nil")

	local instance = SummonModelUtil.FindUnlockable(modelName)
	if not instance then
		warn("SummonModelUtil.Summon - No unlockable found with name: " .. modelName)
		return nil
	end

	if instance:GetAttribute("Unlocked") == true then
		return instance
	end

	SummonModelUtil.AppearModel(instance)

	return instance
end

function SummonModelUtil.ExecuteAction(modelName: string, action: string): Instance?
	assert(modelName, "SummonModelUtil.ExecuteAction - modelName expected, got nil")
	assert(action, "SummonModelUtil.ExecuteAction - action expected, got nil")

	local instance = SummonModelUtil.FindUnlockable(modelName)
	if not instance then
		warn("SummonModelUtil.ExecuteAction - No unlockable found with name: " .. modelName)
		return nil
	end

	if action == "Appear" then
		if instance:GetAttribute("Unlocked") == true then
			return instance
		end
		SummonModelUtil.AppearModel(instance)
	elseif action == "Disappear" then
		if instance:GetAttribute("Unlocked") == false then
			return instance
		end
		SummonModelUtil.DisappearModel(instance)
	else
		warn("SummonModelUtil.ExecuteAction - Unknown action: " .. action)
	end

	return instance
end

--//Return
return SummonModelUtil