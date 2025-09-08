return {
	['testburger'] = {
		label = 'Test Burger',
		weight = 220,
		degrade = 60,
		client = {
			image = 'burger_chicken.png',
			status = { hunger = 200000 },
			anim = 'eating',
			prop = 'burger',
			usetime = 2500,
			export = 'ox_inventory_examples.testburger'
		},
		server = {
			export = 'ox_inventory_examples.testburger',
			test = 'what an amazingly delicious burger, amirite?'
		},
		buttons = {
			{
				label = 'Lick it',
				action = function(slot)
					print('You licked the burger')
				end
			},
			{
				label = 'Squeeze it',
				action = function(slot)
					print('You squeezed the burger :(')
				end
			},
			{
				label = 'What do you call a vegan burger?',
				group = 'Hamburger Puns',
				action = function(slot)
					print('A misteak.')
				end
			},
			{
				label = 'What do frogs like to eat with their hamburgers?',
				group = 'Hamburger Puns',
				action = function(slot)
					print('French flies.')
				end
			},
			{
				label = 'Why were the burger and fries running?',
				group = 'Hamburger Puns',
				action = function(slot)
					print('Because they\'re fast food.')
				end
			}
		},
		consume = 0.3
	},

	['bandage'] = {
		label = 'Bandage',
		weight = 115,
		client = {
			anim = { dict = 'missheistdockssetup1clipboard@idle_a', clip = 'idle_a', flag = 49 },
			prop = { model = `prop_rolled_sock_02`, pos = vec3(-0.14, -0.14, -0.08), rot = vec3(-50.0, -50.0, 0.0) },
			disable = { move = true, car = true, combat = true },
			usetime = 2500,
		}
	},

	['black_money'] = {
		label = 'Dirty Money',
		weight = 0,
		stack = true,
		rarity = 'rare'
	},

	['burger'] = {
		label = 'Burger',
		weight = 220,
		client = {
			status = { hunger = 200000 },
			anim = 'eating',
			prop = 'burger',
			usetime = 2500,
			notification = 'You ate a delicious burger'
		},
	},

	['sprunk'] = {
		label = 'Sprunk',
		weight = 350,
		client = {
			status = { thirst = 200000 },
			anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
			prop = { model = `prop_ld_can_01`, pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) },
			usetime = 2500,
			notification = 'You quenched your thirst with a sprunk'
		}
	},

	['parachute'] = {
		label = 'Parachute',
		weight = 8000,
		stack = false,
		client = {
			anim = { dict = 'clothingshirt', clip = 'try_shirt_positive_d' },
			usetime = 1500
		}
	},

	['garbage'] = {
		label = 'Garbage',
	},

	['paperbag'] = {
		label = 'Paper Bag',
		weight = 1,
		stack = false,
		close = false,
		consume = 0
	},

	['identification'] = {
		label = 'Identification',
		client = {
			image = 'card_id.png'
		}
	},

	['panties'] = {
		label = 'Knickers',
		weight = 10,
		consume = 0,
		client = {
			status = { thirst = -100000, stress = -25000 },
			anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
			prop = { model = `prop_cs_panties_02`, pos = vec3(0.03, 0.0, 0.02), rot = vec3(0.0, -13.5, -1.5) },
			usetime = 2500,
		}
	},

	['lockpick'] = {
		label = 'Lockpick',
		weight = 160,
	},

	['phone'] = {
		label = 'Phone',
		weight = 190,
		stack = false,
		consume = 0,
		client = {
			add = function(total)
				if total > 0 then
					pcall(function() return exports.npwd:setPhoneDisabled(false) end)
				end
			end,

			remove = function(total)
				if total < 1 then
					pcall(function() return exports.npwd:setPhoneDisabled(true) end)
				end
			end
		}
	},

	['money'] = {
		label = 'Money',
	},

	['mustard'] = {
		label = 'Mustard',
		weight = 500,
		client = {
			status = { hunger = 25000, thirst = 25000 },
			anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
			prop = { model = `prop_food_mustard`, pos = vec3(0.01, 0.0, -0.07), rot = vec3(1.0, 1.0, -1.5) },
			usetime = 2500,
			notification = 'You.. drank mustard'
		}
	},

	['water'] = {
		label = 'Water',
		weight = 500,
		client = {
			status = { thirst = 200000 },
			anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
			prop = { model = `prop_ld_flow_bottle`, pos = vec3(0.03, 0.03, 0.02), rot = vec3(0.0, 0.0, -1.5) },
			usetime = 2500,
			cancel = true,
			notification = 'You drank some refreshing water'
		}
	},

	['radio'] = {
		label = 'Radio',
		weight = 1000,
		stack = false,
		allowArmed = true,
		rarity = 'mythic',
	},
	
	['armour'] = {
		label = 'Bulletproof Vest',
		weight = 3000,
		stack = false,
		rarity = 'epic',
		client = {
			image = "armor.png"
		}
	},

	['armour_plate'] = {
		label = "Armor Plate",
		weight = 1500,
		stack = true,
		rarity = 'rare',
		client = {
			image = "armor_plate.png",
		}
	},
	
	['clothing'] = {
		label = 'Clothing',
		consume = 0,
	},
	
	['mastercard'] = {
		label = 'Fleeca Card',
		stack = false,
		weight = 10,
		rarity = 'uncommon',
		client = {
			image = 'card_bank.png'
		}
	},
	['backpack'] = {
		label = 'Small Backpack',
		weight = 220,
		bp_weight = 40, -- 40kg capacity
		bp_slot = 20,   -- 20 slots
		backpack = true, -- Identifies as backpack
		stack = false,
		close = true,
		rarity = 'uncommon',
		description = 'A small backpack for carrying basic items.',
		client = {
			image = 'backpack.png',
		}
	},
	['backpack_medium'] = {
		label = 'Medium Backpack',
		weight = 350,
		bp_weight = 60, -- 60kg capacity
		bp_slot = 30,   -- 30 slots
		backpack = true,
		stack = false,
		close = true,
		rarity = 'uncommon',
		description = 'A medium-sized backpack with more storage space.',
		client = {
			image = 'backpack.png',
		}
	},
	['backpack_large'] = {
		label = 'Large Backpack',
		weight = 500,
		bp_weight = 80, -- 80kg capacity
		bp_slot = 40,   -- 40 slots
		backpack = true, -- Simple boolean to identify as backpack
		stack = false,
		close = true,
		rarity = 'rare',
		description = 'A large backpack for extended trips and heavy loads.',
		client = {
			image = 'backpack.png',
		}
	},
	['tactical_backpack'] = {
		label = 'Tactical Backpack',
		weight = 650,
		bp_weight = 100, -- 100kg capacity
		bp_slot = 50,    -- 50 slots
		backpack = true, -- Identifies as backpack
		stack = false,
		close = true,
		rarity = 'epic',
		description = 'A military-grade tactical backpack with maximum storage capacity.',
		client = {
			image = 'backpack.png',
		}
	},
	['scrapmetal'] = {
		label = 'Scrap Metal',
		weight = 80,
	},

	['veh_package'] = {
		label = "Package",
		weight = 1000,
		client = {
			image = "vehicle_package_2.png",
			event = "SK-Chopping:CL:SDOIAOIUNWIDUAIODBANLSDDD"
		},
		rarity = "uncommon"
	},

	['weedseeds'] = {
		label = "Weed Seeds",
		weight = 100,
		client = {
			image = "seeds_weed_2c.png",
		},
		rarity = "uncommon"
	},
	
	['easychopcontract'] = {
		label = "Easy Scrap Contract",
		weight = 0,
		client = {
			image = "scrap_contract_easy.png",
		},
		rarity = "rare"
	},
	
	['mediumchopcontract'] = {
		label = "Medium Scrap Contract",
		weight = 0,
		client = {
			image = "scrap_contract_medium.png",
		},
		rarity = "epic"
	},
	
	['hardchopcontract'] = {
		label = "Hard Scrap Contract",
		weight = 0,
		client = {
			image = "scrap_contract_hard.png",
		},
		rarity = "mythic"
	},	
}
