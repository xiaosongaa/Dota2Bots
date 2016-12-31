local utils = require(GetScriptDirectory() .. "/util")
local build = require(GetScriptDirectory() .. "/builds/item_build_" .. string.gsub(GetBot():GetUnitName(), "npc_dota_hero_", ""))
if build == "NOT IMPLEMENTED" then return end
----------------------------------------------------------------------------------------------------

--[[ Set up your skill build. ]]
local BotAbilityPriority = build["skills"]

--[[ Set up your item build.  Remember to use base items.  
To build an derived item like item_magic_wand you will just 
buy the four base items so take care to get items in your 
inventory in the correct order! ]]

local tableItemsToBuy = build["items"]


----------------------------------------------------------------------------------------------------

-- Think function for spending skill points
local function ThinkLvlupAbility(level)
    -- Do I have a skill point?
    --print (#BotAbilityPriority .. " > " .. "25 - " .. utils.GetHeroLevel())
    if (#BotAbilityPriority > (25 - utils.GetHeroLevel())) then  
        local ability_name = BotAbilityPriority[1];
        -- Can I slot a skill with this skill point?
        if(ability_name ~="-1")
        then
            local ability = GetBot():GetAbilityByName(ability_name);
            -- Check if its a legit upgrade
            if( ability:CanAbilityBeUpgraded() and ability:GetLevel() < ability:GetMaxLevel())  
            then
                local currentLevel = ability:GetLevel();
                GetBot():Action_LevelAbility(BotAbilityPriority[1]);
                if ability:GetLevel() > currentLevel then
                    --print("Skill: "..ability_name.."  upgraded!");
                    table.remove(BotAbilityPriority,1)
                else
                    --print("Skill: "..ability_name.." upgrade failed?!?");
                    end
            end 
        else
            table.remove(BotAbilityPriority,1)
        end
	end
end

----------------------------------------------------------------------------------------------------

-- Think function to purchase the items and call the skill point think
function ItemPurchaseThink()
    local npcBot = GetBot();
    
    -- check if real meepo
    if( GetBot():GetUnitName() == "npc_dota_hero_meepo") then
        if(utils.GetHeroLevel() > 1) then
            for i=0, 5 do
                if(npcBot:GetItemInSlot(i) ~= nil ) then
                    if not (npcBot:GetItemInSlot(i):GetName() == "item_boots" or npcBot:GetItemInSlot(i):GetName() == "item_power_treads") then
                        break
                    end
                end
                if i == 5 then
                    return
                end
            end
        end
    end

    ThinkLvlupAbility(level)

    --print(npcBot:GetUnitName())
	local currentItems = {}
	for i=0, 8 do
		currentItems[i] = npcBot:GetItemInSlot(i)
	end

	for i,v in ipairs(currentItems) do

	end

	if ( #tableItemsToBuy == 0 )
	then
		npcBot:SetNextItemPurchaseValue( 0 );
		return;
	end

	local sNextItem = tableItemsToBuy[1];

	npcBot:SetNextItemPurchaseValue( GetItemCost( sNextItem ) );


	if ( npcBot:GetGold() >= GetItemCost( sNextItem ) )
	then
        if ( not npcBot.secretShopMode and IsItemPurchasedFromSecretShop( sNextItem ) and npcBot:DistanceFromSecretShop() >= 0 ) then
            -- this item is from secret shop
            npcBot.secretShopMode = true;
            --print("secretshopmode:"..tostring(npcBot.secretShopMode))

        end
        if npcBot.secretShopMode and  npcBot:DistanceFromSecretShop() > 00  then
            return
        end
		if npcBot:Action_PurchaseItem( sNextItem ) == PURCHASE_ITEM_SUCCESS then
            npcBot.secretShopMode = false;
    		if(IsCourierAvailable()) then
    			--print("useCourier" .. tableItemsToBuy[1])
    			npcBot:Action_CourierDeliver( )
    		end
    		table.remove( tableItemsToBuy, 1 );
        end
	end
    --hack job to sell items to make room for others
--[[
    for i=6, 8 do
        if(npcBot:GetItemInSlot(i) ~= nil and GetItemCost( npcBot:GetItemInSlot(i):GetName() ) > 1000 ) then
            npcBot.secretShopMode = true
        end
    end

    if utils.GetHeroLevel() > 1 and npcBot:DistanceFromFountain( ) == 0 or npcBot:DistanceFromSecretShop() == 0 then
        local currentItems = {}
        for i=0, 5 do
            if(npcBot:GetItemInSlot(i) ~= nil) then
                local _item = npcBot:GetItemInSlot(i):GetName()
                table.insert(currentItems, _item)
            end
        end
        local packItems = {}
        for i=6, 8 do
            if(npcBot:GetItemInSlot(i) ~= nil) then
                local _item = npcBot:GetItemInSlot(i)
                npcBot:Action_DropItem(npcBot:GetItemInSlot(i), npcBot:GetLocation())
                table.insert(packItems, _item)
            end
        end
        if (#packItems > 0) then
            print(#packItems .. " Items Dropped")
            local itemSellList = {"item_tango","item_iron_talon","item_poor_mans_shield"}
            for i=0, #packItems do
                for k,v in pairs(currentItems) do
                    if v == itemSellList[1] then
                        npcBot:Action_SellItem( npcBot:GetItemInSlot(k) )
                        table.remove(itemSellList, 1)
                    end
                end
            end
            print(#packItems .. " Items Sold")
            for _,v in pairs(packItems) do
                npcBot:Action_PickUpItem(v)
            end
        end
    end	]]
end

----------------------------------------------------------------------------------------------------

--[[this chunk prevents dota_bot_reload_scripts from breaking your 
	item/skill builds.  Note the script doesn't account for 
	consumables. ]]

local npcBot = GetBot();

-- check skill build vs current level
local ability_name = BotAbilityPriority[1];
local ability = GetBot():GetAbilityByName(ability_name);
--print(ability:GetLevel())
if(ability ~= nil and ability:GetLevel() > 0) then
    --print (#BotAbilityPriority .. " > " .. "25 - " .. utils.GetHeroLevel())
    if #BotAbilityPriority > (25 - utils.GetHeroLevel()) then
        --print(#BotAbilityPriority - (25 - utils.GetHeroLevel()))
        for i=1, (#BotAbilityPriority - (25 - utils.GetHeroLevel())) do
            table.remove(BotAbilityPriority, 1)
        end
    end
end

-- check item build vs current items
local currentItems = {}
for i=0, 15 do
    if(npcBot:GetItemInSlot(i) ~= nil) then
        local _item = npcBot:GetItemInSlot(i):GetName()
        if(_item == "item_magic_wand")then
            table.insert(currentItems, "item_magic_stick")
            table.insert(currentItems, "item_branches")
            table.insert(currentItems, "item_branches")
            table.insert(currentItems, "item_circlet")
        elseif(_item == "item_arcane_boots")then
            table.insert(currentItems, "item_energy_booster")
            table.insert(currentItems, "item_boots")
        elseif(_item == "item_null_talisman")then
            table.insert(currentItems, "item_circlet")
            table.insert(currentItems, "item_mantle")
            table.insert(currentItems, "item_recipe_null_talisman")
        elseif(_item == "item_iron_talon")then
            table.insert(currentItems, "item_quelling_blade")
            table.insert(currentItems, "item_ring_of_protection")
            table.insert(currentItems, "item_recipe_iron_talon")
        elseif(_item == "item_poor_mans_shield")then
            table.insert(currentItems, "item_slippers")
            table.insert(currentItems, "item_slippers")
            table.insert(currentItems, "item_stout_shield")
        elseif(_item == "item_ultimate_scepter")then
            table.insert(currentItems, "item_point_booster")
            table.insert(currentItems, "item_staff_of_wizardry")
            table.insert(currentItems, "item_ogre_axe")
            table.insert(currentItems, "item_blade_of_alacrity")
        elseif(_item == "item_power_treads")then
            table.insert(currentItems, "item_boots")
            table.insert(currentItems, "item_gloves")
            table.insert(currentItems, "item_belt_of_strength")
        elseif(_item == "item_force_staff")then
            table.insert(currentItems, "item_ring_of_regen")
            table.insert(currentItems, "item_staff_of_wizardry")
            table.insert(currentItems, "item_recipe_force_staff")
        elseif(_item == "item_dragon_lance")then
            table.insert(currentItems, "item_ogre_axe")
            table.insert(currentItems, "item_boots_of_elves")
            table.insert(currentItems, "item_boots_of_elves")
        elseif(_item == "item_hurricane_pike")then
            table.insert(currentItems, "item_ring_of_regen")
            table.insert(currentItems, "item_staff_of_wizardry")
            table.insert(currentItems, "item_recipe_force_staff")
            table.insert(currentItems, "item_ogre_axe")
            table.insert(currentItems, "item_boots_of_elves")
            table.insert(currentItems, "item_boots_of_elves")
            table.insert(currentItems, "item_recipe_hurricane_pike")
        elseif(_item == "item_sange")then
            table.insert(currentItems, "item_ogre_axe")
            table.insert(currentItems, "item_belt_of_strength")
            table.insert(currentItems, "item_recipe_sange")
        elseif(_item == "item_yasha")then
            table.insert(currentItems, "item_blade_of_alacrity")
            table.insert(currentItems, "item_boots_of_elves")
            table.insert(currentItems, "item_recipe_yasha")
        elseif(_item == "item_sange_and_yasha")then
            table.insert(currentItems, "item_ogre_axe")
            table.insert(currentItems, "item_belt_of_strength")
            table.insert(currentItems, "item_recipe_sange")
            table.insert(currentItems, "item_blade_of_alacrity")
            table.insert(currentItems, "item_boots_of_elves")
            table.insert(currentItems, "item_recipe_yasha")
        else
            table.insert(currentItems, npcBot:GetItemInSlot(i):GetName())
        end
    end
end

--utils.print_r(currentItems)
for i = 0, #currentItems do
	if(currentItems[i] ~= nil) then
		for j = 0, #tableItemsToBuy do
			if tableItemsToBuy[j] == currentItems[i] then
				--print("Removing Item " .. currentItems[i] .. " index " .. j)
				table.remove(tableItemsToBuy, j)
				break
			end
		end
	end
end
--utils.print_r(tableItemsToBuy)