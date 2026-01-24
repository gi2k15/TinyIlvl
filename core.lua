local addonName, addon = ...
addon = addon or {}
_G.TinyIlvl = addon

addon.slot = {
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

addon.scanTooltip = CreateFrame("GameTooltip", "TinyIlvlScanTooltip", nil, "GameTooltipTemplate")

function addon.GetItemLevelFromTooltip(unit, slotId, itemLink)
	local label = ITEM_LEVEL and ITEM_LEVEL:gsub("%%d", "") or "Item Level "
	addon.scanTooltip:SetOwner(UIParent, "ANCHOR_NONE")
	addon.scanTooltip:ClearLines()
	if unit and slotId then
		addon.scanTooltip:SetInventoryItem(unit, slotId)
	elseif itemLink then
		addon.scanTooltip:SetHyperlink(itemLink)
	end
	for i = 1, addon.scanTooltip:NumLines() do
		local line = _G[addon.scanTooltip:GetName() .. "TextLeft" .. i]
		local text = line and line:GetText()
		if text and text:find(label, 1, true) then
			local level = tonumber(text:match("(%d+)"))
			if level then
				addon.scanTooltip:Hide()
				return level
			end
		end
	end
	addon.scanTooltip:Hide()
	return nil
end
