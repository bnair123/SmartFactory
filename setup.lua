-- setup.lua

local GITHUB_REPO = "https://raw.githubusercontent.com/bnair123/SmartFactory/main"

function writeStartup(script)
    local startupFile = fs.open("startup", "w")
    startupFile.writeLine("shell.run('" .. script .. "')")
    startupFile.close()
end

function writeConfig(data)
    local file = fs.open("config.txt", "w")
    for k, v in pairs(data) do
        file.writeLine(k .. "=" .. v)
    end
    file.close()
end

function downloadScript(role)
    local scriptFile = role .. ".lua"
    print("Downloading " .. scriptFile .. "...")
    shell.run("wget -f " .. GITHUB_REPO .. "/" .. scriptFile .. " " .. scriptFile)
end

function setupMaster()
    local config = { role = "master" }
    downloadScript("master")
    writeConfig(config)
    writeStartup("master.lua")
    print("Master setup complete! Rebooting...")
    os.sleep(2)
    os.reboot()
end

function setupZone()
    write("Enter zone ID (e.g., smeltery): ")
    local zone_id = read()
    write("Enter zone rednet channel (e.g., 100): ")
    local zone_channel = read()
    local config = {
        role = "zone",
        zone_id = zone_id,
        zone_channel = zone_channel,
        version_file = "zone_version.txt"
    }
    downloadScript("zone")
    writeConfig(config)
    writeStartup("zone.lua")
    print("Zone setup complete! Rebooting...")
    os.sleep(2)
    os.reboot()
end

function setupTarget()
    write("Enter zone ID controlling this target (e.g., smeltery): ")
    local zone_id = read()
    write("Enter zone rednet channel (e.g., 100): ")
    local zone_channel = read()
    write("Enter target name (e.g., stone_smelter): ")
    local target_name = read()
    write("Enter recipes this target can handle (comma-separated, e.g., stone,iron_ingot): ")
    local recipes_raw = read()
    local recipes = recipes_raw:gsub("%s+", "")  -- remove spaces
    local config = {
        role = "target",
        zone_id = zone_id,
        zone_channel = zone_channel,
        target_name = target_name,
        recipes = recipes,
        version_file = "target_version.txt"
    }
    downloadScript("target")
    writeConfig(config)
    writeStartup("target.lua")
    print("Target setup complete! Rebooting...")
    os.sleep(2)
    os.reboot()
end

-- Main
print("Smart Factory Setup")
print("Select role:")
print("1. Master")
print("2. Zone Controller")
print("3. Target Machine")
write("Enter choice (1-3): ")
local choice = read()

if choice == "1" then
    setupMaster()
elseif choice == "2" then
    setupZone()
elseif choice == "3" then
    setupTarget()
else
    print("Invalid choice. Exiting setup.")
end
