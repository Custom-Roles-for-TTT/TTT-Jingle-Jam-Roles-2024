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

## Wheel Boy
_Suggested By_: spammonster\
Wheel Boy can spin a wheel to apply random effects to everyone. Spin enough times and they win.
\
\
**ConVars**
```cpp
ttt_wheelboy_enabled             0    // Whether or not wheel boy should spawn
ttt_wheelboy_spawn_weight        1    // The weight assigned to spawning wheel boy
ttt_wheelboy_min_players         0    // The minimum number of players required to spawn wheel boy
ttt_wheelboy_starting_health     150  // The amount of health wheel boy starts with
ttt_wheelboy_max_health          150  // The maximum amount of health wheel boy can have
ttt_wheelboy_wheel_time          15   // How long the wheel should spin for
ttt_wheelboy_wheel_recharge_time 50   // How long wheel boy must wait between wheel spins
ttt_wheelboy_spins_to_win        5    // How many times wheel boy must spin their wheel to win
ttt_wheelboy_wheel_end_wait_time 5    // How long the wheel should wait at the end, showing the result, before it hides
ttt_wheelboy_announce_text       1    // Whether to announce that there is a wheel boy via text
ttt_wheelboy_announce_sound      1    // Whether to announce that there is a wheel boy via a sound clip
ttt_wheelboy_speed_mult          1.2  // The multiplier to use on wheel boy's movement speed (e.g. 1.2 = 120% normal speed)
ttt_wheelboy_sprint_recovery     0.12 // The amount of stamina to recover per tick
ttt_wheelboy_swap_on_kill        0    // Whether wheel boy's killer should become the new wheel boy (if they haven't won yet)
```

# Special Thanks
- [Game icons](https://game-icons.net/) for the role icons
- [The Stig](https://steamcommunity.com/id/The-Stig-294) for the Randoman role that the Hoodoo was very heavily based on
- Angela from the [Lonely Yogs](https://lonely-yogs.co.uk/) for her help with the math for drawing Wheel Boy's segmented wheel
- The Yogscast for clips from their videos for the Wheelboy role