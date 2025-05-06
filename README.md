# SmartFactory
Making a smart factory in MC using CC:Tweaked and RS?AE2 as well as other supporting mods

## Goal
The goal of this project is to make my factory in minecraft smart, such that I am able to control the entire factory and use as little resources (primarily power) to run everything. The base of the project is the create mod, CC:Tweaked and Refined storage.

It also uses advanced peripherals, CC:C, create crafts and additions and more.

Incredibly ambitious project, designed around Supervisory Control and Data Acquisition (SCADA) system in real life, with delegation/horearchy in order to spread the load and keep each system efficient. Though with the limitation of this being in mc this may be too ambitous or I need to work more efficiently ( ie start offloading work to external systems)
In theory up until phase 2 doesn't seem to be too hard to do, though I suspect I will eat my words once I start building it.


## Phases of project
### Phase 1
The primary objective is to just get the skeleton working with the following goals:
- Have system hirearchy ready
    - Master <-> Zonal <-> Target but the target computers for now will also listed to master to see if the update command has been issued
- Work off hardcoded values of power
- Idle state is zones have power but no lines are by default on
- Target during setup announces what it can make in recipes to zone and what its id is, zone then informs master the same info with the zone
    - Master will maintain global list of recipes it can make but is more relevant for the future. No reason not to collect right now for now
- Update command can be issued from master to make iterating software easier
    - Simple look at software version vs the _version.txt and if higher then pull
- Config stored in config.txt to keep persistent between updates
- Unifed setup script that loads and helps setup
- Connection from master to RS (will abstract away to also allow for AE2 in the future)
- Master broadcasts what needs to be crafted, zones that are relevant ask for permission from master and master approves or denies it (to avoid potential conflicts) and allocated it more power
- Zones turn on relevant line to produce and let RS deal with rest
- Review everything, and any changes that need to be made

### Phase 2
- Target/lines become more dynamic
    - Min and max is established (in terms of rotation/SU)
    - Power is adjusted to esaxtly meet speed requirements (Target also get access to stressometer and scroller plane to speed up or slow down motor and then finally adjust power)
    - Able to establish difference between farm and factory --> Farm can stay on during idle whereas prod line not necessary in idle state
    - Prod lines adjust to priority (based on min and max etc)
    - Maybe also attach speedcontroller and scroller plane for more su but not speed?
- Target, zonal and master all negotiate power budget
- Master can activate crafts to keep items in stock
- Master gets overview of processes running and can turn zone or line on
- Master can work on dynamic power budget and account for emergy battery reserves
- Master looks at queue and adjusts priority (ie if 1024k stone needs to be made but only 64 glowstone give significantly more power to stone to speed up prod time)
- Manual override if communication goes down
- Review everything, and any changes that need to be made

### Phase 3
- Targets collect stat (how long processing an item or stack of item takes, amount of power etc) and learns at different speeds and use that for power negotiation
- Targets sends stats to zonal controller that then summerizes and sends to master
- Master collects stats and sends stats to gateway for API and bringing data out in real world
- Gui to see factory stats and control (each zone will have display to control as well as easy specific line and master controller)
- Master learns power demands and stores it
- Encrypted communication (for relevant messages, ie control messages)
- Make system be able to use both cable and wireless as necessary
- Centralised chest that can be used to individually direct soemthing to specific production line with output chest as well
- Control over relevant rail network (Ie ask for something from neighboring farm and send train out for it)
- Review everything, and any changes that need to be made

### Phase 4 (Very optimistic thinking)
- Master starts adjusting its item stocking based on when idle (differentiate between user and computer requests)
- Learn to use battery system more dynamically (ie for bursty loads, but keep charged otherwise)
- (Maybe) Offsite battery backup for real emergencies
- Web site control over factory and GUI to see stats etc
- Add redundancy
- If server wide grid is estbalished and policy to return power to the grid to make profit or store power with grid
- Turtle based delivery system
- If server economy allows then buy and sell as necessary
- Seperated prod lines of same production to optimise for very low power vs high power?
- Review everything, and any changes that need to be made
