BINDING_HEADER_EasyRess = "EasyRess"
BINDING_NAME_EasyRess = "EasyRess"
BINDING_NAME_EasyDrink = "EasyDrink"


local easyresstable = {}
local prodpstable = {}
local clientSupported = false
local isCasting = false
local isInformed = false

if (GetLocale() == "deDE" ) then
	easyresstable = {
		PRIEST = "Auferstehung",	
		MAGE = "Wasser herbeizaubern",
		SHAMAN = "Geist der Ahnen",
	}
	
	--clientSupported = true
elseif (GetLocale() == "enUS" or GetLocale() == "enGB") then
	easyresstable = {		
		PRIEST = "Resurrection",
		MAGE = "Conjure Water",		
		SHAMAN = "Ancestral Spirit",
	}
	
	clientSupported = true
end

SLASH_EASYRESS1 = '/easyRess'
SLASH_EASYDRINK1 = '/easyDrink'


local _, easyRessEnglishClass = UnitClass("player");

local function getup() 
	-- check if character is drinking
	for buff = 0,31 do
		local texture = GetPlayerBuffTexture(buff)
		
		if texture then
			if string.find(texture, "_Drink_") then
				SitOrStand()	
				return
			end
		else
			return
		end
	end	
end

local function nameFromItemlink(itemlink)
	if itemlink then
		pattern = "[[].*[]]"

		x,y =  string.find(itemlink,pattern)
		name =  strsub(itemlink, x + 1, y - 1)
		
		return name
	else 
		return nil
	end
end

local priorities = {
	["Conjured Crystal Water"] = 100,	
	["Blessed Sunfruit Juice"] = 90,
	["Conjured Sparkling Water"] = 80,
	["Morning Glory Dew"] = 79,
	["Conjured Mineral Water"] = 60,
	["Conjured Spring Water"] = 50,
	["Conjured Purified Water"] = 40,	
	["Conjured Fresh Water"] = 30,
	["Conjured Water"] = 20,
}

local function maxWater()
	local b, s = nil
	local currPrio = 0
		
	for bag = 0,4 do		
		for slot = 1,GetContainerNumSlots(bag) do		
			local itemLink = GetContainerItemLink(bag, slot)
			local itemName = nameFromItemlink(itemLink)
			
			
			if itemName and priorities[itemName] 
				and priorities[itemName] > currPrio then
			
				b, s = bag, slot	
				currPrio = priorities[itemName]
			end
		end
	end
	
	return b, s
end

function easyDrink()
	local b, s = maxWater()	
	UseContainerItem(b,s)
end

function easyRess() 	
	if not clientSupported then
		DEFAULT_CHAT_FRAME:AddMessage("EasyRess does not support your client!")
		return
	elseif not easyresstable[easyRessEnglishClass] then
		DEFAULT_CHAT_FRAME:AddMessage("EasyRess does not support your class!")
		return
	elseif isCasting then	
		if not isInformed then
			DEFAULT_CHAT_FRAME:AddMessage("EasyRess does not interrupt your casting!")
			isInformed = true
		end		
		return
	end

	-- stand up if "drink" texture found in buffs
	getup()
	
	local b, s = maxWater()
	if not (b and s) then	
		DEFAULT_CHAT_FRAME:AddMessage("EasyRess couldn't find any water!")
	else		
		UseContainerItem(b, s)		
	end	
	
	CastSpellByName(easyresstable[easyRessEnglishClass])	
end


function SlashCmdList.EASYRESS(msg, editbox)
	easyRess()
end

function SlashCmdList.EASYDRINK(msg, editbox)
	easyDrink()
end

local function onEvent() 
	if event == "SPELLCAST_START"  or event == "SPELLCAST_CHANNEL_START" then
		isCasting = true
	elseif event == "SPELLCAST_STOP" or event == "SPELLCAST_CHANNEL_STOP" 
		or event == "SPELLCAST_INTERRUPTED" or event == "SPELLCAST_FAILED" then
		isCasting = false
	end	
end

local frame pcf = CreateFrame("frame")
pcf:RegisterEvent("SPELLCAST_START")
pcf:RegisterEvent("SPELLCAST_CHANNEL_START")
pcf:RegisterEvent("SPELLCAST_STOP")
pcf:RegisterEvent("SPELLCAST_CHANNEL_STOP")

pcf:RegisterEvent("SPELLCAST_INTERRUPTED")
pcf:RegisterEvent("SPELLCAST_FAILED")

pcf:SetScript("OnEvent", onEvent)