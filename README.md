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
ttt_barrelmimic_enabled             0   // Whether or not the Barrel Mimic should spawn
ttt_barrelmimic_spawn_weight        1   // The weight assigned to spawning the Barrel Mimic
ttt_barrelmimic_min_players         0   // The minimum number of players required to spawn the Barrel Mimic
ttt_barrelmimic_starting_health     100 // The amount of health the Barrel Mimic starts with
ttt_barrelmimic_max_health          100 // The maximum amount of health the Barrel Mimic can have
ttt_barrelmimic_announce            1   // Whether to announce that there is a Barrel Mimic
ttt_barrelmimic_respawn_all_deaths  1   // Whether to respawn when the Barrel Mimic is killed in any way. If disabled, they will only respawn when killed as a barrel
ttt_barrelmimic_respawn_delay       15  // The delay before the Barrel Mimic is killed without winning the round. If set to 0, they will not respawn
ttt_barrelmimic_notify_mode         0   // The logic to use when notifying players that a Barrel Mimic was killed. Killer is notified unless "ttt_barrelmimic_notify_killer" is disabled. 0 - Don't notify anyone. 1 - Only notify traitors and detective. 2 - Only notify traitors. 3 - Only notify detective. 4 - Notify everyone.
ttt_barrelmimic_notify_killer       1   // Whether to notify a Barrel Mimic's killer
ttt_barrelmimic_notify_sound        0   // Whether to play a cheering sound when a Barrel Mimic is killed
ttt_barrelmimic_notify_confetti     0   // Whether to throw confetti when a Barrel Mimic is a killed
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

## Pharaoh
_Suggested By_: Fat_Medibirb\
_Based On_: [\[TTT2\] Pharaoh](https://steamcommunity.com/sharedfiles/filedetails/?id=2002040119), by Tim | Mineotopia\
The Pharaoh is an innocent role that can place an Ankh in the world somewhere. If they die, they consume the Ankh and respawn where it was placed.
\
\
**ConVars**
```cpp
ttt_pharaoh_enabled                0   // Whether or not the Pharaoh should spawn
ttt_pharaoh_spawn_weight           1   // The weight assigned to spawning the Pharaoh
ttt_pharaoh_min_players            0   // The minimum number of players required to spawn the Pharaoh
ttt_pharaoh_starting_health        100 // The amount of health Pharaohs start with
ttt_pharaoh_max_health             100 // The maximum amount of health Pharaohs can have
ttt_pharaoh_is_independent         0   // Whether Pharaohs should be treated as independent
ttt_pharaoh_steal_time             15  // The amount of time it takes to steal an Ankh
ttt_pharaoh_innocent_steal         0   // Whether innocents are allowed to steal the Ankh
ttt_pharaoh_traitor_steal          1   // Whether traitors are allowed to steal the Ankh
ttt_pharaoh_jester_steal           0   // Whether jesters are allowed to steal the Ankh
ttt_pharaoh_independent_steal      1   // Whether independents are allowed to steal the Ankh
ttt_pharaoh_monster_steal          1   // Whether monsters are allowed to steal the Ankh
ttt_pharaoh_respawn_delay          20  // How long (in seconds) after death a Pharaoh should respawn if they placed down an Ankh. Set to 0 to disable respawning
ttt_pharaoh_respawn_warn_pharaoh   1   // Whether the original Pharaoh owner of an Ankh should be notified when it's used by someone else
ttt_pharaoh_ankh_health            500 // How much health the Ankh should have
ttt_pharaoh_move_ankh              1   // Whether an Ankh's owner can move it
ttt_pharaoh_ankh_heal_repair_dist  150 // The maximum distance away the Pharaoh can be for the heal and repair to occur. Set to 0 to disable
ttt_pharaoh_ankh_heal_rate         1   // How often (in seconds) the Pharaoh should heal when they are near the Ankh. Set to 0 to disable
ttt_pharaoh_ankh_heal_amount       1   // How much to heal the Pharaoh per tick when they are near the Ankh. Set to 0 to disable
ttt_pharaoh_ankh_repair_rate       1   // How often (in seconds) the Ankh should repair when their Pharaoh is near. Set to 0 to disable
ttt_pharaoh_ankh_repair_amount     5   // How much to repair the Ankh per tick when their Pharaoh is near it. Set to 0 to disable
ttt_pharaoh_damage_own_ankh        0   // Whether an Ankh's owner can damage it
ttt_pharaoh_warn_damage            1   // Whether to warn an Ankh's owner is warned when it is damaged
ttt_pharaoh_warn_destroy           1   // Whether to warn an Ankh's owner is warned when it is destroyed
ttt_pharaoh_warn_steal             1   // Whether to warn an Ankh's owner is warned when it is stolen
ttt_pharaoh_can_see_jesters        1   // Whether jesters are revealed (via head icons, color/icon on the scoreboard, etc.) to Pharaohs. Only used when "ttt_pharaoh_is_independent" is enabled
ttt_pharaoh_update_scoreboard      1   // Whether Pharaohs see dead players as missing in action on the scoreboard. Only used when "ttt_pharaoh_is_independent" is enabled
```

## Werewolf
_Contributed By_: Nick\
The Werewolf is an independent role who wins by being the last one standing, but can only kill under the cover of night.\
_[Fenrir (Smite) Playermodel](https://steamcommunity.com/sharedfiles/filedetails/?id=497666467) required for visual werewolf transformation._
\
\
**ConVars**
```cpp
ttt_werewolf_enabled                0    // Whether or not the Werewolf should spawn
ttt_werewolf_spawn_weight           1    // The weight assigned to spawning the Werewolf
ttt_werewolf_min_players            0    // The minimum number of players required to spawn the Werewolf
ttt_werewolf_starting_health        100  // The amount of health Werewolves start with
ttt_werewolf_max_health             100  // The maximum amount of health Werewolves can have
ttt_werewolf_is_monster             0    // Whether Werewolves should be treated as members of the monster team (rather than the independent team)
ttt_werewolf_night_visibility_mode  1    // Which players know when it is night. 0 - Only Werewolves, 1 - Everyone if a Werewolf is alive, 2 - Everyone if a Werewolf is in the round, 3 - Everyone regardless of whether a Werewolf exists
ttt_werewolf_timer_visibility_mode  1    // Which players see a timer showing when it will change to/from night. 0 - No one, 1 - Only Werewolves, 2 - Everyone
ttt_werewolf_fog_visibility_mode    2    // Which players see fog/darkness during the night. 0 - No one, 1 - Non-Werewolves, 2 - Everyone
ttt_werewolf_drop_weapons           0    // Whether Werewolves should drop their weapons on the ground when transforming
ttt_werewolf_transform_model        1    // Whether Werewolves' player models should change to a Werewolf while transformed
ttt_werewolf_hide_id                1    // Whether Werewolves' target ID (Name, health, karma etc.) should be hidden from other players' HUDs while transformed
ttt_werewolf_vision_mode            1    // Whether Werewolves see a visible aura around other players, visible through walls. 0 - Never, 1 - While transformed, 2 - Always
ttt_werewolf_show_target_icon       1    // Whether Werewolves see an icon over other players' heads showing who to kill. 0 - Never, 1 - While transformed, 2 - Always
ttt_werewolf_bloodthirst_tint       1    // Whether Werewolves' screens should go red while transformed
ttt_werewolf_night_tint             1    // Whether players' screens should be tinted during the night
ttt_werewolf_day_length_min         75   // The minimum length of the day phase in seconds
ttt_werewolf_day_length_max         105  // The maximum length of the day phase in seconds
ttt_werewolf_night_length_min       20   // The minimum length of the night phase in seconds
ttt_werewolf_night_length_max       40   // The maximum length of the night phase in seconds
ttt_werewolf_day_damage_penalty     0.5  // Damage penalty applied to damage dealt by Werewolves during the day (e.g. 0.5 = 50% less damage)
ttt_werewolf_night_damage_reduction 1    // Damage reduction applied to damage dealt to Werewolves during the night (e.g. 0.5 = 50% less damage)
ttt_werewolf_night_speed_mult       1.3  // The multiplier to use on Werewolves' movement speed during the night (e.g. 1.2 = 120% normal speed)
ttt_werewolf_night_sprint_recovery  0.15 // The amount of stamina Werewolves recover per tick at night
ttt_werewolf_leap_enabled           1    // Whether Werewolves have their leap attack enabled
ttt_werewolf_attack_damage          75   // The amount of a damage Werewolves do with their claws
ttt_werewolf_attack_delay           0.7  // The amount of time between Werewolves' claw attacks
ttt_werewolf_can_see_jesters        1    // Whether jesters are revealed (via head icons, color/icon on the scoreboard, etc.) to Werewolves. Only used when "ttt_werewolf_is_monster" is disabled
ttt_werewolf_update_scoreboard      1    // Whether Werewolves see dead players as missing in action on the scoreboard. Only used when "ttt_werewolf_is_monster" is disabled
```

## Wheel Boy
_Suggested By_: spammonster\
Wheel Boy is a jester role that can spin a wheel to apply random effects to everyone. Spin enough times and they win.
\
\
**ConVars**
```cpp
ttt_wheelboy_enabled             0    // Whether or not Wheel boy should spawn
ttt_wheelboy_spawn_weight        1    // The weight assigned to spawning Wheel boy
ttt_wheelboy_min_players         0    // The minimum number of players required to spawn Wheel boy
ttt_wheelboy_starting_health     150  // The amount of health Wheel boy starts with
ttt_wheelboy_max_health          150  // The maximum amount of health Wheel boy can have
ttt_wheelboy_wheel_time          15   // How long the wheel should spin for
ttt_wheelboy_wheel_recharge_time 50   // How long Wheel boy must wait between wheel spins
ttt_wheelboy_spins_to_win        5    // How many times Wheel boy must spin their wheel to win
ttt_wheelboy_wheel_end_wait_time 5    // How long the wheel should wait at the end, showing the result, before it hides
ttt_wheelboy_announce_text       1    // Whether to announce that there is a Wheel boy via text
ttt_wheelboy_announce_sound      1    // Whether to announce that there is a Wheel boy via a sound clip
ttt_wheelboy_speed_mult          1.2  // The multiplier to use on Wheel boy's movement speed (e.g. 1.2 = 120% normal speed)
ttt_wheelboy_sprint_recovery     0.12 // The amount of stamina to recover per tick
ttt_wheelboy_swap_on_kill        0    // Whether Wheel boy's killer should become the new Wheel boy (if they haven't won yet)
ttt_wheelboy_notify_mode         0   // The logic to use when notifying players that a Wheel boy was killed. Killer is notified unless "ttt_wheelboy_notify_killer" is disabled. 0 - Don't notify anyone. 1 - Only notify traitors and detective. 2 - Only notify traitors. 3 - Only notify detective. 4 - Notify everyone.
ttt_wheelboy_notify_killer       1   // Whether to notify a Wheel boy's killer
ttt_wheelboy_notify_sound        0   // Whether to play a cheering sound when a Wheel boy is killed
ttt_wheelboy_notify_confetti     0   // Whether to throw confetti when a Wheel boy is a killed
```

# Special Thanks
- [Game icons](https://game-icons.net/) for the role icons
- [The Stig](https://steamcommunity.com/id/The-Stig-294) for the Randoman role that the Hoodoo was very heavily based on
- Angela from the [Lonely Yogs](https://lonely-yogs.co.uk/) for her help with the math for drawing Wheel Boy's segmented wheel
- The Yogscast for clips from their videos for the Wheel Boy role
