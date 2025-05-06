-- target.lua

local VERSION = "0.0.1"
local GITHUB_REPO = "https://raw.githubusercontent.com/bnair123/SmartFactory/main"

-- Load config
local config = {}
local config_file = fs.open("config.txt", "r")
if config_file then
    while true do
        local line = config_file.readLine()
        if not line then break end
        local k, v = line:match("([^=]+)=([^=]+)")
        config[k] = v
    end
    config_file.close()
else
    error("Missing config.txt!")
end

local target_id = os.getComputerID()
local zone_id = config.zone_id
local zone_channel = tonumber(config.zone_channel)
local target_name = config.target_name
local recipes = {}
for recipe in string.gmatch(config.recipes, '([^,]+)') do
    table.insert(recipes, recipe)
end

-- Rednet setup
rednet.open("back")  -- adjust as needed

-- Peripherals
local scroller = peripheral.find("scroller_plane")
if not scroller then
    error("No scroller_plane connected!")
end

-- Register with zone
rednet.send(zone_channel, {
    type = "REGISTER_TARGET",
    target_id = target_id,
    name = target_name,
    recipes = recipes
})
print("Registered with zone " .. zone_id .. " as '" .. target_name .. "'")

-- Adjust motor speed (fixed in Phase I)
function setMotorSpeed(fe_allocated)
    local max_fe = 480
    local rpm = (fe_allocated / max_fe) * 256
    scroller.setSpeed(rpm)
    print("Set motor speed to " .. rpm .. " RPM for allocated " .. fe_allocated .. " FE/t")
end

-- Check for updates
function checkForUpdate(role)
    local local_version_file = fs.open(role .. "_version.txt", "r")
    local local_version = local_version_file and local_version_file.readAll() or "0.0.0"
    if local_version_file then local_version_file.close() end

    local remote_version_file = role .. "_version.txt"
    local remote_path = GITHUB_REPO .. "/" .. remote_version_file
    shell.run("wget -f " .. remote_path .. " temp_version.txt")
    local remote_file = fs.open("temp_version.txt", "r")
    local remote_version = remote_file.readAll()
    remote_file.close()
    fs.delete("temp_version.txt")

    if remote_version > local_version then
        print("Updating target script to version " .. remote_version)
        shell.run("wget -f " .. GITHUB_REPO .. "/target.lua target.lua")
        local vfile = fs.open(role .. "_version.txt", "w")
        vfile.write(remote_version)
        vfile.close()
        os.reboot()
    else
        print("Target script already up to date.")
    end
end

-- Main loop
while true do
    local id, message = rednet.receive(1)
    if message then
        if message.type == "SET_POWER" and message.target_id == target_id then
            setMotorSpeed(message.fe)
        elseif message.type == "CHECK_UPDATE" then
            checkForUpdate("target")
        end
    end
end
