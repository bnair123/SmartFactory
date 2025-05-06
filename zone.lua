-- zone.lua

local VERSION = "0.0.1"
local GITHUB_REPO = "https://raw.githubusercontent.com/bnair123/SmartFactory/main"

-- Load local config
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

local zone_id = config.zone_id
local zone_channel = tonumber(config.zone_channel)
local master_channel = 1

-- Rednet setup
rednet.open("back")  -- adjust as needed

-- Peripherals
local energy_transfer = peripheral.find("energyDetector")
if not energy_transfer then
    error("No energyDetector block connected!")
end

-- Registered targets + recipes
local recipes = {}  -- item → { targets = {}, target_names = {} }

-- Helper: send recipe summary to master
function sendRecipeSummary()
    local summary = {
        type = "UPDATE_RECIPES",
        zone_id = zone_id,
        recipes = {},
        targets = {}
    }
    for item, data in pairs(recipes) do
        table.insert(summary.recipes, item)
        summary.targets[item] = data.target_names
    end
    rednet.send(master_channel, summary)
    print("Sent recipe summary to master.")
end

-- Handle target registrations
function handleRegisterTarget(message)
    for _, item in ipairs(message.recipes) do
        if not recipes[item] then
            recipes[item] = { targets = {}, target_names = {}, fe_per_unit = 20 }  -- example FE/unit
        end
        table.insert(recipes[item].targets, message.target_id)
        table.insert(recipes[item].target_names, message.name)
    end
    print("Registered target " .. message.name .. " for items: " .. table.concat(message.recipes, ", "))
    sendRecipeSummary()
end

-- Check if we can fulfill a task request
function handleTaskRequest(message)
    local item = message.item
    if recipes[item] then
        local claim = {
            type = "TASK_CLAIM",
            zone_id = zone_id,
            item = item,
            fe = recipes[item].fe_per_unit * message.amount
        }
        rednet.send(master_channel, claim)
        print("Claimed task for " .. item .. ", needs FE: " .. claim.fe)
    end
end

-- Handle power allocation
function handlePowerAllocation(message)
    print("Received power allocation: " .. message.fe .. " FE/t")
    energy_transfer.setOutput(message.fe)
end

-- Handle master update signal
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
        print("Updating zone script to version " .. remote_version)
        shell.run("wget -f " .. GITHUB_REPO .. "/zone.lua zone.lua")
        local vfile = fs.open(role .. "_version.txt", "w")
        vfile.write(remote_version)
        vfile.close()
        os.reboot()
    else
        print("Zone script already up to date.")
    end
end

-- Main loop
print("Zone Controller '" .. zone_id .. "' running (Version " .. VERSION .. ")")

while true do
    local id, message = rednet.receive(1)
    if message then
        if message.type == "REGISTER_TARGET" then
            handleRegisterTarget(message)
        elseif message.type == "TASK_REQUEST" then
            handleTaskRequest(message)
        elseif message.type == "ALLOCATE_POWER" then
            handlePowerAllocation(message)
        elseif message.type == "CHECK_UPDATE" then
            checkForUpdate("zone")
        end
    end
end
