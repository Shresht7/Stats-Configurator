--  =============
--  HELP MESSAGES
--  =============

local helpMessage =
    [[
    ================================================================================================================================================
    Command         Argument1       Argument2(Optional)  COMMENTS                                                   EXAMPLE
    ================================================================================================================================================
    Help            -               -                   Prints a list of all console-commands.                     Help
    AddConfigurator -               -                   Adds the configurator item to the host-character.          AddConfigurator
    StartModMenu    -               -                   Starts the Mod-Menu Dialog with the host-character.        StartModMenu
    AddSkill        <SkillID>       <Character>         Adds skill (skillID) to character (character-key).         AddSkill Projectile_Fireball Host
    RemoveSkill     <SkillID>       <Character>         Removes skill (skillID) to character (character-key).      RemoveSkill Shout_InspireStart
    SearchStat      <SearchString>  <StatType>          Search for (SearchString) in category (StatType).          SearchStat Summon_Incarnate SkillData
    SyncStat        <StatID>        <Persistence>       Synchronize (StatID) for all clients.                      SyncStat Projectile_PyroclasticRock
    SnapshotVars    <SelectedType>  <SelectedVar>       Prints details of variables to the console.                SnapshotVars data configCollections
    Reference       <StatType>      <AttributeType>     Lookup (StatType) and (AttributeType) in References.       Reference Weapon IsTwoHanded
    DeepDive        <StatID>        -                   Print alls valid attributes and their values.              DeepDive Shout_ShedSkin
    Relay           <Signal>        -                   Relay signal to ModMenu. 'Relay Help' for more info.       Relay S7_BroadcastConfigData
    =================================================================================================================================================
    * Resize the console window if this doesn't fit properly.
]]

local relayHelpMessage =
    [[
    =================================================================================================================
    Signals                         Purpose
    =================================================================================================================
    S7_StatsConfigurator            Loads and applies configuration-profile. (default: S7_Config.json)
    S7_BuildConfigData              Builds ConfigData file using configuration-profile. (default: S7_Config.json)
    S7_BroadcastConfigData          Broadcasts serialized ConfigData to all active clients.
    S7_ValidateClientConfig         Calls for client ConfigData validation. Check response in debug-console.
    S7_ToggleStatsLoader            Toggle StatsLoader setting. Responsible for loading ConfigData on ModuleLoad.
    S7_ToggleSyncStatPersistence    Toggles Sync-Stat Persistence. Stat-edits will be saved persistently if enabled.
    S7_ToggleSafetyCheck            Toggles safe-to-modify attribute check. Will prevent modification of certain keys.
    S7_SetDefaultSettings           Reset ConfigSettings to default values. Export to save persistently.
    S7_ExportCurrentSettings        Export current ConfigSettings. Saves settings in a json file in OsirisData.
    S7_RefreshSettings              Reloads settings from OsirisData folder. if unavailable, loads defaults.
    S7_StatsExportTSV               Export a list of all stat-entries to a TSV file in OsirisData folder.
    S7_Config_CHANGELOG             Request in-game changelog.
    S7_PrintModRegistry             Prints a list of all mods registered to Stats-Configurator.
    S7_RebuildCollections           Rebuilds collections using presets and custom settings.
    S7_ToggleConfigLog              Toggles logging to external file.
    ==================================================================================================================
    * Resize the console window if this doesn't fit properly.
]]

--  ================
--  CONSOLE COMMANDS
--  ================

function S7_Config_ConsoleCommander(...)
    local args = {...}
    local command = args[2] or ""

    if command == "AddConfigurator" then

        --  ADD CONFIGURATOR ITEM
        --  =====================
        
        local hostCharacter = Osi.CharacterGetHostCharacter()
        if Osi.ItemTemplateIsInPartyInventory(hostCharacter, "S7_Config_Inspector_c5959819-25e9-4dbc-ae20-0f6283502254", 1) < 1 then
            Osi.ItemTemplateAddTo("S7_Config_Inspector_c5959819-25e9-4dbc-ae20-0f6283502254", hostCharacter, 1)
            Debug:Print("Configurator added to Host-Character's Inventory.")
        else Debug:Print("Check your bags! The party has the Configurator already.") end

    elseif command == "StartModMenu" then
    
        --  START MOD-MENU
        --  ==============
    
        local hostCharacter = Osi.CharacterGetHostCharacter()
        if Osi.QRY_SpeakerIsAvailable(hostCharacter) then
            Osi.Proc_StartDialog(1, "S7_Config_ModMenu", hostCharacter)
            Debug:Print("ModMenu activated by the host-character.")
        end
    elseif command == "AddSkill" then
        --  ADD SKILL
        --  =========
        local skillName = args[3] or "" -- Skill to add. (Required)
        local character = args[4] or "" -- Character to add to. (Optional - defaults to all characters)
        AddSkill(skillName, character)
    elseif command == "RemoveSkill" then
        --  REMOVE SKILL
        --  ============
        local skillName = args[3] or "" -- Skill to remove. (Required)
        local character = args[4] or "" -- Character to remove from. (Optional - defaults to all characters)
        RemoveSkill(skillName, character)
    elseif command == "SearchStat" then
        --  STAT SEARCH
        --  ===========
        local search = args[3] or "" -- String to search for. (Required)
        local searchType = args[4] or "" -- Restricts the search to stats of only this type (Optional)
        SearchStat(search, searchType)
    elseif command == "SyncStat" then
        --  SYNCHRONIZE STAT
        --  ================
        local statName = args[3] or "" -- StatID to Synchronize (Optional - defaults to entire toSync queue)
        local statPersistence = args[4] or false -- Set stat-persistence (Optional - defaults to false)
        if statName ~= "" then
            if Osi.NRD_StatExists(statName) then -- if stat-exists.
                Ext.SyncStat(statName, statPersistence) --  Sync
                Debug:Print("Synchronized Stat: " .. statName)
            else
                Debug:Print("Stat: " .. statName .. "does not exist!")
            end
        else
            StatsSynchronize() --  Synchronize toSync queue
        end
    elseif command == "SnapshotVars" then
        --  SNAPSHOT VARIABLES
        --  ==================
        local selectedType = args[3] or "" --  Variable Group to snapshot (Optional - defaults to all)
        local selectedVar = args[4] or "" -- VariableName to snapshot (Optional)
        SnapshotVars(selectedType, selectedVar)
    elseif command == "Reference" then
        --  REFERENCE
        --  =========
        local statType = args[3] or "" --  statType to refer
        local attributeType = args[4] or "" -- attributeType to restrict search for (Optional)
        Reference(statType, attributeType)
    elseif command == "DeepDive" then
        local statName = args[3] or "" --  stat to print details of
        DeepDive(statName)
    elseif command == "Relay" then
        --  SEND SIGNAL TO MOD-MENU RELAY
        --  =============================
        local signal = args[3] or "" --  Flag to relay. (Optional - defaults to help)
        if signal == "" or signal == "Help" then
            Debug:Warn("\n" .. relayHelpMessage)
        else
            ModMenuRelay(signal)
        end
    elseif command == "Help" or command == "" then
        --  HELP
        --  ====
        Debug:Warn("\n" .. helpMessage)
    end
end

--  ===============================================================
Ext.RegisterConsoleCommand("S7_Config", S7_Config_ConsoleCommander)
--  ===============================================================

--  ####################################################################################################################################################

--  ===================
--  ADD OR REMOVE SKILL
--  ===================

function AddSkill(skillName, character)
    if ValidString(skillName) then
        if Osi.NRD_StatExists(skillName) and Osi.NRD_StatGetType(skillName) == "SkillData" then
            UserInformation:Fetch() --  Retrieve userData

            if character == "" or character == nil or character == "Clients" then --  AddSkill defaults to all Clients.
                for userProfileID, contents in pairs(UserInformation.Clients) do
                    Osi.CharacterAddSkill(contents["currentCharacter"], skillName, 1)
                    Debug:Print("Skill: " .. skillName .. " added to " .. contents["currentCharacterName"])
                end
            elseif character == "Host" then --  if Host specified
                Osi.CharacterAddSkill(UserInformation.Host["currentCharacter"], skillName, 1)
                Debug:Print("Skill: " .. skillName .. " added to " .. UserInformation.Host["currentCharacterName"])
            else
                for userProfileID, contents in pairs(UserInformation.Clients) do
                    if contents["currentCharacterName"] == character then
                        Osi.CharacterAddSkill(contents["currentCharacter"], skillName, 1)
                        Debug:Print("Skill: " .. skillName .. " added to " .. contents["currentCharacterName"])
                    end
                end
            end
        else
            Debug:Error(skillName .. " is not a skill.")
        end
    else
        Debug:Error("Please enter a valid SkillName.")
    end
end

function RemoveSkill(skillName, character)
    if ValidString(skillName) then
        if Osi.NRD_StatExists(skillName) and Osi.NRD_StatGetType(skillName) == "SkillData" then
            UserInformation:Fetch() --  Retrieve userData

            if character == "" or character == nil or character == "Clients" then --  Remove skill defaults to all Clients.
                for userProfileID, contents in pairs(UserInformation.Clients) do
                    Osi.CharacterRemoveSkill(contents["currentCharacter"], skillName)
                    Debug:Print("Skill: " .. skillName .. " removed from " .. contents["currentCharacterName"])
                end
            elseif character == "Host" then --  If Host specified.
                Osi.CharacterRemoveSkill(UserInformation.Host["currentCharacter"], skillName)
                Debug:Print("Skill: " .. skillName .. " removed from " .. UserInformation.Host["currentCharacterName"])
            else
                for userProfileID, contents in pairs(UserInformation.Clients) do
                    if contents["currentCharacterName"] == character then
                        Osi.CharacterRemoveSkill(contents["currentCharacter"], skillName)
                        Debug:Print("Skill: " .. skillName .. " removed from " .. contents["currentCharacterName"])
                    end
                end
            end
        else
            Debug:Error(skillName .. " is not a skill.")
        end
    else
        Debug:Error("Please enter a valid SkillName")
    end
end

--  ===========
--  STAT SEARCH
--  ===========

function SearchStat(search, searchType)
    if ValidString(search) then --  if search string is not empty or nil
        local allStat = {} -- temp variable to hold the list of stats

        if ValidString(searchType) then
            allStat = Ext.GetStatEntries(searchType)
        else
            allStat = Ext.GetStatEntries()
        end

        Debug:Print("Search Results: ")
        Debug:Print("=================================================")
        for i, stat in ipairs(allStat) do
            if string.match(stat, search) then
                Debug:Print(stat)
            end
        end
        Debug:Print("=================================================")
    else
        Debug:Error("Search String Empty. Try something like Projectile_")
    end
end

--  =============
--  SNAPSHOT VARS
--  =============

function SnapshotVars(selectedType, selectedVar)
    local varList = {
        ["data"] = {
            ["modInfo"] = MODINFO,
            ["ConfigSettings"] = ConfigSettings,
            ["userInfo"] = UserInformation,
            ["configCollections"] = Collections,
            ["quickMenuVars"] = QuickMenuVars,
            ["toConfigure"] = Configurations,
            ["toSync"] = Synchronizations
        },
        ["Files"] = {
            ["Settings"] = Ext.LoadFile(MODINFO.SubdirPrefix .. "S7_ConfigSettings.json") or Rematerialize(DefaultSettings),
            ["ConfigFile"] = Ext.LoadFile(MODINFO.SubdirPrefix .. ConfigSettings.ConfigFile) or "",
            ["ConfigData"] = Ext.LoadFile(MODINFO.SubdirPrefix .. ConfigSettings.StatsLoader.FileName) or ""
        },
        ["Flags"] = {
            ["S7_ConfigActive"] = Osi.GlobalGetFlag("S7_ConfigActive") or 0,
            ["S7_LearnInspect"] = Osi.GlobalGetFlag("S7_LearnInspect") or 0,
            ["S7_Config_GoBack"] = Osi.GlobalGetFlag("S7_Config_GoBack") or 0,
            ["S7_StatsExportTSV"] = Osi.GlobalGetFlag("S7_StatsExportTSV") or 0,
            ["S7_Config_SetOpt1"] = Osi.GlobalGetFlag("S7_Config_SetOpt1") or 0,
            ["S7_Config_SetOpt2"] = Osi.GlobalGetFlag("S7_Config_SetOpt2") or 0,
            ["S7_Config_SetOpt3"] = Osi.GlobalGetFlag("S7_Config_SetOpt3") or 0,
            ["S7_Config_SetOpt4"] = Osi.GlobalGetFlag("S7_Config_SetOpt4") or 0,
            ["S7_Config_SetOpt5"] = Osi.GlobalGetFlag("S7_Config_SetOpt5") or 0,
            ["S7_Config_NextPage"] = Osi.GlobalGetFlag("S7_Config_NextPage") or 0,
            ["S7_Config_PrevPage"] = Osi.GlobalGetFlag("S7_Config_PrevPage") or 0,
            ["S7_BuildConfigData"] = Osi.GlobalGetFlag("S7_BuildConfigData") or 0,
            ["S7_ToggleConfigLog"] = Osi.GlobalGetFlag("S7_ToggleConfigLog") or 0,
            ["S7_RefreshSettings"] = Osi.GlobalGetFlag("S7_RefreshSettings") or 0,
            ["S7_PrintModRegistry"] = Osi.GlobalGetFlag("S7_PrintModRegistry") or 0,
            ["S7_Config_CHANGELOG"] = Osi.GlobalGetFlag("S7_Config_CHANGELOG") or 0,
            ["S7_StatsConfigurator"] = Osi.GlobalGetFlag("S7_StatsConfigurator") or 0,
            ["S7_ToggleSafetyCheck"] = Osi.GlobalGetFlag("S7_ToggleSafetyCheck") or 0,
            ["S7_ToggleStatsLoader"] = Osi.GlobalGetFlag("S7_ToggleStatsLoader") or 0,
            ["S7_Config_ExitCleanUp"] = Osi.GlobalGetFlag("S7_Config_ExitCleanUp") or 0,
            ["S7_SetDefaultSettings"] = Osi.GlobalGetFlag("S7_SetDefaultSettings") or 0,
            ["S7_RebuildCollections"] = Osi.GlobalGetFlag("S7_RebuildCollections") or 0,
            ["S7_BroadcastConfigData"] = Osi.GlobalGetFlag("S7_BroadcastConfigData") or 0,
            ["S7_ValidateClientConfig"] = Osi.GlobalGetFlag("S7_ValidateClientConfig") or 0,
            ["S7_ExportCurrentSettings"] = Osi.GlobalGetFlag("S7_ExportCurrentSettings") or 0,
            ["S7_Config_MoveToNextLevel"] = Osi.GlobalGetFlag("S7_Config_MoveToNextLevel") or 0,
            ["S7_Config_ModAddedTo_NewGame"] = Osi.GlobalGetFlag("S7_Config_ModAddedTo_NewGame") or 0,
            ["S7_ToggleSyncStatPersistence"] = Osi.GlobalGetFlag("S7_ToggleSyncStatPersistence") or 0
        }
    }

    if ValidString(selectedType) then
        for type, _ in pairs(varList) do
            if selectedType == type then
                if ValidString(selectedVar) then
                    Debug:Print(selectedVar .. " : " .. Ext.JsonStringify(varList[selectedType][selectedVar]))
                else
                    for key, value in pairs(varList[selectedType]) do
                        Debug:Print("\n" .. selectedType .. " : " .. key .. " : " .. Ext.JsonStringify(value))
                    end
                end
            end
        end
    else
        for type, content in pairs(varList) do
            for key, value in pairs(content) do
                Debug:Print("\n" .. type .. " : " .. key .. " : " .. Ext.JsonStringify(value))
            end
        end
    end
end

--  =========
--  REFERENCE
--  =========

function Reference(statType, attributeType)
    if ValidString(statType) and (statType ~= "SkillData" or statType ~= "StatusData") then
        if ValidString(attributeType) then
            if statType ~= "SkillData" or statType ~= "StatusData" then
                for key, value in ipairs(References.StatObjectDefinitions[statType]) do
                    if value["@name"] == attributeType then
                        Debug:Print(Ext.JsonStringify(value))
                        if value["@type"] == "Enumeration" then
                            Debug:Print(Ext.JsonStringify(References.Enumerations[value["@enumeration_type_name"]]))
                        end
                    end
                end
            end
        else
            if statType == "SkillData" or statType == "StatusData" then
                Debug:Warn("Please sepecify the sub-type instead.")
                for key, value in pairs(SkillandStatusData) do
                    if key == statType then
                        Debug:Print(statType .. ": " .. Ext.JsonStringify(value))
                    end
                end
            else
                for key, content in pairs(References.StatObjectDefinitions) do
                    if key == statType then
                        Debug:Print(Ext.JsonStringify(content))
                    end
                end
            end
        end
    else Debug:Print("Please enter a type to refer.") end
end

--  ===============
--  DETAILED SEARCH
--  ===============

function DeepDive(statName)
    if ValidString(statName) and Osi.NRD_StatExists(statName) then
        local statType = HandleStatType(statName)
        local statData = Ext.GetStat(statName)

        Debug:Print("Showing details of: " .. statName .. " (" .. statType .. ")")
        Debug:Print("===========================================================")
        for _, content in pairs(References.StatObjectDefinitions[statType]) do
            if SafeToModify(statName, content["@name"]) then
                Debug:Print(content["@name"] .. " (" .. content["@type"] .. "): " .. Ext.JsonStringify(statData[content["@name"]]))
            end
        end
        Debug:Print("===========================================================")
    else Debug:Print("Invalid stat. Make sure that the stat in question actually exists.") end
end

--  #####################################################################################################################################################