--  ##################################################################################################################################################
--                                                                      AUXILIARY FUNCTIONS
--  ##################################################################################################################################################

--  ===========================================
S7_ModIdentifier = {
    ["modName"] = "S7_Config",
    ["modVersion"] = "0.5.2.5"
}
logSource = "Lua:S7_ConfigAuxiliary"
--  ===========================================

toSetDialogVar = {} --  Will holds a queue of pending dialog-variable changes. DialogVars are set and subsequently cleared by S7_SetDialogVars()

--  ##################
--       SETTINGS
--  ##################

--  Default Settings
--  ================

S7_DefaultSettings = {
    ["StatsLoader"] = true, --  Clients call StatsLoader() if true.
    ["ConfigFiles"] = {"S7_Config.json"}, --  A list of all the files the configurator will pull from.
    ["SyncStatPersistence"] = false, --  Changes made with Ext.SyncStat() will be stored persistently if true.
    ["ManuallySynchronize"] = {}, --  statIDs listed here can be manually synchronized using diagnostics-option. Pretty useless all-in-all.
    ["ExportStatIDtoTSV"] = {
        ["FileName"] = "S7_Config_AllTheStats.tsv", --  FileName for ExportedStats. Configurable for configuration sake.
        ["RestrictStatTypeTo"] = {} --  limits the search to only these statTypes. e.g. "Character", "Potions", "SkillData".
    },
    ["BypassSafetyCheck"] = false --  Bypasses S7_SafeToModify() and allow modification of unsupported or problematic keys.
}

S7_ConfigSettings = S7_DefaultSettings --  just to initialize S7_ConfigSettings.

function S7_SetDefaultSettings() --  Resets ConfigSettings to DefaultSettings listed above. On Player's request.
    S7_ConfigSettings = S7_DefaultSettings
    S7_DebugLog("Using default settings.", nil, "Settings", "Settings: Default")
end

--  Import Custom Settings
--  ======================

function S7_RefreshSettings() --  Overrides ConfigSettings on StatsLoaded event and Player's request.
    local function S7_CustomOrDefaultSettings(settingsOverride, setting) --  Overrides ConfigSettings. CustomSettings given priority over Default.
        if settingsOverride[setting] == false then --  If a settingsOverride setting has boolean false.
            return false -- Prevents the function from returning DefaultSettings when false is a valid return value. Only nil should skips settingsOverride.
        else
            return settingsOverride[setting] or S7_DefaultSettings[setting] --  Return settingsOverride (if not nil) or DefaultSettings(if settingsOverride is nil).
        end
    end

    local JSONsetting = Ext.LoadFile("S7_ConfigSettings.json") or "" --  Load CustomSettings json file.
    if (type(JSONsetting) == "string") and (JSONsetting ~= "") and (JSONsetting ~= nil) then --  if json file exists and is not empty.
        local settingsOverride = Ext.JsonParse(JSONsetting) --  Parse json-string.

        for setting, value in pairs(S7_DefaultSettings) do --  Iterate for every key in DefaultSettings.
            S7_ConfigSettings[setting] = S7_CustomOrDefaultSettings(settingsOverride, setting) --  Overrides the changes, pulls the rest from Default.
        end
        S7_DebugLog("Custom settings applied.", nil, "Settings", "Settings: Custom")
    else
        S7_DebugLog("Default settings applied.", nil, "Settings", "Settings: Default")
    end
end

--  ===================================================
Ext.RegisterListener("StatsLoaded", S7_RefreshSettings)
--  ===================================================

--  Export Current Settings
--  =======================

function S7_ExportCurrentSettings() --  Exports the current ConfigSettings to S7_ConfigSettings.json file.
    local exportSettings = Ext.JsonStringify(S7_ConfigSettings) --  stringifies ConfigSettings.
    Ext.SaveFile("S7_ConfigSettings.json", exportSettings) --  Save json file.
    S7_DebugLog("Exporting current ConfigSettings to S7_ConfigSettings.json")
end

--  ############################################################################################################################################

--  #######################
--  STATE-OF-THE-ART-LOGGER
--  #######################

function S7_DebugLog(...) --  Amped up DebugLog.
    local logArgs = {...} --  Multiple Arguments stored in a table.
    local logMsg = logArgs[1] or "" --  The actual log message.
    local logType = logArgs[2] or "[Log]" --  logType tags - e.g. [Warning] or [Osiris] etc.
    local dialogVar = logArgs[3] or nil --  Associated DialogVars (if any).
    local dialogVal = logArgs[4] or logMsg or "" --  Value for the corresponding dialog-var. uses logMsg if empty.

    local S7ConfigLog = ""

    if Ext.LoadFile("S7_ConfigLog.tsv") == nil then --  if the file does not exist
        Ext.SaveFile("S7_ConfigLog.tsv", "State\tLogType\tLog\tAssociated DialogVariable\tDialogValue\n") --  Save file with header column
    end

    S7ConfigLog = S7ConfigLog .. Ext.LoadFile("S7_ConfigLog.tsv") --  If file exists - load all data into S7ConfigLog

    local luaState = ""
    if Ext.IsServer() then
        luaState = "[Server]" --  Code running on Server.
    elseif Ext.IsClient() then
        luaState = "[Client]" --  Code running on Client.
    end

    local logCat = logSource
    local printFunction = Ext.Print --  Default Print Function

    local switchCase = {
        ["[Initializer]"] = "Osiris:Initializer",
        ["[ModVersioning]"] = "Osiris:ModVersioning",
        ["[ModMenu]"] = "Osiris:ModMenu",
        ["[Warning]"] = Ext.PrintWarning,
        ["[Error]"] = Ext.PrintError
    }
    for switch, case in pairs(switchCase) do --  Surrogate SwitchCase
        if logType == switch then --  logType match
            if type(case) == "string" then
                logCat = case --  update logSource if logType points to a string
                break
            elseif type(case) == "function" then
                printFunction = case --  update printFunction if logType points to a function
                break
            end
        end
    end

    local log = "[" .. S7_ModIdentifier.modName .. " - " .. logCat .. "] --- " .. logMsg --  The compiled log message.

    S7ConfigLog = S7ConfigLog .. "\n" .. luaState .. "\t" .. logType .. "\t" .. log

    if dialogVar ~= nil then --  If associated dialogVar specified.
        toSetDialogVar[dialogVar] = dialogVal --  Queue dialogVar
        S7ConfigLog = S7ConfigLog .. "\t" .. dialogVar .. "\t" .. dialogVal
    end

    printFunction(log) --  prints log to Extender's Debug Console
    Ext.SaveFile("S7_ConfigLog.tsv", S7ConfigLog) --  SaveLog in a TSV file.
end

--  =========================================================================================================================================
if Ext.IsServer() then
    Ext.NewCall(S7_DebugLog, "S7_DebugLog", "(STRING)_Log")
    Ext.NewCall(S7_DebugLog, "S7_DebugLog", "(STRING)_Log, (STRING)_LogType")
    Ext.NewCall(S7_DebugLog, "S7_DebugLog", "(STRING)_Log, (STRING)_LogType, (STRING)_LogDialogVar")
    Ext.NewCall(
        S7_DebugLog,
        "S7_DebugLog",
        "(STRING)_Log, (STRING)_LogType, (STRING)_LogDialogVar, (STRING)_LogDialogVal"
    )
end
--  =========================================================================================================================================

--  #########################################################################################################################################

--  SET DIALOG VARIABLES
--  ====================

function S7_SetDialogVars() --  Short-hand for DialogSetVariableFixedString(). Isn't called instantly so changes are applied when Osiris is available.
    local dialogCase = {
        ["StatsLoader"] = "S7_Config_StatsLoader_11670d82-a36e-4657-9868-5fdb7c86db37",
        ["StatsConfigurator"] = "S7_Config_StatsConfiguratorResponse_68b60e77-cbff-460d-8a78-5a264fe0bbcb",
        ["Settings"] = "S7_Config_Settings_c02bc213-de0d-4f0f-b501-7b8913d146a6",
        ["ExportStats"] = "S7_Config_ExportedStats_e59ebc61-6f13-4e91-9200-36e474113c48",
        ["SyncStat"] = "S7_Config_SyncStat_7506390a-9fa8-4300-8abd-5dc476e6b917",
        ["SyncStatPersistence"] = "S7_SyncStatPersistence_e48a7ea1-a9e4-430e-8ccc-99fe3fcc477a",
        ["BypassSafetyCheck"] = "S7_Config_BypassSafety_06618d4e-dff1-4bfb-a0e2-14865b5dfb64",
        ["ModAddedTo"] = "S7_Config_ModAddedTo_70f2c40a-2237-4041-aed6-d1f1623d0ab6",
        ["ModID"] = "S7_Config_ModID_76d92488-990f-45d4-828a-525bf966efaa"
    }

    if S7_ConfigSettings.StatsLoader == true then
        toSetDialogVar["StatsLoader"] = "StatsLoader: Activated."
    else
        toSetDialogVar["StatsLoader"] = "StatsLoader: Deactivated."
    end
    if S7_ConfigSettings.SyncStatPersistence == true then
        toSetDialogVar["SyncStatPersistence"] = "SyncStatPersistence: Activated."
    else
        toSetDialogVar["SyncStatPersistence"] = "SyncStatPersistence: Deactivated."
    end
    if S7_ConfigSettings.BypassSafetyCheck == true then
        toSetDialogVar["BypassSafetyCheck"] = "BypassSafetyCheck: Activated."
    else
        toSetDialogVar["BypassSafetyCheck"] = "BypassSafetyCheck: Deactivated."
    end

    if type(next(toSetDialogVar)) ~= "nil" then --  dialogVar cache is not empty.
        for dialogVar, dialogVal in pairs(toSetDialogVar) do --  for entries in toSetDialogVar
            for dialogName, dialogVariable in pairs(dialogCase) do
                if dialogVar == dialogName then --  If entries match those in dialogCase
                    Osi.DialogSetVariableFixedString("S7_Config_ModMenu", dialogVariable, dialogVal) -- Set DialogVariables.
                end
            end
        end
    end
end

--  =====================================================
if Ext.IsServer() then
    Ext.NewCall(S7_SetDialogVars, "S7_SetDialogVars", "")
end
--  =====================================================

--  EXPORT STATS TO TSV
--  ===================

function S7_StatsExportTSV() --  Fetches literally every stat and exports to TSV.
    Ext.SaveFile(S7_ConfigSettings.ExportStatIDtoTSV.FileName, "") --  Creates an empty TSV or Overwrites the existing one.
    local SaveAllStatsToFile = "S.No\tType\tStatID\n" --  Header Column.

    local allStat = {} --  Initialize temporary table.
    if type(next(S7_ConfigSettings.ExportStatIDtoTSV.RestrictStatTypeTo)) == "nil" then --  No restrictions in settings.
        allStat = Ext.GetStatEntries() --  Get All Stat Entries
    else
        for i, statType in ipairs(S7_ConfigSettings.ExportStatIDtoTSV.RestrictStatTypeTo) do --  Only selected statTypes are loaded.
            local limitedStats = Ext.GetStatEntries(statType)
            for j, stats in ipairs(limitedStats) do
                table.insert(allStat, stats) --  appends selected stat-type entries to allStat.
            end
        end
    end

    for key, value in ipairs(allStat) do
        local type = NRD_StatGetType(value) --  Didn't I just filter stats by statType? - this is what happens when you return to old code with new ideas.
        SaveAllStatsToFile = SaveAllStatsToFile .. key .. "\t" .. type .. "\t" .. value .. "\n" --  Tab Separated Values format.
    end
    Ext.SaveFile(S7_ConfigSettings.ExportStatIDtoTSV.FileName, SaveAllStatsToFile) --  Save TSV files.
    S7_DebugLog("Stats exported to TSV file.", nil, "ExportStats")
end

--  INSPECT SKILL
--  =============

local function S7_InspectStats(StatID, StatType) --  Recieves StatID and StatType from Osiris.
    local compareStat = Ext.GetStatEntries(StatType) --  Retrieves all stat entries of corresponding stat-type for comparison.
    for name, content in pairs(compareStat) do --  Iterate over compareStat.
        if content == StatID then
            S7_DebugLog("Inspected: (" .. StatType .. "): " .. StatID)
        end
    end
end

--  =====================================================================================
if Ext.IsServer() then
    Ext.NewCall(S7_InspectStats, "S7_InspectStats", "(STRING)_StatID, (STRING)_StatType")
end
--  =====================================================================================

--  ###########################################################################################################################################################
