local libFolder = (...):match("(.-)[^%.]+$")
local nsetapi = require(fs.combine(libFolder, "nsetapi"))
dofile(fs.combine(libFolder, "dbprotect.lua"))

local oldFS = {}
for k, v in pairs(fs) do
    oldFS[k] = v
end

nsetapi.useFS(oldFS)
nsetapi.setDefault(fs.combine(libFolder, "envmod.settings"), "ENV_ENABLED", false)
nsetapi.setDefault(fs.combine(libFolder, "envmod.settings"), "ENV_PATH", "/")

local function normalize(path)
    local result = {}

    for part in string.gmatch(path, "[^/]+") do
        if part == ".." then
            if #result == 0 then
                error("Not a directory", 0)
            end
            table.remove(result)
        elseif part ~= "." and part ~= "" then
            table.insert(result, part)
        end
    end

    return table.concat(result, "/")
end

fs.unsetEnvironment = function()
    local newDir = fs.combine(nsetapi.get(fs.combine(libFolder, "envmod.settings"), "ENV_PATH"), shell.dir())
    nsetapi.save(fs.combine(libFolder, "envmod.settings"), "ENV_ENABLED", false)
    nsetapi.save(fs.combine(libFolder, "envmod.settings"), "ENV_PATH", "/")

    for k, v in pairs(oldFS) do
        for k2, _ in pairs(fs) do
            if k2 == k then fs[k] = v end
        end
    end
    if fs.isDir(newDir) then
        shell.setDir(newDir)
    else
        shell.setDir("/")
    end
end

fs.setEnvironment = function(enabled, path)
    nsetapi.save(fs.combine(libFolder, "envmod.settings"), "ENV_ENABLED", enabled)
    nsetapi.save(fs.combine(libFolder, "envmod.settings"), "ENV_PATH", path)

    local newFS = {}

    newFS.getPathParts = function(path)
        local t = {}
        for str in string.gmatch(path, "[^/]+") do
            table.insert(t, str)
        end
        return t
    end

    newFS.sanitizePath = function(path)
        if nsetapi.get(fs.combine(libFolder, "envmod.settings"), "ENV_ENABLED") then
            local norm = normalize(oldFS.combine(path))
            if not norm then
                return nil
            end

            local parts = newFS.getPathParts(norm)
            if parts[1] ~= "rom" then
                local drives = { peripheral.find("drive") }
                local found = false
                for _, drive in pairs(drives) do
                    if parts[1] == drive.getMountPath() then found = true end
                end
                if not found then return oldFS.combine(nsetapi.get(fs.combine(libFolder, "envmod.settings"), "ENV_PATH"), norm) end
            end

            return norm
        end
        return path
    end

    local sanitizePath = newFS.sanitizePath

    newFS.find = function(path)
        return oldFS.find(sanitizePath(path))
    end
    newFS.isDriveRoot = function(path)
        return oldFS.isDriveRoot(sanitizePath(path))
    end
    newFS.list = function(path)
        path = sanitizePath(path)
        local list = oldFS.list(path)
        -- this makes the machine think rom and disks exist, even when they don't
        if path == nsetapi.get(fs.combine(libFolder, "envmod.settings"), "ENV_PATH") then
            table.insert(list, "rom")
            local drives = { peripheral.find("drive") }
            for _, drive in pairs(drives) do
                table.insert(list, drive.getMountPath())
            end
        end
        return list
    end
    newFS.getName = function(path)
        return oldFS.getName(sanitizePath(path))
    end
    newFS.getDir = function(path)
        return oldFS.getDir(sanitizePath(path))
    end
    newFS.getSize = function(path)
        return oldFS.getSize(sanitizePath(path))
    end
    newFS.exists = function(path)
        return oldFS.exists(sanitizePath(path))
    end
    newFS.isDir = function(path)
        return oldFS.isDir(sanitizePath(path))
    end
    newFS.isReadOnly = function(path)
        return oldFS.isReadOnly(sanitizePath(path))
    end
    newFS.makeDir = function(path)
        return oldFS.makeDir(sanitizePath(path))
    end
    newFS.move = function(path, dest)
        return oldFS.move(sanitizePath(path), sanitizePath(dest))
    end
    newFS.copy = function(path, dest)
        return oldFS.copy(sanitizePath(path), sanitizePath(dest))
    end
    newFS.delete = function(path)
        return oldFS.delete(sanitizePath(path))
    end
    newFS.open = function(path, mode)
        return oldFS.open(sanitizePath(path), mode)
    end
    newFS.getDrive = function(path)
        return oldFS.getDrive(sanitizePath(path))
    end
    newFS.getFreeSpace = function(path)
        return oldFS.getFreeSpace(sanitizePath(path))
    end
    newFS.getCapacity = function(path)
        return oldFS.getCapacity(sanitizePath(path))
    end
    newFS.attributes = function(path)
        return oldFS.attributes(sanitizePath(path))
    end

    for k, _ in pairs(fs) do
        for k2, v2 in pairs(newFS) do
            if k2 == k then
                fs[k] = v2; debug.protect(fs[k])
            end
        end
    end

    fs.sanitizePath = newFS.sanitizePath
    fs.getPathParts = newFS.getPathParts
end