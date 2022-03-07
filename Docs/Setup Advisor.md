## Introduction

When it comes to race cars, the vast amount of available options when developing a setup for a specific track and the personal driving style can be overwhelming - and this not only for the beginners. Most of us know some thump rules, for example: "Increase the rear wing angle to increase the rear stabiliity in fast corners and under heavy braking". But only a few of us know all the little tricks to create the best possible compromise for a given driver / car / track combination. And it will always be a compromise, since many requirements are contradictory. Creating loads of downforce for fast corners makes you slow on the straights, right?

Welcome to "Setup Advisor", a new member in the growing collection of tools of the Simulator Controller suite.

## Describing Setup Issues

The real world approach, when developing a setup for a race car, is to drive a few laps and make mental notes of all the flaws and drawbacks of the current car handling. You then describe all these issues to your suspension engineer, who then adjusts the settings on the car accordingly. Another test on the track will hopefully confirm the improvements that have been made, but usually also reveal new issues that arise as a result of the changes. After you have gone through this cycle a few times, you usually have found the best possible compromise for the current track.

"Setup Advisor" supports exactly this approach by allowing you to describe the issues with the current setup on the left-hand side of the window. You can determine how badly the issue affects the driving characteristics and how important an improvement is for the overall performance.

![](https://github.com/SeriousOldMan/Simulator-Controller/blob/Development/Docs/Images/Setup%20Advisor.JPG)

After starting the tool, you first select the simulation and, if necessary, the car and track, as well as the weather conditions for which a setup is to be developed. Different simulators and also different cars might support different sets of setup options. You can choose "Generic" or "All", if the specific simulator and car is not availabe. Then you can click on the "Problem..." button to select an issue for which you want to explore a possible change to the car setup. With the sliders "Importance" and "Severity" you determine the above-mentioned weighting and the severity of the issue. After a few moments, one or more recommendations for useful changes to the setup will appear on the right side of the window. For many issues, tiered recommendations are available based on the selected severity level.

Please note, that it is possible to describe and edit several issues at once. "Setup Advisor" will try to find the best possible compromise, especially when there are conflicting requirements. Of course, this has its limitations and it is therefore always advisable to tackle one or two issues at a time, even if "Setup Advisor" searches for solutions for up to eight issues at a time.

Using the "Load..." and "Save..." buttons in the lower left corner of the window, you can store and retrieve your current selection of issues to your hard drive. The current state will also be stored, when you hold down the Control key, while exiting "Setup Advisor". This state can be retrieved again, when you hold down the Control key, while starting "Setup Advisor".

## Understanding the Recommendations

Since "Setup Advisor" has no knowledge about the concrete settings in the current car setup, all recommendations are of reltive nature. When you get the recommendation for a reduction of "Camber Rear Left" by -1, this does not mean that you have to reduce the rear left camber by exactly 1 click or by 0.1 degree. It rather means, that a reduction of the camber will have the a large, when not the largest impact in the set of recommendations. To be precise, a recommendation with a value of 1.0 or -1.0 is four times as important than a recommendation with a value of 0.25. This is a hint for you where to start with your incremental tests when applying the recommended setup changes to your car.

### Meaning of the setup values

Most of the recommended setup values will be self-explanatory. The table below will show you the meanung of the positive and negative values of the more special setup options.

| Setting                 | Positive values                   | Negative values                   |
| ----------------------- | --------------------------------- | --------------------------------- |
| Brake Balance           | More pressure to the front brakes | More pressure to the rear brakes  |
| Brake Ducts             | More open duct                    | Less open duct                    |
| Splitter / Wing         | More drag / downforce             | Less drag / downforce             |
| Ride Height             | Higher Ride Height                | Lower Ride Height                 |
| Damper                  | More damping / resistance         | Less damping / resistance         |
| Spring / Bumpstop Rate  | Stiffer                           | Softer                            |
| Bumpstop Range          | Longer                            | Shorter                           |
| Differential Preload    | More opening resistance           | Less opening resistance           |
| Anti Roll Bar           | Stiffer                           | Softer                            |
| Toe                     | More Toe Out                      | Less Toe Out                      |
| Camber                  | More negative camber              | Less negative camber              |

Please be aware, that a long list of change recommendations does not mean that you have to change each and every setting. It rather means, that all these settings have an influence on the given issue. I recommend starting with the setting with the biggest impact and then work through the list step by step while monitoring the resulting change in car handling by driving a few laps after each change.

### Handling of contradictions

If you're working on more than one issue at a time, it's likely that you'll have conflicting recommendations to address. Depending on the "Importance" and "Severity" settings, "Setup Advisor" attempts to balance these contradictions. Example: If both a high top speed and equally high cornering speeds are required in fast corners, it depends on the product of the respective "Importance" and "Severity" whether an increase or decrease in the downforce value of the rear wing is recommended at the end.

### Disclaimer

The rules for the recommendations have been compiled from different sources, above all my own experiences. That said, I do not take responsibility for the correctness of all the recommendations, especially when generating recommendations for complex and partly contradictory multi-problem cases. If you find an error in the recommendations, please let me know. I always strive to improve the quality of my software.

## How it works

"Setup Advisor" uses the same rule engine, that is used by the Virtual Race Assistants. A generic set of rules handle the overall computation and the analysis of the problem descriptions given by the driver. Each problem is identified by a descriptor, for example "Understeer.Corner.Exit.Fast" for understeering while accelerating out of fast corners. For each setup option, a descriptor exists as well, for example "Bumpstop.Range.Front.Left" for the length of the bumpstop rubber in the front left spring damper.

During the first phase, the rule engine analyses all given problems and their "Importance" and "Severity" settings. A resulting correction value is derived, while handling contradictory requirements. The a long list of rules are evaluated that look like this:

	[?Understeer.Corner.Exit.Fast.Correction != 0] =>
			(Prove: changeSetting(Electronics.TC, -0.5, ?Understeer.Corner.Exit.Fast.Correction)),
			(Prove: changeSetting(Aero.Wing.Rear, -0.5, ?Understeer.Corner.Exit.Fast.Correction)),
			(Prove: changeSetting(Aero.Wing.Front, 1, ?Understeer.Corner.Exit.Fast.Correction)),
			(Prove: changeSetting(Aero.Splitter.Front, 1, ?Understeer.Corner.Exit.Fast.Correction)),
			(Prove: changeSetting(Aero.Height.Rear, 0.5, ?Understeer.Corner.Exit.Fast.Correction)),
			(Prove: changeSetting(Aero.Height.Front, -0.5, ?Understeer.Corner.Exit.Fast.Correction)),
			(Prove: changeSetting(Differential.Preload, 0.5, ?Understeer.Corner.Exit.Fast.Correction))

	{All: [?Understeer.Corner.Exit.Fast.Correction != 0], [?Understeer.Corner.Exit.Fast.Value > 50]} =>
			(Prove: changeSetting(Bumpstop.Range, [Front.Left, Front.Right], 1, ?Understeer.Corner.Exit.Fast.Correction)),
			(Prove: changeSetting(Bumpstop.Rate, [Front.Left, Front.Right], -1, ?Understeer.Corner.Exit.Fast.Correction)),
			(Prove: changeSetting(Bumpstop.Range, [Rear.Left, Rear.Right], -0.5, ?Understeer.Corner.Exit.Fast.Correction)),
			(Prove: changeSetting(Bumpstop.Rate, [Rear.Left, Rear.Right], 0.5, ?Understeer.Corner.Exit.Fast.Correction))

As you can see, these rules define the changes to be applied to the setup settings to compensate for a specific problem, fast corner exit understeer in this example. It is self-explanatory, that a lot of settings might be influenced by many applicable rules at the same time. The generic rule set of "Setup Advisor" will handle this by computing the resulting setting as the best possible compromise for all resulting changes.