local expect = dofile("rom/modules/main/cc/expect.lua").expect

local nsetapi = {}

local settingsInMemory = {}

local fs = _G.fs

function nsetapi.useFS(nfs)
    fs = nfs
end

function nsetapi.get(cPath, setting)
    expect(1, cPath, "string")
    expect(2, setting, "string")

    if (fs.isDir(cPath)) or (not fs.exists(cPath)) then
        error("File " .. cPath .. " does not exist", 0)
    end

    local configFile = fs.open(cPath, "r")

    if not configFile then
        error("Could not obtain handle for " .. cPath, 0)
    end

    local configData = configFile.readAll()
    configFile.close()
    local configSettings = textutils.unserialise(configData)

    if not configSettings then
        error("Malformed table in " .. cPath, 0)
    end

    settingsInMemory[cPath] = configSettings

    return configSettings[setting]
end

function nsetapi.save(cPath, setting, value)
    expect(1, cPath, "string")
    expect(2, setting, "string")
    expect(3, value, "string", "table", "number", "boolean")
    if not settingsInMemory[cPath] then
        if (fs.isDir(cPath)) or (not fs.exists(cPath)) then
            local configFile = fs.open(cPath, "w")
            configFile.write("{}")
            configFile.close()
        end

        local configFile = fs.open(cPath, "r")

        if not configFile then
            error("Could not obtain handle for " .. cPath, 0)
        end

        local configData = configFile.readAll()
        configFile.close()
        local configSettings = textutils.unserialise(configData)

        if not configSettings then
            error("Malformed table in " .. cPath, 0)
        end

        settingsInMemory[cPath] = configSettings
    end

    settingsInMemory[cPath][setting] = value

    local configFile = fs.open(cPath, "w")

    if not configFile then
        error("Could not obtain handle for " .. cPath, 0)
    end

    configFile.write(textutils.serialise(settingsInMemory[cPath]))

    configFile.close()
end

function nsetapi.saveData(cPath)
    local configFile = fs.open(cPath, "w")

    if not configFile then
        error("Could not obtain handle for " .. cPath, 0)
    end

    configFile.write(textutils.serialise(settingsInMemory[cPath]))

    configFile.close()
end

function nsetapi.setDefault(cPath, setting, value)
    expect(1, cPath, "string")
    expect(2, setting, "string")
    expect(3, value, "string", "table", "number", "boolean")

    if settingsInMemory[cPath] and settingsInMemory[cPath][setting] ~= nil then return end

    if (fs.isDir(cPath)) or (not fs.exists(cPath)) then
        local configFile = fs.open(cPath, "w")
        configFile.write(textutils.serialise({ [setting] = value }))
        configFile.close()
        settingsInMemory[cPath] = { [setting] = value }
    else
        local configFile = fs.open(cPath, "r")
        if not configFile then
            error("Could not obtain handle for " .. cPath, 0)
        end

        local configData = configFile.readAll()
        configFile.close()
        local configSettings = textutils.unserialise(configData)

        if not configSettings then
            error("Malformed table in " .. cPath, 0)
        end

        if configSettings[setting] == nil then
            configSettings[setting] = value
            nsetapi.saveData(cPath)
        end

        settingsInMemory[cPath] = configSettings
    end
end



return nsetapi
