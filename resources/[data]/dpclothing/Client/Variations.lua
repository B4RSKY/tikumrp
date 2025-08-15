function AddNewVariation(which, hash, one, two, single)
	hash = GetHashKey(hash)
	local Where = Variations[which][hash]
	if not single then
		Where[one] = two
		Where[two] = one
	else
		Where[one] = two
	end
end

--[[
		This is where all the different variations go.
		For jackets i included extra things that arent just hoodies aswell, things like the christmas sweater with their different lights.
		So doing the command whilst wearing the christmas sweater you can toggle the light.

		Tip for adding new ones of this is to toggle Config.Debug, and use vMenu Player Appearance to switch around.

		If you are using EUP you might have to change things around!
		But it should be easy enough to understand and make changes as you want.

		Simply just : 

		AddNewVariation(Table, Gender, First, Second)

		And for Hair there is also the "single" var.
		Its important for haircuts.
]]--

Citizen.CreateThread(function()
	--start custom
	-- gry_pontimas custom
	AddNewVariation("Visor", "gry_pontimas", 1, 2)
	AddNewVariation("Hair", "gry_pontimas", 0, 1, true)
	-- ig_eren custom
	AddNewVariation("Visor", "ig_eren", 0, 1)
	
	AddNewVariation("Hair", "ig_eren", 0, 1, true)
	--end custom
	-- mp_m_freemode_01 Visor/Hat Variations
	AddNewVariation("Visor", "mp_m_freemode_01", 9, 10)
	AddNewVariation("Visor", "mp_m_freemode_01", 18, 67)
	AddNewVariation("Visor", "mp_m_freemode_01", 82, 67)
	AddNewVariation("Visor", "mp_m_freemode_01", 44, 45)
	AddNewVariation("Visor", "mp_m_freemode_01", 50, 68)
	AddNewVariation("Visor", "mp_m_freemode_01", 51, 69)
	AddNewVariation("Visor", "mp_m_freemode_01", 52, 70)
	AddNewVariation("Visor", "mp_m_freemode_01", 53, 71)
	AddNewVariation("Visor", "mp_m_freemode_01", 62, 72)
	AddNewVariation("Visor", "mp_m_freemode_01", 65, 66)
	AddNewVariation("Visor", "mp_m_freemode_01", 73, 74)
	AddNewVariation("Visor", "mp_m_freemode_01", 76, 77)
	AddNewVariation("Visor", "mp_m_freemode_01", 79, 78)
	AddNewVariation("Visor", "mp_m_freemode_01", 80, 81)
	AddNewVariation("Visor", "mp_m_freemode_01", 91, 92)
	AddNewVariation("Visor", "mp_m_freemode_01", 104, 105)
	AddNewVariation("Visor", "mp_m_freemode_01", 109, 110)
	AddNewVariation("Visor", "mp_m_freemode_01", 116, 117)
	AddNewVariation("Visor", "mp_m_freemode_01", 118, 119)
	AddNewVariation("Visor", "mp_m_freemode_01", 123, 124)
	AddNewVariation("Visor", "mp_m_freemode_01", 125, 126)
	AddNewVariation("Visor", "mp_m_freemode_01", 127, 128)
	AddNewVariation("Visor", "mp_m_freemode_01", 130, 131)
	-- mp_f_freemode_01 Visor/Hat Variations
	AddNewVariation("Visor", "mp_f_freemode_01", 43, 44)
	AddNewVariation("Visor", "mp_f_freemode_01", 49, 67)
	AddNewVariation("Visor", "mp_f_freemode_01", 64, 65)
	AddNewVariation("Visor", "mp_f_freemode_01", 65, 64)
	AddNewVariation("Visor", "mp_f_freemode_01", 51, 69)
	AddNewVariation("Visor", "mp_f_freemode_01", 50, 68)
	AddNewVariation("Visor", "mp_f_freemode_01", 52, 70)
	AddNewVariation("Visor", "mp_f_freemode_01", 62, 71)
	AddNewVariation("Visor", "mp_f_freemode_01", 72, 73)
	AddNewVariation("Visor", "mp_f_freemode_01", 75, 76)
	AddNewVariation("Visor", "mp_f_freemode_01", 78, 77)
	AddNewVariation("Visor", "mp_f_freemode_01", 79, 80)
	AddNewVariation("Visor", "mp_f_freemode_01", 18, 66)
	AddNewVariation("Visor", "mp_f_freemode_01", 66, 81)
	AddNewVariation("Visor", "mp_f_freemode_01", 81, 66)
	AddNewVariation("Visor", "mp_f_freemode_01", 86, 84)
	AddNewVariation("Visor", "mp_f_freemode_01", 90, 91)
	AddNewVariation("Visor", "mp_f_freemode_01", 103, 104)
	AddNewVariation("Visor", "mp_f_freemode_01", 108, 109)
	AddNewVariation("Visor", "mp_f_freemode_01", 115, 116)
	AddNewVariation("Visor", "mp_f_freemode_01", 117, 118)
	AddNewVariation("Visor", "mp_f_freemode_01", 122, 123)
	AddNewVariation("Visor", "mp_f_freemode_01", 124, 125)
	AddNewVariation("Visor", "mp_f_freemode_01", 126, 127)
	AddNewVariation("Visor", "mp_f_freemode_01", 129, 130)
	-- mp_m_freemode_01 Bags
	AddNewVariation("Bags", "mp_m_freemode_01", 45, 44)
	AddNewVariation("Bags", "mp_m_freemode_01", 41, 40)
	-- mp_f_freemode_01 Bags
	AddNewVariation("Bags", "mp_f_freemode_01", 45, 44)
	AddNewVariation("Bags", "mp_f_freemode_01", 41, 40)
	-- mp_m_freemode_01 Hair
	AddNewVariation("Hair", "mp_m_freemode_01", 6, 8, true)
	AddNewVariation("Hair", "mp_m_freemode_01", 8, 6, true)
	AddNewVariation("Hair", "mp_m_freemode_01", 5, 14, true)
	AddNewVariation("Hair", "mp_m_freemode_01", 14, 5, true)
	AddNewVariation("Hair", "mp_m_freemode_01", 26, 27, true)
	AddNewVariation("Hair", "mp_m_freemode_01", 27, 26, true)
	AddNewVariation("Hair", "mp_m_freemode_01", 29, 30, true)
	AddNewVariation("Hair", "mp_m_freemode_01", 30, 29, true)
	AddNewVariation("Hair", "mp_m_freemode_01", 34, 37, true)
	AddNewVariation("Hair", "mp_m_freemode_01", 37, 34, true)
	AddNewVariation("Hair", "mp_m_freemode_01", 52, 64, true)
	AddNewVariation("Hair", "mp_m_freemode_01", 64, 52, true)
	AddNewVariation("Hair", "mp_m_freemode_01", 73, 74, true)
	AddNewVariation("Hair", "mp_m_freemode_01", 74, 73, true)
	AddNewVariation("Hair", "mp_m_freemode_01", 89, 100, true)
	AddNewVariation("Hair", "mp_m_freemode_01", 100, 89, true)
	AddNewVariation("Hair", "mp_m_freemode_01", 123, 122, true)
	AddNewVariation("Hair", "mp_m_freemode_01", 122, 123, true)
	AddNewVariation("Hair", "mp_m_freemode_01", 124, 135, true)
	AddNewVariation("Hair", "mp_m_freemode_01", 135, 124, true)
	AddNewVariation("Hair", "mp_m_freemode_01", 136, 137, true)
	AddNewVariation("Hair", "mp_m_freemode_01", 137, 136, true)
	AddNewVariation("Hair", "mp_m_freemode_01", 157, 147, true)
	AddNewVariation("Hair", "mp_m_freemode_01", 147, 157, true)
	AddNewVariation("Hair", "mp_m_freemode_01", 158, 159, true)
	AddNewVariation("Hair", "mp_m_freemode_01", 159, 158, true)
	AddNewVariation("Hair", "mp_m_freemode_01", 199, 207, true)
	AddNewVariation("Hair", "mp_m_freemode_01", 207, 199, true)
	AddNewVariation("Hair", "mp_m_freemode_01", 214, 215, true)
	AddNewVariation("Hair", "mp_m_freemode_01", 215, 214, true)
	AddNewVariation("Hair", "mp_m_freemode_01", 267, 268, true)
	AddNewVariation("Hair", "mp_m_freemode_01", 268, 267, true)
	AddNewVariation("Hair", "mp_m_freemode_01", 312, 314, true)
	AddNewVariation("Hair", "mp_m_freemode_01", 314, 312, true)
	AddNewVariation("Hair", "mp_m_freemode_01", 359, 22, true)
	AddNewVariation("Hair", "mp_m_freemode_01", 22, 359, true)
	AddNewVariation("Hair", "mp_m_freemode_01", 379, 380, true)
	AddNewVariation("Hair", "mp_m_freemode_01", 380, 379, true)
	AddNewVariation("Hair", "mp_m_freemode_01", 390, 391, true)
	AddNewVariation("Hair", "mp_m_freemode_01", 391, 390, true)
	AddNewVariation("Hair", "mp_m_freemode_01", 317, 316, true)
	AddNewVariation("Hair", "mp_m_freemode_01", 316, 317, true)
	-- mp_f_freemode_01 Hair
	AddNewVariation("Hair", "mp_f_freemode_01", 1, 49, true)
	AddNewVariation("Hair", "mp_f_freemode_01", 2, 49, true)
	AddNewVariation("Hair", "mp_f_freemode_01", 7, 49, true)
	AddNewVariation("Hair", "mp_f_freemode_01", 9, 49, true)
	AddNewVariation("Hair", "mp_f_freemode_01", 10, 49, true)
	AddNewVariation("Hair", "mp_f_freemode_01", 11, 48, true)
	AddNewVariation("Hair", "mp_f_freemode_01", 14, 53, true)
	AddNewVariation("Hair", "mp_f_freemode_01", 15, 42, true)
	AddNewVariation("Hair", "mp_f_freemode_01", 21, 42, true)
	AddNewVariation("Hair", "mp_f_freemode_01", 23, 42, true)
	AddNewVariation("Hair", "mp_f_freemode_01", 31, 53, true)
	AddNewVariation("Hair", "mp_f_freemode_01", 39, 49, true)
	AddNewVariation("Hair", "mp_f_freemode_01", 40, 49, true)
	AddNewVariation("Hair", "mp_f_freemode_01", 42, 53, true)
	AddNewVariation("Hair", "mp_f_freemode_01", 45, 49, true)
	AddNewVariation("Hair", "mp_f_freemode_01", 48, 49, true)
	AddNewVariation("Hair", "mp_f_freemode_01", 49, 48, true)
	AddNewVariation("Hair", "mp_f_freemode_01", 52, 53, true)
	AddNewVariation("Hair", "mp_f_freemode_01", 53, 42, true)
	AddNewVariation("Hair", "mp_f_freemode_01", 54, 55, true)
	AddNewVariation("Hair", "mp_f_freemode_01", 59, 42, true)
	AddNewVariation("Hair", "mp_f_freemode_01", 59, 54, true)
	AddNewVariation("Hair", "mp_f_freemode_01", 68, 53, true)
	AddNewVariation("Hair", "mp_f_freemode_01", 76, 48, true)
	AddNewVariation("Hair", "mp_f_freemode_01", 369, 545, true)
	AddNewVariation("Hair", "mp_f_freemode_01", 545, 369, true)
	AddNewVariation("Hair", "mp_f_freemode_01", 451, 454, true)
	AddNewVariation("Hair", "mp_f_freemode_01", 454, 451, true)
	-- mp_m_freemode_01 Top/Jacket Variations
	AddNewVariation("Jackets", "mp_m_freemode_01", 29, 30)
	AddNewVariation("Jackets", "mp_m_freemode_01", 31, 32)
	AddNewVariation("Jackets", "mp_m_freemode_01", 42, 43)
	AddNewVariation("Jackets", "mp_m_freemode_01", 68, 69)
	AddNewVariation("Jackets", "mp_m_freemode_01", 74, 75)
	AddNewVariation("Jackets", "mp_m_freemode_01", 87, 88)
	AddNewVariation("Jackets", "mp_m_freemode_01", 99, 100)
	AddNewVariation("Jackets", "mp_m_freemode_01", 101, 102)
	AddNewVariation("Jackets", "mp_m_freemode_01", 103, 104)
	AddNewVariation("Jackets", "mp_m_freemode_01", 126, 127)
	AddNewVariation("Jackets", "mp_m_freemode_01", 129, 130)
	AddNewVariation("Jackets", "mp_m_freemode_01", 184, 185)
	AddNewVariation("Jackets", "mp_m_freemode_01", 188, 189)
	AddNewVariation("Jackets", "mp_m_freemode_01", 194, 195)
	AddNewVariation("Jackets", "mp_m_freemode_01", 196, 197)
	AddNewVariation("Jackets", "mp_m_freemode_01", 198, 199)
	AddNewVariation("Jackets", "mp_m_freemode_01", 200, 203)
	AddNewVariation("Jackets", "mp_m_freemode_01", 202, 205)
	AddNewVariation("Jackets", "mp_m_freemode_01", 206, 207)
	AddNewVariation("Jackets", "mp_m_freemode_01", 210, 211)
	AddNewVariation("Jackets", "mp_m_freemode_01", 217, 218)
	AddNewVariation("Jackets", "mp_m_freemode_01", 229, 230)
	AddNewVariation("Jackets", "mp_m_freemode_01", 232, 233)
	AddNewVariation("Jackets", "mp_m_freemode_01", 251, 253)
	AddNewVariation("Jackets", "mp_m_freemode_01", 256, 261)
	AddNewVariation("Jackets", "mp_m_freemode_01", 262, 263)
	AddNewVariation("Jackets", "mp_m_freemode_01", 265, 266)
	AddNewVariation("Jackets", "mp_m_freemode_01", 267, 268)
	AddNewVariation("Jackets", "mp_m_freemode_01", 279, 280)
	-- mp_f_freemode_01 Top/Jacket Variations
	AddNewVariation("Jackets", "mp_f_freemode_01", 53, 52) 
	AddNewVariation("Jackets", "mp_f_freemode_01", 57, 58) 
	AddNewVariation("Jackets", "mp_f_freemode_01", 62, 63) 
	AddNewVariation("Jackets", "mp_f_freemode_01", 90, 91) 
	AddNewVariation("Jackets", "mp_f_freemode_01", 92, 93) 
	AddNewVariation("Jackets", "mp_f_freemode_01", 94, 95) 
	AddNewVariation("Jackets", "mp_f_freemode_01", 187, 186)
	AddNewVariation("Jackets", "mp_f_freemode_01", 190, 191) 
	AddNewVariation("Jackets", "mp_f_freemode_01", 196, 197) 
	AddNewVariation("Jackets", "mp_f_freemode_01", 198, 199) 
	AddNewVariation("Jackets", "mp_f_freemode_01", 200, 201)
	AddNewVariation("Jackets", "mp_f_freemode_01", 202, 205) 
	AddNewVariation("Jackets", "mp_f_freemode_01", 204, 207) 
	AddNewVariation("Jackets", "mp_f_freemode_01", 210, 211)
	AddNewVariation("Jackets", "mp_f_freemode_01", 214, 215)
	AddNewVariation("Jackets", "mp_f_freemode_01", 227, 228) 
	AddNewVariation("Jackets", "mp_f_freemode_01", 239, 240) 
	AddNewVariation("Jackets", "mp_f_freemode_01", 242, 243) 
	AddNewVariation("Jackets", "mp_f_freemode_01", 259, 261)
	AddNewVariation("Jackets", "mp_f_freemode_01", 265, 270) 
	AddNewVariation("Jackets", "mp_f_freemode_01", 271, 272) 
	AddNewVariation("Jackets", "mp_f_freemode_01", 274, 275) 
	AddNewVariation("Jackets", "mp_f_freemode_01", 276, 277)
	AddNewVariation("Jackets", "mp_f_freemode_01", 292, 293) 
end)

-- And this is the master table, i put it down here since it has all the glove variations, and thats quite the eyesore.
-- You probably dont wanna touch anything down here really.
-- I generated these glove ones with a tool i made, im pretty certain its accurate, there might be native function for this.
-- If there is i wish i knew of it before i spent hours doing it this way.

Variations = {
	Jackets = {
		[`mp_m_freemode_01`] = {},
		[`mp_f_freemode_01`] = {},
		[`gry_pontimas`] = {},
		[`ig_eren`] = {},
		[`sp_mintzy`] = {},
		[`share_ped1`] = {},
		[`sp_disha`] = {},
		[`gry_huha`] = {},
		[`sp_kerry`] = {}
	},
	Hair = {
		[`mp_m_freemode_01`] = {},
		[`mp_f_freemode_01`] = {},
		[`ig_eren`] = {},
		[`gry_pontimas`] = {},
		[`sp_mintzy`] = {},
		[`share_ped1`] = {},
		[`sp_disha`] = {},
		[`gry_huha`] = {},
		[`sp_kerry`] = {}
	},
	Bags = {
		[`mp_m_freemode_01`] = {},
		[`mp_f_freemode_01`] = {},
		[`ig_eren`] = {},
		[`gry_pontimas`] = {},
		[`sp_mintzy`] = {},
		[`share_ped1`] = {},
		[`sp_disha`] = {},
		[`gry_huha`] = {},
		[`sp_kerry`] = {}
	},
	Visor = {
		[`mp_m_freemode_01`] = {},
		[`mp_f_freemode_01`] = {},
		[`ig_eren`] = {},
		[`gry_pontimas`] = {},
		[`sp_mintzy`] = {},
		[`share_ped1`] = {},
		[`sp_disha`] = {},
		[`gry_huha`] = {},
		[`sp_kerry`] = {}
	},
	Gloves = {
		[`mp_m_freemode_01`] = {
			[16] = 5,
			[17] = 6,
			[18] = 8,
			[19] = 11,
			[20] = 12,
			[21] = 14,
			[22] = 173,
			[23] = 174,
			[24] = 175,
			[25] = 0,
			[26] = 1,
			[27] = 2,
			[28] = 4,
			[29] = 5,
			[30] = 6,
			[31] = 8,
			[32] = 11,
			[33] = 12,
			[34] = 14,
			[35] = 15,
			[36] = 8,
			[37] = 37,
			[38] = 37,
			[39] = 0,
			[40] = 1,
			[41] = 2,
			[42] = 4,
			[43] = 5,
			[44] = 6,
			[45] = 8,
			[46] = 11,
			[47] = 12,
			[48] = 14,
			[49] = 173,
			[50] = 174,
			[51] = 175,
			[52] = 0,
			[53] = 1,
			[54] = 1,
			[55] = 55,
			[56] = 0,
			[57] = 1,
			[58] = 11,
			[59] = 1,
			[60] = 1,
			[61] = 1,
			[62] = 15,
			[63] = 0,
			[64] = 1,
			[65] = 2,
			[66] = 4,
			[67] = 4,
			[68] = 6,
			[69] = 8,
			[70] = 11,
			[71] = 12,
			[72] = 14,
			[73] = 15,
			[74] = 0,
			[75] = 2,
			[76] = 4,
			[77] = 4,
			[78] = 4,
			[79] = 4,
			[80] = 0,
			[81] = 1,
			[82] = 2,
			[83] = 4,
			[84] = 5,
			[85] = 8,
			[86] = 1,
			[87] = 11,
			[88] = 12,
			[89] = 14,
			[90] = 15,
			[91] = 0,
			[92] = 1,
			[93] = 2,
			[94] = 4,
			[95] = 5,
			[96] = 6,
			[97] = 8,
			[98] = 11,
			[99] = 12,
			[100] = 14,
			[101] = 15,
			[102] = 0,
			[103] = 1,
			[104] = 2,
			[105] = 4,
			[106] = 5,
			[107] = 6,
			[108] = 8,
			[109] = 11,
			[110] = 12,
			[111] = 14,
			[112] = 15,
			[113] = 0,
			[114] = 1,
			[115] = 2,
			[116] = 4,
			[117] = 5,
			[118] = 6,
			[119] = 8,
			[120] = 11,
			[121] = 12,
			[122] = 14,
			[123] = 15,
			[124] = 0,
			[125] = 1,
			[126] = 2,
			[127] = 4,
			[128] = 5,
			[129] = 6,
			[130] = 8,
			[131] = 11,
			[132] = 12,
			[133] = 14,
			[134] = 15,
			[135] = 0,
			[136] = 1,
			[137] = 2,
			[138] = 4,
			[139] = 5,
			[140] = 6,
			[141] = 8,
			[142] = 11,
			[143] = 12,
			[144] = 14,
			[145] = 15,
			[146] = 0,
			[147] = 1,
			[148] = 2,
			[149] = 4,
			[150] = 5,
			[151] = 6,
			[152] = 8,
			[153] = 11,
			[154] = 12,
			[155] = 14,
			[156] = 15,
			[157] = 4,
			[158] = 4,
			[159] = 4,
			[160] = 0,
			[161] = 1,
			[162] = 2,
			[163] = 4,
			[164] = 5,
			[165] = 6,
			[166] = 8,
			[167] = 11,
			[168] = 12,
			[169] = 14,
			[170] = 15,
			[171] = 4,
			[172] = 4,
			[176] = 173,
			[177] = 173,
			[178] = 173,
			[179] = 173,
			[180] = 173,
			[181] = 173,
			[182] = 173,
			[183] = 174,
			[184] = 174,
			[185] = 174,
			[186] = 174,
			[187] = 174,
			[188] = 174,
			[189] = 174,
			[190] = 175,
			[191] = 175,
			[192] = 175,
			[193] = 175,
			[194] = 175,
			[195] = 175,
			[196] = 175,
			[197] = 15,
			[198] = 15,
			[199] = 0,
			[200] = 1,
			[201] = 2,
			[202] = 4,
			[203] = 5,
			[204] = 6,
			[205] = 8,
			[206] = 11,
			[207] = 12,
			[208] = 14,
			[209] = 173,
			[210] = 174,
			[211] = 175,
			[212] = 0,
			[213] = 1,
			[214] = 2,
			[215] = 4,
			[216] = 5,
			[217] = 6,
			[218] = 8,
		},
		[`mp_f_freemode_01`] = {
			[16] = 11,
			[17] = 3,
			[18] = 3,
			[19] = 3,
			[20] = 0,
			[21] = 1,
			[22] = 2,
			[23] = 3,
			[24] = 4,
			[25] = 5,
			[26] = 6,
			[27] = 7,
			[28] = 9,
			[29] = 11,
			[30] = 12,
			[31] = 14,
			[32] = 15,
			[33] = 0,
			[34] = 1,
			[35] = 2,
			[36] = 3,
			[37] = 4,
			[38] = 5,
			[39] = 6,
			[40] = 7,
			[41] = 9,
			[42] = 11,
			[43] = 12,
			[44] = 14,
			[45] = 15,
			[46] = 0,
			[47] = 1,
			[48] = 2,
			[49] = 3,
			[50] = 4,
			[51] = 5,
			[52] = 6,
			[53] = 7,
			[54] = 9,
			[55] = 11,
			[56] = 12,
			[57] = 14,
			[58] = 15,
			[59] = 0,
			[60] = 1,
			[61] = 2,
			[62] = 3,
			[63] = 4,
			[64] = 5,
			[65] = 6,
			[66] = 7,
			[67] = 9,
			[68] = 3,
			[69] = 12,
			[70] = 14,
			[71] = 15,
			[72] = 0,
			[73] = 1,
			[74] = 2,
			[75] = 5,
			[76] = 4,
			[77] = 7,
			[78] = 9,
			[79] = 11,
			[80] = 12,
			[81] = 0,
			[82] = 15,
			[83] = 0,
			[84] = 1,
			[85] = 0,
			[86] = 1,
			[87] = 2,
			[88] = 3,
			[89] = 6,
			[90] = 7,
			[91] = 9,
			[92] = 11,
			[93] = 9,
			[94] = 0,
			[95] = 15,
			[96] = 0,
			[97] = 1,
			[98] = 0,
			[99] = 3,
			[100] = 15,
			[101] = 5,
			[102] = 6,
			[103] = 7,
			[104] = 9,
			[105] = 7,
			[106] = 9,
			[107] = 11,
			[108] = 12,
			[109] = 0,
			[110] = 1,
			[111] = 2,
			[112] = 3,
			[113] = 15,
			[114] = 5,
			[115] = 6,
			[116] = 7,
			[117] = 0,
			[118] = 11,
			[119] = 12,
			[120] = 0,
			[121] = 15,
			[122] = 0,
			[123] = 11,
			[124] = 2,
			[125] = 86,
			[126] = 15,
			[127] = 3,
			[128] = 3,
			[132] = 129,
			[133] = 129,
			[134] = 129,
			[135] = 129,
			[136] = 129,
			[137] = 129,
			[138] = 129,
			[139] = 130,
			[140] = 130,
			[141] = 6,
			[142] = 7,
			[143] = 9,
			[144] = 11,
			[145] = 12,
			[146] = 0,
			[147] = 15,
			[148] = 0,
			[149] = 1,
			[150] = 2,
			[151] = 321,
			[152] = 15,
			[153] = 5,
			[154] = 6,
			[155] = 7,
			[156] = 9,
			[157] = 11,
			[158] = 12,
			[159] = 0,
			[160] = 15,
			[162] = 161,
			[163] = 161,
			[164] = 161,
			[165] = 161,
			[166] = 161,
			[167] = 161,
			[168] = 161,
			[169] = 15,
			[170] = 15,
			[171] = 0,
			[172] = 1,
			[173] = 2,
			[174] = 3,
			[175] = 4,
			[176] = 5,
			[177] = 6,
			[178] = 7,
			[179] = 9,
			[180] = 11,
			[181] = 12,
			[182] = 14,
			[183] = 129,
			[184] = 130,
			[185] = 131,
			[186] = 153,
			[187] = 0,
			[188] = 1,
			[189] = 2,
			[190] = 3,
			[191] = 4,
			[192] = 5,
			[193] = 6,
			[194] = 7,
			[195] = 9,
			[196] = 11,
			[197] = 12,
			[198] = 14,
			[199] = 129,
			[200] = 130,
			[201] = 131,
			[202] = 153,
			[203] = 161,
			[204] = 161,
			[206] = 3,
			[207] = 3,
			[208] = 3,
		},
		[`gry_pontimas`] = {
			[4] = 8,
			[5] = 6,
		},
		[`ig_eren`] = {
			[4] = 2,
		}
	}
}