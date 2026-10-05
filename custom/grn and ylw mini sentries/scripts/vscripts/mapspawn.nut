//Define model paths
const MINI_SENTRY_MODEL			= "models/buildables/sentry1_mini_4team.mdl"
const MINI_SENTRY_BUILD_MODEL	= "models/buildables/sentry1_mini_4team_heavy.mdl"
const DEFAULT_SENTRY_BLUEPRINT	= "models/buildables/sentry1_blueprint.mdl"

//Precache models
PrecacheModel(MINI_SENTRY_MODEL)
PrecacheModel(MINI_SENTRY_BUILD_MODEL)

function isSentry(obj) {
    return NetProps.GetPropInt(obj, "m_iObjectType") == 2
}

function isMiniOrDispBuilding(obj)
{
	if (!obj) return false
	//if building is not a sentry, return
	if(!isSentry(obj)) return false
	if(NetProps.GetPropBool(obj, "m_bDisposableBuilding") || NetProps.GetPropBool(obj, "m_bMiniBuilding")) return true
}

function applyMiniSentry(obj) {
    if (!obj || !obj.IsValid()) return
    obj.SetModel(MINI_SENTRY_MODEL)
}

function isMvm()
{
    local mapName = GetMapName()
    return mapName.find("mvm_") == 0
}

//Squid: no point in writing the same code twice
function OnGameEvent_player_builtobject(params)
{
	FixSentrySkins(params)
}
//this event is redundant in this case because the buildobject event fires anyway
//function OnGameEvent_player_dropobject(params)
//{
//	FixSentrySkins(params)
//}

function FixSentrySkins(params)
{
	//get the building type
	local objecttype = params.object
	
	//get the building itself
	local obj = (EntIndexToHScript(params.index))
	//if it isn't a sentry gun, return
	if(!isSentry(obj)) return
	//if it isn't disposable or a mini building, return
	if(!isMiniOrDispBuilding(obj)) return
	
	//get the team the building belongs to
	local objteam = obj.GetTeam()
	
	switch (objteam)
	{
		case 2:		//RED
			EntFireByHandle(obj, "skin", "4", 0, obj, obj)
			break
		case 3:		//BLU
			EntFireByHandle(obj, "skin", "5", 0, obj, obj)
			break
		case 4:		//GRN
			EntFireByHandle(obj, "skin", "6", 0, obj, obj)
			break
		case 5:		//YLW
			EntFireByHandle(obj, "skin", "7", 0, obj, obj)
			break
		default:	//Others
			EntFireByHandle(obj, "skin", "0", 0, obj, obj)
			break
	}
	
	//create script scope for sentry
	obj.ValidateScriptScope()
	local scope = obj.GetScriptScope()
	scope.lastCheckedLevel_art <- NetProps.GetPropInt(obj, "m_iUpgradeLevel")
	scope.MiniSentryBuildAnim <- function()
	{
		if (!obj || !obj.IsValid()) return null
		//get building level and construction progress
		local level = NetProps.GetPropInt(obj, "m_iUpgradeLevel")
		local pct   = NetProps.GetPropFloat(obj, "m_flPercentageConstructed")
		//if building is constructing and the gamemode is not mann vs machine
		if (pct < 1.0 && !isMvm())
		{
			local buildModel = MINI_SENTRY_BUILD_MODEL
			//if the building's current model is not the building animation
			if (obj.GetModelName() != buildModel)
			{
				//make it so
				obj.SetModel(buildModel)
				//restart the construction animation
				obj.SetSequence(obj.LookupSequence("build"))
			}
		}
		else
		{
			applyMiniSentry(obj)
			return null
		}
		return 0.0
	}
	AddThinkToEnt(obj, "MiniSentryBuildAnim")
}

function OnGameEvent_player_carryobject(params) {
    local obj = EntIndexToHScript(params.index)
    if (!obj || !obj.IsValid()) return
	//if the building is a sentry gun
    if (isSentry(obj))
	{
		//create a new script scope for the sentry
        obj.ValidateScriptScope()
        local scope = obj.GetScriptScope()
		//null the existing build animation scope
        scope.MiniSentryBuildAnim    <- function() { return null }
		//restore default blueprint model
        obj.SetModel(DEFAULT_SENTRY_BLUEPRINT)
        return
    }
}

__CollectGameEventCallbacks(this)