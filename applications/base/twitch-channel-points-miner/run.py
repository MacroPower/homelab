# -*- coding: utf-8 -*-

import logging
from colorama import Fore
from TwitchChannelPointsMiner import TwitchChannelPointsMiner
from TwitchChannelPointsMiner.logger import LoggerSettings, ColorPalette
from TwitchChannelPointsMiner.classes.Chat import ChatPresence
from TwitchChannelPointsMiner.classes.Discord import Discord
from TwitchChannelPointsMiner.classes.Telegram import Telegram
from TwitchChannelPointsMiner.classes.Settings import Priority, Events, FollowersOrder
from TwitchChannelPointsMiner.classes.entities.Bet import Strategy, BetSettings, Condition, OutcomeKeys, FilterCondition, DelayMode
from TwitchChannelPointsMiner.classes.entities.Streamer import Streamer, StreamerSettings

twitch_miner = TwitchChannelPointsMiner(
    username="Cookie",
    claim_drops_startup=False,                  # If you want to auto claim all drops from Twitch inventory on the startup
    priority=[                                  # Custom priority in this case for example:
        Priority.STREAK,                        # - We want first of all to catch all watch streak from all streamers
        Priority.DROPS,                         # - When we don't have anymore watch streak to catch, wait until all drops are collected over the streamers
        Priority.ORDER                          # - When we have all of the drops claimed and no watch-streak available, use the order priority (POINTS_ASCENDING, POINTS_DESCEDING)
    ],
    enable_analytics=True,                      # Disables Analytics if False. Disabling it significantly reduces memory consumption
    logger_settings=LoggerSettings(
        save=False,                             # If you want to save logs in a file (suggested)
        console_level=logging.DEBUG,            # Level of logs - use logging.DEBUG for more info
        file_level=logging.DEBUG,               # Level of logs - If you think the log file it's too big, use logging.INFO
        emoji=True,                             # On Windows, we have a problem printing emoji. Set to false if you have a problem
        less=False,                             # If you think that the logs are too verbose, set this to True
        colored=True,                           # If you want to print colored text
        color_palette=ColorPalette(             # You can also create a custom palette color (for the common message).
            STREAMER_online="GREEN",            # Don't worry about lower/upper case. The script will parse all the values.
            streamer_offline="red",             # Read more in README.md
            BET_wiN=Fore.MAGENTA                # Color allowed are: [BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN, WHITE, RESET].
        )
    ),
    streamer_settings=StreamerSettings(
        make_predictions=False,                 # If you want to Bet / Make prediction
        follow_raid=True,                       # Follow raid to obtain more points
        claim_drops=False,                      # We can't filter rewards base on stream. Set to False for skip viewing counter increase and you will never obtain a drop reward from this script. Issue #21
        claim_moments=True,                     # If set to True, https://help.twitch.tv/s/article/moments will be claimed when available
        watch_streak=True,                      # If a streamer go online change the priority of streamers array and catch the watch screak. Issue #11
        chat=ChatPresence.ONLINE,               # Join irc chat to increase watch-time [ALWAYS, NEVER, ONLINE, OFFLINE]
        bet=BetSettings(
            strategy=Strategy.HIGH_ODDS,        # Choose you strategy!
            percentage=5,                       # Place the x% of your channel points
            max_points=5000,                    # If the x percentage of your channel points is gt bet_max_points set this value
            percentage_gap=20,                  # Gap difference between outcomesA and outcomesB (for SMART stragegy)
            stealth_mode=True,                  # If the calculated amount of channel points is GT the highest bet, place the highest value minus 1-2 points Issue #33
            delay_mode=DelayMode.FROM_END,      # When placing a bet, we will wait until `delay` seconds before the end of the timer
            delay=6,
            minimum_points=20000,               # Place the bet only if we have at least 20k points. Issue #113
            filter_condition=FilterCondition(
                by=OutcomeKeys.TOTAL_POINTS,     # Where apply the filter. Allowed [PERCENTAGE_USERS, ODDS_PERCENTAGE, ODDS, TOP_POINTS, TOTAL_USERS, TOTAL_POINTS]
                where=Condition.GTE,            # 'by' must be [GT, LT, GTE, LTE] than value
                value=50000
            )
        )
    )
)

twitch_miner.analytics(host="0.0.0.0", port=5000, refresh=5, days_ago=7)

# You can customize the settings for each streamer. If not settings were provided, the script would use the streamer_settings from TwitchChannelPointsMiner.
# If no streamer_settings are provided in TwitchChannelPointsMiner the script will use default settings.
# The streamers array can be a String -> username or Streamer instance.

# The settings priority are: settings in mine function, settings in TwitchChannelPointsMiner instance, default settings.
# For example, if in the mine function you don't provide any value for 'make_prediction' but you have set it on TwitchChannelPointsMiner instance, the script will take the value from here.
# If you haven't set any value even in the instance the default one will be used

twitch_miner.mine(
    [
        Streamer(
            "moonmoon",
            settings=StreamerSettings(
                make_predictions=True,
                follow_raid=True,
                claim_drops=False,
                claim_moments=True,
                watch_streak=True,
                chat=ChatPresence.ONLINE,
                bet=BetSettings(
                    strategy=Strategy.NUMBER_2,
                    percentage=5,
                    max_points=250000,
                    stealth_mode=False,
                    delay_mode=DelayMode.FROM_START,
                    delay=30,
                    filter_condition=FilterCondition(
                        by=OutcomeKeys.ODDS_PERCENTAGE,
                        where=Condition.GTE,
                        value=65
                    ),
                ),
            ),
        ),
        Streamer("clintstevens"),
        Streamer("evample2"),
        Streamer("vei"),
        Streamer("muffnbuttn"),
        Streamer("blitzfalcon"),
        Streamer("sips_"),
        Streamer("SIBquake"),
        Streamer("ster"),
        Streamer("jerma985"),
        Streamer("kitboga"),
        Streamer("barbarousking"),
        Streamer("rocketleague"),
        Streamer("rocketleagueoce"),
        Streamer("collegecarball"),
        Streamer("RocketLeagueSAM"),
        Streamer("RocketStreetLive"),
        Streamer("RocketBaguette"),
    ],
    followers=False,
)
