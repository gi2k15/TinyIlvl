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

local f = CreateFrame("Frame")
local iLvlText = {}

local function UpdateLevels()
	print("Teste")
	local _, averageILvl = GetAverageItemLevel()
	for k = 1, 17 do
		if slot[k] then
			if not iLvlText[k] then
				iLvlText[k] = f:CreateFontString(nil, "OVERLAY", "GameFontNormalOutline")
			end	
			local itemLocation = ItemLocation:CreateFromEquipmentSlot(k)
			if itemLocation:IsValid() then 
				local itemLevel = C_Item.GetCurrentItemLevel(itemLocation)
				--local itemLevel = GetDetailedItemLevelInfo(itemID)
				iLvlText[k].color = CreateColor(ColorGradient(itemLevel / averageILvl - 0.5, 1,0,0, 1,1,0, 0,1,0)) 
				iLvlText[k]:SetText(iLvlText[k].color:WrapTextInColorCode(itemLevel))
				iLvlText[k]:SetPoint("BOTTOM", "Character" .. slot[k] .. "Slot", "BOTTOM", 0, 2)
			elseif iLvlText[k] then
				iLvlText[k]:SetText("")
			end
		end
	end
end

f:RegisterEvent("ITEM_LOCK_CHANGED")
f:SetScript("OnEvent", function()
	UpdateLevels()
end)
PaperDollItemsFrame:HookScript("OnShow", function(self)
	f:SetParent(self)
	UpdateLevels()
end)