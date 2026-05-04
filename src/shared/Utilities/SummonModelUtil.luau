--!strict
--[[
	SummonModelUtil
	Author: @FoeCakes

	Utility module for revealing and hiding Models/Folders tagged with "UnlockableModel".
	Instead of cloning templates, this module operates on instances that already exist
	in the workspace. "Summoning" tweens every BasePart, Decal and Texture from fully
	transparent (and non-collidable) to their original cached state, and vice-versa.

	Public API:
		InitModel(instance)        -> Cache original visual state and hide the instance.
		FindUnlockable(name)       -> Locate a tagged instance by name.
		AppearModel(instance)      -> Tween the instance into visibility; sets Unlocked = true.
		DisappearModel(instance)   -> Tween the instance back to hidden; sets Unlocked = false.
		Summon(modelName)          -> Find by name + AppearModel. Returns the instance.
]]

--//Services
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local GeneralConfig = require(ReplicatedStorage.Shared.Constants.GeneralConfig)

--//Constants
local UNLOCKABLE_TAG = GeneralConfig.UnlockableTag
local TWEEN_INFO = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local STAGGER_DELAY = 0.02

--//Types
type PartSnapshot = {
	Transparency: number,
	CanCollide: boolean?, --> Only stored for BaseParts
}

type ModelCache = {
	partData: { [Instance]: PartSnapshot },
	partList: { Instance },
}

--//Constructor
local SummonModelUtil = {}

--//Cache
--[[
	originalData – Stores the original visual state for every tagged instance.
	Weak-keyed to allow for the garbage collector to do its job.
]]
local originalData: { [Instance]: ModelCache } = {}
setmetatable(originalData :: any, { __mode = "k" })

--[[
	pendingTasks – Per-instance list of scheduled task handles so animations
	can be cancelled cleanly when a new animation is requested.
]]
local pendingTasks: { [Instance]: { thread } } = {}
setmetatable(pendingTasks :: any, { __mode = "k" })

--//Helpers
--[[
	cancelPendingTasks – Cancels every scheduled task.delay handle associated
	with the given instance, preventing stale animations from interfering.
]]
local function cancelPendingTasks(instance: Instance)
	local tasks = pendingTasks[instance]
	if not tasks then return end
	for _, t in tasks do
		task.cancel(t)
	end
	pendingTasks[instance] = nil
end

--[[
	playTween – Creates, plays and auto-destroys a single tween on `obj`.
]]
local function playTween(obj: Instance, tweenGoals: { [string]: any })
	local tween = TweenService:Create(obj, TWEEN_INFO, tweenGoals)
	tween.Completed:Once(function()
		tween:Destroy()
	end)
	tween:Play()
end

--//Public methods

--[[
	InitModel – Snapshots the original Transparency and CanCollide of every
	descendant, then immediately hides the instance (Transparency = 1,
	CanCollide = false). Should be called once per tagged instance at startup.
]]
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

			-->! Hide immediately if model is not yet unlocked
			if instance:GetAttribute("Unlocked") ~= true then
				(obj :: BasePart).Transparency = 1
				(obj :: BasePart).CanCollide = false
			end
		elseif obj:IsA("Decal") or obj:IsA("Texture") then
			data[obj] = {
				Transparency = (obj :: Decal).Transparency,
			}
			table.insert(list, obj)

			-->! Hide immediately if model is not yet unlocked
			if instance:GetAttribute("Unlocked") ~= true then
				(obj :: Decal).Transparency = 1
			end
		end
	end

	-->! Register existing descendants
	register(instance)
	for _, desc in instance:GetDescendants() do
		register(desc)
	end

	-->! Listen for late-arriving descendants (StreamingEnabled support)
	instance.DescendantAdded:Connect(register)

	-->! Mark as locked if not already set
	if instance:GetAttribute("Unlocked") == nil then
		instance:SetAttribute("Unlocked", false)
	end
end

--[[
	FindUnlockable – Iterates every instance tagged "UnlockableModel" and
	returns the first one whose Name matches `name`. Returns nil if none found.
]]
function SummonModelUtil.FindUnlockable(name: string): Instance?
	assert(name, "SummonModelUtil.FindUnlockable - name expected, got nil")

	for _, instance in CollectionService:GetTagged(UNLOCKABLE_TAG) do
		if instance.Name == name then
			return instance
		end
	end

	return nil
end

--[[
	AppearModel – Tweens a tagged Model/Folder from hidden to its original
	visual state with a staggered per-part delay.
	-> Transparency tweens from 1 → original.
	-> CanCollide is restored to its original value AFTER the tween finishes
	   (so players don't collide with invisible geometry). Parts that were
	   originally non-collidable stay non-collidable.
	-> Sets the "Unlocked" attribute to true.
]]
function SummonModelUtil.AppearModel(instance: Instance)
	cancelPendingTasks(instance)

	local cache = originalData[instance]
	if not cache then
		warn("SummonModelUtil.AppearModel - No cached data for: " .. instance:GetFullName())
		return
	end

	-->! Ensure everything starts fully hidden
	for _, obj in cache.partList do
		if obj:IsA("BasePart") then
			(obj :: BasePart).Transparency = 1
			(obj :: BasePart).CanCollide = false
		elseif obj:IsA("Decal") or obj:IsA("Texture") then
			(obj :: Decal).Transparency = 1
		end
	end

	if GeneralConfig.AnimationsOn == true then
		-->! Staggered tween each part back to its original transparency
		local tasks: { thread } = {}
		pendingTasks[instance] = tasks

		for i, obj in ipairs(cache.partList) do
			local snapshot = cache.partData[obj]
			local handle = task.delay((i - 1) * STAGGER_DELAY, function()
				if not obj.Parent then return end

				playTween(obj, { Transparency = snapshot.Transparency })

				-->! Restore CanCollide after the tween finishes (only if originally true)
				if obj:IsA("BasePart") and snapshot.CanCollide then
					task.delay(TWEEN_INFO.Time, function()
						if obj.Parent then
							(obj :: BasePart).CanCollide = snapshot.CanCollide
						end
					end)
				end
			end)
			table.insert(tasks, handle)
		end
	else
		-->! Immediately restore each part to its original state (no animation)
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

	-->! Mark as unlocked
	instance:SetAttribute("Unlocked", true)
end

--[[
	DisappearModel – Tweens a tagged Model/Folder back to hidden with a
	staggered per-part delay.
	-> CanCollide is disabled immediately (prevents interaction during fade-out).
	-> Transparency tweens from current → 1.
	-> Sets the "Unlocked" attribute to false.
]]
function SummonModelUtil.DisappearModel(instance: Instance)
	cancelPendingTasks(instance)

	local cache = originalData[instance]
	if not cache then
		warn("SummonModelUtil.DisappearModel - No cached data for: " .. instance:GetFullName())
		return
	end

	if GeneralConfig.AnimationsOn == true then
		-->! Staggered tween each part to hidden
		local tasks: { thread } = {}
		pendingTasks[instance] = tasks

		for i, obj in ipairs(cache.partList) do
			local handle = task.delay((i - 1) * STAGGER_DELAY, function()
				if not obj.Parent then return end

				-->! Disable collision immediately so players can't interact during fade
				if obj:IsA("BasePart") then
					(obj :: BasePart).CanCollide = false
				end

				playTween(obj, { Transparency = 1 })
			end)
			table.insert(tasks, handle)
		end
	else
		-->! Immediately hide each part (no animation)
		for _, obj in cache.partList do
			if obj:IsA("BasePart") then
				(obj :: BasePart).Transparency = 1
				(obj :: BasePart).CanCollide = false
			elseif obj:IsA("Decal") or obj:IsA("Texture") then
				(obj :: Decal).Transparency = 1
			end
		end
	end

	-->! Mark as locked
	instance:SetAttribute("Unlocked", false)
end

--[[
	Summon – High-level convenience method. Finds an "UnlockableModel"-tagged
	instance by name and plays the appear animation on it.
	Skips re-summoning if the instance is already unlocked.
	Returns the instance if found, nil otherwise.
]]
function SummonModelUtil.Summon(modelName: string): Instance?
	assert(modelName, "SummonModelUtil.Summon - modelName expected, got nil")

	-->! Find the tagged instance by name
	local instance = SummonModelUtil.FindUnlockable(modelName)
	if not instance then
		warn("SummonModelUtil.Summon - No unlockable found with name: " .. modelName)
		return nil
	end

	-->! Skip if already unlocked
	if instance:GetAttribute("Unlocked") == true then
		return instance
	end

	-->! Play appear animation
	SummonModelUtil.AppearModel(instance)

	return instance
end

--//Return
return SummonModelUtil