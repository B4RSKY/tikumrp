return {
	{
		coords = vec3(452.3, -991.4, 30.7),
		target = {
			loc = vec3(451.25, -994.28, 30.69),
			length = 1.2,
			width = 5.6,
			heading = 0,
			minZ = 29.49,
			maxZ = 32.09,
			label = 'Open personal locker'
		},
		name = 'policelocker',
		label = 'Personal locker',
		owner = true,
		slots = 70,
		weight = 70000,
		groups = shared.police
	},
	{
		coords = vec3(-489.99, -978.17, 35.45),
		target = {
			loc = vec3(-489.99, -978.17, 35.45),
			length = 0.6,
			width = 1.8,
			heading = 340,
			minZ = 43.34,
			maxZ = 44.74,
			label = 'Loker Pribadi'
		},
		name = 'emslocker',
		label = 'Loker Pribadi',
		owner = true,
		slots = 50,
		weight = 70000,
		groups = {['ambulance'] = 1}
	},
	{
		coords = vec3(-926.75, -2025.5, 14.45),
		target = {
			loc = vec3(-926.75, -2025.5, 14.45),
			length = 0.6,
			width = 1.8,
			heading = 340,
			minZ = 43.34,
			maxZ = 44.74,
			label = 'Loker Pribadi'
		},
		name = 'mechloker',
		label = 'Loker Pribadi',
		owner = true,
		slots = 50,
		weight = 70000,
		groups = {['mechanic'] = 1}
	},
}
