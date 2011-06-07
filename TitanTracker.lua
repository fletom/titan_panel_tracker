TitanTracker = {}
local TT = TitanTracker

TT.id = 'Tracker'
TT.addon = 'TitanTracker'

TT.version = tostring(GetAddOnMetadata(TT.addon, 'Version')) or 'Unknown'
TT.author = GetAddOnMetadata(TT.addon, 'Author') or 'Unknown'

function TT.Button_OnLoad(self)
	self.registry = {
		id = TT.id,
		version = TT.version,
		category = 'General',
		menuText = 'Tracker',
		buttonTextFunction = 'TitanTracker_GetButtonText', 
		tooltipTitle = 'Titan Panel [Tracker]',
		tooltipTextFunction = 'TitanTracker_GetTooltipText', 
		icon = 'Interface\\ICONS\\Ability_Hunter_Pathfinding',
		iconWidth = 16,
		controlVariables = {
			ShowIcon = true,
			ShowLabelText = true,
			ShowRegularText = true,
			DisplayOnRightSide = true,
		},
		savedVariables = {
			ShowIcon = true,
			ShowLabelText = true,
			ShowRegularText = false,
			ShowColoredText = false,
			DisplayOnRightSide = false,             
		}
	}
	
	self:RegisterEvent('MINIMAP_UPDATE_TRACKING')
	self:RegisterEvent('PLAYER_ENTERING_WORLD')
end

function TT.Button_OnEvent(self, event, ...)
	if (event == 'MINIMAP_UPDATE_TRACKING') then
		TitanPanelPluginHandle_OnUpdate({'Tracker', TITAN_PANEL_UPDATE_BUTTON})
	end
	if (event == 'PLAYER_ENTERING_WORLD') then
		-- We need to do this because of a bug in Blizzard's source that
		-- calls UIDropDownMenu_Refresh() upon MINIMAP_UPDATE_TRACKING,
		-- wiping any UIDropDownMenu that is open at the time. Since we
		-- have keepShownOnClick = true for our buttons, we must stop that
		-- from happening.
		-- See: http://us.battle.net/wow/en/forum/topic/2522463631
		MiniMapTrackingButton:UnregisterEvent('MINIMAP_UPDATE_TRACKING')
		
		-- Should this be a user option?
		MiniMapTrackingButton:Hide()
	end
end

function TitanTracker_GetButtonText(id)
	return 'Tracker: ', TT.GetTrackingInfo()
end

function TitanTracker_GetTooltipText()
	return TT.GetTrackingInfo()..' tracking enabled'..'\n'
	..TitanUtils_GetGreenText('Right-click to change tracking options.')
end

function TitanPanelRightClickMenu_PrepareTrackerMenu()
	
	-- Since Titan Panel won't let us move the icon/text options
	-- to a second level menu, we'll omit it entirely for aesthetic
	-- reasons. To change these options or hide Titan Tracker, one
	-- can just right click on Titan Panel itself and find these
	-- options in 
	
	TitanPanelRightClickMenu_AddTitle(TitanPlugins[TT.id].menuText)

	local name, texture, active, category
	local tracking_count = GetNumTrackingTypes()
	for tracking_index = 1, tracking_count do
		name, texture, active, category = GetTrackingInfo(tracking_index)
		UIDropDownMenu_AddButton({
			text = name,
			value = name,
			icon = texture,
			checked = active,
			arg1 = tracking_index,
			arg2 = name,
			isNotRadio = true,
			func = TT.TrackingClickCallback,
			keepShownOnClick = true,
		})
	end
end

function TT.GetTrackingInfo()
	
	active_tracking_count = 0
	tracking_count = GetNumTrackingTypes()
	for tracking_index = 1, tracking_count do
		local name, texture, active, category = GetTrackingInfo(tracking_index)
		if active then
			active_tracking_count = active_tracking_count + 1
		end
	end
	
	return format('%d/%d', active_tracking_count, tracking_count)
end

function TT.TrackingClickCallback(button, index, name, checked)
	SetTracking(index, checked)
end