local compress = require("lib/luz/compress")
local lex = require("lib/luz/lex")
local lualzw = require("lib/lualzw")

local function getTree(path)
    local tree = {
        name = fs.getName(path),
        path = path,
        isDir = fs.isDir(path),
        children = {},
        content = "",
        luzCompressed = false,
    }

    if not tree.isDir then
        print("Compressing "..tree.path)
        if tree.path:sub(-4) == ".lua" then
            local file = fs.open(tree.path, "rb")
            local tmp = file.readAll()
            local content = lex(tmp, 1, 2)
            tree.content = compress(content)
            file.close()
            tree.luzCompressed = true
        else
            local file = fs.open(tree.path, "rb")
            tree.content = lualzw.compress(file.readAll())
            file.close()
            tree.luzCompressed = false
        end
    else
        local items = fs.list(path)
        for _, item in ipairs(items) do
            local childPath = fs.combine(path, item)
            table.insert(tree.children, textutils.unserialise(getTree(childPath)))
            print("Got " .. childPath)
        end
    end

    return textutils.serialise(tree)
end

local function getTreeSR(path)
    if not fs.isDir(path) then
        return getTree(path)
    end

    local items = fs.list(path)
    local children = {}
    for _, item in ipairs(items) do
        local childPath = fs.combine(path, item)
        table.insert(children, textutils.unserialise(getTree(childPath)))
    end

    local virtualRoot = {
        name = "",
        path = path,
        isDir = true,
        children = children,
        content = "",
    }

    return textutils.serialise(virtualRoot)
end

local function prompt(text)
    print(text)
    term.blit("?> ", "044", "fff")
    return io.read()
end

term.clear()
term.setCursorPos(1, 1)
print("Items marked with default can be skipped by just pressing enter.\n")
local targetDir
repeat
    targetDir = prompt("What directory or file should be packaged?")
until fs.exists(targetDir)

local appName = prompt("What is the name of the app? (default MyApp)")
appName = appName ~= "" and appName or "MyApp"

local version = prompt("What is the version? (default 1)")
version = version ~= "" and version or 1

local author = prompt("Author name? (default Me)")
author = author ~= "" and author or "Me"

local isolated
repeat
    isolated = prompt("Run as isolated app? (default false)")
until isolated == "" or isolated == "false" or isolated == "true"
isolated = isolated ~= "" and isolated or "false"

isolated = isolated == "true" and true or false

print("Compressing app " .. appName .. " (this can take some time)")
local compressedFile = getTreeSR(targetDir)
print("Complete.")

local assembledMetadata = { appName = appName, version = version, author = author, isolated = isolated }

local data = { metadata = assembledMetadata, data = compressedFile }

local resultFile = fs.open(string.lower(appName .. "." .. version .. "." .. author .. ".sp"), "wb")
resultFile.write(textutils.serialise(data))
resultFile.close()

print("Package " .. string.lower(appName .. "." .. version .. "." .. author .. ".sp") .. " assembled.")
