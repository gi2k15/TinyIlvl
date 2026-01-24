local slot = {
	[1] = "Head",
	[2] = "Neck",
	[3] = "Shoulder",
	[5] = "Chest",
	[6] = "Waist",
	[7] = "Legs",
	[8] = "Feet",
	[9] = "Wrist",
	[10] = "Hands",
	[11] = "Finger0",
	[12] = "Finger1",
	[13] = "Trinket0",
	[14] = "Trinket1",
	[15] = "Back",
	[16] = "MainHand",
	[17] = "SecondaryHand"
}

local f = {
	player = CreateFrame("Frame"),
	target = CreateFrame("Frame"),
	bags = CreateFrame("Frame"),
}
f.player:SetParent(PaperDollItemsFrame)

local iLvlText = {
	player = {},
	target = {},
}

local scanTooltip = CreateFrame("GameTooltip", "Inspect_ilvlScanTooltip", nil, "GameTooltipTemplate")

local function GetItemLevelFromTooltip(unit, slotId, itemLink)
	local label = ITEM_LEVEL and ITEM_LEVEL:gsub("%%d", "") or "Item Level "
	scanTooltip:SetOwner(UIParent, "ANCHOR_NONE")
	scanTooltip:ClearLines()
	if unit and slotId then
		scanTooltip:SetInventoryItem(unit, slotId)
	elseif itemLink then
		scanTooltip:SetHyperlink(itemLink)
	end
	for i = 1, scanTooltip:NumLines() do
		local line = _G[scanTooltip:GetName() .. "TextLeft" .. i]
		local text = line and line:GetText()
		if text and text:find(label, 1, true) then
			local level = tonumber(text:match("(%d+)"))
			if level then
				scanTooltip:Hide()
				return level
			end
		end
	end
	scanTooltip:Hide()
	return nil
end

local function GetLevels(target)
	local button
	if target == "player" then
		button = "Character"
	else
		button = "Inspect"
		if not iLvlText[target].ilvl then
			iLvlText[target].ilvl = f.target:CreateFontString(nil, "OVERLAY", "GameFontNormalOutline")
		end
		iLvlText[target].ilvl:SetText("ilvl " .. C_PaperDollInfo.GetInspectItemLevel(target))
		iLvlText[target].ilvl:SetPoint("RIGHT", InspectPaperDollItemsFrame, "TOPRIGHT", -5, -45)
	end
	-- Prefer displayed ilvl (character sheet) and fall back to average API.
	local averageILvl = C_PaperDollInfo.GetInspectItemLevel(target)
	if not averageILvl or averageILvl <= 0 then
		local avgItemLevel, avgItemLevelEquipped, avgItemLevelPvp = GetAverageItemLevel()
		averageILvl = avgItemLevelEquipped or 0
	end
	
	for k = 1, 17 do
		if slot[k] then
			if not iLvlText[target][k] then
				iLvlText[target][k] = f[target]:CreateFontString(nil, "OVERLAY", "GameFontNormalOutline")
			end	
			local itemLink = GetInventoryItemLink(target, k)
			if itemLink then 
				local effectiveILvl = GetItemLevelFromTooltip(target, k, itemLink)
				if not effectiveILvl then
					effectiveILvl = GetDetailedItemLevelInfo(itemLink)
				end
				local itemQuality = GetInventoryItemQuality(target, k)
				if effectiveILvl and averageILvl > 0 then
					local r, g, b = GetItemQualityColor(itemQuality)
					iLvlText[target][k].color = CreateColor(r, g, b)
					iLvlText[target][k]:SetText(iLvlText[target][k].color:WrapTextInColorCode(effectiveILvl))
				else
					iLvlText[target][k]:SetText("")
				end
				if k == 2 and itemQuality == 6 and target == "player" then
					iLvlText[target][k]:SetPoint("TOP", button .. slot[k] .. "Slot", "TOP", 0, -2)
				else
					iLvlText[target][k]:SetPoint("BOTTOM", button .. slot[k] .. "Slot", "BOTTOM", 0, 2)
				end
			elseif iLvlText[target][k] then
				iLvlText[target][k]:SetText("")
			end
		end
	end
end

-- Character
f.player:RegisterEvent("ITEM_UNLOCKED")
f.player:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
f.player:SetScript("OnEvent", function()
    GetLevels("player")
end)

PaperDollItemsFrame:HookScript("OnShow", function()
    GetLevels("player")
end)

-- Inspect
f.target:RegisterEvent("ADDON_LOADED")
f.target:RegisterEvent("INSPECT_READY")
f.target:SetScript("OnEvent", function(self, event, ...)
	if event == "ADDON_LOADED" and ... == "Blizzard_InspectUI" then
		self:SetParent(InspectPaperDollItemsFrame)
		self:UnregisterEvent("ADDON_LOADED")
	elseif event == "INSPECT_READY" and InspectPaperDollItemsFrame then
		GetLevels("target")
	end
end)

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
