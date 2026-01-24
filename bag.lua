local addonName, addon = ...
local GetItemLevelFromTooltip = addon.GetItemLevelFromTooltip

local f = {
	bags = CreateFrame("Frame"),
}

local function EnsureBagQualityText(button)
	if button.TinyIlvlQualityText then
		return button.TinyIlvlQualityText
	end
	local text = button:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
	text:SetDrawLayer("OVERLAY", 7)
	text:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -3)
	text:SetJustifyH("LEFT")
	text:SetShadowColor(0, 0, 0, 1)
	text:SetShadowOffset(1, -1)
	button.TinyIlvlQualityText = text
	return text
end

local function GetBagFrameButtons(frame)
	if frame.GetItemButtons then
		return frame:GetItemButtons()
	end
	if frame.itemButtons then
		return frame.itemButtons
	end
	if frame.Items then
		return frame.Items
	end
	return nil
end

local function GetBagSlotFromButton(button, frame)
	local bag = button.bagID
	if not bag and button.GetBagID then
		bag = button:GetBagID()
	end
	if not bag and frame and frame.GetID then
		bag = frame:GetID()
	end
	local slot = button.slotID
	if not slot and button.GetSlot then
		slot = button:GetSlot()
	end
	if not slot and button.GetID then
		slot = button:GetID()
	end
	return bag, slot
end

local function UpdateBagFrameQuality(frame)
	if not frame or not C_Container then
		return
	end
	local buttons = GetBagFrameButtons(frame)
	if buttons then
		for _, button in ipairs(buttons) do
			local bag, slotId = GetBagSlotFromButton(button, frame)
			if bag and slotId then
				local text = EnsureBagQualityText(button)
				local itemLink = C_Container.GetContainerItemLink(bag, slotId)
				if itemLink and IsEquippableItem(itemLink) then
					local effectiveILvl = GetItemLevelFromTooltip(nil, nil, itemLink)
					if not effectiveILvl then
						effectiveILvl = GetDetailedItemLevelInfo(itemLink)
					end
					if effectiveILvl then
						text:SetText(effectiveILvl)
						local info = C_Container.GetContainerItemInfo(bag, slotId)
						if info and info.quality then
							local r, g, b = GetItemQualityColor(info.quality)
							text:SetTextColor(r, g, b)
						end
					else
						text:SetText("")
					end
				else
					text:SetText("")
				end
			end
		end
		return
	end
	local bag = frame.GetID and frame:GetID() or nil
	if not bag then
		return
	end
	local size = frame.size or C_Container.GetContainerNumSlots(bag)
	if not size or size <= 0 then
		return
	end
	for slotId = 1, size do
		local button = _G[frame:GetName() .. "Item" .. slotId]
		if button then
			local text = EnsureBagQualityText(button)
			local itemLink = C_Container.GetContainerItemLink(bag, slotId)
			if itemLink then
				local effectiveILvl = GetItemLevelFromTooltip(nil, nil, itemLink)
				if not effectiveILvl then
					effectiveILvl = GetDetailedItemLevelInfo(itemLink)
				end
				if effectiveILvl then
					text:SetText(effectiveILvl)
					local info = C_Container.GetContainerItemInfo(bag, slotId)
					if info and info.quality then
						local r, g, b = GetItemQualityColor(info.quality)
						text:SetTextColor(r, g, b)
					end
				else
					text:SetText("")
				end
			else
				text:SetText("")
			end
		end
	end
end

local function UpdateAllBagFrameQuality()
	if not C_Container then
		return
	end
	if ContainerFrameCombinedBags and ContainerFrameCombinedBags:IsShown() then
		UpdateBagFrameQuality(ContainerFrameCombinedBags)
	end
	for i = 1, NUM_CONTAINER_FRAMES do
		local frame = _G["ContainerFrame" .. i]
		if frame and frame:IsShown() then
			UpdateBagFrameQuality(frame)
		end
	end
end

local function HookBagFrames()
	if type(ContainerFrame_Update) == "function" then
		hooksecurefunc("ContainerFrame_Update", UpdateBagFrameQuality)
	end
	if type(ContainerFrame_OnShow) == "function" then
		hooksecurefunc("ContainerFrame_OnShow", UpdateBagFrameQuality)
	end
	if ContainerFrameCombinedBags and not ContainerFrameCombinedBags.TinyIlvlHooked then
		ContainerFrameCombinedBags:HookScript("OnShow", UpdateBagFrameQuality)
		ContainerFrameCombinedBags.TinyIlvlHooked = true
	end
	for i = 1, NUM_CONTAINER_FRAMES do
		local frame = _G["ContainerFrame" .. i]
		if frame and not frame.TinyIlvlHooked then
			frame:HookScript("OnShow", UpdateBagFrameQuality)
			frame.TinyIlvlHooked = true
		end
	end
	UpdateAllBagFrameQuality()
end

f.bags:RegisterEvent("ADDON_LOADED")
f.bags:RegisterEvent("BAG_UPDATE_DELAYED")
f.bags:RegisterEvent("PLAYER_ENTERING_WORLD")
f.bags:SetScript("OnEvent", function(self, event, ...)
	if event == "ADDON_LOADED" and ... == "Blizzard_Bags" then
		HookBagFrames()
	elseif event == "PLAYER_ENTERING_WORLD" then
		HookBagFrames()
	else
		UpdateAllBagFrameQuality()
	end
end)
