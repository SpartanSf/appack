local args = { ... }
local decompress = require("lib/luz/decompress")
local lualzw = require("lib/lualzw")

if (not args[1]) or fs.isDir(args[1]) or (not fs.exists(args[1])) then error("Must provide a package", 0) end

local packageFile = fs.open(args[1], "rb")
local packageContent = packageFile.readAll()
packageFile.close()

packageContent = textutils.unserialise(packageContent)

local function restoreTree(node, currentPath)
    if type(node) == "string" then node = textutils.unserialise(node) end
    assert(type(node.name) == "string", "Node missing 'name'")

    local realPath = fs.combine(currentPath, node.name)

    if node.isDir then
        if not fs.exists(realPath) then
            fs.makeDir(realPath)
        end
        if type(node.children) == "table" then
            for _, child in ipairs(node.children) do
                restoreTree(child, realPath)
            end
        end
    else
        if node.luzCompressed == true then
            local content = decompress(node.content or "")
            local file = fs.open(realPath, "wb")
            file.write(content)
            file.close()
        else
            local content = lualzw.decompress(node.content or "")
            local file = fs.open(realPath, "wb")
            file.write(content)
            file.close()
        end
    end
end

if packageContent and packageContent.metadata and packageContent.data then
    print("Installing package " ..
        packageContent.metadata.appName .. " " .. packageContent.metadata.version .. " by " ..
        packageContent.metadata.author)

    local rootTree = textutils.unserialise(packageContent.data)
    if not rootTree or type(rootTree) ~= "table" then
        error("Could not unserialise root tree", 0)
    end

    local programPath = packageContent.metadata.appName .. packageContent.metadata.version
    fs.makeDir(programPath)

    restoreTree(rootTree, programPath)

    local mainPath = fs.combine(programPath, "main.lua")

    if fs.exists(mainPath) then
        if packageContent.metadata.isolated then
            local mainFile = fs.open(mainPath, "rb")
            local mainContent = mainFile.readAll()
            mainFile.close()

            mainContent = [[-- ENVIRONMENT ISOLATION IS NOT SECURE. DO NOT RELY ON IT FOR OPERATIONS REQUIRING SECURITY.
-- PACKAGER CODE. APP IS ISOLATED.
local function __PACKAGER_MAIN()
if not fs.setEnvironment then
    require("/lib/newEnv")
end
fs.setEnvironment(true, "]] .. programPath .. [[")]] .. "\n-- PACKAGER INIT CODE END.\n" .. mainContent .. "\n-- PACKAGER CODE. APP IS ISOLATED.\nfs.unsetEnvironment()\nend" .. [[

xpcall(__PACKAGER_MAIN, function(err)
    printError("Caught error: "..tostring(err))
    fs.unsetEnvironment()
end)
-- PACKAGER ERROR ENVIRONMENT ESCAPE CODE END.]]

            mainFile = fs.open(mainPath, "wb")
            mainFile.write(mainContent)
            mainFile.close()
        end

        loadfile(mainPath, "bt", _ENV)()
    else
        if packageContent.metadata.isolated then
            error("main.lua is missing. Unable to add isolating code.", 0)
        end
        error("Package installed, however main.lua is missing.", 0)
    end
else
    error("Invalid package", 0)
end
