﻿;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   Modular Simulator Controller System - AI Race Engineer                ;;;
;;;                                                                         ;;;
;;;   Author:     Oliver Juwig (TheBigO)                                    ;;;
;;;   License:    (2023) Creative Commons - BY-NC-SA                        ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;-------------------------------------------------------------------------;;;
;;;                        Global Include Section                           ;;;
;;;-------------------------------------------------------------------------;;;

#Include "..\..\Framework\Framework.ahk"


;;;-------------------------------------------------------------------------;;;
;;;                         Local Include Section                           ;;;
;;;-------------------------------------------------------------------------;;;

#Include "..\..\Libraries\Task.ahk"
#Include "..\..\Libraries\RuleEngine.ahk"
#Include "RaceAssistant.ahk"
#Include "..\..\Database\Libraries\SessionDatabase.ahk"


;;;-------------------------------------------------------------------------;;;
;;;                          Public Classes Section                         ;;;
;;;-------------------------------------------------------------------------;;;

class RaceEngineer extends RaceAssistant {
	iAdjustLapTime := true

	iSaveTyrePressures := kAsk

	iHasPressureData := false
	iSessionDataActive := false

	iPitstopOptionsFile := false

	class RaceEngineerRemoteHandler extends RaceAssistant.RaceAssistantRemoteHandler {
		__New(remotePID) {
			super.__New("Race Engineer", remotePID)
		}

		pitstopPlanned(arguments*) {
			this.callRemote("pitstopPlanned", arguments*)
		}

		pitstopPrepared(arguments*) {
			this.callRemote("pitstopPrepared", arguments*)
		}

		pitstopFinished(arguments*) {
			this.callRemote("pitstopFinished", arguments*)
		}

		startPitstopSetup(arguments*) {
			this.callRemote("startPitstopSetup", arguments*)
		}

		finishPitstopSetup(arguments*) {
			this.callRemote("finishPitstopSetup", arguments*)
		}

		updateTyreSet(arguments*) {
			this.callRemote("updateTyreSet", arguments*)
		}

		setPitstopRefuelAmount(arguments*) {
			this.callRemote("setPitstopRefuelAmount", arguments*)
		}

		setPitstopTyreSet(arguments*) {
			this.callRemote("setPitstopTyreSet", arguments*)
		}

		setPitstopTyrePressures(arguments*) {
			this.callRemote("setPitstopTyrePressures", arguments*)
		}

		requestPitstopRepairs(arguments*) {
			this.callRemote("requestPitstopRepairs", arguments*)
		}

		requestPitstopDriver(arguments*) {
			this.callRemote("requestPitstopDriver", arguments*)
		}

		savePressureData(arguments*) {
			this.callRemote("savePressureData", arguments*)
		}

		updateTyresDatabase(arguments*) {
			this.callRemote("updateTyresDatabase", arguments*)
		}

		planDriverSwap(arguments*) {
			this.callRemote("planDriverSwap", arguments*)
		}
	}

	AdjustLapTime {
		Get {
			return this.iAdjustLapTime
		}
	}

	SaveTyrePressures {
		Get {
			return this.iSaveTyrePressures
		}
	}

	HasPressureData {
		Get {
			return this.iHasPressureData
		}
	}

	SessionDataActive {
		Get {
			return this.iSessionDataActive
		}
	}

	__New(configuration, remoteHandler := false, name := false, language := kUndefined
		, synthesizer := false, speaker := false, vocalics := false, recognizer := false, listener := false, muted := false, voiceServer := false) {
		super.__New(configuration, "Race Engineer", remoteHandler, name, language, synthesizer, speaker, vocalics, recognizer, listener, muted, voiceServer)

		this.updateConfigurationValues({Announcements: {FuelWarning: true, DamageReporting: true, DamageAnalysis: true, PressureReporting: true, WeatherUpdate: true}})
	}

	updateConfigurationValues(values) {
		super.updateConfigurationValues(values)

		if values.HasProp("AdjustLapTime")
			this.iAdjustLapTime := values.AdjustLapTime

		if values.HasProp("SaveTyrePressures") {
			this.iSaveTyrePressures := values.SaveTyrePressures

			logMessage(kLogDebug, "SaveTyrePressures is now " . this.iSaveTyrePressures)
		}
	}

	updateDynamicValues(values) {
		super.updateDynamicValues(values)

		if values.HasProp("HasPressureData") {
			this.iHasPressureData := values.HasPressureData

			logMessage(kLogDebug, "HasPressureData is now " . this.iHasPressureData)
		}
	}

	handleVoiceCommand(grammar, words) {
		local reset := true

		switch grammar, false {
			case "LapsRemaining":
				this.lapInfoRecognized(words)
			case "FuelRemaining":
				this.fuelInfoRecognized(words)
			case "BrakeWear":
				this.brakeWearRecognized(words)
			case "BrakeTemperatures":
				this.brakeTemperaturesRecognized(words)
			case "TyreWear":
				this.tyreWearRecognized(words)
			case "TyreTemperatures":
				this.tyreInfoRecognized(Array(this.getSpeaker().Fragments["Temperatures"]))
			case "TyrePressures":
				this.tyreInfoRecognized(concatenate(Array(this.getSpeaker().Fragments["Pressures"]), words))
			case "Weather":
				this.weatherRecognized(words)
			case "PitstopPlan":
				reset := false

				this.clearContinuation()

				if !this.supportsPitstop()
					this.getSpeaker().speakPhrase("NoPitstop")
				else if this.hasPlannedPitstop() {
					this.getSpeaker().speakPhrase("ConfirmRePlan")

					this.setContinuation(ObjBindMethod(this, "planPitstopRecognized", words))
				}
				else {
					this.getSpeaker().speakPhrase("Confirm")

					Task.yield()

					loop 10
						Sleep(500)

					this.planPitstopRecognized(words)
				}
			case "DriverSwapPlan":
				reset := false

				this.clearContinuation()

				if !this.supportsPitstop()
					this.getSpeaker().speakPhrase("NoPitstop")
				else if !this.TeamSession {
					this.getSpeaker().speakPhrase("NoDriverSwap")

					if this.supportsPitstop() {
						this.getSpeaker().speakPhrase("ConfirmPlan", {forYou: this.getSpeaker().Fragments["ForYou"]}, true)

						this.setContinuation(ObjBindMethod(this, "planPitstop"))
					}
				}
				else if this.hasPlannedPitstop() {
					this.getSpeaker().speakPhrase("ConfirmRePlan")

					this.setContinuation(ObjBindMethod(this, "driverSwapRecognized", words))
				}
				else {
					this.getSpeaker().speakPhrase("Confirm")

					Task.yield()

					loop 10
						Sleep(500)

					this.driverSwapRecognized(words)
				}
			case "PitstopPrepare":
				reset := false

				this.clearContinuation()

				if !this.supportsPitstop()
					this.getSpeaker().speakPhrase("NoPitstop")
				else
					this.preparePitstopRecognized(words)
			case "PitstopAdjustFuel":
				reset := false

				this.clearContinuation()

				if !this.supportsPitstop()
					this.getSpeaker().speakPhrase("NoPitstop")
				else
					this.pitstopAdjustFuelRecognized(words)
			case "PitstopAdjustCompound":
				reset := false

				this.clearContinuation()

				if !this.supportsPitstop()
					this.getSpeaker().speakPhrase("NoPitstop")
				else
					this.pitstopAdjustCompoundRecognized(words)
			case "PitstopAdjustPressureUp", "PitstopAdjustPressureDown":
				reset := false

				this.clearContinuation()

				if !this.supportsPitstop()
					this.getSpeaker().speakPhrase("NoPitstop")
				else
					this.pitstopAdjustPressureRecognized(words)
			case "PitstopNoPressureChange":
				reset := false

				this.clearContinuation()

				if !this.supportsPitstop()
					this.getSpeaker().speakPhrase("NoPitstop")
				else
					this.pitstopAdjustNoPressureRecognized(words)
			case "PitstopNoTyreChange":
				reset := false

				this.clearContinuation()

				if !this.supportsPitstop()
					this.getSpeaker().speakPhrase("NoPitstop")
				else
					this.pitstopAdjustNoTyreRecognized(words)
			case "PitstopAdjustRepairSuspension":
				reset := false

				this.clearContinuation()

				if !this.supportsPitstop()
					this.getSpeaker().speakPhrase("NoPitstop")
				else
					this.pitstopAdjustRepairRecognized("Suspension", words)
			case "PitstopAdjustRepairBodywork":
				reset := false

				this.clearContinuation()

				if !this.supportsPitstop()
					this.getSpeaker().speakPhrase("NoPitstop")
				else
					this.pitstopAdjustRepairRecognized("Bodywork", words)
			case "PitstopAdjustRepairEngine":
				reset := false

				this.clearContinuation()

				if !this.supportsPitstop()
					this.getSpeaker().speakPhrase("NoPitstop")
				else
					this.pitstopAdjustRepairRecognized("Engine", words)
			default:
				super.handleVoiceCommand(grammar, words)
		}

		if reset
			this.clearContinuation()
	}

	lapInfoRecognized(words) {
		local knowledgeBase := this.KnowledgeBase
		local lap, speaker, remainingFuelLaps, remainingSessionLaps, remainingStintLaps

		if !this.hasEnoughData()
			return

		speaker := this.getSpeaker()
		remainingFuelLaps := Floor(knowledgeBase.getValue("Lap.Remaining.Fuel", 0))

		if (remainingFuelLaps == 0)
			speaker.speakPhrase("Later")
		else {
			speaker.beginTalk()

			try {
				speaker.speakPhrase("LapsAlready", {laps: knowledgeBase.getValue("Lap", 0) - this.BaseLap + 1})

				speaker.speakPhrase("LapsFuel", {laps: remainingFuelLaps})

				remainingSessionLaps := Ceil(knowledgeBase.getValue("Lap.Remaining.Session", 0))
				remainingStintLaps := Floor(knowledgeBase.getValue("Lap.Remaining.Stint", 0))

				if ((remainingStintLaps < remainingFuelLaps) && (remainingStintLaps < remainingSessionLaps))
					speaker.speakPhrase("LapsStint", {laps: remainingSessionLaps})
				else if (remainingSessionLaps < remainingFuelLaps)
					speaker.speakPhrase("LapsSession", {laps: remainingSessionLaps})
			}
			finally {
				speaker.endTalk()
			}
		}
	}

	fuelInfoRecognized(words) {
		local knowledgeBase := this.KnowledgeBase
		local speaker := this.getSpeaker()
		local lap, fuel

		lap := knowledgeBase.getValue("Lap", 0)

		if (lap == 0)
			speaker.speakPhrase("Later")
		else {
			fuel := knowledgeBase.getValue("Lap." . lap . ".Fuel.Remaining", 0)

			if (fuel == 0)
				speaker.speakPhrase("Later")
			else
				speaker.speakPhrase("Fuel", {fuel: floor(speaker.number2Speech(convertUnit("Volume", fuel))), unit: speaker.Fragments[getUnit("Volume")]})
		}
	}

	tyreInfoRecognized(words) {
		local knowledgeBase := this.KnowledgeBase
		local speaker := this.getSpeaker()
		local fragments := speaker.Fragments
		local forCold := false
		local forSetup := false
		local unit, lap, index, suffix, value, setupPressures, ignore, tyreType, goal, resultSet, compound

		if !this.hasEnoughData()
			return

		if inList(words, fragments["Temperatures"])
			unit := "Temperature"
		else if inList(words, fragments["Pressures"]) {
			unit := "Pressure"

			forSetup := inList(words, fragments["Setup"])
			forCold := inList(words, fragments["Cold"])
		}
		else {
			speaker.speakPhrase("Repeat")

			return
		}

		speaker.beginTalk()

		try {
			lap := knowledgeBase.getValue("Lap")

			if (unit == "Pressure")
				speaker.speakPhrase("Pressures", {type: forSetup ? fragments["Setup"] : (forCold ? fragments["Cold"] : "")})
			else
				speaker.speakPhrase("Temperatures")

			if forSetup {
				compound := knowledgeBase.getValue("Tyre.Compound", "Dry")
				setupPressures := []

				for ignore, tyreType in ["FL", "FR", "RL", "RR"] {
					goal := RuleCompiler().compileGoal("lastPressure(" . compound . ", " . tyreType . ", ?pressure)")
					resultSet := knowledgeBase.prove(goal)

					setupPressures.Push(resultSet ? resultSet.getValue(goal.Arguments[3]).toString() : 0)
				}
			}

			for index, suffix in ["FL", "FR", "RL", "RR"] {
				if (unit = "Pressure") {
					if forSetup
						value := speaker.number2Speech(convertUnit("Pressure", setupPressures[index]))
					else if forCold
						value := speaker.number2Speech(convertUnit("Pressure", knowledgeBase.getValue("Tyre.Pressure.Target." . suffix)))
					else
						value := speaker.number2Speech(convertUnit("Pressure", knowledgeBase.getValue("Lap." . lap . ".Tyre.Pressure." . suffix)))
				}
				else
					value := speaker.number2Speech(convertUnit("Temperature", knowledgeBase.getValue("Lap." . lap . ".Tyre.Temperature." . suffix)), 0)

				speaker.speakPhrase("Tyre" . suffix, {value: value
													, unit: (unit = "Pressure") ? fragments[getUnit("Pressure")]
																				: (fragments["Degrees"] . A_Space . fragments[getUnit("Temperature")])})
			}
		}
		finally {
			speaker.endTalk()
		}
	}

	tyreWearRecognized(words) {
		local knowledgeBase := this.KnowledgeBase
		local speaker := this.getSpeaker()
		local lap := knowledgeBase.getValue("Lap")
		local flWear := knowledgeBase.getValue("Lap." . lap . ".Tyre.Wear.FL", kUndefined)
		local frWear, rlWear, rrWear

		if !this.hasEnoughData()
			return

		if (flWear == kUndefined)
			speaker.speakPhrase("NoWear")
		else {
			frWear := knowledgeBase.getValue("Lap." . lap . ".Tyre.Wear.FR")
			rlWear := knowledgeBase.getValue("Lap." . lap . ".Tyre.Wear.RL")
			rrWear := knowledgeBase.getValue("Lap." . lap . ".Tyre.Wear.RR")

			speaker.beginTalk()

			try {
				speaker.speakPhrase("Wear")

				speaker.speakPhrase("WearFL", {used: Round(flWear), remaining: Round(100 - flWear)})

				speaker.speakPhrase("WearFR", {used: Round(frWear), remaining: Round(100 - frWear)})

				speaker.speakPhrase("WearRL", {used: Round(rlWear), remaining: Round(100 - rlWear)})

				speaker.speakPhrase("WearRR", {used: Round(rrWear), remaining: Round(100 - rrWear)})
			}
			finally {
				speaker.endTalk()
			}
		}
	}

	brakeTemperaturesRecognized(words) {
		local knowledgeBase := this.KnowledgeBase
		local speaker := this.getSpeaker()
		local fragments := speaker.Fragments
		local lap

		if !this.hasEnoughData()
			return

		speaker.beginTalk()

		try {
			lap := knowledgeBase.getValue("Lap")

			speaker.speakPhrase("Temperatures")

			speaker.speakPhrase("BrakeFL", {value: speaker.number2Speech(convertUnit("Temperature", knowledgeBase.getValue("Lap." . lap . ".Brake.Temperature.FL")), 0)
										  , unit: (fragments["Degrees"] . A_Space . fragments[getUnit("Temperature")])})

			speaker.speakPhrase("BrakeFR", {value: speaker.number2Speech(convertUnit("Temperature", knowledgeBase.getValue("Lap." . lap . ".Brake.Temperature.FR")), 0)
										  , unit: (fragments["Degrees"] . A_Space . fragments[getUnit("Temperature")])})

			speaker.speakPhrase("BrakeRL", {value: speaker.number2Speech(convertUnit("Temperature", knowledgeBase.getValue("Lap." . lap . ".Brake.Temperature.RL")), 0)
										  , unit: (fragments["Degrees"] . A_Space . fragments[getUnit("Temperature")])})

			speaker.speakPhrase("BrakeRR", {value: speaker.number2Speech(convertUnit("Temperature", knowledgeBase.getValue("Lap." . lap . ".Brake.Temperature.RR")), 0)
										  , unit: (fragments["Degrees"] . A_Space . fragments[getUnit("Temperature")])})
		}
		finally {
			speaker.endTalk()
		}
	}

	brakeWearRecognized(words) {
		local knowledgeBase := this.KnowledgeBase
		local speaker := this.getSpeaker()
		local lap := knowledgeBase.getValue("Lap")
		local flWear := knowledgeBase.getValue("Lap." . lap . ".Brake.Wear.FL", kUndefined)
		local frWear, rlWear, rrWear

		if !this.hasEnoughData()
			return

		if (flWear == kUndefined)
			speaker.speakPhrase("NoWear")
		else {
			frWear := knowledgeBase.getValue("Lap." . lap . ".Brake.Wear.FR")
			rlWear := knowledgeBase.getValue("Lap." . lap . ".Brake.Wear.RL")
			rrWear := knowledgeBase.getValue("Lap." . lap . ".Brake.Wear.RR")

			speaker.beginTalk()

			try {
				speaker.speakPhrase("Wear")

				speaker.speakPhrase("WearFL", {used: speaker.number2Speech(flWear, 1), remaining: speaker.number2Speech(100 - flWear, 1)})

				speaker.speakPhrase("WearFR", {used: speaker.number2Speech(frWear, 1), remaining: speaker.number2Speech(100 - frWear, 1)})

				speaker.speakPhrase("WearRL", {used: speaker.number2Speech(rlWear, 1), remaining: speaker.number2Speech(100 - rlWear, 1)})

				speaker.speakPhrase("WearRR", {used: speaker.number2Speech(rrWear, 1), remaining: speaker.number2Speech(100 - rrWear, 1)})
			}
			finally {
				speaker.endTalk()
			}
		}
	}

	weatherRecognized(words) {
		local knowledgeBase := this.KnowledgeBase
		local weather10Min := (knowledgeBase ? knowledgeBase.getValue("Weather.Weather.10Min", false) : false)

		if !weather10Min
			this.getSpeaker().speakPhrase("Later")
		else if (weather10Min = "Dry")
			this.getSpeaker().speakPhrase("WeatherGood")
		else
			this.getSpeaker().speakPhrase("WeatherRain")
	}

	planPitstopRecognized(words) {
		this.planPitstop()
	}

	driverSwapRecognized(words) {
		this.planDriverSwap()
	}

	preparePitstopRecognized(words) {
		this.getSpeaker().speakPhrase("Confirm")

		Task.yield()

		loop 10
			Sleep(500)

		this.preparePitstop()
	}

	pitstopAdjustFuelRecognized(words) {
		local knowledgeBase := this.KnowledgeBase
		local speaker := this.getSpeaker()
		local fragments := speaker.Fragments
		local convert := false
		local volumePosition := false
		local fillUp := false
		local fuel, ignore, word, lap, remainingFuel

		if !this.hasPlannedPitstop() {
			speaker.beginTalk()

			try {
				speaker.speakPhrase("NotPossible")

				speaker.speakPhrase("ConfirmPlan", {forYou: ""}, true)
			}
			finally {
				speaker.endTalk()
			}

			this.setContinuation(ObjBindMethod(this, "planPitstop"))
		}
		else {
			for ignore, word in words
				if (InStr(word, fragments["Liter"]) || InStr(word, "litre")) {
					volumePosition := A_Index

					break
				}
				else if InStr(word, fragments["Gallon"]) {
					volumePosition := A_Index
					convert := true

					break
				}

			if volumePosition {
				fuel := words[volumePosition - 1]

				if InStr(values2String(A_Space, words*), A_Space . fragments["UpTo"] . A_Space) {
					lap := knowledgeBase.getValue("Lap")
					remainingFuel := (knowledgeBase.getValue("Lap." . lap . ".Fuel.Remaining", 0) - knowledgeBase.getValue("Lap." . lap . ".Fuel.AvgConsumption", 0))

					if convert
						if (getUnit("Volume") = "Gallon (US)")
							remainingFuel := Floor(remainingFuel / 3.785411)
						else
							remainingFuel := Floor(remainingFuel / 4.546092)

					fuel := Round(Max(0, fuel - remainingFuel))
				}

				if this.isNumber(fuel, &fuel) {
					speaker.speakPhrase("ConfirmFuelChange", {fuel: fuel, unit: fragments[convert ? "Gallon" : "Liter"]}, true)

					if convert
						if (getUnit("Volume") = "Gallon (US)")
							fuel := Ceil(fuel * 3.785411)
						else
							fuel := Ceil(fuel * 4.546092)

					this.setContinuation(ObjBindMethod(this, "updatePitstopFuel", fuel))

					return
				}
			}

			speaker.speakPhrase("Repeat")
		}
	}

	pitstopAdjustCompoundRecognized(words) {
		local knowledgeBase := this.KnowledgeBase
		local speaker := this.getSpeaker()
		local fragments := speaker.Fragments
		local compound, compoundColor, ignore, candidate

		if !this.hasPlannedPitstop() {
			speaker.beginTalk()

			try {
				speaker.speakPhrase("NotPossible")
				speaker.speakPhrase("ConfirmPlan", {forYou: ""}, true)
			}
			finally {
				speaker.endTalk()
			}

			this.setContinuation(ObjBindMethod(this, "planPitstop"))
		}
		else {
			compound := false

			if inList(words, fragments["WetTyre"])
				compound := "Wet"
			else if inList(words, fragments["IntermediateTyre"])
				compound := "Intermediate"
			else if inList(words, fragments["DryTyre"])
				compound := "Dry"

			if compound {
				for ignore, candidate in SessionDatabase.getTyreCompounds(knowledgeBase.getValue("Session.Simulator")
																		, knowledgeBase.getValue("Session.Car")
																		, knowledgeBase.getValue("Session.Track"))
					if (InStr(candidate, compound) = 1) {
						splitCompound(compound, &compound, &compoundColor)

						speaker.speakPhrase("ConfirmCompoundChange", {compound: fragments[compound . "Tyre"]}, true)

						this.setContinuation(ObjBindMethod(this, "updatePitstopTyreCompound", compound, compoundColor))
					}
					else
						speaker.speakPhrase("CompoundNotAvailable", {compound: fragments[compound . "Tyre"]})
			}
			else
				speaker.speakPhrase("Repeat")
		}
	}

	pitstopAdjustPressureRecognized(words) {
		local speaker := this.getSpeaker()
		local fragments := speaker.Fragments
		local tyreType, action, pointPosition, found, pressureValue, tenthPressureValue, ignore, word, startChar, delta

		static tyreTypeFragments := false

		if !this.hasPlannedPitstop() {
			speaker.beginTalk()

			try {
				speaker.speakPhrase("NotPossible")
				speaker.speakPhrase("ConfirmPlan", {forYou: ""}, true)
			}
			finally {
				speaker.endTalk()
			}

			this.setContinuation(ObjBindMethod(this, "planPitstop"))
		}
		else {
			if !tyreTypeFragments
				tyreTypeFragments := CaseInsenseMap("FL", fragments["FrontLeft"], "FR", fragments["FrontRight"]
												  , "RL", fragments["RearLeft"], "RR", fragments["RearRight"])

			tyreType := false

			if inList(words, fragments["All"])
				tyreType := "All"
			else if inList(words, fragments["Front"]) {
				if inList(words, fragments["Left"])
					tyreType := "FL"
				else if inList(words, fragments["Right"])
					tyreType := "FR"
			}
			else if inList(words, fragments["Rear"]) {
				if inList(words, fragments["Left"])
					tyreType := "RL"
				else if inList(words, fragments["Right"])
					tyreType := "RR"
			}

			if tyreType {
				action := false

				if (inList(words, fragments["Increase"]) || inList(words, fragments["More"]))
					action := kIncrease
				else if (inList(words, fragments["Decrease"]) || inList(words, fragments["Less"]))
					action := kDecrease

				pointPosition := inList(words, fragments[(getFloatSeparator() = ".") ? "Point" : "Coma"])
				found := false

				if pointPosition {
					pressureValue := words[pointPosition - 1]
					tenthPressureValue := words[pointPosition + 1]

					found := (this.isNumber(pressureValue, &pressureValue) && this.isNumber(tenthPressureValue, &tenthPressureValue))
				}
				else
					for ignore, word in words {
						if isFloat(word) {
							pressureValue := Floor(word)
							tenthPressureValue := Round((word - pressureValue) * 10)

							found := true

							break
						}
						else {
							startChar := SubStr(word, 1, 1)

							if isInteger(startChar)
								if (StrLen(word) = 2) {
									found := (this.isNumber(startChar, &pressureValue) && this.isNumber(SubStr(word, 2, 1), &tenthPressureValue))

									if found
										break
								}
						}
					}

				if found {
					action := fragments[action]

					delta := Round(pressureValue + (tenthPressureValue / 10), 1)

					if (tyreType = "All")
						speaker.speakPhrase("ConfirmAllPressureChange", {action: action, unit: fragments[getUnit("Pressure")]
																	   , delta: speaker.number2Speech(delta, 1)}, true)
					else
						speaker.speakPhrase("ConfirmPressureChange", {action: action, tyre: tyreTypeFragments[tyreType]
																	, unit: fragments[getUnit("Pressure")]
																	, delta: speaker.number2Speech(delta, 1)}, true)

					this.setContinuation(ObjBindMethod(this, "updatePitstopTyrePressure", tyreType, (action == kIncrease) ? delta : (delta * -1)))

					return
				}
			}

			speaker.speakPhrase("Repeat")
		}
	}

	pitstopAdjustNoPressureRecognized(words) {
		local speaker := this.getSpeaker()

		if !this.hasPlannedPitstop() {
			speaker.beginTalk()

			try {
				speaker.speakPhrase("NotPossible")
				speaker.speakPhrase("ConfirmPlan", {forYou: ""}, true)
			}
			finally {
				speaker.endTalk()
			}

			this.setContinuation(ObjBindMethod(this, "planPitstop"))
		}
		else {
			speaker.speakPhrase("ConfirmNoPressureChange", false, true)

			this.setContinuation(ObjBindMethod(this, "updatePitstopPressures"))
		}
	}

	pitstopAdjustNoTyreRecognized(words) {
		local speaker := this.getSpeaker()

		if !this.hasPlannedPitstop() {
			speaker.beginTalk()

			try {
				speaker.speakPhrase("NotPossible")
				speaker.speakPhrase("ConfirmPlan", {forYou: ""}, true)
			}
			finally {
				speaker.endTalk()
			}

			this.setContinuation(ObjBindMethod(this, "planPitstop"))
		}
		else {
			speaker.speakPhrase("ConfirmNoTyreChange", false, true)

			this.setContinuation(ObjBindMethod(this, "updatePitstopTyreChange"))
		}
	}

	pitstopAdjustRepairRecognized(repairType, words) {
		local speaker := this.getSpeaker()
		local fragments := speaker.Fragments
		local negation

		if !this.hasPlannedPitstop() {
			speaker.beginTalk()

			try {
				speaker.speakPhrase("NotPossible")
				speaker.speakPhrase("ConfirmPlan", {forYou: ""}, true)
			}
			finally {
				speaker.endTalk()
			}

			this.setContinuation(ObjBindMethod(this, "planPitstop"))
		}
		else {
			negation := ""

			if inList(words, fragments["Not"])
				negation := fragments["Not"]

			speaker.speakPhrase("ConfirmRepairChange", {damage: fragments[repairType], negation: negation}, true)

			this.setContinuation(ObjBindMethod(this, "updatePitstopRepair", repairType, negation = ""))
		}
	}

	updatePitstopFuel(fuel) {
		local speaker := this.getSpeaker()

		speaker.beginTalk()

		try {
			if !this.hasPlannedPitstop() {
				speaker.speakPhrase("NotPossible")
				speaker.speakPhrase("ConfirmPlan", {forYou: ""}, true)

				this.setContinuation(ObjBindMethod(this, "planPitstop"))
			}
			else {
				this.KnowledgeBase.setValue("Pitstop.Planned.Fuel", fuel)

				if this.Debug[kDebugKnowledgeBase]
					this.dumpKnowledgeBase(this.KnowledgeBase)

				speaker.speakPhrase("ConfirmPlanUpdate")
				speaker.speakPhrase("MoreChanges", false, true)
			}
		}
		finally {
			speaker.endTalk()
		}
	}

	updatePitstopTyreCompound(compound, color) {
		local speaker := this.getSpeaker()
		local knowledgeBase, ignore, tyreType

		speaker.beginTalk()

		try {
			if !this.hasPlannedPitstop() {
				speaker.speakPhrase("NotPossible")
				speaker.speakPhrase("ConfirmPlan", {forYou: ""}, true)

				this.setContinuation(ObjBindMethod(this, "planPitstop"))
			}
			else {
				knowledgeBase := this.KnowledgeBase

				if (knowledgeBase.getValue("Pitstop.Planned.Tyre.Compound") != compound) {
					speaker.speakPhrase("ConfirmPlanUpdate")

					knowledgeBase.setValue("Tyre.Compound.Target", compound)
					knowledgeBase.setValue("Tyre.Compound.Color.Target", color)

					knowledgeBase.clearFact("Pitstop.Planned.Tyre.Compound")
					knowledgeBase.clearFact("Pitstop.Planned.Tyre.Compound.Color")

					for ignore, tyreType in ["FL", "FR", "RL", "RR"] {
						knowledgeBase.clearFact("Pitstop.Planned.Tyre.Pressure." . tyreType)
						knowledgeBase.clearFact("Pitstop.Planned.Tyre.Pressure." . tyreType . ".Increment")
					}

					knowledgeBase.clearFact("Pitstop.Planned.Tyre.Pressure.Correction")

					this.planPitstop({Update: true, Pressures: true, Confirm: false})

					speaker.speakPhrase("MoreChanges", false, true)
				}
				else {
					speaker.speakPhrase("ConfirmPlanUpdate")
					speaker.speakPhrase("MoreChanges", false, true)
				}
			}
		}
		finally {
			speaker.endTalk()
		}
	}

	updatePitstopTyrePressure(tyreType, delta) {
		local knowledgeBase := this.KnowledgeBase
		local speaker := this.getSpeaker()
		local targetValue, targetIncrement, ignore, tyre

		speaker.beginTalk()

		try {
			if !this.hasPlannedPitstop() {
				speaker.speakPhrase("NotPossible")
				speaker.speakPhrase("ConfirmPlan", {forYou: ""}, true)

				this.setContinuation(ObjBindMethod(this, "planPitstop"))
			}
			else {
				delta := convertUnit("Pressure", internalValue("Float", delta))

				if (tyreType = "All")
					tyreType := ["FL", "FR", "RL", "RR"]
				else
					tyreType := Array(tyreType)

				for ignore, tyre in tyreType {
					targetValue := knowledgeBase.getValue("Pitstop.Planned.Tyre.Pressure." . tyre)
					targetIncrement := knowledgeBase.getValue("Pitstop.Planned.Tyre.Pressure." . tyre . ".Increment")

					knowledgeBase.setValue("Pitstop.Planned.Tyre.Pressure." . tyre, targetValue + delta)
					knowledgeBase.setValue("Pitstop.Planned.Tyre.Pressure." . tyre . ".Increment", targetIncrement + delta)
				}

				if this.Debug[kDebugKnowledgeBase]
					this.dumpKnowledgeBase(this.KnowledgeBase)

				speaker.speakPhrase("ConfirmPlanUpdate")
				speaker.speakPhrase("MoreChanges", false, true)
			}
		}
		finally {
			speaker.endTalk()
		}
	}

	updatePitstopPressures() {
		local speaker := this.getSpeaker()
		local knowledgeBase

		speaker.beginTalk()

		try {
			if !this.hasPlannedPitstop() {
				speaker.speakPhrase("NotPossible")
				speaker.speakPhrase("ConfirmPlan", {forYou: ""}, true)

				this.setContinuation(ObjBindMethod(this, "planPitstop"))
			}
			else {
				knowledgeBase := this.KnowledgeBase

				if (knowledgeBase.getValue("Pitstop.Planned.Tyre.Compound", "Dry") = "Dry") {
					knowledgeBase.setValue("Pitstop.Planned.Tyre.Pressure.FL", knowledgeBase.getValue("Session.Setup.Tyre.Dry.Pressure.FL", 26.1))
					knowledgeBase.setValue("Pitstop.Planned.Tyre.Pressure.FR", knowledgeBase.getValue("Session.Setup.Tyre.Dry.Pressure.FR", 26.1))
					knowledgeBase.setValue("Pitstop.Planned.Tyre.Pressure.RL", knowledgeBase.getValue("Session.Setup.Tyre.Dry.Pressure.RL", 26.1))
					knowledgeBase.setValue("Pitstop.Planned.Tyre.Pressure.RR", knowledgeBase.getValue("Session.Setup.Tyre.Dry.Pressure.RR", 26.1))
				}
				else {
					knowledgeBase.setValue("Pitstop.Planned.Tyre.Pressure.FL", knowledgeBase.getValue("Session.Setup.Tyre.Wet.Pressure.FL", 26.1))
					knowledgeBase.setValue("Pitstop.Planned.Tyre.Pressure.FR", knowledgeBase.getValue("Session.Setup.Tyre.Wet.Pressure.FR", 26.1))
					knowledgeBase.setValue("Pitstop.Planned.Tyre.Pressure.RL", knowledgeBase.getValue("Session.Setup.Tyre.Wet.Pressure.RL", 26.1))
					knowledgeBase.setValue("Pitstop.Planned.Tyre.Pressure.RR", knowledgeBase.getValue("Session.Setup.Tyre.Wet.Pressure.RR", 26.1))
				}

				knowledgeBase.setValue("Pitstop.Planned.Tyre.Pressure.FL.Increment", 0)
				knowledgeBase.setValue("Pitstop.Planned.Tyre.Pressure.FR.Increment", 0)
				knowledgeBase.setValue("Pitstop.Planned.Tyre.Pressure.RL.Increment", 0)
				knowledgeBase.setValue("Pitstop.Planned.Tyre.Pressure.RR.Increment", 0)

				if this.Debug[kDebugKnowledgeBase]
					this.dumpKnowledgeBase(knowledgeBase)

				speaker.speakPhrase("ConfirmPlanUpdate")
				speaker.speakPhrase("MoreChanges", false, true)
			}
		}
		finally {
			speaker.endTalk()
		}
	}

	updatePitstopTyreChange() {
		local speaker := this.getSpeaker()
		local knowledgeBase

		speaker.beginTalk()

		try {
			if !this.hasPlannedPitstop() {
				speaker.speakPhrase("NotPossible")
				speaker.speakPhrase("ConfirmPlan", {forYou: ""}, true)

				this.setContinuation(ObjBindMethod(this, "planPitstop"))
			}
			else {
				knowledgeBase := this.KnowledgeBase

				knowledgeBase.setValue("Pitstop.Planned.Tyre.Compound", false)
				knowledgeBase.setValue("Pitstop.Planned.Tyre.Compound.Color", false)

				if this.Debug[kDebugKnowledgeBase]
					this.dumpKnowledgeBase(knowledgeBase)

				speaker.speakPhrase("ConfirmPlanUpdate")
				speaker.speakPhrase("MoreChanges", false, true)
			}
		}
		finally {
			speaker.endTalk()
		}
	}

	updatePitstopRepair(repairType, repair) {
		local speaker := this.getSpeaker()

		speaker.beginTalk()

		try {
			if !this.hasPlannedPitstop() {
				speaker.speakPhrase("NotPossible")
				speaker.speakPhrase("ConfirmPlan", {forYou: ""}, true)

				this.setContinuation(ObjBindMethod(this, "planPitstop"))
			}
			else {
				this.KnowledgeBase.setValue("Pitstop.Planned.Repair." . repairType, repair)

				if this.Debug[kDebugKnowledgeBase]
					this.dumpKnowledgeBase(this.KnowledgeBase)

				speaker.speakPhrase("ConfirmPlanUpdate")
				speaker.speakPhrase("MoreChanges", false, true)
			}
		}
		finally {
			speaker.endTalk()
		}
	}

	collectTyrePressures() {
		local session := "Other"
		local default := false

		switch this.Session {
			case kSessionPractice:
				session := "Practice"
				default := true
			case kSessionQualification:
				session := "Qualification"
			case kSessionRace:
				session := "Race"
				default := true
		}

		return getMultiMapValue(this.Settings, "Session Settings", "Pressures." . session, default)
	}

	readSettings(simulator, car, track, &settings) {
		local section := ("Simulator." . this.SettingsDatabase.getSimulatorName(simulator))

		return combine(super.readSettings(simulator, car, track, &settings)
					 , CaseInsenseMap("Session.Settings.Pitstop.Service.Refuel", getMultiMapValue(settings, section, "Pitstop.Service.Refuel", true)
									, "Session.Settings.Pitstop.Service.Tyres", getMultiMapValue(settings, section, "Pitstop.Service.Tyres", true)
									, "Session.Settings.Pitstop.Service.Repairs", getMultiMapValue(settings, section, "Pitstop.Service.Repairs", true)
									, "Session.Settings.Pitstop.Delta", getMultiMapValue(settings, "Strategy Settings", "Pitstop.Delta"
																					   , getDeprecatedValue(settings, "Session Settings", "Race Settings", "Pitstop.Delta", 30))
									, "Session.Settings.Damage.Suspension.Repair", getDeprecatedValue(settings, "Session Settings", "Race Settings"
																											  , "Damage.Suspension.Repair", "Always")
									, "Session.Settings.Damage.Suspension.Repair.Threshold", getDeprecatedValue(settings, "Session Settings", "Race Settings"
																														, "Damage.Suspension.Repair.Threshold", 0)
									, "Session.Settings.Damage.Bodywork.Repair", getDeprecatedValue(settings, "Session Settings", "Race Settings"
																											, "Damage.Bodywork.Repair", "Impact")
									, "Session.Settings.Damage.Bodywork.Repair.Threshold", getDeprecatedValue(settings, "Session Settings", "Race Settings"
																													  , "Damage.Bodywork.Repair.Threshold", 1)
									, "Session.Settings.Damage.Engine.Repair", getDeprecatedValue(settings, "Session Settings", "Race Settings"
																										  , "Damage.Engine.Repair", "Impact")
									, "Session.Settings.Damage.Engine.Repair.Threshold", getDeprecatedValue(settings, "Session Settings", "Race Settings"
																													, "Damage.Engine.Repair.Threshold", 1)
									, "Session.Settings.Tyre.Compound.Change", getDeprecatedValue(settings, "Session Settings", "Race Settings"
																										  , "Tyre.Compound.Change", "Never")
									, "Session.Settings.Tyre.Compound.Change.Threshold", getDeprecatedValue(settings, "Session Settings", "Race Settings"
																													, "Tyre.Compound.Change.Threshold", 0)
									, "Session.Settings.Tyre.Pressure.Correction.Temperature", getMultiMapValue(settings, "Session Settings"
																														, "Tyre.Pressure.Correction.Temperature", true)
									, "Session.Settings.Tyre.Pressure.Correction.Setup", getMultiMapValue(settings, "Session Settings"
																												  , "Tyre.Pressure.Correction.Setup", false)
									, "Session.Settings.Tyre.Pressure.Correction.Pressure", getMultiMapValue(settings, "Session Settings"
																													 , "Tyre.Pressure.Correction.Pressure", false)
									, "Session.Settings.Tyre.Dry.Pressure.Target.FL", getDeprecatedValue(settings, "Session Settings", "Race Settings"
																												 , "Tyre.Dry.Pressure.Target.FL", 26.5)
									, "Session.Settings.Tyre.Dry.Pressure.Target.FR", getDeprecatedValue(settings, "Session Settings", "Race Settings"
																												 , "Tyre.Dry.Pressure.Target.FR", 26.5)
									, "Session.Settings.Tyre.Dry.Pressure.Target.RL", getDeprecatedValue(settings, "Session Settings", "Race Settings"
																												 , "Tyre.Dry.Pressure.Target.RL", 26.5)
									, "Session.Settings.Tyre.Dry.Pressure.Target.RR", getDeprecatedValue(settings, "Session Settings", "Race Settings"
																												 , "Tyre.Dry.Pressure.Target.RR", 26.5)
									, "Session.Settings.Tyre.Wet.Pressure.Target.FL", getDeprecatedValue(settings, "Session Settings", "Race Settings"
																												 , "Tyre.Wet.Pressure.Target.FL", 30.0)
									, "Session.Settings.Tyre.Wet.Pressure.Target.FR", getDeprecatedValue(settings, "Session Settings", "Race Settings"
																												 , "Tyre.Wet.Pressure.Target.FR", 30.0)
									, "Session.Settings.Tyre.Wet.Pressure.Target.RL", getDeprecatedValue(settings, "Session Settings", "Race Settings"
																												 , "Tyre.Wet.Pressure.Target.RL", 30.0)
									, "Session.Settings.Tyre.Wet.Pressure.Target.RR", getDeprecatedValue(settings, "Session Settings", "Race Settings"
																												 , "Tyre.Wet.Pressure.Target.RR", 30.0)
									, "Session.Settings.Tyre.Pressure.Deviation", getDeprecatedValue(settings, "Session Settings", "Race Settings"
																											 , "Tyre.Pressure.Deviation", 0.2)
									, "Session.Setup.Tyre.Set.Fresh", getDeprecatedValue(settings, "Session Setup", "Race Setup"
																								 , "Tyre.Set.Fresh", 8)
									, "Session.Setup.Tyre.Set", getDeprecatedValue(settings, "Session Setup", "Race Setup", "Tyre.Set", 7)
									, "Session.Setup.Tyre.Dry.Pressure.FL", getDeprecatedValue(settings, "Session Setup", "Race Setup"
																									   , "Tyre.Dry.Pressure.FL", 26.1)
									, "Session.Setup.Tyre.Dry.Pressure.FR", getDeprecatedValue(settings, "Session Setup", "Race Setup"
																									   , "Tyre.Dry.Pressure.FR", 26.1)
									, "Session.Setup.Tyre.Dry.Pressure.RL", getDeprecatedValue(settings, "Session Setup", "Race Setup"
																									   , "Tyre.Dry.Pressure.RL", 26.1)
									, "Session.Setup.Tyre.Dry.Pressure.RR", getDeprecatedValue(settings, "Session Setup", "Race Setup"
																									   , "Tyre.Dry.Pressure.RR", 26.1)
									, "Session.Setup.Tyre.Wet.Pressure.FL", getDeprecatedValue(settings, "Session Setup", "Race Setup"
																									   , "Tyre.Wet.Pressure.FL", 28.2)
									, "Session.Setup.Tyre.Wet.Pressure.FR", getDeprecatedValue(settings, "Session Setup", "Race Setup"
																									   , "Tyre.Wet.Pressure.FR", 28.2)
									, "Session.Setup.Tyre.Wet.Pressure.RL", getDeprecatedValue(settings, "Session Setup", "Race Setup"
																									   , "Tyre.Wet.Pressure.RL", 28.2)
									, "Session.Setup.Tyre.Wet.Pressure.RR", getDeprecatedValue(settings, "Session Setup", "Race Setup"
																									   , "Tyre.Wet.Pressure.RR", 28.2)))
	}

	prepareSession(&settings, &data) {
		super.prepareSession(&settings, &data)

		if settings
			this.updateConfigurationValues({UseTalking: getMultiMapValue(settings, "Assistant.Engineer", "Voice.UseTalking", true)})
	}

	createSession(&settings, &data) {
		local facts := super.createSession(&settings, &data)
		local configuration := this.Configuration
		local simulatorName := this.SettingsDatabase.getSimulatorName(facts["Session.Simulator"])

		if settings
			this.updateConfigurationValues({UseTalking: getMultiMapValue(settings, "Assistant.Engineer", "Voice.UseTalking", true)})

		facts["Session.Settings.Damage.Analysis.Laps"]
			:= getMultiMapValue(configuration, "Race Engineer Analysis", simulatorName . ".DamageAnalysisLaps", 1)

		facts["Session.Settings.Tyre.Pressure.Correction.Temperature.Air"]
			:= getMultiMapValue(settings, "Session Settings", "Tyre.Pressure.Correction.Temperature.Air", -0.1)
		facts["Session.Settings.Tyre.Pressure.Correction.Temperature.Track"]
			:= getMultiMapValue(settings, "Session Settings", "Tyre.Pressure.Correction.Temperature.Track", -0.02)

		facts["Session.Setup.Tyre.Compound"]
			:= getMultiMapValue(data, "Car Data", "TyreCompound"
									, getDeprecatedValue(settings, "Session Setup", "Race Setup", "Tyre.Compound", "Dry"))
		facts["Session.Setup.Tyre.Compound.Color"]
			:= getMultiMapValue(data, "Car Data", "TyreCompoundColor"
									, getDeprecatedValue(settings, "Session Setup", "Race Setup", "Tyre.Compound.Color", "Black"))

		if (this.Session = kSessionPractice)
			this.updateConfigurationValues({Announcements: {FuelWarning: getMultiMapValue(settings, "Assistant.Engineer", "Announcement.Practice.LowFuel", true)
														  , DamageReporting: getMultiMapValue(settings, "Assistant.Engineer", "Announcement.Practice.Damage", false)
														  , DamageAnalysis: getMultiMapValue(settings, "Assistant.Engineer", "Announcement.Practice.Damage", false)
														  , PressureReporting: getMultiMapValue(settings, "Assistant.Engineer", "Announcement.Practice.Pressure", true)}})
		else if (this.Session = kSessionQualification)
			this.updateConfigurationValues({Announcements: {FuelWarning: getMultiMapValue(settings, "Assistant.Engineer", "Announcement.Qualification.LowFuel", false)
														  , DamageReporting: getMultiMapValue(settings, "Assistant.Engineer", "Announcement.Qualification.Damage", false)
														  , DamageAnalysis: getMultiMapValue(settings, "Assistant.Engineer", "Announcement.Qualification.Damage", false)
														  , PressureReporting: getMultiMapValue(settings, "Assistant.Engineer", "Announcement.Qualification.Pressure", true)}})
		else if (this.Session = kSessionRace)
			this.updateConfigurationValues({Announcements: {FuelWarning: getMultiMapValue(settings, "Assistant.Engineer", "Announcement.Race.LowFuel", true)
										  , DamageReporting: getMultiMapValue(settings, "Assistant.Engineer", "Announcement.Race.Damage", true)
										  , DamageAnalysis: getMultiMapValue(settings, "Assistant.Engineer", "Announcement.Race.Damage", true)
										  , PressureReporting: getMultiMapValue(settings, "Assistant.Engineer", "Announcement.Race.Pressure", true)}})

		return facts
	}

	startSession(settings, data) {
		local facts, simulatorName, configuration, deprecated, saveSettings, speaker, strategistPlugin, strategistName
		local knowledgeBase

		facts := this.createSession(&settings, &data)

		simulatorName := this.Simulator
		configuration := this.Configuration

		deprecated := getMultiMapValue(configuration, "Race Engineer Shutdown", simulatorName . ".SaveSettings", kNever)
		saveSettings := getMultiMapValue(configuration, "Race Assistant Shutdown", simulatorName . ".SaveSettings", deprecated)

		this.updateConfigurationValues({LearningLaps: getMultiMapValue(configuration, "Race Engineer Analysis", simulatorName . ".LearningLaps", 1)
									  , AdjustLapTime: getMultiMapValue(configuration, "Race Engineer Analysis", simulatorName . ".AdjustLapTime", true)
									  , SaveSettings: saveSettings
									  , SaveTyrePressures: getMultiMapValue(configuration, "Race Engineer Shutdown", simulatorName . ".SaveTyrePressures", kAsk)})

		knowledgeBase := this.createKnowledgeBase(facts)

		this.updateDynamicValues({KnowledgeBase: knowledgeBase, HasPressureData: false
								, BestLapTime: 0, OverallTime: 0, LastFuelAmount: 0, InitialFuelAmount: 0, EnoughData: false})

		if this.Speaker {
			speaker := this.getSpeaker()

			speaker.beginTalk()

			try {
				speaker.speakPhrase("GreetingEngineer")

				if ProcessExist("Race Strategist.exe") {
					strategistPlugin := Plugin("Race Strategist", kSimulatorConfiguration)
					strategistName := strategistPlugin.getArgumentValue("raceAssistantName", false)

					if strategistName {
						speaker.speakPhrase("GreetingStrategist", {strategist: strategistName})

						speaker.speakPhrase("CallUs")
					}
					else
						speaker.speakPhrase("CallMe")
				}
				else
					speaker.speakPhrase("CallMe")
			}
			finally {
				speaker.endTalk()
			}
		}

		if this.Debug[kDebugKnowledgeBase]
			this.dumpKnowledgeBase(this.KnowledgeBase)
	}

	finishSession(shutdown := true) {
		local knowledgeBase := this.KnowledgeBase

		if knowledgeBase {
			logMessage(kLogDebug, "Finish: Speaker is " . this.Speaker)
			logMessage(kLogDebug, "Finish: Listener is " . this.Listener)
			logMessage(kLogDebug, "Finish: SaveTyrePressures is " . this.SaveTyrePressures)
			logMessage(kLogDebug, "Finish: HasPressureData is " . this.HasPressureData)
			logMessage(kLogDebug, "Finish: collectTyrePressures() is " . this.collectTyrePressures())

			if (this.Session == kSessionRace)
				if ProcessExist("Race Strategist.exe")
					Sleep(5000)

			if (shutdown && this.Speaker)
				this.getSpeaker().speakPhrase("Bye")

			if (shutdown && (knowledgeBase.getValue("Lap", 0) > this.LearningLaps)) {
				this.shutdownSession("Before")

				if (((this.SaveTyrePressures = kAsk) && this.collectTyrePressures() && this.HasPressureData) || (this.SaveSettings = kAsk)) {
					this.getSpeaker().speakPhrase("ConfirmDataUpdate", false, true)

					this.setContinuation(ObjBindMethod(this, "shutdownSession", "After"))

					Task.startTask(ObjBindMethod(this, "forceFinishSession"), 120000, kLowPriority)

					return
				}
			}

			this.updateDynamicValues({KnowledgeBase: false})
		}

		this.updateDynamicValues({BestLapTime: 0, OverallTime: 0, LastFuelAmount: 0, InitialFuelAmount: 0, EnoughData: false, HasPressureData: false})
		this.updateSessionValues({Simulator: "", Session: kSessionFinished, SessionTime: false})
	}

	forceFinishSession() {
		if !this.SessionDataActive {
			this.updateDynamicValues({KnowledgeBase: false})

			this.finishSession()

			return false
		}
		else {
			Task.CurrentTask.Sleep := 5000

			return Task.CurrentTask
		}
	}

	shutdownSession(phase) {
		this.iSessionDataActive := true

		try {
			if (((phase = "After") && (this.SaveSettings = kAsk)) || ((phase = "Before") && (this.SaveSettings = kAlways)))
				if (this.Session == kSessionRace)
					this.saveSessionSettings()

			if (((phase = "After") && (this.SaveTyrePressures = kAsk)) || ((phase = "Before") && (this.SaveTyrePressures = kAlways)))
				if (this.HasPressureData && this.collectTyrePressures())
					this.updateTyresDatabase()
		}
		finally {
			this.iSessionDataActive := false
		}

		if (phase = "After") {
			if this.Speaker
				this.getSpeaker().speakPhrase("DataUpdated")

			this.updateDynamicValues({KnowledgeBase: false, HasPressureData: false})

			this.finishSession()
		}
	}

	prepareData(lapNumber, data) {
		local knowledgeBase, bodyworkDamage, suspensionDamage

		data := super.prepareData(lapNumber, data)

		knowledgeBase := this.KnowledgeBase

		if (knowledgeBase.getValue("Lap", false) != lapNumber) {
			bodyworkDamage := string2Values(",", getMultiMapValue(data, "Car Data", "BodyworkDamage", ""))

			knowledgeBase.setFact("Lap." . lapNumber . ".Damage.Bodywork.Front", Round(bodyworkDamage[1], 2))
			knowledgeBase.setFact("Lap." . lapNumber . ".Damage.Bodywork.Rear", Round(bodyworkDamage[2], 2))
			knowledgeBase.setFact("Lap." . lapNumber . ".Damage.Bodywork.Left", Round(bodyworkDamage[3], 2))
			knowledgeBase.setFact("Lap." . lapNumber . ".Damage.Bodywork.Right", Round(bodyworkDamage[4], 2))
			knowledgeBase.setFact("Lap." . lapNumber . ".Damage.Bodywork.Center", Round(bodyworkDamage[5], 2))

			suspensionDamage := string2Values(",", getMultiMapValue(data, "Car Data", "SuspensionDamage", ""))

			knowledgeBase.setFact("Lap." . lapNumber . ".Damage.Suspension.FL", Round(suspensionDamage[1], 2))
			knowledgeBase.setFact("Lap." . lapNumber . ".Damage.Suspension.FR", Round(suspensionDamage[2], 2))
			knowledgeBase.setFact("Lap." . lapNumber . ".Damage.Suspension.RL", Round(suspensionDamage[3], 2))
			knowledgeBase.setFact("Lap." . lapNumber . ".Damage.Suspension.RR", Round(suspensionDamage[4], 2))

			knowledgeBase.setFact("Lap." . lapNumber . ".Damage.Engine"
								, Round(getMultiMapValue(data, "Car Data", "EngineDamage", 0), 1))
		}

		return data
	}

	addLap(lapNumber, &data) {
		local knowledgeBase := this.KnowledgeBase
		local driverForname := ""
		local driverSurname := ""
		local driverNickname := ""
		local result, currentCompound, currentCompoundColor, targetCompound, targetCompoundColor, prefix
		local coldPressures, hotPressures, pressuresLosses, airTemperature, trackTemperature, weatherNow
		local savedKnowledgeBase, stateFile, key, value

		static lastLap := 0

		if (lapNumber <= lastLap)
			lastLap := 0
		else if ((lastLap == 0) && (lapNumber > 1))
			lastLap := (lapNumber - 1)

		if knowledgeBase {
			if (this.Speaker && (lapNumber > 1)) {
				driverForname := knowledgeBase.getValue("Driver.Forname", "John")
				driverSurname := knowledgeBase.getValue("Driver.Surname", "Doe")
				driverNickname := knowledgeBase.getValue("Driver.Nickname", "JDO")
			}

			if (this.RemoteHandler && knowledgeBase.getValue("Pitstop.Planned.Nr", false)) {
				savedKnowledgeBase := newMultiMap()

				for key, value in this.KnowledgeBase.Facts.Facts
					if (InStr(key, "Pitstop") = 1)
						setMultiMapValue(savedKnowledgeBase, "Pitstop Pending", key, value)

				stateFile := temporaryFileName(this.AssistantType . " Pitstop Pending", "state")

				writeMultiMap(stateFile, savedKnowledgeBase)

				this.RemoteHandler.saveLapState(lapNumber, stateFile)
			}
		}

		result := super.addLap(lapNumber, &data)

		if (this.Speaker && (lastLap < (lapNumber - 2)) && (computeDriverName(driverForname, driverSurname, driverNickname) != this.DriverFullName))
			this.getSpeaker().speakPhrase("WelcomeBack")

		lastLap := lapNumber

		if (this.SaveTyrePressures != kNever) {
			knowledgeBase := this.KnowledgeBase

			currentCompound := knowledgeBase.getValue("Tyre.Compound", false)
			currentCompoundColor := knowledgeBase.getValue("Tyre.Compound.Color", false)

			if this.hasEnoughData(false) {
				targetCompound := knowledgeBase.getValue("Tyre.Compound.Target", false)
				targetCompoundColor := knowledgeBase.getValue("Tyre.Compound.Color.Target", false)
			}
			else {
				targetCompound := currentCompound
				targetCompoundColor := currentCompoundColor
			}

			if (currentCompound && (currentCompound = targetCompound) && (currentCompoundColor = targetCompoundColor)) {
				if (lapNumber <= knowledgeBase.getValue("Session.Settings.Lap.Learning.Laps", 2)) {
					if (currentCompound = "Dry")
						prefix := "Session.Setup.Tyre.Dry.Pressure."
					else
						prefix := "Session.Setup.Tyre.Wet.Pressure."
				}
				else if this.hasEnoughData(false)
					prefix := "Tyre.Pressure.Target."
				else
					prefix := false

				if prefix
					try {
						coldPressures := values2String(",", Round(knowledgeBase.getValue(prefix . "FL"), 1)
														  , Round(knowledgeBase.getValue(prefix . "FR"), 1)
														  , Round(knowledgeBase.getValue(prefix . "RL"), 1)
														  , Round(knowledgeBase.getValue(prefix . "RR"), 1))

						hotPressures := values2String(",", Round(knowledgeBase.getValue("Lap." . lapNumber . ".Tyre.Pressure.FL"), 1)
														 , Round(knowledgeBase.getValue("Lap." . lapNumber . ".Tyre.Pressure.FR"), 1)
														 , Round(knowledgeBase.getValue("Lap." . lapNumber . ".Tyre.Pressure.RL"), 1)
														 , Round(knowledgeBase.getValue("Lap." . lapNumber . ".Tyre.Pressure.RR"), 1))

						prefix := "Tyre.Pressure.Loss."

						pressuresLosses := values2String(",", Round(knowledgeBase.getValue(prefix . "FL", 0), 1)
															, Round(knowledgeBase.getValue(prefix . "FR", 0), 1)
															, Round(knowledgeBase.getValue(prefix . "RL", 0), 1)
															, Round(knowledgeBase.getValue(prefix . "RR", 0), 1))

						airTemperature := Round(getMultiMapValue(data, "Weather Data", "Temperature", 0))
						trackTemperature := Round(getMultiMapValue(data, "Track Data", "Temperature", 0))

						if (airTemperature = 0)
							airTemperature := Round(getMultiMapValue(data, "Car Data", "AirTemperature", 0))

						if (trackTemperature = 0)
							trackTemperature := Round(getMultiMapValue(data, "Car Data", "RoadTemperature", 0))

						weatherNow := getMultiMapValue(data, "Weather Data", "Weather", "Dry")

						logMessage(kLogDebug, "Saving pressures for " . lapNumber)

						this.savePressureData(lapNumber, knowledgeBase.getValue("Session.Simulator")
													   , knowledgeBase.getValue("Session.Car"), knowledgeBase.getValue("Session.Track")
													   , weatherNow, airTemperature, trackTemperature
													   , currentCompound, currentCompoundColor, coldPressures, hotPressures, pressuresLosses)
					}
					catch Any as exception {
						logError(exception)
					}
			}
		}

		return result
	}

	updateLap(lapNumber, &data) {
		local knowledgeBase := this.KnowledgeBase
		local result := super.updateLap(lapNumber, &data)
		local needProduce := false
		local tyrePressures := string2Values(",", getMultiMapValue(data, "Car Data", "TyrePressure", ""))
		local tyreTemperatures := string2Values(",", getMultiMapValue(data, "Car Data", "TyreTemperature", ""))
		local bodyworkDamage := string2Values(",", getMultiMapValue(data, "Car Data", "BodyworkDamage", ""))
		local suspensionDamage := string2Values(",", getMultiMapValue(data, "Car Data", "SuspensionDamage", ""))
		local threshold := knowledgeBase.getValue("Session.Settings.Tyre.Pressure.Deviation")
		local changed := false
		local fact, index, tyreType, oldValue, newValue, position

		if (tyrePressures.Length >= 4) {
			for index, tyreType in ["FL", "FR", "RL", "RR"] {
				newValue := Round(tyrePressures[index], 2)
				fact := ("Lap." . lapNumber . ".Tyre.Pressure." . tyreType)
				oldValue := knowledgeBase.getValue(fact, false)

				if (oldValue && (Abs(oldValue - newValue) > threshold)) {
					knowledgeBase.setValue(fact, newValue)

					changed := true
				}
			}

			if changed {
				knowledgeBase.addFact("Tyre.Update.Pressure", true)

				needProduce := true
			}
		}

		if (tyreTemperatures.Length >= 4)
			for index, tyreType in ["FL", "FR", "RL", "RR"]
				knowledgeBase.setFact("Lap." . lapNumber . ".Tyre.Temperature." . tyreType, Round(tyreTemperatures[index], 2))

		if (bodyWorkDamage.Length >= 5) {
			changed := false

			for index, position in ["Front", "Rear", "Left", "Right", "Center"] {
				newValue := Round(bodyworkDamage[index], 2)
				fact := ("Lap." . lapNumber . ".Damage.Bodywork." . position)
				oldValue := knowledgeBase.getValue(fact, 0)

				if (oldValue < newValue)
					knowledgeBase.setFact(fact, newValue)

				changed := (changed || (Round(oldValue) < Round(newValue)))
			}

			if changed {
				knowledgeBase.addFact("Damage.Update.Bodywork", lapNumber)

				needProduce := true
			}
		}

		if (suspensionDamage.Length >= 4) {
			changed := false

			for index, position in ["FL", "FR", "RL", "RR"] {
				newValue := Round(suspensionDamage[index], 2)
				fact := ("Lap." . lapNumber . ".Damage.Suspension." . position)
				oldValue := knowledgeBase.getValue(fact, 0)

				if (oldValue < newValue)
					knowledgeBase.setFact(fact, newValue)

				changed := (changed || (Round(oldValue) < Round(newValue)))
			}

			if changed {
				knowledgeBase.addFact("Damage.Update.Suspension", lapNumber)

				needProduce := true
			}
		}

		newValue := Round(getMultiMapValue(data, "Car Data", "EngineDamage", 0), 1)
		fact := ("Lap." . lapNumber . ".Damage.Engine")

		if (knowledgeBase.getValue(fact, 0) < newValue) {
			knowledgeBase.setFact(fact, newValue)

			knowledgeBase.addFact("Damage.Update.Engine", lapNumber)

			needProduce := true
		}

		if needProduce {
			if knowledgeBase.produce()
				result := true

			if this.Debug[kDebugKnowledgeBase]
				this.dumpKnowledgeBase(this.KnowledgeBase)
		}

		return result
	}

	savePressureData(lapNumber, simulator, car, track, weather, airTemperature, trackTemperature
				   , compound, compoundColor, coldPressures, hotPressures, pressuresLosses) {
		this.iSessionDataActive := true

		try {
			if (this.RemoteHandler && this.collectTyrePressures()) {
				this.updateDynamicValues({HasPressureData: true})

				this.RemoteHandler.savePressureData(lapNumber, simulator, car, track, weather, airTemperature, trackTemperature
												  , compound, compoundColor, coldPressures, hotPressures, pressuresLosses)
			}
		}
		finally {
			this.iSessionDataActive := false
		}
	}

	updateTyresDatabase() {
		if (this.RemoteHandler && this.collectTyrePressures())
			this.RemoteHandler.updateTyresDatabase()

		this.updateDynamicValues({HasPressureData: false})
	}

	hasPlannedPitstop() {
		return (this.KnowledgeBase ? this.KnowledgeBase.getValue("Pitstop.Planned", false) : false)
	}

	hasPreparedPitstop() {
		return (this.KnowledgeBase ? this.KnowledgeBase.getValue("Pitstop.Prepared", false) : false)
	}

	supportsPitstop() {
		if this.RemoteHandler {
			switch this.Session {
				case kSessionPractice:
					return getMultiMapValue(this.Settings, "Session Settings", "Pitstop.Practice", false)
				case kSessionQualification:
					return getMultiMapValue(this.Settings, "Session Settings", "Pitstop.Qualification", false)
				case kSessionRace:
					return getMultiMapValue(this.Settings, "Session Settings", "Pitstop.Race", true)
				default:
					return false
			}
		}
		else
			return false
	}

	requestInformation(category, arguments*) {
		this.clearContinuation()

		switch category, false {
			case "Time":
				this.timeRecognized([])
			case "LapsRemaining":
				this.lapInfoRecognized([])
			case "FuelRemaining":
				this.fuelInfoRecognized([])
			case "Weather":
				this.weatherRecognized([])
			case "TyrePressures":
				this.tyreInfoRecognized(Array(this.getSpeaker().Fragments["Pressures"]))
			case "TyrePressuresCold":
				this.tyreInfoRecognized(Array(this.getSpeaker().Fragments["Pressures"], this.getSpeaker().Fragments["Cold"]))
			case "TyrePressuresSetup":
				this.tyreInfoRecognized(Array(this.getSpeaker().Fragments["Pressures"], this.getSpeaker().Fragments["Setup"]))
			case "TyreTemperatures":
				this.tyreInfoRecognized(Array(this.getSpeaker().Fragments["Temperatures"]))
			case "TyreWear":
				this.tyreWearRecognized([])
			case "BrakeTemperatures":
				this.brakeTemperaturesRecognized([])
			case "BrakeWear":
				this.brakeWearRecognized([])
		}
	}

	planPitstop(optionsOrLap := kUndefined, refuelAmount := kUndefined
			  , changeTyres := kUndefined, tyreSet := kUndefined
			  , tyreCompound := kUndefined, tyreCompoundColor := kUndefined, tyrePressures := kUndefined
			  , repairBodywork := kUndefined, repairSuspension := kUndefined, repairEngine := kUndefined
			  , requestDriver := kUndefined) {
		local knowledgeBase := this.KnowledgeBase
		local confirm := true
		local options := ((optionsOrLap = kUndefined) ? true : optionsOrLap)
		local plannedLap := false
		local force := false
		local result, pitstopNumber, speaker, fragments, fuel, lap, correctedFuel, targetFuel
		local correctedTyres, compound, color, incrementFL, incrementFR, incrementRL, incrementRR, pressureCorrection
		local temperatureDelta, debug, tyre, tyreType, lostPressure, deviationThreshold

		this.clearContinuation()

		if (optionsOrLap = "Now") {
			optionsOrLap := kUndefined
			options := true

			force := true
		}
		else if (optionsOrLap != kUndefined) {
			if (InStr(optionsOrLap, "!") = 1)
				optionsOrLap := SubStr(optionsOrLap, 2)


			if isNumber(optionsOrLap) {
				options := true

				if (optionsOrLap != false)
					plannedLap := Max(optionsOrLap, knowledgeBase.getValue("Lap") + 1)
			}
			else if (isObject(optionsOrLap) && optionsOrLap.HasProp("Confirm"))
				confirm := optionsOrLap.Confirm
		}

		if (!force && !plannedLap)
			if !this.hasEnoughData()
				return false

		if !this.supportsPitstop() {
			if this.Speaker
				this.getSpeaker().speakPhrase("NoPitstop")

			return false
		}

		knowledgeBase.addFact("Pitstop.Plan", ((options == true) || !options.HasProp("Update") || !options.Update) ? true : false)

		correctedFuel := false

		if (refuelAmount != kUndefined) {
			if (InStr(refuelAmount, "!") = 1)
				knowledgeBase.addFact("Pitstop.Plan.Fuel.Amount", SubStr(refuelAmount, 2) + 0)
			else {
				targetFuel := knowledgeBase.getValue("Fuel.Amount.Target", false)

				if (targetFuel && (targetFuel != refuelAmount)) {
					if ((knowledgeBase.getValue("Lap." . knowledgeBase.getValue("Lap") . ".Fuel.Remaining") + targetFuel)
					  < knowledgeBase.getValue("Session.Settings.Fuel.Max"))
						correctedFuel := true
					else
						knowledgeBase.addFact("Pitstop.Plan.Fuel.Amount", refuelAmount)
				}
				else
					knowledgeBase.addFact("Pitstop.Plan.Fuel.Amount", refuelAmount)
			}
		}

		correctedTyres := false

		if (changeTyres != kUndefined) {
			if (InStr(changeTyres . "", "!") = 1) {
				changeTyres := (SubStr(changeTyres, 2) + 0)

				knowledgeBase.addFact("Pitstop.Plan.Tyre.Change", changeTyres)
			}
			else {
				if (changeTyres != (knowledgeBase.getValue("Tyre.Compound.Target", false) != false)) {
					changeTyres := !changeTyres

					correctedTyres := true
				}
			}

			if changeTyres {
				if (tyreSet != kUndefined)
					knowledgeBase.addFact("Pitstop.Plan.Tyre.Set", tyreSet)

				if (tyreCompound != kUndefined)
					knowledgeBase.addFact("Pitstop.Plan.Tyre.Compound", tyreCompound)

				if (tyreCompoundColor != kUndefined)
					knowledgeBase.addFact("Pitstop.Plan.Tyre.Compound.Color", tyreCompoundColor)

				if (tyrePressures != kUndefined) {
					tyrePressures := string2Values(",", tyrePressures)

					knowledgeBase.addFact("Pitstop.Plan.Tyre.Pressure.FL", tyrePressures[1])
					knowledgeBase.addFact("Pitstop.Plan.Tyre.Pressure.FR", tyrePressures[2])
					knowledgeBase.addFact("Pitstop.Plan.Tyre.Pressure.RL", tyrePressures[3])
					knowledgeBase.addFact("Pitstop.Plan.Tyre.Pressure.RR", tyrePressures[4])
				}
			}
		}

		if (repairBodywork != kUndefined)
			knowledgeBase.addFact("Pitstop.Plan.Repair.Bodywork", repairBodywork)

		if (repairSuspension != kUndefined)
			knowledgeBase.addFact("Pitstop.Plan.Repair.Suspension", repairSuspension)

		if (repairEngine != kUndefined)
			knowledgeBase.addFact("Pitstop.Plan.Repair.Engine", repairEngine)

		if (requestDriver != kUndefined)
			knowledgeBase.addFact("Pitstop.Plan.Driver.Request", requestDriver)

		result := knowledgeBase.produce()

		if this.Debug[kDebugKnowledgeBase]
			this.dumpKnowledgeBase(knowledgeBase)

		pitstopNumber := knowledgeBase.getValue("Pitstop.Planned.Nr")

		knowledgeBase.setFact("Pitstop.Planned.Lap", plannedLap ? (plannedLap - 1) : false)

		if this.Speaker {
			speaker := this.getSpeaker()
			fragments := speaker.Fragments

			speaker.beginTalk()

			try {
				if ((options == true) || (options.HasProp("Intro") && options.Intro))
					speaker.speakPhrase("Pitstop", {number: pitstopNumber})

				if ((options == true) || (options.HasProp("Fuel") && options.Fuel)) {
					fuel := Round(knowledgeBase.getValue("Pitstop.Planned.Fuel", 0))

					if (fuel == 0)
						speaker.speakPhrase("NoRefuel")
					else
						speaker.speakPhrase("Refuel", {fuel: speaker.number2Speech(convertUnit("Volume", fuel), 0), unit: fragments[getUnit("Volume")]})

					if correctedFuel
						speaker.speakPhrase("RefuelAdjusted")
				}

				compound := knowledgeBase.getValue("Pitstop.Planned.Tyre.Compound", false)

				if ((options == true) || (options.HasProp("Compound") && options.Compound)) {
					if compound {
						color := knowledgeBase.getValue("Pitstop.Planned.Tyre.Compound.Color")
						tyreSet := knowledgeBase.getValue("Pitstop.Planned.Tyre.Set", 0)

						if (compound = "Dry")
							speaker.speakPhrase(!tyreSet ? "DryTyresNoSet" : "DryTyres", {compound: fragments[compound . "Tyre"], color: color, set: tyreSet})
						else
							speaker.speakPhrase(!tyreSet ? "WetTyresNoSet" : "WetTyres", {compound: fragments[compound . "Tyre"], color: color, set: tyreSet})
					}
					else {
						if (knowledgeBase.getValue("Lap.Remaining.Stint", 0) > 5)
							speaker.speakPhrase("NoTyreChange")
						else
							speaker.speakPhrase("NoTyreChangeLap")
					}
				}

				debug := this.VoiceManager.Debug[kDebugPhrases]

				if (compound && ((options == true) || (options.HasProp("Pressures") && options.Pressures))) {
					incrementFL := Round(knowledgeBase.getValue("Pitstop.Planned.Tyre.Pressure.FL.Increment", 0), 1)
					incrementFR := Round(knowledgeBase.getValue("Pitstop.Planned.Tyre.Pressure.FR.Increment", 0), 1)
					incrementRL := Round(knowledgeBase.getValue("Pitstop.Planned.Tyre.Pressure.RL.Increment", 0), 1)
					incrementRR := Round(knowledgeBase.getValue("Pitstop.Planned.Tyre.Pressure.RR.Increment", 0), 1)

					if (debug || (incrementFL != 0) || (incrementFR != 0) || (incrementRL != 0) || (incrementRR != 0) || (tyrePressures != kUndefined))
						speaker.speakPhrase("NewPressures")

					if (debug || (incrementFL != 0) || (tyrePressures != kUndefined))
						speaker.speakPhrase("TyreFL", {value: speaker.number2Speech(convertUnit("Pressure", knowledgeBase.getValue("Pitstop.Planned.Tyre.Pressure.FL")))
													 , unit: fragments[getUnit("Pressure")]})

					if (debug || (incrementFR != 0) || (tyrePressures != kUndefined))
						speaker.speakPhrase("TyreFR", {value: speaker.number2Speech(convertUnit("Pressure", knowledgeBase.getValue("Pitstop.Planned.Tyre.Pressure.FR")))
													 , unit: fragments[getUnit("Pressure")]})

					if (debug || (incrementRL != 0) || (tyrePressures != kUndefined))
						speaker.speakPhrase("TyreRL", {value: speaker.number2Speech(convertUnit("Pressure", knowledgeBase.getValue("Pitstop.Planned.Tyre.Pressure.RL")))
													 , unit: fragments[getUnit("Pressure")]})

					if (debug || (incrementRR != 0) || (tyrePressures != kUndefined))
						speaker.speakPhrase("TyreRR", {value: speaker.number2Speech(convertUnit("Pressure", knowledgeBase.getValue("Pitstop.Planned.Tyre.Pressure.RR")))
													 , unit: fragments[getUnit("Pressure")]})

					pressureCorrection := Round(knowledgeBase.getValue("Pitstop.Planned.Tyre.Pressure.Correction", 0), 1)

					if (Abs(pressureCorrection) > 0.05) {
						temperatureDelta := knowledgeBase.getValue("Weather.Temperature.Air.Delta", 0)

						if (temperatureDelta = 0)
							temperatureDelta := ((pressureCorrection > 0) ? -1 : 1)

						speaker.speakPhrase((pressureCorrection > 0) ? "PressureCorrectionUp" : "PressureCorrectionDown"
										  , {value: speaker.number2Speech(convertUnit("Pressure", Abs(pressureCorrection)))
										   , unit: fragments[getUnit("Pressure")]
										   , pressureDirection: (pressureCorrection > 0) ? fragments["Increase"] : fragments["Decrease"]
										   , temperatureDirection: (temperatureDelta > 0) ? fragments["Rising"] : fragments["Falling"]})
					}

					deviationThreshold := knowledgeBase.getValue("Session.Settings.Tyre.Pressure.Deviation")

					for tyre, tyreType in Map("FrontLeft", "FL", "FrontRight", "FR", "RearLeft", "RL", "RearRight", "RR") {
						lostPressure := knowledgeBase.getValue("Pitstop.Planned.Tyre.Pressure.Lost." . tyreType, false)

						if (lostPressure && (lostPressure >= deviationThreshold))
							speaker.speakPhrase("PressureAdjustment", {tyre: fragments[tyre]
																	 , lost: speaker.number2Speech(convertUnit("Pressure", lostPressure))
																	 , unit: fragments[getUnit("Pressure")]})
					}
				}

				if ((options == true) || (options.HasProp("Repairs") && options.Repairs)
				 || (repairBodywork != kUndefined) || (repairSuspension != kUndefined) || (repairEngine != kUndefined)) {
					if knowledgeBase.getValue("Pitstop.Planned.Repair.Suspension", false)
						speaker.speakPhrase("RepairSuspension")
					else if debug
						speaker.speakPhrase("NoRepairSuspension")

					if knowledgeBase.getValue("Pitstop.Planned.Repair.Bodywork", false)
						speaker.speakPhrase("RepairBodywork")
					else if debug
						speaker.speakPhrase("NoRepairBodywork")

					if knowledgeBase.getValue("Pitstop.Planned.Repair.Engine", false)
						speaker.speakPhrase("RepairEngine")
					else if debug
						speaker.speakPhrase("NoRepairEngine")
				}

				if confirm
					if plannedLap
						speaker.speakPhrase("PitstopLap", {lap: plannedLap})
					else {
						speaker.speakPhrase("ConfirmPrepare", false, true)

						this.setContinuation(VoiceManager.ReplyContinuation(this, ObjBindMethod(this, "preparePitstop"), false, "Okay"))
					}
			}
			finally {
				speaker.endTalk()
			}
		}

		if (result && this.RemoteHandler)
			this.RemoteHandler.pitstopPlanned(pitstopNumber, plannedLap)

		return result
	}

	planDriverSwap(lap := kUndefined, arguments*) {
		local knowledgeBase := this.KnowledgeBase
		local repairBodywork, repairSuspension, repairEngine, speaker

		static lastRequest := []

		this.clearContinuation()

		if (arguments.Length == 0) {
			if this.RemoteHandler {
				repairBodywork := knowledgeBase.getValue("Damage.Repair.Bodywork.Target", false)
				repairSuspension := knowledgeBase.getValue("Damage.Repair.Suspension.Target", false)
				repairEngine := knowledgeBase.getValue("Damage.Repair.Engine.Target", false)

				if (lap = kUndefined) {
					lastRequest := []

					this.RemoteHandler.planDriverSwap(false, repairBodywork, repairSuspension, repairEngine)
				}
				else {
					lastRequest := Array(lap)

					this.RemoteHandler.planDriverSwap(lap, repairBodywork, repairSuspension, repairEngine)
				}
			}
		}
		else if (lap == false) {
			if this.Speaker {
				speaker := this.getSpeaker()

				speaker.speakPhrase("NoDriverSwap")

				if this.supportsPitstop() {
					speaker.speakPhrase("ConfirmPlan", {forYou: speaker.Fragments["ForYou"]}, true)

					this.setContinuation(ObjBindMethod(this, "planPitstop", lastRequest*))
				}
			}

			lastRequest := []
		}
		else if (InStr(lap, "!") = 1) {
			lap := SubStr(lap, 2)

			lastRequest := concatenate(Array(lap), arguments)

			if this.RemoteHandler {
				repairBodywork := knowledgeBase.getValue("Damage.Repair.Bodywork.Target", false)
				repairSuspension := knowledgeBase.getValue("Damage.Repair.Suspension.Target", false)
				repairEngine := knowledgeBase.getValue("Damage.Repair.Engine.Target", false)

				this.RemoteHandler.planDriverSwap(lap, repairBodywork, repairSuspension, repairEngine)
			}
		}
		else {
			lastRequest := []

			this.planPitstop(lap, arguments*)
		}
	}

	preparePitstop(lap := false) {
		local speaker, result

		this.clearContinuation()

		if !this.supportsPitstop() {
			if this.Speaker
				this.getSpeaker().speakPhrase("NoPitstop")

			return false
		}

		if !this.hasPlannedPitstop() {
			if this.Speaker {
				speaker := this.getSpeaker()

				speaker.speakPhrase("MissingPlan")

				if this.supportsPitstop() {
					speaker.speakPhrase("ConfirmPlan", {forYou: ""}, true)

					this.setContinuation(ObjBindMethod(this, "planPitstop"))
				}
			}

			return false
		}
		else {
			if this.Speaker {
				speaker := this.getSpeaker()

				if lap
					speaker.speakPhrase("PrepareLap", {lap: lap})
				else
					speaker.speakPhrase("PrepareNow")
			}

			if !lap
				this.KnowledgeBase.addFact("Pitstop.Prepare", true)
			else
				this.KnowledgeBase.setFact("Pitstop.Planned.Lap", lap - 1)

			result := this.KnowledgeBase.produce()

			if this.Debug[kDebugKnowledgeBase]
				this.dumpKnowledgeBase(this.KnowledgeBase)

			return result
		}
	}

	pitstopOptionChanged(option, values*) {
		local knowledgeBase := this.KnowledgeBase
		local prssKey, incrKey, targetPressure, index, suffix

		if this.hasPreparedPitstop() {
			switch option, false {
				case "Refuel":
					knowledgeBase.setFact("Pitstop.Planned.Fuel", values[1])
				case "Tyre Compound":
					knowledgeBase.setFact("Pitstop.Planned.Tyre.Compound", values[1])
					knowledgeBase.setFact("Pitstop.Planned.Tyre.Compound.Color", values[2])
				case "Tyre Set":
					knowledgeBase.setFact("Pitstop.Planned.Tyre.Set", values[1])
				case "Tyre Pressures":
					for index, suffix in ["FL", "FR", "RL", "RR"] {
						prssKey := ("Pitstop.Planned.Tyre.Pressure." . suffix)
						incrKey := ("Pitstop.Planned.Tyre.Pressure." . suffix . ".Increment")

						targetPressure := values[index]

						knowledgeBase.setFact(incrKey, knowledgeBase.getValue(incrKey) + (targetPressure - knowledgeBase.getValue(prssKey)))
						knowledgeBase.setFact(prssKey, targetPressure)
					}
				case "Repair Suspension":
					knowledgeBase.setFact("Pitstop.Planned.Repair.Suspension", values[1])
				case "Repair Bodywork":
					knowledgeBase.setFact("Pitstop.Planned.Repair.Bodywork", values[1])
				case "Repair Engine":
					knowledgeBase.setFact("Pitstop.Planned.Repair.Engine", values[1])
			}

			if this.Speaker[false]
				this.getSpeaker().speakPhrase("ConfirmPlanUpdate")
		}
	}

	performPitstop(lapNumber := false, optionsFile := false) {
		this.iPitstopOptionsFile := optionsFile

		super.performPitstop(lapNumber, optionsFile)
	}

	executePitstop(lapNumber) {
		local knowledgeBase := this.KnowledgeBase
		local lastLap, flWear, frWear, rlWear, rrWear, driver, tyreCompound, tyreCompoundColor, tyreSet, result
		local lastPitstop, pitstop, options, compound, pressures, tyre

		if this.Speaker[false]
			this.getSpeaker().speakPhrase("Perform")

		lastPitstop := knowledgeBase.getValue("Pitstop.Last", 0)

		if this.RemoteHandler {
			lastLap := (lapNumber - 1)

			flWear := knowledgeBase.getValue("Lap." . lastLap . ".Tyre.Wear.FL", kUndefined)

			if (flWear != kUndefined) {
				frWear := knowledgeBase.getValue("Lap." . lastLap . ".Tyre.Wear.FR")
				rlWear := knowledgeBase.getValue("Lap." . lastLap . ".Tyre.Wear.RL")
				rrWear := knowledgeBase.getValue("Lap." . lastLap . ".Tyre.Wear.RR")

				driver := computeDriverName(knowledgeBase.getValue("Lap." . lastLap . ".Driver.Forname")
										  , knowledgeBase.getValue("Lap." . lastLap . ".Driver.Surname")
										  , knowledgeBase.getValue("Lap." . lastLap . ".Driver.Nickname"))

				tyreCompound := knowledgeBase.getValue("Lap." . lastLap . ".Tyre.Compound")
				tyreCompoundColor := knowledgeBase.getValue("Lap." . lastLap . ".Tyre.Compound.Color")
				tyreSet := knowledgeBase.getValue("Lap." . lastLap . ".Tyre.Set", false)
			}
		}

		result := super.executePitstop(lapNumber)

		pitstop := knowledgeBase.getValue("Pitstop.Last", 0)

		if this.iPitstopOptionsFile {
			if (knowledgeBase.getValue("Pitstop." . pitstop . ".Refuel", kUndefined) = kUndefined) {
				options := readMultiMap(this.iPitstopOptionsFile)

				knowledgeBase.setFact("Pitstop." . pitstop . ".Fuel", getMultiMapValue(options, "Pitstop", "Refuel", 0))

				compound := getMultiMapValue(options, "Pitstop", "Tyre.Compound", false)

				knowledgeBase.setFact("Pitstop." . pitstop . ".Tyre.Compound", compound)

				if compound {
					knowledgeBase.setFact("Pitstop." . pitstop . ".Tyre.Compound.Color", getMultiMapValue(options, "Pitstop", "Tyre.Compound.Color", false))
					knowledgeBase.setFact("Pitstop." . pitstop . ".Tyre.Set", getMultiMapValue(options, "Pitstop", "Tyre.Set", false))

					pressures := string2Values(";", getMultiMapValue(options, "Pitstop", "Tyre.Pressures", ""))

					for index, tyre in ["FL", "FR", "RL", "RR"]
						knowledgeBase.setFact("Pitstop." . pitstop . ".Tyre.Pressure." . tyre, pressures[index])
				}
				else
					knowledgeBase.setFact("Pitstop." . pitstop . ".Tyre.Compound.Color", false)

				knowledgeBase.setFact("Pitstop." . pitstop . ".Repair.Suspension", getMultiMapValue(options, "Pitstop", "Repair.Suspension", false))
				knowledgeBase.setFact("Pitstop." . pitstop . ".Repair.Bodywork", getMultiMapValue(options, "Pitstop", "Repair.Bodywork", false))
				knowledgeBase.setFact("Pitstop." . pitstop . ".Repair.Engine", getMultiMapValue(options, "Pitstop", "Repair.Engine", false))

				if this.Debug[kDebugKnowledgeBase]
					this.dumpKnowledgeBase(knowledgeBase)
			}

			deleteFile(this.iPitstopOptionsFile)

			this.iPitstopOptionsFile := false
		}

		if (this.RemoteHandler && (flWear != kUndefined) && (pitstop != lastPitstop))
			this.RemoteHandler.updateTyreSet(pitstop, driver, false
										   , tyreCompound, tyreCompoundColor, tyreSet
										   , flWear, frWear, rlWear, rrWear)

		return result
	}

	finishPitstop(lapNumber) {
		local result := super.finishPitstop(lapNumber)

		if this.RemoteHandler
			this.RemoteHandler.pitstopFinished(this.KnowledgeBase.getValue("Pitstop.Last", 0))

		return result
	}

	callPlanPitstop(lap := kUndefined, arguments*) {
		this.clearContinuation()

		if !this.supportsPitstop()
			this.getSpeaker().speakPhrase("NoPitstop")
		else if ((lap = kUndefined) && this.hasPlannedPitstop()) {
			this.getSpeaker().speakPhrase("ConfirmRePlan")

			this.setContinuation(ObjBindMethod(this, "invokePlanPitstop", false, lap, arguments*))
		}
		else
			this.invokePlanPitstop(true, lap, arguments*)
	}

	invokePlanPitstop(confirm, lap := kUndefined, arguments*) {
		this.clearContinuation()

		if (lap == kUndefined) {
			if confirm {
				this.getSpeaker().speakPhrase("Confirm")

				Task.yield()

				loop 10
					Sleep(500)
			}

			this.planPitstop()
		}
		else
			this.planPitstop(lap, arguments*)
	}

	callPlanDriverSwap(lap := kUndefined, arguments*) {
		local speaker := this.getSpeaker()

		this.clearContinuation()

		if !this.supportsPitstop()
			speaker.speakPhrase("NoPitstop")
		else if (!this.TeamSession || (lap == false)) {
			speaker.speakPhrase("NoDriverSwap")

			if this.supportsPitstop() {
				speaker.speakPhrase("ConfirmPlan", {forYou: speaker.Fragments["ForYou"]}, true)

				this.setContinuation(ObjBindMethod(this, "planPitstop", lap, arguments*))
			}
		}
		else if ((lap = kUndefined) && this.hasPlannedPitstop()) {
			speaker.speakPhrase("ConfirmRePlan")

			this.setContinuation(ObjBindMethod(this, "invokePlanDriverSwap", false, lap, arguments*))
		}
		else
			this.invokePlanDriverSwap(true, lap, arguments*)
	}

	invokePlanDriverSwap(confirm, lap := kUndefined, arguments*) {
		this.clearContinuation()

		if (lap == kUndefined) {
			if confirm {
				this.getSpeaker().speakPhrase("Confirm")

				Task.yield()

				loop 10
					Sleep(500)
			}

			this.planDriverSwap()
		}
		else
			this.planDriverSwap(lap, arguments*)
	}

	callPreparePitstop(lap := false) {
		this.clearContinuation()

		if !this.supportsPitstop()
			this.getSpeaker().speakPhrase("NoPitstop")
		else {
			this.getSpeaker().speakPhrase("Confirm")

			Task.yield()

			loop 10
				Sleep(500)

			if lap
				this.preparePitstop(lap)
			else
				this.preparePitstop()
		}
	}

	requestPitstopHistory(callbackCategory, callbackMessage, callbackPID, arguments*) {
		local knowledgeBase := this.KnowledgeBase
		local pitstopHistory := newMultiMap()
		local numPitstops := 0
		local numTyreSets := 1
		local lastLap := 0
		local fileName, pitstopLap, tyreCompound, tyreCompoundColor, tyreSet

		setMultiMapValue(pitstopHistory, "TyreSets", "1.Compound"
					   , knowledgeBase.getValue("Session.Setup.Tyre.Compound"))
		setMultiMapValue(pitstopHistory, "TyreSets", "1.CompoundColor"
					   , knowledgeBase.getValue("Session.Setup.Tyre.Compound.Color"))
		setMultiMapValue(pitstopHistory, "TyreSets", "1.Set"
					   , knowledgeBase.getValue("Session.Setup.Tyre.Set"))

		loop knowledgeBase.getValue("Pitstop.Last") {
			numPitstops += 1

			pitstopLap := knowledgeBase.getValue("Pitstop." . A_Index . ".Lap")

			setMultiMapValue(pitstopHistory, "Pitstops", A_Index . ".Lap", pitstopLap)
			setMultiMapValue(pitstopHistory, "Pitstops", A_Index . ".Refuel"
						   , knowledgeBase.getValue("Pitstop." . A_Index . ".Fuel"))

			tyreCompound := knowledgeBase.getValue("Pitstop." . A_Index . ".Tyre.Compound")
			tyreCompoundColor := knowledgeBase.getValue("Pitstop." . A_Index . ".Tyre.Compound.Color")
			tyreSet := knowledgeBase.getValue("Pitstop." . A_Index . ".Tyre.Set")

			if tyreCompound {
				setMultiMapValue(pitstopHistory, "TyreSets", numTyreSets . ".Laps", pitstopLap - lastLap)

				numTyreSets += 1
				lastLap := pitstopLap

				setMultiMapValue(pitstopHistory, "TyreSets", numTyreSets . ".Compound", tyreCompound)
				setMultiMapValue(pitstopHistory, "TyreSets", numTyreSets . ".CompoundColor", tyreCompoundColor)
				setMultiMapValue(pitstopHistory, "TyreSets", numTyreSets . ".Set", tyreSet)

				setMultiMapValue(pitstopHistory, "Pitstops", A_Index . ".TyreCompound", tyreCompound)
				setMultiMapValue(pitstopHistory, "Pitstops", A_Index . ".TyreCompoundColor", tyreCompoundColor)
				setMultiMapValue(pitstopHistory, "Pitstops", A_Index . ".TyreSet", tyreSet)
				setMultiMapValue(pitstopHistory, "Pitstops", A_Index . ".TyreChange", true)
			}
			else
				setMultiMapValue(pitstopHistory, "Pitstops", A_Index . ".TyreChange", false)

			setMultiMapValue(pitstopHistory, "Pitstops", A_Index . ".RepairBodywork"
						   , knowledgeBase.getValue("Pitstop." . A_Index . ".Repair.Bodywork"))
			setMultiMapValue(pitstopHistory, "Pitstops", A_Index . ".RepairSuspension"
						   , knowledgeBase.getValue("Pitstop." . A_Index . ".Repair.Suspension"))
			setMultiMapValue(pitstopHistory, "Pitstops", A_Index . ".RepairEngine"
						   , knowledgeBase.getValue("Pitstop." . A_Index . ".Repair.Engine", false))
		}

		setMultiMapValue(pitstopHistory, "TyreSets", numTyreSets . ".Laps", knowledgeBase.getValue("Lap") - lastLap)

		setMultiMapValue(pitstopHistory, "Pitstops", "Count", numPitstops)
		setMultiMapValue(pitstopHistory, "TyreSets", "Count", numTyreSets)

		fileName := temporaryFileName("Pitstop", "history")

		writeMultiMap(filename, pitstopHistory)

		messageSend(kFileMessage, callbackCategory, callbackMessage . ":" . values2String(";", fileName, arguments*), callbackPID)
	}

	lowFuelWarning(remainingLaps) {
		local knowledgeBase := this.KnowledgeBase
		local speaker

		if (this.hasEnoughData(false) && this.Speaker[false] && this.Announcements["FuelWarning"])
			if (!knowledgeBase.getValue("InPitlane", false) && !knowledgeBase.getValue("InPit", false)) {
				speaker := this.getSpeaker()

				speaker.beginTalk()

				try {
					speaker.speakPhrase((remainingLaps <= 2) ? "VeryLowFuel" : "LowFuel", {laps: remainingLaps})

					if this.supportsPitstop() {
						if this.hasPreparedPitstop()
							speaker.speakPhrase((remainingLaps <= 2) ? "LowComeIn" : "ComeIn")
						else if !this.hasPlannedPitstop() {
							speaker.speakPhrase("ConfirmPlan", {forYou: ""}, true)

							this.setContinuation(ObjBindMethod(this, "planPitstop", "Now"))
						}
						else {
							speaker.speakPhrase("ConfirmPrepare", false, true)

							this.setContinuation(VoiceManager.ReplyContinuation(this, ObjBindMethod(this, "preparePitstop"), false, "Okay"))
						}
					}
				}
				finally {
					speaker.endTalk()
				}
			}
	}

	damageWarning(newSuspensionDamage, newBodyworkDamage, newEngineDamage) {
		local knowledgeBase := this.KnowledgeBase
		local speaker, phrase

		if ((this.hasEnoughData(false) || (knowledgeBase.getValue("Lap", 0) < this.LearningLaps)) && this.Speaker[false] && this.Announcements["DamageReporting"])
			if (!knowledgeBase.getValue("InPitlane", false) && !knowledgeBase.getValue("InPit", false)) {
				speaker := this.getSpeaker()
				phrase := false

				if newEngineDamage {
					if (newSuspensionDamage || newBodyworkDamage)
						phrase := "AllDamage"
					else
						phrase := "EngineDamage"
				}
				else if (newSuspensionDamage && newBodyworkDamage)
					phrase := "BothDamage"
				else if newSuspensionDamage
					phrase := "SuspensionDamage"
				else if newBodyworkDamage
					phrase := "BodyworkDamage"

				speaker.beginTalk()

				try {
					speaker.speakPhrase(phrase)

					if (knowledgeBase.getValue("Lap.Remaining.Session", knowledgeBase.getValue("Lap.Remaining", 0)) > 4)
						speaker.speakPhrase("DamageAnalysis")
					else
						speaker.speakPhrase("NoDamageAnalysis")
				}
				finally {
					speaker.endTalk()
				}
			}
	}

	reportDamageAnalysis(repair, stintLaps, delta) {
		local knowledgeBase := this.KnowledgeBase
		local speaker

		if (this.hasEnoughData(false) && knowledgeBase.getValue("Lap.Remaining.Session", knowledgeBase.getValue("Lap.Remaining", 0)) > 3)
			if (this.Speaker[false] && this.Announcements["DamageAnalysis"])
				if (!knowledgeBase.getValue("InPitlane", false) && !knowledgeBase.getValue("InPit", false)) {
					speaker := this.getSpeaker()

					stintLaps := Round(stintLaps)

					if repair {
						speaker.beginTalk()

						try {
							speaker.speakPhrase("RepairPitstop", {laps: stintLaps, delta: speaker.number2Speech(delta, 1)})

							if this.supportsPitstop() {
								speaker.speakPhrase("ConfirmPlan", {forYou: ""}, true)

								this.setContinuation(ObjBindMethod(this, "planPitstop", "Now"))
							}
						}
						finally {
							speaker.endTalk()
						}
					}
					else if (repair == false)
						speaker.speakPhrase((Abs(delta) < 0.2) ? "NoTimeLost" : "NoRepairPitstop", {laps: stintLaps, delta: speaker.number2Speech(delta, 1)})
				}
	}

	pressureLossWarning(tyre, lostPressure) {
		local knowledgeBase := this.KnowledgeBase
		local speaker, fragments

		static tyreLookup := CaseInsenseMap("FL", "FrontLeft", "FR", "FrontRight", "RL", "RearLeft", "RR", "RearRight")

		if (this.hasEnoughData(false) && (this.Session == kSessionRace))
			if (!knowledgeBase.getValue("InPitlane", false) && !knowledgeBase.getValue("InPit", false))
				if (this.Speaker[false] && this.Announcements["PressureReporting"]) {
					speaker := this.getSpeaker()
					fragments := speaker.Fragments

					speaker.speakPhrase("PressureLoss", {tyre: fragments[tyreLookup[tyre]]
													   , lost: speaker.number2Speech(convertUnit("Pressure", lostPressure))
													   , unit: fragments[getUnit("Pressure")]})
				}
	}

	weatherChangeNotification(change, minutes) {
		local knowledgeBase := this.KnowledgeBase
		local speaker

		if !ProcessExist("Race Strategist.exe")
			if (this.hasEnoughData(false) && this.Speaker[false] && (this.Session == kSessionRace) && this.Announcements["WeatherUpdate"]) {
				speaker := this.getSpeaker()

				speaker.speakPhrase(change ? "WeatherChange" : "WeatherNoChange", {minutes: minutes})
			}
	}

	weatherTyreChangeRecommendation(minutes, recommendedCompound) {
		local knowledgeBase := this.KnowledgeBase
		local speaker, fragments

		if (!ProcessExist("Race Strategist.exe") && (knowledgeBase.getValue("Lap.Remaining.Session", knowledgeBase.getValue("Lap.Remaining", 0)) > 3))
			if (this.hasEnoughData(false) && this.Speaker[false] && (this.Session == kSessionRace)) {
				speaker := this.getSpeaker()
				fragments := speaker.Fragments

				speaker.beginTalk()

				try {
					speaker.speakPhrase(((recommendedCompound = "Wet") || (recommendedCompound = "Intermediate")) ? "WeatherRainChange"
																												  : "WeatherDryChange"
									  , {minutes: minutes, compound: fragments[recommendedCompound . "Tyre"]})

					if this.supportsPitstop() {
						speaker.speakPhrase("ConfirmPlan", {forYou: ""}, true)

						this.setContinuation(ObjBindMethod(this, "planPitstop", "Now"))
					}
				}
				finally {
					speaker.endTalk()
				}
			}
	}

	startPitstopSetup(pitstopNumber) {
		if this.RemoteHandler
			this.RemoteHandler.startPitstopSetup(pitstopNumber)
	}

	finishPitstopSetup(pitstopNumber) {
		if this.RemoteHandler {
			this.RemoteHandler.finishPitstopSetup(pitstopNumber)

			this.RemoteHandler.pitstopPrepared(pitstopNumber)

			if this.Speaker
				this.getSpeaker().speakPhrase("CallToPit")
		}
	}

	setPitstopRefuelAmount(pitstopNumber, fuel) {
		if this.RemoteHandler
			this.RemoteHandler.setPitstopRefuelAmount(pitstopNumber, fuel)
	}

	setPitstopTyreSet(pitstopNumber, compound, compoundColor, set) {
		if this.RemoteHandler
			this.RemoteHandler.setPitstopTyreSet(pitstopNumber, compound, compoundColor, set)
	}

	setPitstopTyrePressures(pitstopNumber, pressureFL, pressureFR, pressureRL, pressureRR) {
		if this.RemoteHandler
			this.RemoteHandler.setPitstopTyrePressures(pitstopNumber, Round(pressureFL, 1), Round(pressureFR, 1), Round(pressureRL, 1), Round(pressureRR, 1))
	}

	requestPitstopRepairs(pitstopNumber, repairSuspension, repairBodywork, repairEngine) {
		if this.RemoteHandler
			this.RemoteHandler.requestPitstopRepairs(pitstopNumber, repairSuspension, repairBodywork, repairEngine)
	}

	requestPitstopDriver(pitstopNumber, driver) {
		if (this.RemoteHandler && driver)
			this.RemoteHandler.requestPitstopDriver(pitstopNumber, driver)
	}

	getTyrePressures(weather, airTemperature, trackTemperature, &compound, &compoundColor, &pressures, &certainty) {
		local knowledgeBase := this.KnowledgeBase

		return this.TyresDatabase.getTyreSetup(knowledgeBase.getValue("Session.Simulator")
											 , knowledgeBase.getValue("Session.Car"), knowledgeBase.getValue("Session.Track")
											 , weather, airTemperature, trackTemperature, &compound, &compoundColor, &pressures, &certainty, true)
	}
}

;;;-------------------------------------------------------------------------;;;
;;;                   Private Function Declaration Section                  ;;;
;;;-------------------------------------------------------------------------;;;

lowFuelWarning(context, remainingLaps) {
	context.KnowledgeBase.RaceAssistant.lowFuelWarning(Round(remainingLaps))

	return true
}

damageWarning(context, newSuspensionDamage, newBodyworkDamage, newEngineDamage) {
	context.KnowledgeBase.RaceAssistant.clearContinuation()

	context.KnowledgeBase.RaceAssistant.damageWarning(newSuspensionDamage, newBodyworkDamage, newEngineDamage)

	return true
}

reportDamageAnalysis(context, repair, stintLaps, delta) {
	context.KnowledgeBase.RaceAssistant.clearContinuation()

	context.KnowledgeBase.RaceAssistant.reportDamageAnalysis(repair, stintLaps, delta)

	return true
}

pressureLossWarning(context, tyre, lostPressure) {
	context.KnowledgeBase.RaceAssistant.clearContinuation()

	context.KnowledgeBase.RaceAssistant.pressureLossWarning(tyre, lostPressure)

	return true
}

weatherChangeNotification(context, change, minutes) {
	context.KnowledgeBase.RaceAssistant.clearContinuation()

	context.KnowledgeBase.RaceAssistant.weatherChangeNotification(change, minutes)

	return true
}

weatherTyreChangeRecommendation(context, minutes, recommendedCompound) {
	context.KnowledgeBase.RaceAssistant.clearContinuation()

	context.KnowledgeBase.RaceAssistant.weatherTyreChangeRecommendation(minutes, recommendedCompound)

	return true
}

startPitstopSetup(context, pitstopNumber) {
	context.KnowledgeBase.RaceAssistant.startPitstopSetup(pitstopNumber)

	return true
}

finishPitstopSetup(context, pitstopNumber) {
	context.KnowledgeBase.RaceAssistant.finishPitstopSetup(pitstopNumber)

	return true
}

setPitstopRefuelAmount(context, pitstopNumber, fuel) {
	context.KnowledgeBase.RaceAssistant.setPitstopRefuelAmount(pitstopNumber, fuel)

	return true
}

setPitstopTyreSet(context, pitstopNumber, compound, compoundColor, set) {
	context.KnowledgeBase.RaceAssistant.setPitstopTyreSet(pitstopNumber, compound, compoundColor, set)

	return true
}

setPitstopTyrePressures(context, pitstopNumber, pressureFL, pressureFR, pressureRL, pressureRR) {
	context.KnowledgeBase.RaceAssistant.setPitstopTyrePressures(pitstopNumber, pressureFL, pressureFR, pressureRL, pressureRR)

	return true
}

requestPitstopRepairs(context, pitstopNumber, repairSuspension, repairBodywork, repairEngine) {
	context.KnowledgeBase.RaceAssistant.requestPitstopRepairs(pitstopNumber, repairSuspension, repairBodywork, repairEngine)

	return true
}

requestPitstopDriver(context, pitstopNumber, driver) {
	context.KnowledgeBase.RaceAssistant.requestPitstopDriver(pitstopNumber, driver)

	return true
}

setupTyrePressures(context, weather, airTemperature, trackTemperature, tyreCompound, tyreCompoundColor) {
	local knowledgeBase := context.KnowledgeBase
	local pressures := false
	local certainty := 1.0

	if !inList(kTyreCompounds, compound(tyreCompound, tyreCompoundColor)) {
		tyreCompound := false
		tyreCompoundColor := false
	}

	airTemperature := Round(airTemperature)
	trackTemperature := Round(trackTemperature)

	if context.KnowledgeBase.RaceAssistant.getTyrePressures(weather, airTemperature, trackTemperature, &tyreCompound, &tyreCompoundColor, &pressures, &certainty) {
		knowledgeBase.setFact("Tyre.Setup.Certainty", certainty)
		knowledgeBase.setFact("Tyre.Setup.Compound", tyreCompound)
		knowledgeBase.setFact("Tyre.Setup.Compound.Color", tyreCompoundColor)
		knowledgeBase.setFact("Tyre.Setup.Weather", weather)
		knowledgeBase.setFact("Tyre.Setup.Temperature.Air", airTemperature)
		knowledgeBase.setFact("Tyre.Setup.Temperature.Track", trackTemperature)
		knowledgeBase.setFact("Tyre.Setup.Pressure.FL", pressures[1])
		knowledgeBase.setFact("Tyre.Setup.Pressure.FR", pressures[2])
		knowledgeBase.setFact("Tyre.Setup.Pressure.RL", pressures[3])
		knowledgeBase.setFact("Tyre.Setup.Pressure.RR", pressures[4])

		return true
	}
	else
		return false
}