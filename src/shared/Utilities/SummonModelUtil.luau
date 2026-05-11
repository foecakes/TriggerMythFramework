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
local UNLOCKABLE_TAG = GeneralConfig.Model_UnlockableTag
local TWEEN_INFO = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

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
--[[
	cancelPendingTasks – Cancels every scheduled task.delay handle associated
	with the given instance, preventing stale animations from interfering.
]]
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

--[[
	playTween – Creates, plays and auto-destroys a single tween on `obj`.
	Automatically cancels any existing tween on the same object.
]]
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
--[[
	InitModel – Snapshots the original Transparency and CanCollide of every
	descendant, then immediately hides the instance (Transparency = 1,
	CanCollide = false). Should be called once per tagged instance at startup.
	Returns a cleanup function to disconnect listeners.
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

	-->! Register existing descendants
	register(instance)
	for _, desc in instance:GetDescendants() do
		register(desc)
	end

	-->! Listen for late-arriving descendants (StreamingEnabled support)
	local connection: RBXScriptConnection? = instance.DescendantAdded:Connect(register)

	-->! Mark as locked if not already set
	if instance:GetAttribute("Unlocked") == nil then
		instance:SetAttribute("Unlocked", false)
	end

	return function()
		if connection then
			connection:Disconnect()
			connection = nil
		end
		cancelPendingTasks(instance)
		originalData[instance] = nil
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
	visual state.
	-> Transparency tweens from 1 -> original.
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
		-->! Tween each part back to its original transparency
		local tasks: { thread } = {}
		pendingTasks[instance] = tasks

		for _, obj in ipairs(cache.partList) do
			local snapshot = cache.partData[obj]
			local handle = task.delay(0, function()
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
	per-part tween.
	-> CanCollide is disabled immediately (prevents interaction during fade-out).
	-> Transparency tweens from current -> 1.
	-> Sets the "Unlocked" attribute to false.
]]
function SummonModelUtil.DisappearModel(instance: Instance)
	cancelPendingTasks(instance)

	local cache = originalData[instance]
	if not cache then
		warn("SummonModelUtil.DisappearModel - No cached data for: " .. instance:GetFullName())
		return
	end

	if GeneralConfig.Model_AnimationsOn == true then
		-->! Tween each part to hidden
		local tasks: { thread } = {}
		pendingTasks[instance] = tasks

		for _, obj in ipairs(cache.partList) do
			local handle = task.delay(0, function()
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

--[[
	ExecuteAction – High-level method that finds an "UnlockableModel"-tagged
	instance by name and executes the given action ("Appear" or "Disappear").
	Skips if the instance is already in the target state.
	Returns the instance if found, nil otherwise.
]]
function SummonModelUtil.ExecuteAction(modelName: string, action: string): Instance?
	assert(modelName, "SummonModelUtil.ExecuteAction - modelName expected, got nil")
	assert(action, "SummonModelUtil.ExecuteAction - action expected, got nil")

	-->! Find the tagged instance by name
	local instance = SummonModelUtil.FindUnlockable(modelName)
	if not instance then
		warn("SummonModelUtil.ExecuteAction - No unlockable found with name: " .. modelName)
		return nil
	end

	if action == "Appear" then
		-->! Skip if already unlocked
		if instance:GetAttribute("Unlocked") == true then
			return instance
		end
		SummonModelUtil.AppearModel(instance)
	elseif action == "Disappear" then
		-->! Skip if already locked
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