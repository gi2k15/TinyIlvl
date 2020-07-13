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

local function ColorGradient(perc, ...)
-- Function retrieved from Wowpedia. https://wow.gamepedia.com/ColorGradient
-- CC BY-SA 3.0
	if perc >= 1 then
		local r, g, b = select(select('#', ...) - 2, ...)
		return r, g, b
	elseif perc <= 0 then
		local r, g, b = ...
		return r, g, b
	end
	
	local num = select('#', ...) / 3
	
	local segment, relperc = math.modf(perc*(num-1))
	local r1, g1, b1, r2, g2, b2 = select((segment*3)+1, ...)
	
	return r1 + (r2-r1)*relperc, g1 + (g2-g1)*relperc, b1 + (b2-b1)*relperc
end

local f = {
	player = CreateFrame("Frame"),
	target = CreateFrame("Frame"),
}
local iLvlText = {}

local function GetLevels(target)
	iLvlText[target] = {}
	local button
	if target == "player" then
		button = "Character"
	else
		button = "Inspect"
	end
	local _, averageILvl = GetAverageItemLevel()
	for k = 1, 17 do
		if slot[k] then
			if not iLvlText[target][k] then
				iLvlText[target][k] = f[target]:CreateFontString(nil, "OVERLAY", "GameFontNormalOutline")
			end	
			local itemLink = GetInventoryItemLink(target, k)
			if itemLink then 
				local itemLevel = GetDetailedItemLevelInfo(itemLink)
				local itemQuality = GetInventoryItemQuality(target, k)
				iLvlText[target][k].color = CreateColor(ColorGradient(itemLevel / averageILvl - 0.5, 1,0,0, 1,1,0, 0,1,0)) 
				iLvlText[target][k]:SetText(iLvlText[target][k].color:WrapTextInColorCode(itemLevel))
				if k == 2 and itemQuality == 6 then
					iLvlText[target][k]:SetPoint("TOP", button .. slot[k] .. "Slot", "TOP", 0, -2)
					print("Artifact")
				else
					iLvlText[target][k]:SetPoint("BOTTOM", button .. slot[k] .. "Slot", "BOTTOM", 0, 2)
				end
			elseif iLvlText[target][k] then
				iLvlText[target][k]:SetText("")
			end
		end
	end
end

f.player:RegisterEvent("ITEM_LOCK_CHANGED")
f.player:SetScript("OnEvent", function(self, event)
	GetLevels("player")
end)
PaperDollItemsFrame:HookScript("OnShow", function(self)
	f.player:SetParent(self)
	GetLevels("player")
end)

f.target:RegisterEvent("INSPECT_READY")
f.target:SetScript("OnEvent", function(self)
	--self:UnregisterEvent("INSPECT_READY")
	f.target:SetParent(InspectPaperDollItemsFrame)
	GetLevels("target")
end)