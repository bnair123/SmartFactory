-- master.lua

local VERSION = "0.0.1"
local GITHUB_REPO = "https://raw.githubusercontent.com/bnair123/SmartFactory/main"

-- Hardcoded FE setup (Phase I)
local TOTAL_FE = 960  -- Total FE/t
local zones = {
    smeltery = { channel = 100, fe = 240 },
    farm = { channel = 101, fe = 240 },
    workshop = { channel = 102, fe = 240 }
}

-- Recipe tracking
local global_recipes = {}  -- item → { zones = { smeltery, farm }, targets = { stone_smelter } }

-- Peripheral detection
local rs = peripheral.find("rsBridge")
if not rs then
    error("No rsBridge peripheral found!")
end

-- Rednet setup
rednet.open("back")  -- adjust to your modem side

-- Load zone recipes (populated by incoming announcements)
function handleZoneRecipeUpdate(message)
    local zone_id = message.zone_id
    for _, item in ipairs(message.recipes) do
        if not global_recipes[item] then
            global_recipes[item] = { zones = {}, targets = {} }
        end
        if not table.contains(global_recipes[item].zones, zone_id) then
            table.insert(global_recipes[item].zones, zone_id)
        end
    end
end

-- Check RS crafting needs
function checkRS()
    local crafting_tasks = rs.getCraftingTasks()
    for _, task in ipairs(crafting_tasks) do
        local item = task.item
        local amount = task.amount
        if global_recipes[item] then
            -- Broadcast task request
            rednet.broadcast({
                type = "TASK_REQUEST",
                item = item,
                amount = amount
            })
            print("Requested " .. amount .. " of " .. item)
        else
            print("No known zones for item: " .. item)
        end
    end
end

-- Handle task claims + power allocation
function handleClaims()
    local id, message = rednet.receive(0.5)
    if message and message.type == "TASK_CLAIM" then
        local zone_id = message.zone_id
        local fe_alloc = zones[zone_id].fe
        rednet.send(zones[zone_id].channel, {
            type = "ALLOCATE_POWER",
            fe = fe_alloc
        })
        print("Allocated " .. fe_alloc .. " FE/t to zone " .. zone_id)
    elseif message and message.type == "UPDATE_RECIPES" then
        handleZoneRecipeUpdate(message)
    end
end

-- Broadcast update signal
function broadcastUpdate()
    for role, _ in pairs(zones) do
        rednet.broadcast({
            type = "CHECK_UPDATE",
            version = VERSION,
            role = role
        })
    end
    print("Broadcasted update check (version " .. VERSION .. ")")
end

-- Utility function: check remote version file
function checkRemoteVersion(role)
    local remote_version_file = role .. "_version.txt"
    local remote_path = GITHUB_REPO .. "/" .. remote_version_file
    local local_version_file = fs.open(remote_version_file, "r")
    local local_version = local_version_file and local_version_file.readAll() or "0.0.0"
    if local_version_file then local_version_file.close() end

    shell.run("wget -f " .. remote_path .. " temp_version.txt")
    local remote_file = fs.open("temp_version.txt", "r")
    local remote_version = remote_file.readAll()
    remote_file.close()
    fs.delete("temp_version.txt")

    return remote_version, local_version
end

-- Main loop
print("Master controller running (Version " .. VERSION .. ")")

-- Initial hard allocation to all zones
for zone_id, zone in pairs(zones) do
    rednet.send(zone.channel, {
        type = "ALLOCATE_POWER",
        fe = zone.fe
    })
    print("Initial power allocation: " .. zone.fe .. " FE/t to " .. zone_id)
end

while true do
    checkRS()
    handleClaims()

    -- Example: trigger update check every 5 minutes
    if os.clock() % 300 < 1 then
        broadcastUpdate()
    end

    sleep(5)
end

