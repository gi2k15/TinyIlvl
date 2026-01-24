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
}
f.player:SetParent(PaperDollItemsFrame)

local iLvlText = {
	player = {},
	target = {},
}

local scanTooltip = CreateFrame("GameTooltip", "Inspect_ilvlScanTooltip", nil, "GameTooltipTemplate")

local function ColorGradient(perc, r1,g1,b1, r2,g2,b2, r3,g3,b3)
    if perc >= 1 then
        return r3, g3, b3
    elseif perc <= 0 then
        return r1, g1, b1
    end

    local segment, relperc = math.modf(perc * 2)
    local rr1, rg1, rb1, rr2, rg2, rb2 = select((segment * 3) + 1, r1,g1,b1, r2,g2,b2, r3,g3,b3)

    return rr1 + (rr2 - rr1) * relperc, rg1 + (rg2 - rg1) * relperc, rb1 + (rb2 - rb1) * relperc
end

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
					iLvlText[target][k].color = CreateColor(ColorGradient(effectiveILvl / averageILvl - 0.5, 1,0,0, 1,1,0, 0,1,0)) -- red, yellow, green
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
