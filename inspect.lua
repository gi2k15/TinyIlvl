local addonName, addon = ...
local slot = addon.slot
local GetItemLevelFromTooltip = addon.GetItemLevelFromTooltip

local f = {
	player = CreateFrame("Frame"),
	target = CreateFrame("Frame"),
}
f.player:SetParent(PaperDollItemsFrame)

local iLvlText = {
	player = {},
	target = {},
}

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
