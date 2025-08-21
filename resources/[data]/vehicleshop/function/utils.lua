function printdbg(...)
    if Config.EnableDebug then
        local args = { ... }

        for i = 1, #args do
            local arg = args[i]
            args[i] = type(arg) == 'table' and json.encode(arg, { sort_keys = true, indent = true }) or tostring(arg)
        end

        print('^1[DEBUG] ^7', table.concat(args, '\t'))
    end
end

local NumberCharset = {}
local Charset = {}

for i = 48,  57 do table.insert(NumberCharset, string.char(i)) end
for i = 65,  90 do table.insert(Charset, string.char(i)) end
for i = 97, 122 do table.insert(Charset, string.char(i)) end

local function IsPlateTaken(plate)
	local p = promise.new()
	
    lib.callback("vehicleshop:isPlateTaken", false, function(isPlateTaken)
		p:resolve(isPlateTaken)
	end, plate)

	return Citizen.Await(p)
end

local function GetRandomNumber(length)
	Wait(0)
	return length > 0 and GetRandomNumber(length - 1) .. NumberCharset[math.random(1, #NumberCharset)] or ''
end

local function GetRandomLetter(length)
	Wait(0)
	return length > 0 and GetRandomLetter(length - 1) .. Charset[math.random(1, #Charset)] or ''
end


local function GeneratePlate()
	math.randomseed(GetGameTimer())

	local generatedPlate = string.upper(GetRandomLetter(1) .. ' ' .. GetRandomNumber(3) .. ' ' .. GetRandomLetter(2))
    
	local isTaken = IsPlateTaken(generatedPlate)
	if isTaken then 
		return GeneratePlate()
	end

	return generatedPlate
end

exports('GeneratePlate', GeneratePlate)

function InfoKeybind()
    Scale = RequestScaleformMovie("INSTRUCTIONAL_BUTTONS");
    while not HasScaleformMovieLoaded(Scale) do
        Citizen.Wait(0)
    end

    BeginScaleformMovieMethod(Scale, "CLEAR_ALL");
    EndScaleformMovieMethod();

    --Right
    BeginScaleformMovieMethod(Scale, "SET_DATA_SLOT");
    ScaleformMovieMethodAddParamInt(0);
    PushScaleformMovieMethodParameterString("~INPUT_MOVE_RIGHT_ONLY~");
    PushScaleformMovieMethodParameterString("Rotate right");
    EndScaleformMovieMethod();

    --Left
    BeginScaleformMovieMethod(Scale, "SET_DATA_SLOT");
    ScaleformMovieMethodAddParamInt(1);
    PushScaleformMovieMethodParameterString("~INPUT_MOVE_LEFT_ONLY~");
    PushScaleformMovieMethodParameterString("Rotate Left");
    EndScaleformMovieMethod();

    BeginScaleformMovieMethod(Scale, "SET_DATA_SLOT");
    ScaleformMovieMethodAddParamInt(2);
    PushScaleformMovieMethodParameterString("~INPUT_CELLPHONE_CANCEL~");
    PushScaleformMovieMethodParameterString("Exit");
    EndScaleformMovieMethod();


    BeginScaleformMovieMethod(Scale, "DRAW_INSTRUCTIONAL_BUTTONS");
    ScaleformMovieMethodAddParamInt(0);
    EndScaleformMovieMethod();

    DrawScaleformMovieFullscreen(Scale, 255, 255, 255, 255, 0);
end