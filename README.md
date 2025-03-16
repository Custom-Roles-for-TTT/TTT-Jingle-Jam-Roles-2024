# _Custom Roles for TTT_ Roles Pack for Jingle Jam 2024
A pack of [Custom Roles for TTT](https://github.com/Custom-Roles-for-TTT/TTT-Custom-Roles) roles created based on the generous donations of our community members in support of [Jingle Jam 2024](https://www.jinglejam.co.uk/).

# Roles

## Barrel Mimic
_Suggested By_: Corvatile\
The Barrel Mimic is a jester role that can transform into a barrel. If their barrel is exploded and kills another player, they win!
\
\
**ConVars**
```cpp
ttt_barrelmimic_enabled             0   // Whether or not the barrel mimic should spawn
ttt_barrelmimic_spawn_weight        1   // The weight assigned to spawning the barrel mimic
ttt_barrelmimic_min_players         0   // The minimum number of players required to spawn the barrel mimic
ttt_barrelmimic_starting_health     100 // The amount of health the barrel mimic starts with
ttt_barrelmimic_max_health          100 // The maximum amount of health the barrel mimic can have
ttt_barrelmimic_announce            1   // Whether to announce that there is a barrel mimic
ttt_barrelmimic_respawn_all_deaths  1   // Whether to respawn when the Barrel Mimic is killed in any way. If disabled, they will only respawn when killed as a barrel
ttt_barrelmimic_respawn_delay       15  // The delay before the Barrel Mimic is killed without winning the round. If set to 0, they will not respawn
```

## Hoodoo
_Suggested By_: Corvatile\
_Based On_: Randoman, by The Stig\
The Hoodoo is a traitor role who is able to buy traitor-focused  events, rather than normal traitor items.\
_Requires [TTT Randomat 2.0 for Custom Roles for TTT](https://steamcommunity.com/sharedfiles/filedetails/?id=2055805086) to be installed._
\
\
**ConVars**
```cpp
ttt_hoodoo_enabled                    0      // Whether or not the hoodoo should spawn
ttt_hoodoo_spawn_weight               1      // The weight assigned to spawning the hoodoo
ttt_hoodoo_min_players                0      // The minimum number of players required to spawn the hoodoo
ttt_hoodoo_starting_health            100    // The amount of health the hoodoo starts with
ttt_hoodoo_max_health                 100    // The maximum amount of health the hoodoo can have
ttt_hoodoo_banned_randomats           "lame" // Events not allowed in the hoodoo's shop, separate ids with commas. You can find an ID by looking at an event in the randomat ULX menu.
ttt_hoodoo_prevent_auto_randomat      1      // Prevent auto-randomat triggering if there is a hoodoo at the start of the round.
ttt_hoodoo_guaranteed_categories      "biased_traitor" // At least one randomat from each of these categories will always be in the hoodoo's shop. Separate categories with a comma. Categories: biased_innocent, biased_traitor, biased_zombie, biased, deathtrigger, entityspawn, eventtrigger, fun, gamemode, item, largeimpact, moderateimpact, rolechange, smallimpact, spectator, stats
ttt_hoodoo_banned_categories          "gamemode,rolechange" // Randomats that have any of these categories will never be in the hoodoo's shop. Separate categories with a comma. You can find a randomat's category by looking at an event in the randomat ULX menu."
ttt_hoodoo_guaranteed_randomats       ""     // These events are guaranteed be in the hoodoo's shop, separate event IDs with commas.
ttt_hoodoo_event_on_unbought_death    0      // Whether a randomat should trigger if a hoodoo dies and never bought anything that round
ttt_hoodoo_choose_event_on_drop       1      // Whether the held randomat item should always trigger "Choose an event!" after being bought by a hoodoo and dropped on the ground
ttt_hoodoo_choose_event_on_drop_count 5      // The number of events a player should be able to choose from when using a dropped randomat
ttt_hoodoo_guarantee_pockets_event    1      // Whether the "What did I find in my pocket?" event should always be available in the hoodoo's shop while the beggar role is enabled
ttt_hoodoo_credits_starting           0      // The number of credits a hoodoo should start with
ttt_hoodoo_shop_sync                  0      // Whether a hoodoo should have all weapons that vanilla detectives have in their weapon shop
ttt_hoodoo_shop_random_percent        0      // The percent chance that a weapon in the shop will be not be shown for the hoodoo
ttt_hoodoo_shop_random_enabled        0      // Whether role shop randomization is enabled for the hoodoo
```

## Werewolf
_Suggested By_: Nick\
The Werewolf is an independent role who wins by being the last one standing, but can only kill under the cover of night.
\
\
**ConVars**
```cpp
ttt_werewolf_enabled                0       // Whether or not the Werewolf should spawn
ttt_werewolf_spawn_weight           1       // The weight assigned to spawning the Werewolf
ttt_werewolf_min_players            0       // The minimum number of players required to spawn the Werewolf
ttt_werewolf_starting_health        100     // The amount of health Werewolves start with
ttt_werewolf_max_health             100     // The maximum amount of health Werewolves can have
ttt_werewolf_is_monster             0       // Whether Werewolves should be treated as members of the monster team (rather than the independent team)
ttt_werewolf_night_visibility_mode  1       // Which players know when it is night. 0 - Only Werewolves, 1 - Everyone if a Werewolf is alive, 2 - Everyone if a Werewolf is in the round, 3 - Everyone regardless of whether a Werewolf exists
ttt_werewolf_timer_visibility_mode  1       // Which players see a timer showing when it will change to/from night. 0 - No one, 1 - Only Werewolves, 2 - Everyone
ttt_werewolf_fog_visibility_mode    2       // Which players see fog/darkness during the night. 0 - No one, 1 - Non-Werewolves, 2 - Everyone
ttt_werewolf_drop_weapons           0       // Whether Werewolves should drop their weapons on the ground when transforming
ttt_werewolf_transform_model        1       // Whether Werewolves' player models should change to a Werewolf while transformed
ttt_werewolf_hide_id                1       // Whether Werewolves' target ID (Name, health, karma etc.) should be hidden from other players' HUDs while transformed
ttt_werewolf_vision_mode            1       // Whether Werewolves see a visible aura around other players, visible through walls. 0 - Never, 1 - While transformed, 2 - Always
ttt_werewolf_show_target_icon       1       // Whether Werewolves see an icon over other players' heads showing who to kill. 0 - Never, 1 - While transformed, 2 - Always
ttt_werewolf_bloodthirst_tint       1       // Whether Werewolves' screens should go red while transformed
ttt_werewolf_night_tint             1       // Whether players' screens should be tinted during the night
ttt_werewolf_day_length_min         90      // The minimum length of the day phase in seconds
ttt_werewolf_day_length_max         120     // The maximum length of the day phase in seconds
ttt_werewolf_night_length_min       45      // The minimum length of the night phase in seconds
ttt_werewolf_night_length_max       60      // The maximum length of the night phase in seconds
ttt_werewolf_day_damage_penalty     0.5     // Damage penalty applied to damage dealt by Werewolves during the day (e.g. 0.5 = 50% less damage)
ttt_werewolf_night_damage_reduction 1       // Damage reduction applied to damage dealt to Werewolves during the night (e.g. 0.5 = 50% less damage)
ttt_werewolf_night_speed_mult       1.3     // The multiplier to use on Werewolves' movement speed during the night (e.g. 1.2 = 120% normal speed)
ttt_werewolf_night_sprint_recovery  0.12    // The amount of stamina Werewolves recover per tick at night
ttt_werewolf_leap_enabled           1       // Whether Werewolves have their leap attack enabled
ttt_werewolf_attack_damage          75      // The amount of a damage Werewolves do with their claws
ttt_werewolf_attack_delay           0.7     // The amount of time between Werewolves' claw attacks
ttt_werewolf_can_see_jesters        1       // Whether jesters are revealed (via head icons, color/icon on the scoreboard, etc.) to Werewolves
ttt_werewolf_update_scoreboard      1       // Whether Werewolves see dead players as missing in action on the scoreboard
```


# Special Thanks
- [Game icons](https://game-icons.net/) for the role icons
- [The Stig](https://steamcommunity.com/id/The-Stig-294) for the Randoman role that the Hoodoo was very heavily based on