Config = Config or {}

Config.framework = "QBCore"						-- [ESX|QBCore] Your framework

Config.ESX_settings = {							-- (ESX Only) ESX settings
	['is_updated'] = true,						-- Set to false if your ESX uses the getSharedObject event (usually for ESX versions older than 1.9.0)
	['shared_object'] = "esx:getSharedObject",	-- GetSharedObject event if you set 'is_updated' config to false
	['esx_version'] = 'weight'					-- [weight|limit] Configure here if your inventory uses weight or limit
}

Config.locale = "en"							-- Set the file language [en/br/de/es/fr/no/fr/zh-cn/ja]

Config.format = {
	['currency'] = 'IDR',						-- This is the currency format, so that your currency symbol appears correctly [Examples: BRL, USD, EUR] (Currency codes: https://taxsummaries.pwc.com/glossary/currency-codes)
	['location'] = 'id-ID'						-- This is the location of your country, to format the decimal places according to your standard [Examples: pt-BR, en-US] (Language codes: http://www.lingoes.net/en/translator/langcode.htm)
}

-- Here, you can easily switch between the available script compatibilities.
-- The "default" option will use the framework's default script
-- ATTENTION: If you set it to "other," it's necessary to configure the script inside the custom_scripts folder in the respective file. See: https://docs.lixeirocharmoso.com/utils/adding_your_exports
Config.custom_scripts_compatibility = {
	['fuel'] = "ox_fuel",						-- [ox_fuel|ps-fuel|sna-fuel|cdn-fuel|LegacyFuel|default|other] Fuel script Compatibility
	['inventory'] = "ox_inventory",					-- [ox_inventory|qs-inventory|ps-inventory|default|other] Inventory script Compatibility
	['keys'] = "default",						-- [qs-vehiclekeys|cd_garage|jaksam|wasabi_carlock|default|other] Keys script Compatibility
	['mdt'] = "default",						-- [ps-mdt|redutzu-mdt|default|other] MDT script Compatibility (to log weapon serial)
	['target'] = "ox_target",					-- [qb-target|ox_target|disabled|other] Target script Compatibility (disabled will use markers)
	['notification'] = "ox_lib",				-- [okokNotify|qbcore|ox_lib|default|other] Notification script Compatibility
}

Config.notification = {							-- (Only if notification is default)
	['has_title'] = false,						-- Select if you want the notification to have a title or not
	['position'] = "top-right",					-- [top-left|top-center|top-right|middle-left|middle-right|bottom-left|bottom-center|bottom-right] Position of the notification on the screen
	['duration'] = 8000,						-- Time (in ms) the notifications will be shown
}

Config.marker_style = 1							-- (Only if target is disabled) [1|2] There are 2 available styles for markers, choose them here

Config.spawned_vehicles = {						-- Config for the vehicles that are spawned in each script
	['fmid_ikanv2'] = {
		['is_static'] = false,
		['plate_prefix'] = "FS"
	}
}

Config.owned_vehicles = {							-- (Only for the vehicles that will be inserted into your garage) This is the config to insert a vehicle in the player owned vehicles table
	['plate_format'] = 'xxxxxxxx',					-- Plate generation format. [n = number | l = letter | x = any]
	['default'] = {									-- The garage type
		['garage'] = 'motelgarage',					-- This is the garage where the owned vehicles will be inserted
		-- ['garage'] = 'SanAndreasAvenue', 		-- Default garage for ESX framework
		['garage_display_name'] = 'Motel Parking'	-- Just a nice name to display to the user
	},
	['airplane'] = {
		['garage'] = 'intairport',
		['garage_display_name'] = 'Airport Hangar'
	},
	['boat'] = {
		['garage'] = 'lsymc',
		['garage_display_name'] = 'LSYMC Boathouse'
	}
}

Config.debug_job = false						-- Enable this to see in the server console the job you are in