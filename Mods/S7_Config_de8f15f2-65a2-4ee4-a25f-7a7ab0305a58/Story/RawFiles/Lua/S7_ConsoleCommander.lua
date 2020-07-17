--  ###################################################################################################################################################
--                                                                 CONSOLE COMMANDER
--  ===================================================================================================================================================
logSource = "Lua:ConsoleCommander"
--  ###################################################################################################################################################

--  ================
--  CONSOLE COMMANDS
--  ================

function S7_Config_ConsoleCommander(...)
    local args = {...}
    local command = args[2] or ""

    if command == "StartModMenu" then
        --  START MOD-MENU
        --  ==============
        local hostCharacter = Osi.CharacterGetHostCharacter()
        if Osi.QRY_SpeakerIsAvailable(hostCharacter) then
            Osi.Proc_StartDialog(1, "S7_Config_ModMenu", hostCharacter)
            S7_ConfigLog("ModMenu activated by the host-character.")
        end
    elseif command == "AddSkill" then
        --  ADD SKILL
        --  =========
        local skillName = args[3] or ""
        local character = args[4] or ""
        AddSkill(skillName, character)
    elseif command == "RemoveSkill" then
        --  REMOVE SKILL
        --  ============
        local skillName = args[3] or ""
        local character = args[4] or ""
        RemoveSkill(skillName, character)
    elseif command == "StatSearch" then
        --  STAT SEARCH
        --  ===========
        local search = args[3] or ""
        local searchAttribute = args[4] or ""
        local searchType = args[5] or ""
        StatSearch(search, searchAttribute, searchType)
    elseif command == "StatSync" then
        --  SYNCHRONIZE STAT
        --  ================
        local statName = args[3] or ""
        local statPersistence = args[4] or false
        if Osi.NRD_StatExists(statName) then -- if stat-exists.
            Ext.SyncStat(statName, statPersistence) --  Sync
            S7_ConfigLog("Synchronized Stat: " .. statName)
        else
            S7_ConfigLog("Stat: " .. statName .. "does not exist!", "[Warning]")
        end
    elseif command == "SnapshotVars" then
        --  SNAPSHOT VARIABLES
        --  ==================
        local selectedType = args[3] or ""
        local selectedVar = args[4] or ""
        SnapshotVars(selectedType, selectedVar)
    elseif command == "Relay" then
        --  SEND SIGNAL TO MOD-MENU RELAY
        --  =============================
        local signal = args[3] or ""
        if signal == "" or signal == "Help" then
            S7_ConfigLog("\n" .. relayHelpMessage, "[Warning]")
        else
            S7_Config_ModMenuRelay(signal)
        end
    elseif command == "Help" or command == "" then
        --  HELP
        --  ====
        S7_ConfigLog("\n" .. helpMessage, "[Warning]")
    end

    ExportLog() -- Exports ConfigLogs if they're enabled.
end

helpMessage =
    [[
    ================================================================================================================================================
    Command         Argument1       Argument2       COMMENTS                                                   EXAMPLE
    ================================================================================================================================================
    Help            -               -               Prints a helpful list of commands.                         Help
    StartModMenu    -               -               Starts the Mod-Menu Dialog.                                StartModMenu
    AddSkill        <SkillID>       <Character>     Adds skill (skillID) to character (character-key).         AddSkill Projectile_Fireball Host
    RemoveSkill     <SkillID>       <Character>     Removes skill (skillID) to character (character-key).      RemoveSkill Shout_InspireStart
    StatSearch      <SearchString>  <StatType>      Search for (SearchString) in category (StatType).          StatSearch Summon_Incarnate SkillData
    StatSync        <StatID>        <Persistence>   Synchronize (StatID) for all clients.                      StatSync Projectile_PyroclasticRock
    SnapshotVars    <SelectedType>  <SelectedVar>   Prints details ofthe  relevant variable to the console.    SnapshotVars data configCollections
    Relay           <Signal>        -               Relay signal to ModMenu. Relay Help for more info.         Relay S7_BroadcastConfigData
    =================================================================================================================================================
    * Resize the console window if this doesn't fit properly.
]]

relayHelpMessage =
    [[
    =================================================================================================================
    Signals                         Purpose
    =================================================================================================================
    S7_StatsConfigurator            Loads and applies configuration-profile. (default: S7_Config.json)
    S7_BuildConfigData              Builds ConfigData file using configuration-profile (default: S7_Config.json)
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

--  ===============================================================
Ext.RegisterConsoleCommand("S7_Config", S7_Config_ConsoleCommander)
--  ===============================================================

--  ####################################################################################################################################################

--  ===================
--  ADD OR REMOVE SKILL
--  ===================

function AddSkill(skillName, character)
    if skillName ~= "" and skillName ~= nil then
        if Osi.NRD_StatExists(skillName) and Osi.NRD_StatGetType(skillName) == "SkillData" then
            FetchPlayers()
            if character == "" or character == nil or character == "Clients" then
                for userProfileID, contents in pairs(userInfo.clientCharacters) do
                    Osi.CharacterAddSkill(contents["currentCharacter"], skillName, 1)
                    S7_ConfigLog("Skill: " .. skillName .. " added to " .. contents["currentCharacterName"])
                end
            elseif character == "Host" then
                Osi.CharacterAddSkill(userInfo.hostCharacter["currentCharacter"], skillName, 1)
                S7_ConfigLog("Skill: " .. skillName .. " added to " .. userInfo.hostCharacter["currentCharacterName"])
            else
                for userProfileID, contents in pairs(userInfo.clientCharacters) do
                    if contents["currentCharacterName"] == character then
                        Osi.CharacterAddSkill(contents["currentCharacter"], skillName, 1)
                        S7_ConfigLog("Skill: " .. skillName .. " added to " .. contents["currentCharacterName"])
                    end
                end
            end
        else
            S7_ConfigLog(skillName .. " is not a skill.", "[Error]")
        end
    else
        S7_ConfigLog("Invalid SkillName", "[Error]")
    end
end

function RemoveSkill(skillName, character)
    if skillName ~= "" and skillName ~= nil then
        if Osi.NRD_StatExists(skillName) and Osi.NRD_StatGetType(skillName) == "SkillData" then
            FetchPlayers()
            if character == "" or character == nil or character == "Clients" then
                for userProfileID, contents in ipairs(userInfo.clientCharacters) do
                    Osi.CharacterRemoveSkill(contents["currentCharacter"], skillName)
                    S7_ConfigLog("Skill: " .. skillName .. " removed from " .. contents["currentCharacterName"])
                end
            elseif character == "Host" then
                Osi.CharacterRemoveSkill(userInfo.hostCharacter["currentCharacter"], skillName)
                S7_ConfigLog(
                    "Skill: " .. skillName .. " removed from " .. userInfo.hostCharacter["currentCharacterName"]
                )
            else
                for userProfileID, contents in pairs(userInfo.clientCharacters) do
                    if contents["currentCharacterName"] == character then
                        Osi.CharacterRemoveSkill(contents["currentCharacter"], skillName)
                        S7_ConfigLog("Skill: " .. skillName .. " removed from " .. contents["currentCharacterName"])
                    end
                end
            end
        else
            S7_ConfigLog(skillName .. " is not a skill.", "[Error]")
        end
    else
        S7_ConfigLog("Invalid SkillName", "[Error]")
    end
end

--  ===========
--  STAT SEARCH
--  ===========

function StatSearch(search, searchAttribute, searchType)
    if search ~= nil and search ~= "" then
        local allStat = {}
        if searchType ~= "" and searchType ~= nil then
            allStat = Ext.GetStatEntries(searchType)
        else
            allStat = Ext.GetStatEntries()
        end
        S7_ConfigLog("Search Results: ")
        S7_ConfigLog("=================================================")
        for i, stat in ipairs(allStat) do
            if string.match(stat, search) then
                if searchAttribute ~= "" or searchAttribute ~= nil then
                    S7_ConfigLog(stat .. ": " .. Ext.JsonStringify(Ext.StatGetAttribute(search, searchAttribute)))
                else
                    S7_ConfigLog(stat)
                end
            end
        end
        S7_ConfigLog("=================================================")
    else
        S7_ConfigLog("Search String Empty. Try something like Projectile_Fire", "[Warning]")
    end
end

--  =====================
--      SNAPSHOT VARS
--  =====================

function SnapshotVars(selectedType, selectedVar)
    local varList = {
        ["data"] = {
            ["modInfo"] = modInfo,
            ["ConfigSettings"] = ConfigSettings,
            ["userInfo"] = userInfo,
            ["configCollections"] = configCollections,
            ["quickMenuVars"] = quickMenuVars,
            ["toConfigure"] = toConfigure,
            ["toSync"] = toSync
        },
        ["Files"] = {
            ["Settings"] = Ext.LoadFile("S7_ConfigSettings.json") or DefaultSettings,
            ["ConfigFile"] = Ext.LoadFile(ConfigSettings.ConfigFile) or "",
            ["ConfigData"] = Ext.LoadFile(ConfigSettings.StatsLoader.FileName) or ""
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
                    S7_ConfigLog(selectedVar .. " : " .. Ext.JsonStringify(varList[selectedType][selectedVar]))
                else
                    for key, value in pairs(varList[selectedType]) do
                        S7_ConfigLog("\n" .. selectedType .. " : " .. key .. " : " .. Ext.JsonStringify(value))
                    end
                end
            else
                S7_ConfigLog("Invalid Variable Type", "[Error]")
            end
        end
    else
        for type, content in pairs(varList) do
            for key, value in pairs(content) do
                S7_ConfigLog("\n" .. type .. " : " .. key .. " : " .. Ext.JsonStringify(value))
            end
        end
    end
end

--  #####################################################################################################################################################
