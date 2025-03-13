local ROLE = {}

ROLE.nameraw = "werewolf"
ROLE.name = "Werewolf"
ROLE.nameplural = "Werewolves"
ROLE.nameext = "a Werewolf"
ROLE.nameshort = "wwf"

ROLE.desc = [[You are {role}!]]
ROLE.shortdesc = ""

ROLE.team = ROLE_TEAM_INDEPENDENT

ROLE.canseejesters = true
ROLE.canseemia = true

ROLE.convars = {
    {
        cvar = "ttt_werewolf_is_monster",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_werewolf_night_visibility_mode",
        type = ROLE_CONVAR_TYPE_DROPDOWN,
        choices = {"Only Werewolves", "Everyone if a Werewolf is alive", "Everyone if a Werewolf is in the round", "Everyone regardless of whether a Werewolf exists"},
        isNumeric = true
    },
    {
        cvar = "ttt_werewolf_timer_visibility_mode",
        type = ROLE_CONVAR_TYPE_DROPDOWN,
        choices = {"No one", "Only Werewolves", "Everyone"},
        isNumeric = true
    },
    {
        cvar = "ttt_werewolf_fog_visibility_mode",
        type = ROLE_CONVAR_TYPE_DROPDOWN,
        choices = {"No one", "Non-Werewolves", "Everyone"},
        isNumeric = true
    },
    {
        cvar = "ttt_werewolf_drop_weapons",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_werewolf_transform_model",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_werewolf_hide_id",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_werewolf_vision_mode",
        type = ROLE_CONVAR_TYPE_DROPDOWN,
        choices = {"Never", "While transformed", "Always"},
        isNumeric = true
    },
    {
        cvar = "ttt_werewolf_day_length_min",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_werewolf_day_length_max",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_werewolf_night_length_min",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_werewolf_night_length_max",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_werewolf_day_damage_penalty",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 2
    },
    {
        cvar = "ttt_werewolf_night_damage_reduction",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 2
    },
    {
        cvar = "ttt_werewolf_night_speed_mult",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 2
    },
    {
        cvar = "ttt_werewolf_night_sprint_recovery",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 2
    }
}

RegisterRole(ROLE)

local werewolf_is_monster = CreateConVar("ttt_werewolf_is_monster", 0, FCVAR_REPLICATED, "Whether Werewolves should be treated as members of the monster team")
local werewolf_night_visibility_mode = CreateConVar("ttt_werewolf_night_visibility_mode", 1, FCVAR_REPLICATED, "Which players know when it is night", 0, 3)
local werewolf_timer_visibility_mode = CreateConVar("ttt_werewolf_timer_visibility_mode", 1, FCVAR_REPLICATED, "Which players see a timer showing when it will change to/from night", 0, 2)
local werewolf_fog_visibility_mode = CreateConVar("ttt_werewolf_fog_visibility_mode", 1, FCVAR_REPLICATED, "Which players see fog/darkness during the night", 0, 2)
local werewolf_drop_weapons = CreateConVar("ttt_werewolf_drop_weapons", 0, FCVAR_REPLICATED, "Whether Werewolves should drop their weapons on the ground when transforming")
local werewolf_transform_model = CreateConVar("ttt_werewolf_transform_model", 1, FCVAR_REPLICATED, "Whether the Werewolves' player models should change to a Werewolf while transformed")
local werewolf_hide_id = CreateConVar("ttt_werewolf_hide_id", 1, FCVAR_REPLICATED, "Whether Werewolves' target ID (Name, health, karma etc.) should be hidden from other players' HUDs while transformed")
local werewolf_vision_mode = CreateConVar("ttt_werewolf_vision_mode", 1, FCVAR_REPLICATED, "Whether Werewolves have a visible aura around other players, visible through walls", 0, 2)
local werewolf_day_length_min = CreateConVar("ttt_werewolf_day_length_min", 90, FCVAR_REPLICATED, "The minimum length of the day phase in seconds", 1, 300)
local werewolf_day_length_max = CreateConVar("ttt_werewolf_day_length_max", 120, FCVAR_REPLICATED, "The maximum length of the day phase in seconds", 1, 300)
local werewolf_night_length_min = CreateConVar("ttt_werewolf_night_length_min", 45, FCVAR_REPLICATED, "The minimum length of the night phase in seconds", 1, 300)
local werewolf_night_length_max = CreateConVar("ttt_werewolf_night_length_max", 60, FCVAR_REPLICATED, "The maximum length of the night phase in seconds", 1, 300)
local werewolf_day_damage_penalty = CreateConVar("ttt_werewolf_day_damage_penalty", 0.5, FCVAR_REPLICATED, "Damage penalty applied to damage dealt by Werewolves during the day", 0, 1)
local werewolf_night_damage_reduction = CreateConVar("ttt_werewolf_night_damage_reduction", 1, FCVAR_REPLICATED, "Damage reduction applied to damage dealt to Werewolves during the night", 0, 1)
local werewolf_night_speed_mult = CreateConVar("ttt_werewolf_night_speed_mult", 1.2, FCVAR_REPLICATED, "The multiplier to use on Werewolves' movement speed during the night", 1, 2)
local werewolf_night_sprint_recovery = CreateConVar("ttt_werewolf_night_sprint_recovery", 0.12, FCVAR_REPLICATED, "The amount of stamina Werewolves recover per tick at night", 0, 1)

if SERVER then

end

if CLIENT then

end
