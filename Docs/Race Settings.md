The following table will give you an overview over all settings, which are available in the session database. As described [here](https://github.com/SeriousOldMan/Simulator-Controller/wiki/Virtual-Race-Engineer#race-settings-1), this settings can be defined precisely for a given simulator / car / track / weather combo and will overwrite the settings you have chosen in the "Race Settings" dialog. This allows you to automate most of the settings required for an upcoming session.

### General settings

This settings are generally available, although you can and have to define them specific for a given simulator / car / track / weather combo as described. Further down below you can find additional settings, which are not generally available, but are specific for a selected simulator. 

| Category   | Setting                                  | Type    | Default                         | Available in "Race Settings" dialog| Description  |
|------------|------------------------------------------|---------|---------------------------------|------------------------------------|--------------|
| Data       | Collect Telemetry during Practice        | Boolean | True                            | No  | If *True*, general telemetry data is collected by the Strategist during practice sessions. |
| Data       | Collect Telemetry during Qualifying      | Boolean | False                           | No  | If *True*, general telemetry data is collected by the Strategist during qualifying sessions. |
| Data       | Collect Telemetry during Race            | Boolean | True                            | No  | If *True*, general telemetry data is collected by the Strategist during race sessions. |
| Data       | Collect Tyre Pressures during Practice   | Boolean | True                            | No  | If *True*, pressures (hot and cold) are collected by the Engineer during practice sessions. |
| Data       | Collect Tyre Pressures during Qualifying | Boolean | False                           | No  | If *True*, pressures (hot and cold) are collected by the Engineer during qualifying sessions. |
| Data       | Collect Tyre Pressures during Race       | Boolean | True                            | No  | If *True*, pressures (hot and cold) are collected by the Engineer during race sessions. |
| Pitstop    | Repair Bodywork                          | Never, Always, Threshold, Impact | Impact | Yes | Defines, when the Engineer will recommend a pitstop for bodywork repairs. See the above [explanations](https://github.com/SeriousOldMan/Simulator-Controller/wiki/Virtual-Race-Engineer#tab-pitstop) for more information. |
| Pitstop    | Threshold for Repair Bodywork            | Float | 1.0                               | Yes | Detail value, when *Repair Bodywork* is *Threshold* or *Impact*. |
| Pitstop    | Repair Suspension                        | Never, Always, Threshold, Impact | Always | Yes | Defines, when the Engineer will recommend a pitstop for suspension repairs. See the above [explanations](https://github.com/SeriousOldMan/Simulator-Controller/wiki/Virtual-Race-Engineer#tab-pitstop) for more information. |
| Pitstop    | Threshold for Repair Suspension          | Float | 0.0                               | Yes | Detail value, when *Repair Suspension* is *Threshold* or *Impact*. |
| Pitstop    | Repair Engine                            | Never, Always, Threshold, Impact | Impact | Yes | Defines, when the Engineer will recommend a pitstop for engine repairs. See the above [explanations](https://github.com/SeriousOldMan/Simulator-Controller/wiki/Virtual-Race-Engineer#tab-pitstop) for more information. |
| Pitstop    | Threshold for Repair Engine              | Float | 1.0                               | Yes | Detail value, when *Repair Engine* is *Threshold* or *Impact*. |
| Pitstop    | Change Compound                          | Never, Temperature, Weather | Never       | Yes | Defines, when the Engineer will recommend to mount a different tyre compund at the next pitstop. See the above [explanations](https://github.com/SeriousOldMan/Simulator-Controller/wiki/Virtual-Race-Engineer#tab-pitstop) for more information. If *Weather* is chosen here, the rules for [weather specific tyre compounds](https://github.com/SeriousOldMan/Simulator-Controller/wiki/Tyre-Compounds#weather-and-tyre-compounds) apply. |
| Pitstop    | Threshold for Change Compound            | Float | 0.0                               | Yes | Detail value, when *Change Compound* is *Temperature*. |
| Pitstop    | Tyre Compound Choices                    | Text  |                                   | No  | Using this setting the available tyre compounds for a given car can be defined. See the [explanation of compound rules](https://github.com/SeriousOldMan/Simulator-Controller/wiki/Tyre-Compounds#creating-own-compound-rules) for more information. |
| Pitstop    | Fresh Tyre Set                           | Integer | 2                               | Yes | Specifies the first fresh tyre set to use during a pitstop. Typically not entered into the "Session Database", but into "Race Settings" just before the start of a session. |
| Pitstop    | Threshold for Target Pressure Deviation  | Float | 0.2                               | Yes | This value specifies the deviation from the ideal hot pressure, which must be detected, before the Engineer considers altering the cold setup pressure for this tyre. |
| Pitstop    | Dry Target Pressure Front Left           | Float | 26.5                              | Yes | The ideal hot pressure for the front left tyre with dry compound. |
| Pitstop    | Dry Target Pressure Front Right          | Float | 26.5                              | Yes | The ideal hot pressure for the front right tyre with dry compound. |
| Pitstop    | Dry Target Pressure Rear Left            | Float | 26.5                              | Yes | The ideal hot pressure for the rear left tyre with dry compound. |
| Pitstop    | Dry Target Pressure Rear Right           | Float | 26.5                              | Yes | The ideal hot pressure for the rear right tyre with dry compound. |
| Pitstop    | Wet Target Pressure Front Left           | Float | 30.0                              | Yes | The ideal hot pressure for the front left tyre with intermediate or wet compound. |
| Pitstop    | Wet Target Pressure Front Right          | Float | 30.0                              | Yes | The ideal hot pressure for the front right tyre with intermediate or wet compound. |
| Pitstop    | Wet Target Pressure Rear Left            | Float | 30.0                              | Yes | The ideal hot pressure for the rear left tyre with intermediate or wet compound. |
| Pitstop    | Wet Target Pressure Rear Right           | Float | 30.0                              | Yes | The ideal hot pressure for the rear right tyre with intermediate or wet compound. |
| Pitstop    | Tyre Pressure Database Correction        | Boolean | False                           | Yes | If *True* and if cold pressures is available in the pressure database for the current environmental conditions, these values will also be used to calculate the setup pressures at the next pitstop. See the above [explanations](https://github.com/SeriousOldMan/Simulator-Controller/wiki/Virtual-Race-Engineer#tab-pitstop) for more information. |
| Pitstop    | Tyre Pressure Temperature Correction     | Boolean | True                            | Yes | If *True*, the trend of the air temperature will be considered to apply a small correction to the setup pressures at the next pitstop. See the above [explanations](https://github.com/SeriousOldMan/Simulator-Controller/wiki/Virtual-Race-Engineer#tab-pitstop) for more information. |
| Pitstop    | Tyre Pressure Loss Correction            | Boolean | False                           | Yes | If *True*, a detected pressure loss of a tyre will be considered and a correction to the setup pressure at the next pitstop will be automatically applied. See the above [explanations](https://github.com/SeriousOldMan/Simulator-Controller/wiki/Virtual-Race-Engineer#tab-pitstop) for more information. |
| Pitstop    | Temperature Air Correction Value         | Boolean | -0.1                            | No  | When target pressures are calculated, but no exact match is available, this correction value is added for each degree celsius of deviation in the ambient temperature. |
| Pitstop    | Temperature Track Correction Value       | Boolean | -0.02                           | No  | When target pressures are calculated, but no exact match is available, this correction value is added for each degree celsius of deviation in the track temperature. |
| Pitstop    | Service Order                            | Simultaneous, Sequential | Simultaneous   | Yes | Defines, whether refueling and tyre service will happen simulteneously, thereby saving some time in the pit. |
| Pitstop    | Refuel Service Rule                      | Fixed, Dynamic | Dynamic                  | Yes | Defines, whether refueling will take a fixed amount of time or whether refueling will take a fixed amount of time. |
| Pitstop    | Refuel Service Duration                  | Float | 1.5                               | Yes | The time used for the *Refuel Service Rule* in seconds. If refueling time will be calculated dynamically, this number must be the seconds used for each 10 litres of fuel. |
| Pitstop    | Tyre Service Duration                    | Integer | 30                              | Yes | Amount of time (in seconds) needed for swapping all four tyres. |
| Session    | Average Fuel Consumption                 | Float | 3.0                               | Yes | Average fuel consumption of the given car / track / weather combo. Only used in the first few laps in statistical calculations. This value will be updated automatically (depending on your [configuration](https://github.com/SeriousOldMan/Simulator-Controller/wiki/Installation-&-Configuration#tab-race-engineer)), once you have been on the track. |
| Session    | Safety Fuel                              | Float | 4                                 | Yes | The amount of fuel the Engineer will take in reserve in his calulations. |
| Session    | Fuel Capacity                            | Float | 120                               | No  | The size of the fuel tank for the given car / track / weather combo. This value will be updated automatically (depending on your [configuration](https://github.com/SeriousOldMan/Simulator-Controller/wiki/Installation-&-Configuration#tab-race-engineer)), once you have been on the track. |
| Session    | Average Lap Time                         | Integer | 120                             | Yes | Average lap time of the given car / track / weather combo. Only used in the first few laps in statistical calculations. This value will be updated automatically (depending on your [configuration](https://github.com/SeriousOldMan/Simulator-Controller/wiki/Installation-&-Configuration#tab-race-engineer)), once you have been on the track. |
| Session    | Formation Lap                            | Boolean | True                            | Yes | If *True*, the session rules require a formation lap, which is considered in fuel calculations. Typically not entered into the "Session Database", but into "Race Settings" just before the start of a session. |
| Session    | Post Race Lap                            | Boolean | True                            | Yes | If *True*, the session rules require a cool down lap after the end of the session, which is considered in fuel calculations. Typically not entered into the "Session Database", but into "Race Settings" just before the start of a session. |
| Setup      | Tyre Compound                            | Dry, Intermediate, Wet | Dry              | Yes | The tyre compound mounted at the start of the session. Typically not entered into the "Session Database", but into "Race Settings" just before the start of a session. For some simulators, this information can be determined automatically via API (depending on your [configuration](https://github.com/SeriousOldMan/Simulator-Controller/wiki/Installation-&-Configuration#tab-race-engineer)). |
| Setup      | Tyre Compound Color                      | [See this list](https://github.com/SeriousOldMan/Simulator-Controller/wiki/Tyre-Compounds#compound-rules) | Black                | Yes | The tyre compound mixture used at the start of the session. Typically not entered into the "Session Database", but into "Race Settings" just before the start of a session. For some simulators, this information can be determined automatically via API (depending on your [configuration](https://github.com/SeriousOldMan/Simulator-Controller/wiki/Installation-&-Configuration#tab-race-engineer)). |
| Setup      | Tyre Set                                 | Integer | 1                               | Yes | Specifies the tyre set of the tyres initially mounted for the car. Typically not entered into the "Session Database", but into "Race Settings" just before the start of a session. For some simulators, this information can be determined automatically via API (depending on your [configuration](https://github.com/SeriousOldMan/Simulator-Controller/wiki/Installation-&-Configuration#tab-race-engineer)). |
| Setup      | Dry Pressure Front Left                  | Float | 26.1                              | Yes | The setup (cold) pressure of the front left tyre at the start of the session for dry tyre compounds. Typically not entered into the "Session Database", but into "Race Settings" just before the start of a session. For some simulators, this information can be determined automatically via API (depending on your [configuration](https://github.com/SeriousOldMan/Simulator-Controller/wiki/Installation-&-Configuration#tab-race-engineer)). |
| Setup      | Dry Pressure Front Right                 | Float | 26.1                              | Yes | The setup (cold) pressure of the front right tyre at the start of the session for dry tyre compounds. Typically not entered into the "Session Database", but into "Race Settings" just before the start of a session. For some simulators, this information can be determined automatically via API (depending on your [configuration](https://github.com/SeriousOldMan/Simulator-Controller/wiki/Installation-&-Configuration#tab-race-engineer)). |
| Setup      | Dry Pressure Rear Left                   | Float | 26.1                              | Yes | The setup (cold) pressure of the rear left tyre at the start of the session for dry tyre compounds. Typically not entered into the "Session Database", but into "Race Settings" just before the start of a session. For some simulators, this information can be determined automatically via API (depending on your [configuration](https://github.com/SeriousOldMan/Simulator-Controller/wiki/Installation-&-Configuration#tab-race-engineer)). |
| Setup      | Dry Pressure Rear Right                  | Float | 26.1                              | Yes | The setup (cold) pressure of the rear right tyre at the start of the session for dry tyre compounds. Typically not entered into the "Session Database", but into "Race Settings" just before the start of a session. For some simulators, this information can be determined automatically via API (depending on your [configuration](https://github.com/SeriousOldMan/Simulator-Controller/wiki/Installation-&-Configuration#tab-race-engineer)). |
| Setup      | Wet Pressure Front Left                  | Float | 28.5                              | Yes | The setup (cold) pressure of the front left tyre at the start of the session for intermediate or wet tyre compounds. Typically not entered into the "Session Database", but into "Race Settings" just before the start of a session. For some simulators, this information can be determined automatically via API (depending on your [configuration](https://github.com/SeriousOldMan/Simulator-Controller/wiki/Installation-&-Configuration#tab-race-engineer)). |
| Setup      | Wet Pressure Front Right                 | Float | 28.5                              | Yes | The setup (cold) pressure of the front right tyre at the start of the session for intermediate or wet tyre compounds. Typically not entered into the "Session Database", but into "Race Settings" just before the start of a session. For some simulators, this information can be determined automatically via API (depending on your [configuration](https://github.com/SeriousOldMan/Simulator-Controller/wiki/Installation-&-Configuration#tab-race-engineer)). |
| Setup      | Wet Pressure Rear Left                   | Float | 28.5                              | Yes | The setup (cold) pressure of the rear left tyre at the start of the session for intermediate or wet tyre compounds. Typically not entered into the "Session Database", but into "Race Settings" just before the start of a session. For some simulators, this information can be determined automatically via API (depending on your [configuration](https://github.com/SeriousOldMan/Simulator-Controller/wiki/Installation-&-Configuration#tab-race-engineer)). |
| Setup      | Wet Pressure Rear Right                  | Float | 28.5                              | Yes | The setup (cold) pressure of the rear right tyre at the start of the session for intermediate or wet tyre compounds. Typically not entered into the "Session Database", but into "Race Settings" just before the start of a session. For some simulators, this information can be determined automatically via API (depending on your [configuration](https://github.com/SeriousOldMan/Simulator-Controller/wiki/Installation-&-Configuration#tab-race-engineer)). |
| Strategy   | Position Extrapolation                   | Integer | 3                               | Yes | The Strategist permanently simulates the events of the upcoming laps depending on the development of the recent laps to predict future race standings. This information is used for example for pitstop recommendations and strategy updates. This value specifies, how many laps into the future will be calculated on each crossing of the start / finish line. Attention: High values might result in high CPU consumption. |
| Strategy   | Overtake Delta                           | Integer | 1                               | Yes | During simulation of the future race development, the Strategist will also take overtaking into account. This value defines the time loss for both cars in seconds according to this formula: Abs( X / laptime difference), where *X* is the value entered here. |
| Strategy   | Pitlane Delta                            | Integer | 60                              | Yes | The time difference in seconds between drive by and drive through of the pitlane. |
| Strategy   | Pitstop Window                           | Integer | 2                               | Yes | Specifies, how many laps before an after the projected pitstop (depending on available fuel), the Strategist will simulate to create his recommendation for an upcoming pitstop. |
| Strategy   | Considered Traffic                       | Integer | 5                               | Yes | Specifies the length of the track (in percentage of the overall length) which will be considered in traffic density calculations by the Strategist. |
| Spotter    | Late Join                                | Boolean | True                            | No  | If *True* (which is the default), the Spotter will also become active, when you join mid-session. |
| Spotter    | Threshold for Lap Up car in range        | Float | 1.0                               | No  | Specifies the gap in seconds, before the Spotter will analyzes a situation with a car which is at least one lap ahead of you. |
| Spotter    | Threshold for Lap Down car in range      | Float | 2.0                               | No  | Specifies the gap in seconds, before the Spotter will analyzes a situation with a car which is at least one lap behind you. |
| Spotter    | Threshold for Attack car in front        | Float | 0.8                               | No  | Specifies the gap in seconds, before the Spotter will think that it is time to attack the car in front of you (if you are faster on average). |
| Spotter    | Threshold for Gained on car in front     | Float | 0.3                               | No  | Specifies the time in seconds, you must have gained to the car in front, until the Spotter will give you updated information about the gap and the laptime difference. |
| Spotter    | Threshold for Lost on car in front       | Float | 1.0                               | No  | Specifies the time in seconds, you must have lost to the car in front, until the Spotter will give you updated information about the gap and the laptime difference. |
| Spotter    | Threshold for Attack car behind          | Float | 0.8                               | No  | Specifies the gap in seconds, before the Spotter will think that the car behind you will attak you (if it is faster on average). |
| Spotter    | Threshold for Lost on car behind         | Float | 0.3                               | No  | Specifies the time in seconds, you must have lost to the car behind you, until the Spotter will give you updated information about the gap and the laptime difference. |
| Spotter    | Threshold for Gained on car behind       | Float | 1.5                               | No  | Specifies the time in seconds, you must have gained to the car behind you, until the Spotter will give you updated information about the gap and the laptime difference. |
| Engineer   | Late Join                                | Boolean | False                           | No  | If *True*, the Engineer will also become active, when you join mid-session. Attention: This can lead to funny results in almost all calculations. |
| Engineer   | Refuel Service                           | Boolean | True                            | No  | If *True*, the Engineer will consider refueling during pitstop servicing. You won't want to change this. |
| Engineer   | Tyre Service                             | Boolean | True                            | No  | If *True*, the Engineer will consider tyre changing during pitstop servicing. You may want to disable this for simulators without correct pressure information available in the API, like *iRacing*. In this case you will have to manage the tyres on your own. |
| Engineer   | Repair Service                           | Boolean | True                            | No  | If *True*, the Engineer will consider repairing during pitstop servicing. You can disable this and manage the repair settings on your own, but why you want to do this? |
| Engineer   | Pitstop Service during Practice          | Boolean | False                           | No  | If *True*, pitstop service handling will be available during practice. Normally disabled, but practical, if you want to test this stuff. |
| Engineer   | Pitstop Service during Qualifying        | Boolean | False                           | No  | If *True*, pitstop service handling will be available during practice. You typically won't want to enable this. |
| Engineer   | Pitstop Service during Race              | Boolean | True                            | No  | If *True*, pitstop service handling will be available during race sessions. You won't want to disable this, right? |
| Engineer   | Low Fuel Warning                         | Integer | 3                               | Yes | Specifies the number of laps, the Engineer will issue a fuel warning, before you will run out of fuel. |
| Engineer   | Fuel warning during Practice             | Boolean | True                            | No  | If *True*, the Engineer will issue fuel warnings during practice sessions. |
| Engineer   | Damage warning during Practice           | Boolean | False                           | No  | If *True*, the Engineer will issue damage warnings during practice sessions. |
| Engineer   | Pressure warning during Practice         | Boolean | False                           | No  | If *True*, the Engineer will issue pressure loss warnings during practice sessions. |
| Engineer   | Fuel warning during Qualifying           | Boolean | False                           | No  | If *True*, the Engineer will issue fuel warnings during qualifying sessions. |
| Engineer   | Damage warning during Qualifying         | Boolean | False                           | No  | If *True*, the Engineer will issue damage warnings during qualifying sessions. |
| Engineer   | Pressure warning during Qualifying       | Boolean | True                            | No  | If *True*, the Engineer will issue pressure loss warnings during qualifying sessions. |
| Engineer   | Fuel warning during Race                 | Boolean | True                            | No  | If *True*, the Engineer will issue fuel warnings during race sessions. |
| Engineer   | Damage warning during Race               | Boolean | True                            | No  | If *True*, the Engineer will issue damage warnings during race sessions. |
| Engineer   | Pressure warning during Race             | Boolean | True                            | No  | If *True*, the Engineer will issue pressure loss warnings during race sessions. |
| Strategist | Late Join                                | Boolean | False                           | No  | If *True*, the Strategist will also become active, when you join mid-session. Attention: This can lead to funny results in almost all calculations. |

### Simulator specific settings

The following settings are only available, if you have selected the corresponding simulator.

1. *Assetto Corsa*

| Category   | Setting                                  | Type    | Default                         | Description  |
|------------|------------------------------------------|---------|---------------------------------|--------------|
| Pitstop    | Key Delay                                | Integer | 20                              | The time in ms to wait between each virtual key press, when controlling the pitstop dialog of *Assetto Corsa*. Increase this, if your computer can't keep up with the speed of the virtual input. |
| Pitstop    | # Car Specific Settings                  | Integer | 0                               | Some cars of *Assetto Corsa* provide car specific settings, which can be changed during pitstop. You can specify them using this setting, so that the setting navigation for these cars is correct. Only necessary for cars not already known in the meta data set for *Assetto Corsa* in Simulator Controller. |
| Pitstop    | Minimum Pressure Front Left              | Integer | 15                              | Minimum pressure for the front left tyre allowed for a given car in *Assetto Corsa*. Only necessary for cars not already known in the meta data set for *Assetto Corsa* in Simulator Controller. |
| Pitstop    | Minimum Pressure Front Right              | Integer | 15                             | Minimum pressure for the front right tyre allowed for a given car in *Assetto Corsa*. Only necessary for cars not already known in the meta data set for *Assetto Corsa* in Simulator Controller. |
| Pitstop    | Minimum Pressure Rear Left              | Integer | 15                              | Minimum pressure for the rear left tyre allowed for a given car in *Assetto Corsa*. Only necessary for cars not already known in the meta data set for *Assetto Corsa* in Simulator Controller. |
| Pitstop    | Minimum Pressure Rear Right              | Integer | 15                             | Minimum pressure for the rear right tyre allowed for a given car in *Assetto Corsa*. Only necessary for cars not already known in the meta data set for *Assetto Corsa* in Simulator Controller. |

2. *Assetto Corsa Competizione*

| Category   | Setting                                  | Type    | Default                         | Description  |
|------------|------------------------------------------|---------|---------------------------------|--------------|
| Pitstop    | Key Delay                                | Integer | 20                              | The time in ms to wait between each virtual key press, when controlling the pitstop dialog of *Assetto Corsa Competizione*. Increase this, if your computer can't keep up with the speed of the virtual input. |
| Pitstop    | Image Search                             | Boolean | False                           | If *True*, the [image search method](https://github.com/SeriousOldMan/Simulator-Controller/wiki/Plugins-&-Modes#important-preparation-for-the-pitstop-mfd-handling) is used, when controlling the Pitstop MFD of *Assetto Corsa Competizione*. If you enable this, because the default option walk disturbs you while driving, you have to provide the search images as described in the [documentation] for the ["ACC" plugin](https://github.com/SeriousOldMan/Simulator-Controller/wiki/Plugins-&-Modes#plugin-acc). |

3. *Automobilista 2*, *Project Cars 2*, *iRacing* and *RaceRoom Racing Experience*

| Category   | Setting                                  | Type    | Default                         | Description  |
|------------|------------------------------------------|---------|---------------------------------|--------------|
| Pitstop    | Key Delay                                | Integer | 20                              | The time in ms to wait between each virtual key press, when controlling the pitstop settings of the simulator. Increase this, if your computer can't keep up with the speed of the virtual input. |