﻿;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   Modular Simulator Controller System - Race Center Tool                ;;;
;;;                                                                         ;;;
;;;   Author:     Oliver Juwig (TheBigO)                                    ;;;
;;;   License:    (2023) Creative Commons - BY-NC-SA                        ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;-------------------------------------------------------------------------;;;
;;;                       Global Declaration Section                        ;;;
;;;-------------------------------------------------------------------------;;;

;@SC-IF %configuration% == Development
#Include "..\Framework\Development.ahk"
;@SC-EndIF

;@SC-If %configuration% == Production
;@SC #Include "..\Framework\Production.ahk"
;@SC-EndIf

; REMOVED: #MaxMem 128

;@Ahk2Exe-SetMainIcon ..\..\Resources\Icons\Console.ico
;@Ahk2Exe-ExeName Race Center.exe


;;;-------------------------------------------------------------------------;;;
;;;                         Global Include Section                          ;;;
;;;-------------------------------------------------------------------------;;;

#Include "..\Framework\Application.ahk"


;;;-------------------------------------------------------------------------;;;
;;;                         Local Include Section                           ;;;
;;;-------------------------------------------------------------------------;;;

#Include "..\Libraries\HTMLViewer.ahk"
#Include "..\Libraries\Messages.ahk"
#Include "..\Libraries\Math.ahk"
#Include "..\Libraries\CLR.ahk"
#Include "..\Libraries\GDIP.ahk"
#Include "..\Database\Libraries\SessionDatabase.ahk"
#Include "..\Database\Libraries\SettingsDatabase.ahk"
#Include "..\Database\Libraries\TyresDatabase.ahk"
#Include "..\Database\Libraries\TelemetryDatabase.ahk"
#Include "Libraries\RaceReportViewer.ahk"
#Include "Libraries\Strategy.ahk"
#Include "Libraries\StrategyViewer.ahk"


;;;-------------------------------------------------------------------------;;;
;;;                   Private Constant Declaration Section                  ;;;
;;;-------------------------------------------------------------------------;;;

global kClose := "Close"
global kConnect := "Connect"
global kEvent := "Event"

global kSessionReports := concatenate(["Track"], kRaceReports, ["Pressures", "Brakes", "Temperatures", "Free"])
global kDetailReports := ["Plan", "Stint", "Lap", "Session", "Drivers", "Strategy", "Pitstop", "Pitstops", "Setups"]

global kSessionDataSchemas := CaseInsenseMap("Stint.Data", ["Nr", "Lap", "Driver.Forname", "Driver.Surname", "Driver.Nickname"
														  , "Weather", "Compound", "Lap.Time.Average", "Lap.Time.Best", "Fuel.Consumption", "Accidents"
														  , "Position.Start", "Position.End", "Time.Start", "Driver.ID", "Penalties", "Time.End"]
										   , "Driver.Data", ["Forname", "Surname", "Nickname", "Nr", "ID"]
										   , "Lap.Data", ["Stint", "Nr", "Lap", "Lap.Time", "Position", "Grip", "Map", "TC", "ABS"
														, "Weather", "Temperature.Air", "Temperature.Track"
														, "Fuel.Remaining", "Fuel.Consumption", "Damage", "Accident"
														, "Tyre.Laps", "Tyre.Compound", "Tyre.Compound.Color"
														, "Tyre.Pressure.Cold.Average", "Tyre.Pressure.Cold.Front.Average", "Tyre.Pressure.Cold.Rear.Average"
														, "Tyre.Pressure.Cold.Front.Left", "Tyre.Pressure.Cold.Front.Right"
														, "Tyre.Pressure.Cold.Rear.Left", "Tyre.Pressure.Cold.Rear.Right"
														, "Tyre.Pressure.Hot.Average", "Tyre.Pressure.Hot.Front.Average", "Tyre.Pressure.Hot.Rear.Average"
														, "Tyre.Pressure.Hot.Front.Left", "Tyre.Pressure.Hot.Front.Right"
														, "Tyre.Pressure.Hot.Rear.Left", "Tyre.Pressure.Hot.Rear.Right"
														, "Tyre.Temperature.Average", "Tyre.Temperature.Front.Average", "Tyre.Temperature.Rear.Average"
														, "Tyre.Temperature.Front.Left", "Tyre.Temperature.Front.Right"
														, "Tyre.Temperature.Rear.Left", "Tyre.Temperature.Rear.Right"
														, "Tyre.Wear.Average", "Tyre.Wear.Front.Average", "Tyre.Wear.Rear.Average"
														, "Tyre.Wear.Front.Left", "Tyre.Wear.Front.Right"
														, "Tyre.Wear.Rear.Left", "Tyre.Wear.Rear.Right"
														, "Brake.Temperature.Front.Left", "Brake.Temperature.Front.Right"
														, "Brake.Temperature.Rear.Left", "Brake.Temperature.Rear.Right"
														, "Brake.Wear.Average", "Brake.Wear.Front.Average", "Brake.Wear.Rear.Average"
														, "Brake.Wear.Front.Left", "Brake.Wear.Front.Right"
														, "Brake.Wear.Rear.Left", "Brake.Wear.Rear.Right"
														, "EngineDamage"
														, "Brake.Temperature.Average"
														, "Brake.Temperature.Front.Average", "Brake.Temperature.Rear.Average"
														, "Tyre.Pressure.Loss.Front.Left", "Tyre.Pressure.Loss.Front.Right"
														, "Tyre.Pressure.Loss.Rear.Left", "Tyre.Pressure.Loss.Rear.Right"
														, "Penalty", "Time.Stint.Remaining", "Time.Driver.Remaining"]
										   , "Pitstop.Data", ["Lap", "Fuel", "Tyre.Compound", "Tyre.Compound.Color", "Tyre.Set"
															, "Tyre.Pressure.Cold.Front.Left", "Tyre.Pressure.Cold.Front.Right"
															, "Tyre.Pressure.Cold.Rear.Left", "Tyre.Pressure.Cold.Rear.Right"
															, "Repair.Bodywork", "Repair.Suspension", "Repair.Engine"
															, "Driver.Current", "Driver.Next", "Status", "Stint"]
										   , "Pitstop.Service.Data", ["Pitstop", "Lap", "Time", "Driver.Previous", "Driver.Next", "Fuel"
																	, "Tyre.Compound", "Tyre.Compound.Color", "Tyre.Set", "Tyre.Pressures"
																	, "Bodywork.Repair", "Suspension.Repair", "Engine.Repair"]
										   , "Pitstop.Tyre.Data", ["Pitstop", "Driver", "Laps", "Compound", "Compound.Color", "Set"
																 , "Tyre", "Tread", "Wear", "Grain", "Blister", "FlatSpot"]
										   , "Delta.Data", ["Lap", "Car", "Type", "Delta", "Distance", "ID"]
										   , "Standings.Data", ["Lap", "Car", "Driver", "Position", "Time", "Laps", "Delta", "ID", "Category"]
										   , "Plan.Data", ["Stint", "Driver", "Time.Planned", "Time.Actual", "Lap.Planned", "Lap.Actual"
														 , "Fuel.Amount", "Tyre.Change"]
										   , "Setups.Data", ["Driver", "Weather", "Temperature.Air", "Temperature.Track"
														   , "Tyre.Compound", "Tyre.Compound.Color"
														   , "Tyre.Pressure.Front.Left", "Tyre.Pressure.Front.Right"
														   , "Tyre.Pressure.Rear.Left", "Tyre.Pressure.Rear.Right"
														   , "Notes"])

global kRCTyresSchemas := kTyresSchemas.Clone()

kRCTyresSchemas["Tyres.Pressures"] := concatenate(kRCTyresSchemas["Tyres.Pressures"].Clone()
												, ["Tyre.Pressure.Loss.Front.Left", "Tyre.Pressure.Loss.Front.Right"
												, "Tyre.Pressure.Loss.Rear.Left", "Tyre.Pressure.Loss.Rear.Right"])


;;;-------------------------------------------------------------------------;;;
;;;                          Public Classes Section                         ;;;
;;;-------------------------------------------------------------------------;;;

;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;
;;; Class                        RaceCenterTask                             ;;;
;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;

class RaceCenterTask extends Task {
	Window {
		Get {
			return RaceCenter.Instance.Window
		}
	}

	run() {
		local rCenter := RaceCenter.Instance

		if rCenter.startWorking() {
			try {
				super.run()

				return false
			}
			finally {
				rCenter.finishWorking()
			}
		}
		else
			return this
	}
}

;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;
;;; Class                        RaceCenterSimulationTask                   ;;;
;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;

class RaceCenterSimulationTask extends RaceCenterTask {
	iSimulation := false

	Simulation {
		Get {
			return this.iSimulation
		}

		Set {
			return (this.iSimulation := value)
		}
	}
}

;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;
;;; Class                       SyncSessionTask                             ;;;
;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;

class SyncSessionTask extends RaceCenterTask {
	__New() {
		super.__New(ObjBindMethod(RaceCenter.Instance, "syncSession"), 10000)

		this.Runnable := false
	}

	run() {
		super.run()

		this.Sleep := (RaceCenter.Instance.Synchronize ? (RaceCenter.Instance.Synchronize * 1000) : 10000)

		return this
	}

	resume() {
		super.resume()

		this.NextExecution := A_TickCount
	}
}

;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;
;;; Class                          RaceCenter                               ;;;
;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;

class RaceCenter extends ConfigurationItem {
	static kInvalidToken := "__Invalid__"

	iWindow := false

	iWorking := 0
	iSyncTask := false

	iSessionDirectory := false
	iRaceSettings := false

	iConnector := false
	iConnection := false

	iServerURL := ""
	iServerToken := RaceCenter.kInvalidToken

	iTeams := CaseInsenseMap()
	iSessions := CaseInsenseMap()
	iSessionDrivers := CaseInsenseMap()
	iTeamDrivers := []

	iTeamIdentifier := false
	iTeamName := false

	iSessionIdentifier := false
	iSessionName := false

	iSynchronize := 10

	iSessionLoaded := false
	iSessionFinished := false

	iSetupsVersion := false
	iTeamDriversVersion := false

	iPlanVersion := false
	iDate := false
	iTime := false

	iSimulator := false
	iCar := false
	iTrack := false
	iWeather := false
	iWeather10Min := false
	iWeather30Min := false
	iAirTemperature := false
	iTrackTemperature := false

	iTyreCompounds := [normalizeCompound("Dry")]

	iTyreCompound := false
	iTyreCompoundColor := false

	iStrategy := false

	iUseSessionData := true
	iUseTelemetryDatabase := false
	iUseCurrentMap := true
	iUseTraffic := false

	iDrivers := []
	iStints := CaseInsenseWeakMap()
	iLaps := CaseInsenseWeakMap()

	iPitstops := CaseInsenseMap()
	iLastPitstopUpdate := false

	iCurrentStint := false
	iLastLap := false

	iSetupsListView := false
	iPlanListView := false
	iStintsListView := false
	iLapsListView := false
	iPitstopsListView := false

	iSelectedSetup := false
	iSelectedPlanStint := false

	iTyrePressureMode := "Reference"
	iCorrectPressureLoss := false

	iSessionStore := false
	iTelemetryDatabase := false
	iPressuresDatabase := false

	iSimulationTelemetryDatabase := false

	iReportsListView := false
	iWaitViewer := false
	iChartViewer := false
	iReportViewer := false
	iDetailsViewer := false
	iSelectedReport := false
	iSelectedChartType := false

	iAvailableDrivers := []
	iSelectedDrivers := false

	iSelectedDetailReport := false
	iSelectedDetailHTML := false

	iStrategyViewer := false

	iTasks := []

	iPressuresRequest := false

	class RaceCenterResizer extends Window.Resizer {
		iRedraw := false

		__New(arguments*) {
			super.__New(arguments*)

			Task.startTask(ObjBindMethod(this, "RedrawHTMLViwer"), 500, kLowPriority)
		}

		Resize(deltaWidth, deltaHeight) {
			this.iRedraw := true
		}

		RedrawHTMLViwer() {
			if this.iRedraw {
				local center := RaceCenter.Instance
				local ignore, button

				for ignore, button in ["LButton", "MButton", "RButton"]
					if GetKeyState(button, "P")
						return Task.CurrentTask

				this.iRedraw := false

				center.ChartViewer.Resized()
				center.DetailsViewer.Resized()

				center.pushTask(ObjBindMethod(RaceCenter.Instance, "updateReports", true))
			}

			return Task.CurrentTask
		}
	}

	class RaceCenterTelemetryDatabase extends TelemetryDatabase {
		iRaceCenter := false
		iTelemetryDatabase := false

		class SessionTelemetryDatabase extends RaceCenter.RaceCenterTelemetryDatabase {
			Drivers {
				Get {
					return this.RaceCenter.SelectedDrivers
				}
			}
		}

		class SimulationTelemetryDatabase extends RaceCenter.RaceCenterTelemetryDatabase {
		}

		RaceCenter {
			Get {
				return this.iRaceCenter
			}
		}

		TelemetryDatabase {
			Get {
				return this.iTelemetryDatabase
			}
		}

		__New(raceCenter, simulator := false, car := false, track := false) {
			this.iRaceCenter := raceCenter

			super.__New()

			this.Shared := false

			this.setDatabase(Database(raceCenter.SessionDirectory, kTelemetrySchemas))

			if simulator
				this.iTelemetryDatabase := TelemetryDatabase(simulator, car, track)
		}

		setDrivers(drivers) {
			super.setDrivers(drivers)

			if this.TelemetryDatabase
				this.TelemetryDatabase.setDrivers(drivers)
		}

		getMapData(weather, tyreCompound, tyreCompoundColor) {
			local entries := []
			local newEntries, ignore, entry, ignore, entry, found, candidate, lastLap, result

			if this.RaceCenter.UseSessionData
				for ignore, entry in super.getMapData(weather, tyreCompound, tyreCompoundColor)
					if ((entry["Fuel.Consumption"] > 0) && (entry["Lap.Time"] > 0))
						entries.Push(entry)

			if (this.RaceCenter.UseTelemetryDatabase && this.TelemetryDatabase) {
				newEntries := []

				for ignore, entry in this.TelemetryDatabase.getMapData(weather, tyreCompound, tyreCompoundColor) {
					if ((entry["Fuel.Consumption"] > 0) && (entry["Lap.Time"] > 0)) {
						found := false

						for ignore, candidate in entries
							if ((candidate["Map"] = entry["Map"]) && (candidate["Lap.Time"] = entry["Lap.Time"])
																  && (candidate["Fuel.Consumption"] = entry["Fuel.Consumption"])) {
								found := true

								break
							}

						if !found
							newEntries.Push(entry)
					}
				}

				for ignore, entry in newEntries
					entries.Push(entry)
			}

			if this.RaceCenter.UseCurrentMap {
				lastLap := this.iRaceCenter.LastLap

				if lastLap {
					result := []

					for ignore, entry in entries
						if (entry["Map"] = lastLap.Map)
							result.Push(entry)

					return result
				}
			}

			return entries
		}

		getTyreData(weather, tyreCompound, tyreCompoundColor) {
			local entries := []
			local newEntries, ignore, entry, found, candidate

			if this.RaceCenter.UseSessionData
				for ignore, entry in super.getTyreData(weather, tyreCompound, tyreCompoundColor)
					if (entry["Lap.Time"] > 0)
						entries.Push(entry)

			if (this.RaceCenter.UseTelemetryDatabase && this.TelemetryDatabase) {
				newEntries := []

				for ignore, entry in this.TelemetryDatabase.getTyreData(weather, tyreCompound, tyreCompoundColor) {
					if (entry["Lap.Time"] > 0) {
						found := false

						for ignore, candidate in entries
							if ((candidate["Tyre.Laps"] = entry["Tyre.Laps"]) && (candidate["Lap.Time"] = entry["Lap.Time"])) {
								found := true

								break
							}

						if !found
							newEntries.Push(entry)
					}
				}

				for ignore, entry in newEntries
					entries.Push(entry)
			}

			return entries
		}

		getMapLapTimes(weather, tyreCompound, tyreCompoundColor) {
			local entries := []
			local newEntries, ignore, entry, found, candidate, lastLap, result

			if this.RaceCenter.UseSessionData
				for ignore, entry in super.getMapLapTimes(weather, tyreCompound, tyreCompoundColor)
					if (entry["Lap.Time"] > 0)
						entries.Push(entry)

			if (this.RaceCenter.UseTelemetryDatabase && this.TelemetryDatabase) {
				newEntries := []

				for ignore, entry in this.TelemetryDatabase.getMapLapTimes(weather, tyreCompound, tyreCompoundColor) {
					if (entry["Lap.Time"] > 0) {
						found := false

						for ignore, candidate in entries
							if ((candidate["Map"] = entry["Map"]) && (candidate["Fuel.Remaining"] = entry["Fuel.Remaining"])
																  && (candidate["Lap.Time"] = entry["Lap.Time"])) {
								found := true

								break
							}

						if !found
							newEntries.Push(entry)
					}
				}

				for ignore, entry in newEntries
					entries.Push(entry)
			}

			if this.iRaceCenter.UseCurrentMap {
				lastLap := this.iRaceCenter.LastLap

				if lastLap {
					result := []

					for ignore, entry in entries
						if (entry["Map"] = lastLap.Map)
							result.Push(entry)

					return result
				}
			}

			return entries
		}

		getTyreLapTimes(weather, tyreCompound, tyreCompoundColor) {
			local entries := []
			local newEntries, ignore, entry, found, candidate

			if this.RaceCenter.UseSessionData
				for ignore, entry in super.getTyreLapTimes(weather, tyreCompound, tyreCompoundColor)
					if (entry["Lap.Time"] > 0)
						entries.Push(entry)

			if (this.RaceCenter.UseTelemetryDatabase && this.TelemetryDatabase) {
				newEntries := []

				for ignore, entry in this.TelemetryDatabase.getTyreLapTimes(weather, tyreCompound, tyreCompoundColor) {
					if (entry["Lap.Time"] > 0) {
						found := false

						for ignore, candidate in entries
							if ((candidate["Tyre.Laps"] = entry["Tyre.Laps"]) && (candidate["Lap.Time"] = entry["Lap.Time"])) {
								found := true

								break
							}

						if !found
							newEntries.Push(entry)
					}
				}

				for ignore, entry in newEntries
					entries.Push(entry)
			}

			return entries
		}
	}

	class SessionPressuresDatabase {
		iDatabase := false

		Database {
			Get {
				return this.iDatabase
			}
		}

		__New(rCenter) {
			this.iDatabase := Database(rCenter.SessionDirectory, kRCTyresSchemas)
		}

		updatePressures(weather, airTemperature, trackTemperature, tyreCompound, tyreCompoundColor, coldPressures, hotPressures, pressuresLosses, driver, flush) {
			local tyres, types, typeIndex, tPressures, tyreIndex, pressure

			if (!tyreCompoundColor || (tyreCompoundColor = ""))
				tyreCompoundColor := "Black"

			this.Database.add("Tyres.Pressures",
							  Database.Row("Weather", weather, "Temperature.Air", airTemperature, "Temperature.Track", trackTemperature
										 , "Compound", tyreCompound, "Compound.Color", tyreCompoundColor, "Driver", driver
										 , "Tyre.Pressure.Cold.Front.Left", null(coldPressures[1])
										 , "Tyre.Pressure.Cold.Front.Right", null(coldPressures[2])
										 , "Tyre.Pressure.Cold.Rear.Left", null(coldPressures[3])
										 , "Tyre.Pressure.Cold.Rear.Right", null(coldPressures[4])
										 , "Tyre.Pressure.Hot.Front.Left", null(hotPressures[1])
										 , "Tyre.Pressure.Hot.Front.Right", null(hotPressures[2])
										 , "Tyre.Pressure.Hot.Rear.Left", null(hotPressures[3])
										 , "Tyre.Pressure.Hot.Rear.Right", null(hotPressures[4])
										 , "Tyre.Pressure.Loss.Front.Left", null(pressuresLosses[1])
										 , "Tyre.Pressure.Loss.Front.Right", null(pressuresLosses[2])
										 , "Tyre.Pressure.Loss.Rear.Left", null(pressuresLosses[3])
										 , "Tyre.Pressure.Loss.Rear.Right", null(pressuresLosses[4]))
							, flush)

			tyres := ["FL", "FR", "RL", "RR"]
			types := ["Cold", "Hot"]

			for typeIndex, tPressures in [coldPressures, hotPressures]
				for tyreIndex, pressure in tPressures
					this.updatePressure(weather, airTemperature, trackTemperature, tyreCompound, tyreCompoundColor
									  , types[typeIndex], tyres[tyreIndex], pressure, 1, driver, flush)
		}

		updatePressure(weather, airTemperature, trackTemperature, tyreCompound, tyreCompoundColor
					 , type, tyre, pressure, count, driver, flush) {
			local rows

			if (isNull(null(pressure)))
				return

			if (!tyreCompoundColor || (tyreCompoundColor = ""))
				tyreCompoundColor := "Black"

			rows := this.Database.query("Tyres.Pressures.Distribution"
									  , {Where: CaseInsenseMap("Weather", weather, "Temperature.Air", airTemperature, "Temperature.Track", trackTemperature
															 , "Driver", driver, "Compound", tyreCompound, "Compound.Color", tyreCompoundColor
															 , "Type", type, "Tyre", tyre, "Pressure", pressure)})

			if (rows.Length > 0)
				rows[1]["Count"] := rows[1]["Count"] + count
			else
				this.Database.add("Tyres.Pressures.Distribution"
								, Database.Row("Weather", weather, "Temperature.Air", airTemperature, "Temperature.Track", trackTemperature
											 , "Driver", driver, "Compound", tyreCompound, "Compound.Color", tyreCompoundColor
											 , "Type", type, "Tyre", tyre, "Pressure", pressure, "Count", count)
								, flush)
		}
	}

	class SessionStrategy extends Strategy {
		initializeAvailableTyreSets() {
			super.initializeAvailableTyreSets()

			RaceCenter.Instance.initializeAvailableTyreSets(this)
		}
	}

	class SessionTrafficStrategy extends TrafficStrategy {
		initializeAvailableTyreSets() {
			super.initializeAvailableTyreSets()

			RaceCenter.Instance.initializeAvailableTyreSets(this)
		}
	}

	class Pitstop {
		iID := false

		iTime := false
		iLap := 0
		iDuration := 0

		ID {
			Get {
				return this.iID
			}
		}

		Time {
			Get {
				return this.iTime
			}
		}

		Lap {
			Get {
				return this.iLap
			}
		}

		Duration {
			Get {
				return this.iDuration
			}

			Set {
				return (this.iDuration := value)
			}
		}

		__New(id, time, lap) {
			this.iID := id
			this.iTime := time
			this.iLap := lap
		}
	}

	Window {
		Get {
			return this.iWindow
		}
	}

	Control[name] {
		Get {
			return this.Window[name]
		}
	}

	RaceSettings {
		Get {
			return this.iRaceSettings
		}
	}

	SessionDirectory {
		Get {
			if this.SessionActive
				return (this.iSessionDirectory . this.iSessionName . "\")
			else if this.SessionLoaded
				return this.SessionLoaded
			else
				return this.iSessionDirectory
		}
	}

	Connector {
		Get {
			return this.iConnector
		}
	}

	Connected {
		Get {
			return (this.iConnection != false)
		}
	}

	Connection {
		Get {
			return this.iConnection
		}
	}

	ServerURL {
		Get {
			return this.iServerURL
		}
	}

	ServerToken {
		Get {
			return this.iServerToken
		}
	}

	Teams[key?] {
		Get {
			return (isSet(key) ? this.iTeams[key] : this.iTeams)
		}
	}

	Sessions[key?] {
		Get {
			return (isSet(key) ? this.iSessions[key] : this.iSessions)
		}
	}

	SessionDrivers[key?] {
		Get {
			return (isSet(key) ? this.iSessionDrivers[key] : this.iSessionDrivers)
		}
	}

	TeamDrivers[key?] {
		Get {
			return (isSet(key) ? this.iTeamDrivers[key] : this.iTeamDrivers)
		}
	}

	SelectedTeam[asIdentifier := false] {
		Get {
			return (asIdentifier ? this.iTeamIdentifier : this.iTeamName)
		}
	}

	SelectedSession[asIdentifier := false] {
		Get {
			return (asIdentifier ? this.iSessionIdentifier : this.iSessionName)
		}
	}

	Synchronize {
		Get {
			return this.iSynchronize
		}
	}

	SessionActive {
		Get {
			return (this.Connected && this.SelectedTeam[true] && this.SelectedSession[true])
		}
	}

	SessionFinished {
		Get {
			return this.iSessionFinished
		}
	}

	SessionLoaded {
		Get {
			return this.iSessionLoaded
		}
	}

	HasData {
		Get {
			return ((this.SessionActive && this.CurrentStint) || this.SessionLoaded)
		}
	}

	SetupsVersion {
		Get {
			return this.iSetupsVersion
		}
	}

	TeamDriversVersion {
		Get {
			return this.iTeamDriversVersion
		}
	}

	PlanVersion {
		Get {
			return this.iPlanVersion
		}
	}

	Date {
		Get {
			return this.iDate
		}
	}

	Time {
		Get {
			return this.iTime
		}
	}

	Simulator {
		Get {
			return this.iSimulator
		}
	}

	Car {
		Get {
			return this.iCar
		}
	}

	Track {
		Get {
			return this.iTrack
		}
	}

	Weather {
		Get {
			return this.iWeather
		}
	}

	Weather10Min {
		Get {
			return this.iWeather10Min
		}
	}

	Weather30Min {
		Get {
			return this.iWeather30Min
		}
	}

	AirTemperature {
		Get {
			return this.iAirTemperature
		}
	}

	TrackTemperature {
		Get {
			return this.iTrackTemperature
		}
	}

	TyreCompounds[key?] {
		Get {
			return (isSet(key) ? this.iTyreCompounds[key] : this.iTyreCompounds)
		}
	}

	TyreCompound {
		Get {
			return this.iTyreCompound
		}
	}

	TyreCompoundColor {
		Get {
			return this.iTyreCompoundColor
		}
	}

	Strategy {
		Get {
			return this.iStrategy
		}
	}

	StintDriver {
		Get {
			return this.iStintDriver
		}
	}

	UseSessionData {
		Get {
			return this.iUseSessionData
		}
	}

	UseTelemetryDatabase {
		Get {
			return this.iUseTelemetryDatabase
		}
	}

	UseCurrentMap {
		Get {
			return this.iUseCurrentMap
		}
	}

	UseTraffic {
		Get {
			return this.iUseTraffic
		}
	}

	Drivers {
		Get {
			return this.iDrivers
		}
	}

	Stints[key?] {
		Get {
			return (isSet(key) ? this.iStints[key] : this.iStints)
		}

		Set {
			return (isSet(key) ? (this.iStints[key] := value) : (this.iStints := value))
		}
	}

	CurrentStint[asIdentifier := false] {
		Get {
			if this.iCurrentStint
				return (asIdentifier ? this.iCurrentStint.Identifier : this.iCurrentStint)
			else
				return false
		}
	}

	Laps[key?] {
		Get {
			return (isSet(key) ? this.iLaps[key] : this.iLaps)
		}

		Set {
			return (isSet(key) ? (this.iLaps[key] := value) : (this.iLaps := value))
		}
	}

	LastLap[asIdentifier := false] {
		Get {
			if this.iLastLap
				return (asIdentifier ? this.iLastLap.Identifier : this.iLastLap)
			else
				return false
		}
	}

	Pitstops[id?] {
		Get {
			if isSet(id) {
				if !this.iPitstops.Has(id)
					this.iPitstops[id] := []

				return this.iPitstops[id]
			}
			else
				return this.iPitstops
		}
	}

	SetupsListView {
		Get {
			return this.iSetupsListView
		}
	}

	PlanListView {
		Get {
			return this.iPlanListView
		}
	}

	StintsListView {
		Get {
			return this.iStintsListView
		}
	}

	LapsListView {
		Get {
			return this.iLapsListView
		}
	}

	PitstopsListView {
		Get {
			return this.iPitstopsListView
		}
	}

	SelectedSetup {
		Get {
			return this.iSelectedSetup
		}
	}

	SelectedPlanStint {
		Get {
			return this.iSelectedPlanStint
		}
	}

	TyrePressureMode {
		Get {
			return this.iTyrePressureMode
		}
	}

	CorrectPressureLoss {
		Get {
			return this.iCorrectPressureLoss
		}
	}

	SessionStore {
		Get {
			if !this.iSessionStore
				this.iSessionStore := Database(this.SessionDirectory, kSessionDataSchemas)

			return this.iSessionStore
		}
	}

	TelemetryDatabase {
		Get {
			if !this.iTelemetryDatabase
				this.iTelemetryDatabase := RaceCenter.RaceCenterTelemetryDatabase.SessionTelemetryDatabase(this)

			return this.iTelemetryDatabase
		}
	}

	SimulationTelemetryDatabase {
		Get {
			return (this.iSimulationTelemetryDatabase ? this.iSimulationTelemetryDatabase : this.TelemetryDatabase)
		}
	}

	PressuresDatabase {
		Get {
			if !this.iPressuresDatabase
				this.iPressuresDatabase := RaceCenter.SessionPressuresDatabase(this)

			return this.iPressuresDatabase
		}
	}

	ReportsListView {
		Get {
			return this.iReportsListView
		}
	}

	WaitViewer {
		Get {
			return this.iWaitViewer
		}
	}

	ChartViewer {
		Get {
			return this.iChartViewer
		}
	}

	ReportViewer {
		Get {
			return this.iReportViewer
		}
	}

	DetailsViewer {
		Get {
			return this.iDetailsViewer
		}
	}

	StrategyViewer {
		Get {
			return this.iStrategyViewer
		}
	}

	SelectedReport {
		Get {
			return this.iSelectedReport
		}
	}

	SelectedChartType {
		Get {
			return this.iSelectedChartType
		}
	}

	AvailableDrivers[index?] {
		Get {
			return (isSet(index) ? this.iAvailableDrivers[index] : this.iAvailableDrivers)
		}
	}

	SelectedDrivers {
		Get {
			return this.iSelectedDrivers
		}
	}

	SelectedDetailReport {
		Get {
			return this.iSelectedDetailReport
		}
	}

	__New(configuration, raceSettings) {
		local dllName, dllFile

		this.iRaceSettings := raceSettings

		dllName := "Team Server Connector.dll"
		dllFile := kBinariesDirectory . dllName

		try {
			if !FileExist(dllFile) {
				logMessage(kLogCritical, translate("Team Server Connector.dll not found in ") . kBinariesDirectory)

				throw "Unable to find Team Server Connector.dll in " . kBinariesDirectory . "..."
			}

			this.iConnector := CLR_LoadLibrary(dllFile).CreateInstance("TeamServer.TeamServerConnector")
		}
		catch Any as exception {
			logMessage(kLogCritical, translate("Error while initializing Team Server Connector - please rebuild the applications"))

			showMessage(translate("Error while initializing Team Server Connector - please rebuild the applications") . translate("...")
					  , translate("Modular Simulator Controller System"), "Alert.png", 5000, "Center", "Bottom", 800)
		}

		super.__New(configuration)

		RaceCenter.Instance := this

		this.iSyncTask := SyncSessionTask()

		this.iSyncTask.start()

		PeriodicTask(ObjBindMethod(this, "keepAlive"), 120000, kLowPriority).start()
	}

	loadFromConfiguration(configuration) {
		local directory, settings

		super.loadFromConfiguration(configuration)

		if FileExist(kUserConfigDirectory . "Team Server.ini")
			configuration := readMultiMap(kUserConfigDirectory . "Team Server.ini")

		directory := getMultiMapValue(configuration, "Team Server", "Session.Folder", kTempDirectory . "Sessions")

		if (!directory || (directory = ""))
			directory := (kTempDirectory . "Sessions")

		this.iSessionDirectory := (directory . "\")

		settings := this.RaceSettings

		this.iServerURL := getMultiMapValue(settings, "Team Settings", "Server.URL"
										  , getMultiMapValue(configuration, "Team Server", "Server.URL", ""))
		this.iServerToken := getMultiMapValue(settings, "Team Settings", "Server.Token"
											, getMultiMapValue(configuration, "Team Server", "Server.Token", RaceCenter.kInvalidToken))
		this.iTeamName := getMultiMapValue(settings, "Team Settings", "Team.Name", "")
		this.iTeamIdentifier := getMultiMapValue(settings, "Team Settings", "Team.Identifier", false)
		this.iSessionName := getMultiMapValue(settings, "Team Settings", "Session.Name", "")
		this.iSessionIdentifier := getMultiMapValue(settings, "Team Settings", "Session.Identifier", false)
	}

	createGui(configuration) {
		local center := this
		local centerGui, centerTab, x, y, width, ignore, report, choices, serverURLs, settings, button, control

		validateNumber(field, *) {
			field := centerGui[field]

			if !isNumber(internalValue("Float", field.Text)) {
				field.Text := (field.HasProp("ValidText") ? field.ValidText : "")

				loop 10
					SendInput("{Right}")
			}
			else
				field.ValidText := field.Text
		}

		closeRaceCenter(*) {
			ExitApp(0)
		}

		connectServer(*) {
			center.iServerURL := centerGui["serverURLEdit"].Text
			center.iServerToken := ((centerGui["serverTokenEdit"].Text = "") ? RaceCenter.kInvalidToken : centerGui["serverTokenEdit"].Text)

			center.connect()
		}

		chooseTeam(*) {
			center.withExceptionhandler(ObjBindMethod(center, "selectTeam")
									  , getValues(center.Teams)[centerGui["teamDropDownMenu"].Value])
		}

		chooseSession(*) {
			center.withExceptionhandler(ObjBindMethod(center, "selectSession")
									  , getValues(center.Sessions)[centerGui["sessionDropDownMenu"].Value])
		}

		connectSession(*) {
			connectServer()
		}

		chooseReport(listView, line, *) {
			if center.HasData {
				if center.isWorking()
					return

				if line
					center.showReport(kSessionReports[line])
			}
			else
				loop listView.GetCount()
					listView.Modify(A_Index, "-Select")
		}

		reportSettings(*) {
			center.withExceptionhandler(ObjBindMethod(center, "reportSettings", center.SelectedReport))
		}

		chooseDriver(*) {
			center.withExceptionHandler(ObjBindMethod(center, "selectDriver"
									  , (centerGui["driverDropDown"].Value = 1) ? true : center.AvailableDrivers[centerGui["driverDropDown"].Value - 1]))
		}

		chooseAxis(*) {
			center.withExceptionhandler(ObjBindMethod(center, "showTelemetryReport"))
		}

		chooseChartType(*) {
			center.selectChartType(["Scatter", "Bar", "Bubble", "Line"][centerGui["chartTypeDropDown"].Value])
		}

		sessionMenu(*) {
			center.withExceptionhandler(ObjBindMethod(center, "chooseSessionMenu", centerGui["sessionMenuDropDown"].Value))
		}

		planMenu(*) {
			center.withExceptionhandler(ObjBindMethod(center, "choosePlanMenu", centerGui["planMenuDropDown"].Value))
		}

		strategyMenu(*) {
			center.withExceptionhandler(ObjBindMethod(center, "chooseStrategyMenu", centerGui["strategyMenuDropDown"].Value))
		}

		pitstopMenu(*) {
			center.withExceptionhandler(ObjBindMethod(center, "choosePitstopMenu", centerGui["pitstopMenuDropDown"].Value))
		}

		updateDate(*) {
			center.iDate := centerGui["sessionDateCal"].Value
		}

		updateTime(*) {
			local time := center.Time

			center.iTime := centerGui["sessionTimeEdit"].Value

			time := DateDiff(time, center.iTime, "Minutes")

			center.updatePlan(-time)

			loop center.PlanListView.GetCount()
				center.PlanListView.Modify(A_Index, "-Select")

			center.iSelectedPlanStint := false

			center.updateState()
		}

		choosePlan(listView, line, *) {
			local stint, driver, timePlanned, timeActual, lapPlanned, lapActual, refuelAmount, tyreChange, time, currentTime

			if line {
				center.PlanListView.Modify(line, "Select")

				center.iSelectedPlanStint := line

				stint := center.PlanListView.GetText(line, 1)
				driver := center.PlanListView.GetText(line, 2)
				timePlanned := center.PlanListView.GetText(line, 3)
				timeActual := center.PlanListView.GetText(line, 4)
				lapPlanned := center.PlanListView.GetText(line, 5)
				lapActual := center.PlanListView.GetText(line, 6)
				refuelAmount := center.PlanListView.GetText(line, 7)
				tyreChange := center.PlanListView.GetText(line, 8)

				time := string2Values(":", timePlanned)

				currentTime := "20200101000000"

				if (time.Length = 2) {
					currentTime := DateAdd(currentTime, time[1], "Hours")
					currentTime := DateAdd(currentTime, time[2], "Minutes")
				}

				timePlanned := currentTime

				time := string2Values(":", timeActual)

				currentTime := "20200101000000"

				if (time.Length = 2) {
					currentTime := DateAdd(currentTime, time[1], "Hours")
					currentTime := DateAdd(currentTime, time[2], "Minutes")
				}

				timeActual := currentTime

				centerGui["planDriverDropDownMenu"].Choose(inList(getKeys(center.SessionDrivers), driver) + 1)
				centerGui["planTimeEdit"].Value := timePlanned
				centerGui["actTimeEdit"].Value := timeActual
				centerGui["planLapEdit"].Text := lapPlanned
				centerGui["actLapEdit"].Text := lapActual
				centerGui["planRefuelEdit"].Text := refuelAmount
				centerGui["planTyreCompoundDropDown"].Choose((tyreChange = "x") ? 1 : 2)

				center.updateState()
			}
		}

		updatePlan(*) {
			updatePlanAsync() {
				local row, stint, time

				row := center.PlanListView.GetNext(0)

				if (row && (row != center.SelectedPlanStint)) {
					center.PlanListView.Modify(row, "-Select")

					row := false
					center.iSelectedPlanStint := false
				}

				if (row > 0) {
					if (centerGui["planDriverDropDownMenu"].Value = 1)
						center.PlanListView.Modify(row, "Col2", "")
					else
						center.PlanListView.Modify(row, "Col2", getKeys(center.SessionDrivers)[centerGui["planDriverDropDownMenu"].Value - 1])

					time := FormatTime(centerGui["planTimeEdit"].Value, "HH:mm")

					center.PlanListView.Modify(row, "Col3", ((time = "00:00") ? "" : time))

					time := FormatTime(centerGui["actTimeEdit"].Value, "HH:mm")

					center.PlanListView.Modify(row, "Col4", ((time = "00:00") ? "" : time))

					stint := center.PlanListView.GetText(row, 1)

					if (stint > 1)
						center.PlanListView.Modify(row, "Col5", centerGui["planLapEdit"].Text, centerGui["actLapEdit"].Text, centerGui["planRefuelEdit"].Text
															  , (centerGui["planTyreCompoundDropDown"].Value = 2) ? "" : "x")

					if (center.SelectedDetailReport = "Plan")
						center.showPlanDetails()
				}
			}

			center.pushTask(updatePlanAsync)
		}

		addPlan(*) {
			local row, translator, msgResult

			row := center.PlanListView.GetNext(0)

			if (row && (row != center.SelectedPlanStint)) {
				center.PlanListView.Modify(row, "-Select")

				row := false
				center.iSelectedPlanStint := false
			}

			if row {
				translator := translateMsgBoxButtons.Bind(["Before", "After", "Cancel"])

				OnMessage(0x44, translator)
				msgResult := MsgBox(translate("Do you want to add the new entry before or after the currently selected entry?"), translate("Insert"), 262179)
				OnMessage(0x44, translator, 0)

				if (msgResult = "Cancel")
					return

				if (msgResult = "Yes")
					center.withExceptionhandler(ObjBindMethod(center, "addPlan", "Before"))

				if (msgResult = "No")
					center.withExceptionhandler(ObjBindMethod(center, "addPlan", "After"))
			}
			else
				center.withExceptionhandler(ObjBindMethod(center, "addPlan"))
		}

		deletePlan(*) {
			local row, msgResult

			row := center.PlanListView.GetNext(0)

			if (row && (row != center.SelectedPlanStint)) {
				center.PlanListView.Modify(row, "-Select")

				row := false
				center.iSelectedPlanStint := false
			}

			if row {
				OnMessage(0x44, translateYesNoButtons)
				msgResult := MsgBox(translate("Do you really want to delete the selected plan entry?"), translate("Delete"), 262436)
				OnMessage(0x44, translateYesNoButtons, 0)

				if (msgResult = "Yes")
					center.withExceptionhandler(ObjBindMethod(center, "deletePlan"))
			}
		}

		releasePlan(*) {
			center.withExceptionhandler(ObjBindMethod(center, "releasePlan"))
		}

		chooseStint(listView, line, *) {
			if line
				center.withExceptionhandler(ObjBindMethod(center, "showStintDetails", center.Stints[listView.GetText(line, 1)]))
		}

		chooseLap(listView, line, *) {
			if line
				center.withExceptionhandler(ObjBindMethod(center, "showLapDetails", center.Laps[listView.GetText(line, 1)]))
		}

		chooseSimulationSettings(*) {
			center.iUseSessionData := (centerGui["useSessionDataDropDown"].Value == 1)
			center.iUseTelemetryDatabase := (centerGui["useTelemetryDataDropDown"].Value == 1)
			center.iUseCurrentMap := (centerGui["keepMapDropDown"].Value == 1)
			center.iUseTraffic := (centerGui["considerTrafficDropDown"].Value == 1)

			center.updateState()
		}

		updateSetup(*) {
			updateSetupAsync() {
				local row := center.SetupsListView.GetNext(0)

				if (row && (row != center.SelectedSetup)) {
					center.SetupsListView.Modify(row, "-Select")

					row := false
					center.iSelectedSetup := false
				}

				if row {
					validateNumber("setupBasePressureFLEdit")
					validateNumber("setupBasePressureFREdit")
					validateNumber("setupBasePressureRLEdit")
					validateNumber("setupBasePressureRREdit")

					center.SetupsListView.Modify(row, "", getKeys(center.SessionDrivers)[centerGui["setupDriverDropDownMenu"].Value]
														, translate(kWeatherConditions[centerGui["setupWeatherDropDownMenu"].Value]) . A_Space
														. translate("(") . centerGui["setupAirTemperatureEdit"].Text . ", "
																		 . centerGui["setupTrackTemperatureEdit"].Text . translate(")")
														, translate(center.TyreCompounds[centerGui["setupCompoundDropDownMenu"].Value])
														, values2String(", ", centerGui["setupBasePressureFLEdit"].Text
																			, centerGui["setupBasePressureFREdit"].Text
																			, centerGui["setupBasePressureRLEdit"].Text
																			, centerGui["setupBasePressureRREdit"].Text)
														, centerGui["setupNotesEdit"].Text)
				}

				if (center.SelectedDetailReport = "Setups")
					center.showSetupsDetails()
			}

			center.pushTask(updateSetupAsync)
		}

		addSetup(*) {
			if (center.SessionDrivers.Count > 0)
				center.withExceptionhandler(ObjBindMethod(center, "addSetup"))
			else {
				OnMessage(0x44, translateOkButton)
				MsgBox(translate("There are no drivers available. Please select a valid session first."), translate("Information"), 262192)
				OnMessage(0x44, translateOkButton, 0)
			}
		}

		copySetup(*) {
			local row := center.SetupsListView.GetNext(0)

			if (row && (row != center.SelectedSetup)) {
				center.SetupsListView.Modify(row, "-Select")

				row := false
				center.iSelectedSetup := false
			}

			if row
				center.withExceptionhandler(ObjBindMethod(center, "copySetup"))
		}

		deleteSetup(*) {
			local row := center.SetupsListView.GetNext(0)
			local msgResult

			if (row && (row != center.SelectedSetup)) {
				center.SetupsListView.Modify(row, "-Select")

				row := false
				center.iSelectedSetup := false
			}

			if row {
				OnMessage(0x44, translateYesNoButtons)
				msgResult := MsgBox(translate("Do you really want to delete the current driver specific setup?"), translate("Delete"), 262436)
				OnMessage(0x44, translateYesNoButtons, 0)

				if (msgResult = "Yes")
					center.withExceptionhandler(ObjBindMethod(center, "deleteSetup"))
			}
		}

		loadSetup(*) {
			local exePath := kBinariesDirectory . "Session Database.exe"
			local options, row

			row := center.SetupsListView.GetNext(0)

			if (row = center.SelectedSetup) {
				center.iPressuresRequest := row

				try {
					options := ["-Setup", ProcessExist()]

					if (center.Simulator && center.Car && center.Track) {
						tyreCompound := center.TyreCompounds[centerGui["setupCompoundDropDownMenu"].Value]

						options := concatenate(options, ["-Simulator", "`"" . SessionDatabase.getSimulatorName(center.Simulator) . "`""
													   , "-Car", "`"" . center.Car . "`""
													   , "-Track", "`"" . center.Track . "`""
													   , "-Weather", center.Weather
													   , "-AirTemperature", Round(convertUnit("Temperature", internalValue("Float", centerGui["setupAirTemperatureEdit"].Text), false))
													   , "-TrackTemperature", Round(convertUnit("Temperature", internalValue("Float", centerGui["setupTrackTemperatureEdit"].Text), false))
													   , "-Compound", compound(tyreCompound), "-CompoundColor", compoundColor(tyreCompound)])
					}

					options := values2String(A_Space, options*)

					Run("`"" . exePath . "`" " . options, kBinariesDirectory)
				}
				catch Any as exception {
					logMessage(kLogCritical, translate("Cannot start the Session Database tool (") . exePath . translate(") - please rebuild the applications in the binaries folder (") . kBinariesDirectory . translate(")"))

					showMessage(substituteVariables(translate("Cannot start the Session Database tool (%exePath%) - please check the configuration..."), {exePath: exePath})
							  , translate("Modular Simulator Controller System"), "Alert.png", 5000, "Center", "Bottom", 800)
				}
			}
		}

		chooseSetup(listView, line, *) {
			local driver, conditions, tyreCompound, pressures, temperatures

			if line {
				center.iSelectedSetup := line

				driver := center.SetupsListView.GetText(line, 1)
				conditions := center.SetupsListView.GetText(line, 2)
				tyreCompound := center.SetupsListView.GetText(line, 3)
				pressures := center.SetupsListView.GetText(line, 4)

				conditions := string2Values(translate("("), conditions)

				centerGui["setupDriverDropDownMenu"].Choose(inList(getKeys(center.SessionDrivers), driver))

				centerGui["setupWeatherDropDownMenu"].Choose(inList(collect(kWeatherConditions, translate), conditions[1]))
				centerGui["setupCompoundDropDownMenu"].Choose(inList(collect(center.TyreCompounds, translate), normalizeCompound(tyreCompound)))

				temperatures := string2Values(", ", StrReplace(conditions[2], translate(")"), ""))

				centerGui["setupAirTemperatureEdit"].Text := temperatures[1]
				centerGui["setupTrackTemperatureEdit"].Text := temperatures[2]

				pressures := string2Values(", ", pressures)

				centerGui["setupBasePressureFLEdit"].Text := pressures[1]
				centerGui["setupBasePressureFREdit"].Text := pressures[2]
				centerGui["setupBasePressureRLEdit"].Text := pressures[3]
				centerGui["setupBasePressureRREdit"].Text := pressures[4]

				centerGui["setupNotesEdit"].Text := center.SetupsListView.GetText(line, 5)

				center.updateState()
			}
		}

		releaseSetups(*) {
			if center.SessionActive
				center.withExceptionhandler(ObjBindMethod(center, "releaseSetups"))
			else {
				OnMessage(0x44, translateOkButton)
				MsgBox(translate("You are not connected to an active session."), translate("Information"), 262192)
				OnMessage(0x44, translateOkButton, 0)
			}
		}

		uploadSetups(*) {
			local fileName, translator, msgResult

			centerGui.Opt("+OwnDialogs")

			OnMessage(0x44, translateLoadCancelButtons)
			fileName := FileSelect(1, "", translate("Import Setups..."), "Setups (*.setups)")
			OnMessage(0x44, translateLoadCancelButtons, 0)

			if (fileName != "")
				if (center.SessionStore.Tables["Setups.Data"].Length > 0) {
					translator := translateMsgBoxButtons.Bind(["Insert", "Replace", "Cancel"])

					OnMessage(0x44, translator)
					msgResult := MsgBox(translate("Do you want to replace all current entries or do you want to add the imported entries to the list?"), translate("Import"), 262179)
					OnMessage(0x44, translator, 0)

					if (msgResult = "Cancel")
						return

					if (msgResult = "Yes")
						center.withExceptionhandler(ObjBindMethod(center, "importSetups", fileName, false))

					if (msgResult = "No")
						center.withExceptionhandler(ObjBindMethod(center, "importSetups", fileName, true))
				}
				else
					center.withExceptionhandler(ObjBindMethod(center, "importSetups", fileName, false))
		}

		downloadSetups(*) {
			local fileName, setups

			centerGui.Opt("+OwnDialogs")

			OnMessage(0x44, translateSaveCancelButtons)
			fileName := FileSelect("S17", "", translate("Export Setups..."), "Setups (*.setups)")
			OnMessage(0x44, translateSaveCancelButtons, 0)

			if (fileName != "") {
				if !InStr(fileName, ".")
					fileName := (fileName . ".setups")

				center.saveSetups(true)

				setups := (center.SessionDirectory . "Setups.Data.CSV")

				try {
					FileCopy(setups, fileName, 1)
				}
				catch Any as exception {
					logError(exception)
				}
			}
		}

		updateState(*) {
			center.withExceptionhandler(ObjBindMethod(center, "updateState"))
		}

		copyPressures(*) {
			local hasPitstops := false
			local lap, driver, conditions, fuel, tyreCompound, tyreCompoundColor, tyreSet, pressures
			local pressuresMenu, label

			copyPressure(driver, compound, pressures, *) {
				local chosen := inList(collect(concatenate(["No Tyre Change"], center.TyreCompounds), translate), compound)

				pressures := string2Values(", ", pressures)

				centerGui["pitstopTyreCompoundDropDown"].Choose((chosen == 0) ? 1 : chosen)
				centerGui["pitstopPressureFLEdit"].Text := pressures[1]
				centerGui["pitstopPressureFREdit"].Text := pressures[2]
				centerGui["pitstopPressureRLEdit"].Text := pressures[3]
				centerGui["pitstopPressureRREdit"].Text := pressures[4]

				if driver {
					driver := inList(center.TeamDrivers, driver)

					if driver
						centerGui["pitstopDriverDropDownMenu"].Choose(driver + 1)
				}

				center.updateState()
			}

			pressuresMenu := Menu()

			if this.Laps.Has(1) {
				lap := this.Laps[1]

				this.getStintSetup(1, true, &fuel, &tyreCompound, &tyreCompoundColor, &tyreSet, &pressures)

				if pressures {
					driver := lap.Stint.Driver.FullName

					conditions := (translate(lap.Weather) . A_Space . translate("(")
								 . displayValue("Float", convertUnit("Temperature", lap.AirTemperature)) . ", "
								 . displayValue("Float", convertUnit("Temperature", lap.TrackTemperature)) . translate(")"))

					tyreCompound := compound(tyreCompound, tyreCompoundColor)

					label := (translate("Session") . translate(" - ") . driver . translate(" - "))
						   . (conditions . translate(" - ") . tyreCompound . translate(": ") . values2String(", ", pressures*))

					pressuresMenu.Add(label, copyPressure.Bind(driver, tyreCompound, pressures))

					hasPitstops := true
				}
			}

			loop center.PitstopsListView.GetCount() {
				if ((A_Index = 1) && hasPitstops)
					pressuresMenu.Add()

				lap := center.PitstopsListView.GetText(A_Index, 2)

				if center.Laps.Has(lap) {
					driver := center.PitstopsListView.GetText(A_Index, 3)
					tyreCompound := center.PitstopsListView.GetText(A_Index, 5)
					pressures := center.PitstopsListView.GetText(A_Index, 7)

					lap := center.Laps[lap]

					conditions := (translate(lap.Weather) . A_Space . translate("(")
								 . displayValue("Float", convertUnit("Temperature", lap.AirTemperature)) . ", "
								 . displayValue("Float", convertUnit("Temperature", lap.TrackTemperature)) . translate(")"))

					label := (translate("Pitstop") . A_Space . A_Index . translate(" - "))

					if (driver && (driver != "-"))
						label .= (driver . translate(" - "))

					label .= (conditions . translate(" - ") . tyreCompound . translate(": ") . pressures)

					pressuresMenu.Add(label, copyPressure.Bind((driver && (driver != "-")) ? driver : false, tyreCompound, pressures))

					hasPitstops := true
				}
			}

			loop center.SetupsListView.GetCount() {
				if ((A_Index = 1) && hasPitstops)
					pressuresMenu.Add()

				driver := center.SetupsListView.GetText(A_Index, 1)
				conditions := center.SetupsListView.GetText(A_Index, 2)
				tyreCompound := center.SetupsListView.GetText(A_Index, 3)
				pressures := center.SetupsListView.GetText(A_Index, 4)

				pressuresMenu.Add((driver . translate(" - ") . conditions . translate(" - ") . tyreCompound . translate(": ") . pressures)
								, copyPressure.Bind(driver, tyreCompound, pressures))

				hasPitstops := true
			}

			if hasPitstops
				pressuresMenu.Show()
		}

		planPitstop(*) {
			center.withExceptionhandler(ObjBindMethod(center, "planPitstop"))
		}

		choosePitstop(listView, line, *) {
			local sessionStore := center.SessionStore
			local pitstops := sessionStore.Tables["Pitstop.Data"]
			local pitstop

			if line {
				pitstop := center.PitstopsListView.GetText(line, 1)

				if (pitstops.Has(pitstop) && (pitstops[pitstop]["Status"] = "Planned")) {
					center.PitstopsListView.Modify(line, "-Check")

					loop center.PitstopsListView.GetCount()
						center.PitstopsListView.Modify(line, "-Select")
				}
				else {
					center.PitstopsListView.Modify(line, "Check")

					center.withExceptionhandler(ObjBindMethod(center, "showPitstopDetails", pitstop))
				}
			}
		}

		centerGui := Window({Descriptor: "Race Center", Closeable: true, Resizeable: "Deferred"})

		this.iWindow := centerGui

		centerGui.SetFont("s10 Bold", "Arial")

		centerGui.Add("Text", "w1334 H:Center Center", translate("Modular Simulator Controller System")).OnEvent("Click", moveByMouse.Bind(centerGui, "Race Center"))

		centerGui.SetFont("s9 Norm", "Arial")

		centerGui.Add("Documentation", "x608 YP+20 w134 H:Center Center", translate("Race Center")
					, "https://github.com/SeriousOldMan/Simulator-Controller/wiki/Team-Server#race-center")

		centerGui.Add("Text", "x8 yp+30 w1350 W:Grow 0x10")

		centerGui.SetFont("Norm")
		centerGui.SetFont("s10 Bold", "Arial")

		centerGui.Add("Picture", "x16 yp+12 w30 h30 Section", kIconsDirectory . "Report.ico")
		centerGui.Add("Text", "x50 yp+5 w80 h26", translate("Reports"))

		centerGui.SetFont("s8 Norm", "Arial")

		x := 16
		y := 70
		width := 388

		settings := readMultiMap(kUserConfigDirectory . "Application Settings.ini")

		serverURLs := string2Values(";", getMultiMapValue(settings, "Team Server", "Server URLs", ""))

		if (!inList(serverURLs, this.ServerURL) && StrLen(this.ServerURL) > 0)
			serverURLs.Push(this.ServerURL)

		chosen := inList(serverURLs, this.ServerURL)
		if (!chosen && (serverURLs.Length > 0))
			chosen := 1

		centerGui.Add("Text", "x16 yp+30 w90 h23 +0x200", translate("Server URL"))
		centerGui.Add("ComboBox", "x141 yp+1 w245 Choose" . chosen . " VserverURLEdit", serverURLs)

		centerGui.Add("Text", "x16 yp+24 w90 h23 +0x200", translate("Session Token"))
		centerGui.Add("Edit", "x141 yp+1 w245 h21 VserverTokenEdit", this.ServerToken)

		button := centerGui.Add("Button", "x116 yp-1 w23 h23 Center +0x200")
		button.OnEvent("Click", connectServer)
		setButtonIcon(button, kIconsDirectory . "Authorize.ico", 1, "L4 T4 R4 B4")

		centerGui.Add("Text", "x16 yp+26 w90 h23 +0x200", translate("Team / Session"))

		if this.SelectedTeam[true]
			centerGui.Add("DropDownList", "x141 yp w120 Choose1 vteamDropDownMenu", [this.SelectedTeam]).OnEvent("Change", chooseTeam)
		else
			centerGui.Add("DropDownList", "x141 yp w120 vteamDropDownMenu").OnEvent("Change", chooseTeam)

		if this.SelectedSession[true]
			centerGui.Add("DropDownList", "x266 yp w120 Choose1 vsessionDropDownMenu", [this.SelectedSession]).OnEvent("Change", chooseSession)
		else
			centerGui.Add("DropDownList", "x266 yp w120 Choose0 vsessionDropDownMenu").OnEvent("Change", chooseSession)

		button := centerGui.Add("Button", "x116 yp-1 w23 h23 Center +0x200")
		button.OnEvent("Click", connectSession)
		setButtonIcon(button, kIconsDirectory . "Renew.ico", 1, "L4 T4 R4 B4")

		centerGui.Add("Text", "x24 yp+31 w356 0x10")

		this.iReportsListView := centerGui.Add("ListView", "x16 yp+10 w115 h230 H:Grow(0.2) -Multi -LV0x10 AltSubmit NoSort NoSortHdr", [translate("Report")])
		this.iReportsListView.OnEvent("Click", chooseReport)

		for ignore, report in kSessionReports
			if (report = "Drivers")
				this.iReportsListView.Add("", translate("Driver (Start)"))
			else
				this.iReportsListView.Add("", translate(report))

		this.iReportsListView.ModifyCol(1, "AutoHdr")

		centerGui.Add("Text", "x141 yp+2 w70 h23 +0x200", translate("Driver"))
		centerGui.Add("DropDownList", "x195 yp w191 vdriverDropDown").OnEvent("Change", chooseDriver)

		centerGui.Add("Text", "x141 yp+24 w70 h23 +0x200", translate("X-Axis"))

		centerGui.Add("DropDownList", "x195 yp w191 vdataXDropDown").OnEvent("Change", chooseAxis)

		centerGui.Add("Text", "x141 yp+24 w70 h23 +0x200", translate("Series"))

		centerGui.Add("DropDownList", "x195 yp w191 vdataY1DropDown").OnEvent("Change", chooseAxis)
		centerGui.Add("DropDownList", "x195 yp+24 w191 vdataY2DropDown").OnEvent("Change", chooseAxis)
		centerGui.Add("DropDownList", "x195 yp+24 w191 vdataY3DropDown").OnEvent("Change", chooseAxis)
		centerGui.Add("DropDownList", "x195 yp+24 w191 vdataY4DropDown").OnEvent("Change", chooseAxis)
		centerGui.Add("DropDownList", "x195 yp+24 w191 vdataY5DropDown").OnEvent("Change", chooseAxis)
		centerGui.Add("DropDownList", "x195 yp+24 w191 vdataY6DropDown").OnEvent("Change", chooseAxis)

		centerGui.Add("Text", "x400 ys w40 h23 +0x200", translate("Plot"))
		centerGui.Add("DropDownList", "x444 yp w80 Choose1 vchartTypeDropDown", collect(["Scatter", "Bar", "Bubble", "Line"], translate)).OnEvent("Change", chooseChartType)

		centerGui.Add("Button", "x1327 yp w23 h23 X:Move vreportSettingsButton").OnEvent("Click", reportSettings)
		setButtonIcon(centerGui["reportSettingsButton"], kIconsDirectory . "General Settings.ico", 1)

		this.iChartViewer := centerGui.Add("HTMLViewer", "x400 yp+24 w950 h343 W:Grow H:Grow(0.2) Border vchartViewer")

		centerGui.Rules := "Y:Move(0.2)"

		centerGui.Add("Text", "x8 yp+351 w1350 W:Grow 0x10")

		centerGui.SetFont("s8 Norm", "Arial")

		centerGui.Add("Picture", "x16 yp+10 w30 h30 Section", kIconsDirectory . "Tools BW.ico")
		centerGui.Add("Text", "x50 yp+5 w80 h26", translate("Session"))

		centerGui.Add("Text", "x935 yp+8 w381 0x2 X:Move vmessageField")

		this.iWaitViewer := centerGui.Add("HTMLViewer", "x1323 yp-8 w30 h30 X:Move vwaitViewer Hidden")

		this.iWaitViewer.document.open()
		this.iWaitViewer.document.write("<html><body style='background-color: #" . this.Window.Theme.WindowBackColor . "' style='overflow: auto' leftmargin='0' topmargin='0' rightmargin='0' bottommargin='0'><img src='" . (kResourcesDirectory . "Wait.gif") . "' width=28 height=28 border=0 padding=0></body></html>")
		this.iWaitViewer.document.close()

		centerGui.SetFont("s8 Norm", "Arial")

		centerGui.Add("DropDownList", "x195 yp-2 w180 Choose1 +0x200 vsessionMenuDropDown").OnEvent("Change", sessionMenu)

		centerGui.Add("DropDownList", "x380 yp w180 Choose1 +0x200 vplanMenuDropDown", collect(["Plan", "---------------------------------------------", "Update from Strategy", "Clear Plan...", "---------------------------------------------", "Plan Summary", "---------------------------------------------", "Release Plan"], translate)).OnEvent("Change", planMenu)

		centerGui.Add("DropDownList", "x565 yp w180 Choose1 +0x200 vstrategyMenuDropDown").OnEvent("Change", strategyMenu)

		centerGui.Add("DropDownList", "x750 yp w180 Choose1 +0x200 vpitstopMenuDropDown").OnEvent("Change", pitstopMenu)

		centerGui.SetFont("s8 Norm", "Arial")

		centerGui.SetFont("Norm", "Arial")
		centerGui.SetFont("Italic", "Arial")

		centerGui.Add("Text", "x619 ys+39 w80 h21", translate("Output"))
		centerGui.Add("Text", "x700 yp+7 w651 0x10 W:Grow")

		this.iDetailsViewer := centerGui.Add("HTMLViewer", "x619 yp+14 w732 h293 W:Grow H:Grow(0.8) Border vdetailsViewer")

		this.iStrategyViewer := StrategyViewer(centerGui, this.iDetailsViewer)

		centerGui.SetFont("Norm", "Arial")

		/*
		centerGui.Rules := ""

		centerGui.Add("Text", "x8 y815 w1350 0x10 Y:Move W:Grow")

		centerGui.Add("Text", "x16 y827 w554 Y:Move Border vmessageField")

		centerGui.Add("Button", "x649 y824 w80 h23 Y:Move H:Center", translate("Close")).OnEvent("Click", closeRaceCenter)

		centerGui.Rules := "Y:Move(0.2)"
		*/

		centerTab := centerGui.Add("Tab3", "x16 ys+39 w593 h316 H:Grow(0.8) AltSubmit -Wrap Section vraceCenterTabView", collect(["Plan", "Stints", "Laps", "Strategy", "Setups", "Pitstops"], translate))

		centerTab.UseTab(1)

		centerGui.Add("Text", "x24 ys+33 w90 h23 +0x200", translate("Session"))
		centerGui.Add("DateTime", "x106 yp w80 h23 vsessionDateCal").OnEvent("Change", updateDate)
		centerGui.Add("DateTime", "x190 yp w50 h23  vsessionTimeEdit  1", "HH:mm").OnEvent("Change", updateTime)

		this.iPlanListView := centerGui.Add("ListView", "x24 ys+63 w344 h240 H:Grow(0.8) -Multi -LV0x10 AltSubmit NoSort NoSortHdr", collect(["Stint", "Driver", "Time (est.)", "Time (act.)", "Lap (est.)", "Lap (act.)", "Refuel", "Tyre Change"], translate))
		this.iPlanListView.OnEvent("Click", choosePlan)

		centerGui.Add("Text", "x378 ys+68 w90 h23 +0x200", translate("Driver"))
		centerGui.Add("DropDownList", "x474 yp w126 vplanDriverDropDownMenu").OnEvent("Change", updatePlan)

		centerGui.Add("Text", "x378 yp+28 w90 h23 +0x200", translate("Time (est. / act.)"))
		centerGui.Add("DateTime", "x474 yp w50 h23 vplanTimeEdit  1", "HH:mm").OnEvent("Change", updatePlan)
		centerGui.Add("DateTime", "x528 yp w50 h23 vactTimeEdit  1", "HH:mm").OnEvent("Change", updatePlan)

		centerGui.Add("Text", "x378 yp+28 w90 h20", translate("Lap (est. / act.)"))
		centerGui.Add("Edit", "x474 yp-2 w50 h20 Limit3 Number vplanLapEdit").OnEvent("Change", updatePlan)
		centerGui.Add("UpDown", "x506 yp w18 h20 Range1-999")
		centerGui.Add("Edit", "x528 yp w50 h20 Limit3 Number vactLapEdit").OnEvent("Change", updatePlan)
		centerGui.Add("UpDown", "x560 yp w18 h20")

		centerGui.Add("Text", "x378 yp+30 w85 h20", translate("Refuel"))
		centerGui.Add("Edit", "x474 yp-2 w50 h20 Limit3 Number vplanRefuelEdit").OnEvent("Change", updatePlan)
		centerGui.Add("UpDown", "x506 yp-2 w18 h20 Range1-999")
		centerGui.Add("Text", "x528 yp+2 w80 h20", getUnit("Volume", true))

		centerGui.Add("Text", "x378 yp+24 w85 h23 +0x200", translate("Tyre Change"))

		choices := collect(["Yes", "No"], translate)

		centerGui.Add("DropDownList", "x474 yp w50 Choose1 vplanTyreCompoundDropDown", choices).OnEvent("Change", updatePlan)

		centerGui.Add("Button", "x550 yp+30 w23 h23 Center +0x200 vaddPlanButton").OnEvent("Click", addPlan)
		setButtonIcon(centerGui["addPlanButton"], kIconsDirectory . "Plus.ico", 1, "L4 T4 R4 B4")
		centerGui.Add("Button", "x575 yp w23 h23 Center +0x200 vdeletePlanButton").OnEvent("Click", deletePlan)
		setButtonIcon(centerGui["deletePlanButton"], kIconsDirectory . "Minus.ico", 1, "L4 T4 R4 B4")

		centerGui.Add("Button", "x408 ys+279 w160 Y:Move(0.8)", translate("Release Plan")).OnEvent("Click", releasePlan)

		centerTab.UseTab(2)

		this.iStintsListView := centerGui.Add("ListView", "x24 ys+33 w577 h270 H:Grow(0.8) -Multi -LV0x10 AltSubmit NoSort NoSortHdr", collect(["#", "Driver", "Weather", "Compound", "Laps", "Pos. (Start)", "Pos. (End)", "Avg. Lap Time", "Consumption", "Accidents", "Penalties", "Potential", "Race Craft", "Speed", "Consistency", "Car Control"], translate))
		this.iStintsListView.OnEvent("Click", chooseStint)

		centerTab.UseTab(3)

		this.iLapsListView := centerGui.Add("ListView", "x24 ys+33 w577 h270 H:Grow(0.8) -Multi -LV0x10 AltSubmit NoSort NoSortHdr", collect(["#", "Stint", "Driver", "Position", "Weather", "Grip", "Lap Time", "Consumption", "Remaining", "Pressures", "Accident", "Penalty"], translate))
		this.iLapsListView.OnEvent("Click", chooseLap)

		centerTab.UseTab(4)

		centerGui.SetFont("Norm", "Arial")
		centerGui.SetFont("Italic", "Arial")

		centerGui.Add("GroupBox", "x24 ys+33 w260 h124", translate("Simulation"))

		centerGui.SetFont("Norm", "Arial")

		centerGui.Add("Text", "x32 yp+24 w85 h23 +0x200", translate("Random Factor"))
		centerGui.Add("Edit", "x170 yp w50 h20 Limit2 Number VrandomFactorEdit", 5)
		centerGui.Add("UpDown", "x202 yp w18 h20 Range0-99", 5)
		centerGui.Add("Text", "x228 yp+2 w50 h20", translate("%"))

		centerGui.Add("Text", "x32 yp+22 w85 h23 +0x200", translate("# Scenarios"))
		centerGui.Add("Edit", "x170 yp w50 h20 Limit2 Number VnumScenariosEdit", 20)
		centerGui.Add("UpDown", "x202 yp w18 h20 Range1-99", 20)

		centerGui.Add("Text", "x32 yp+24 w85 h23 +0x200", translate("Variation"))
		centerGui.Add("Text", "x150 yp w18 h23 +0x200", translate("+/-"))
		centerGui.Add("Edit", "x170 yp w50 h20 Limit2 Number VvariationWindowEdit", 3)
		centerGui.Add("UpDown", "x202 yp w18 h20 Range1-99", 3)
		centerGui.Add("Text", "x228 yp+2 w50 h20", translate("laps"))

		centerGui.SetFont("Norm", "Arial")
		centerGui.SetFont("Italic", "Arial")

		centerGui.Add("GroupBox", "x304 ys+33 w296 h124", translate("Settings"))

		centerGui.SetFont("Norm", "Arial")

		centerGui.Add("Text", "x312 yp+24 w160 h23", translate("Use Session Data"))
		centerGui.Add("DropDownList", "x480 yp-3 w50 Choose1 vuseSessionDataDropDown", collect(["Yes", "No"], translate)).OnEvent("Change", chooseSimulationSettings)

		centerGui.Add("Text", "x312 yp+27 w160 h23", translate("Use Telemetry Database"))
		centerGui.Add("DropDownList", "x480 yp-3 w50 Choose2 vuseTelemetryDataDropDown", collect(["Yes", "No"], translate)).OnEvent("Change", chooseSimulationSettings)

		centerGui.Add("Text", "x312 yp+27 w160 h23", translate("Keep current Map"))
		centerGui.Add("DropDownList", "x480 yp-3 w50 Choose1 vkeepMapDropDown", collect(["Yes", "No"], translate)).OnEvent("Change", chooseSimulationSettings)

		centerGui.Add("Text", "x312 yp+27 w160 h23", translate("Analyze Traffic"))
		centerGui.Add("DropDownList", "x480 yp-3 w50 Choose2 vconsiderTrafficDropDown", collect(["Yes", "No"], translate)).OnEvent("Change", chooseSimulationSettings)

		centerGui.SetFont("Norm", "Arial")
		centerGui.SetFont("Italic", "Arial")

		centerGui.Add("GroupBox", "x24 yp+37 w576 h148", translate("Traffic Analysis (Monte Carlo)"))

		centerGui.SetFont("Norm", "Arial")

		centerGui.Add("Text", "x32 yp+24 w85 h23 +0x200", translate("Laptime Variation"))
		centerGui.Add("DropDownList", "x162 yp w50 Choose1 vlapTimeVariationDropDown", collect(["Yes", "No"], translate))
		centerGui.Add("Text", "x220 yp+2 w290 h20", translate("according to driver consistency"))

		centerGui.Add("Text", "x32 yp+22 w85 h23 +0x200", translate("Driver Errors"))
		centerGui.Add("DropDownList", "x162 yp w50 Choose1 vdriverErrorsDropDown", collect(["Yes", "No"], translate))
		centerGui.Add("Text", "x220 yp+2 w290 h20", translate("according to driver car control"))

		centerGui.Add("Text", "x32 yp+22 w85 h23 +0x200", translate("Pitstops"))
		centerGui.Add("DropDownList", "x162 yp w50 Choose1 vpitstopsDropDown", collect(["Yes", "No"], translate))
		centerGui.Add("Text", "x220 yp+2 w290 h20", translate("according to random factor"))

		centerGui.Add("Text", "x32 yp+24 w85 h23 +0x200", translate("Overtake"))
		centerGui.Add("Text", "x132 yp w28 h23 +0x200", translate("Abs("))
		centerGui.Add("Edit", "x162 yp w50 h20 Limit2 Number Limit2 VovertakeDeltaEdit", 1)
		centerGui.Add("UpDown", "x194 yp-2 w18 h20 Range1-99 0x80", 1)
		centerGui.Add("Text", "x220 yp+4 w340 h20", translate("/ laptime difference) = additional seconds for each passed car"))

		centerGui.Add("Text", "x32 yp+20 w85 h23 +0x200", translate("Traffic"))
		centerGui.Add("Edit", "x162 yp w50 h20 Limit2 Number Limit2 VtrafficConsideredEdit", 5)
		centerGui.Add("UpDown", "x194 yp-2 w18 h20 Range1-99 0x80", 5)
		centerGui.Add("Text", "x220 yp+4 w290 h20", translate("% track length"))

		centerTab.UseTab(5)

		this.iSetupsListView := centerGui.Add("ListView", "x24 ys+33 w344 h270 H:Grow(0.8) -Multi -LV0x10 AltSubmit", collect(["Driver", "Conditions", "Compound", "Pressures", "Notes"], translate))
		this.iSetupsListView.OnEvent("Click", chooseSetup)

		centerGui.Add("Text", "x378 ys+38 w90 h23 +0x200", translate("Driver"))
		centerGui.Add("DropDownList", "x474 yp w126 vsetupDriverDropDownMenu").OnEvent("Change", updateSetup)

		centerGui.Add("Text", "x378 yp+30 w70 h23 +0x200", translate("Weather"))

		choices := collect(kWeatherConditions, translate)

		centerGui.Add("DropDownList", "x474 yp w126 Choose0 vsetupWeatherDropDownMenu", choices).OnEvent("Change", updateSetup)

		centerGui.Add("Text", "x378 yp+24 w70 h23 +0x200", translate("Temperatures"))

		centerGui.Add("Edit", "x474 yp w40 Number Limit2 vsetupAirTemperatureEdit", "").OnEvent("Change", updateSetup)
		centerGui.Add("UpDown", "x476 yp w18 h20 Range0-99")

		centerGui.Add("Edit", "x521 yp w40 Number Limit2 vsetupTrackTemperatureEdit", "").OnEvent("Change", updateSetup)
		centerGui.Add("UpDown", "x523 yp w18 h20 Range0-99")
		centerGui.Add("Text", "x563 yp w35 h23 +0x200", translate("A / T"))

		choices := collect([normalizeCompound("Dry")], translate)

		centerGui.Add("Text", "x378 yp+24 w70 h23 +0x200", translate("Compound"))
		centerGui.Add("DropDownList", "x474 yp+1 w126 Choose0 vsetupCompoundDropDownMenu", choices).OnEvent("Change", updateSetup)

		centerGui.Add("Text", "x378 yp+30 w90 h23 +0x200", translate("Pressure Front"))
		centerGui.Add("Edit", "x474 yp+1 w50 h23 vsetupBasePressureFLEdit").OnEvent("Change", updateSetup)
		centerGui.Add("Edit", "xp+52 yp w50 h23 vsetupBasePressureFREdit").OnEvent("Change", updateSetup)
		centerGui.Add("Text", "xp+52 yp+3 w30 h20", getUnit("Pressure"))

		centerGui.Add("Text", "x378 yp+20 w90 h23 +0x200", translate("Pressure Rear"))
		centerGui.Add("Edit", "x474 yp+1 w50 h23 vsetupBasePressureRLEdit").OnEvent("Change", updateSetup)
		centerGui.Add("Edit", "xp+52 yp w50 h23 vsetupBasePressureRREdit").OnEvent("Change", updateSetup)
		centerGui.Add("Text", "xp+52 yp+3 w30 h20", getUnit("Pressure"))

		centerGui.Add("Text", "x378 yp+20 w90 h23 +0x200", translate("Notes"))
		centerGui.Add("Edit", "x474 yp+1 w126 h46 vsetupNotesEdit").OnEvent("Change", updateSetup)

		centerGui.Add("Button", "x474 yp+50 w23 h23 Center +0x200 vloadSetupButton").OnEvent("Click", loadSetup)
		setButtonIcon(centerGui["loadSetupButton"], kIconsDirectory . "Database.ico", 1, "L4 T4 R4 B4")

		centerGui.Add("Button", "x525 yp w23 h23 Center +0x200 vaddSetupButton").OnEvent("Click", addSetup)
		setButtonIcon(centerGui["addSetupButton"], kIconsDirectory . "Plus.ico", 1, "L4 T4 R4 B4")
		centerGui.Add("Button", "x550 yp w23 h23 Center +0x200 vcopySetupButton").OnEvent("Click", copySetup)
		setButtonIcon(centerGui["copySetupButton"], kIconsDirectory . "Copy.ico", 1, "L4 T4 R4 B4")
		centerGui.Add("Button", "x575 yp w23 h23 Center +0x200 vdeleteSetupButton").OnEvent("Click", deleteSetup)
		setButtonIcon(centerGui["deleteSetupButton"], kIconsDirectory . "Minus.ico", 1, "L4 T4 R4 B4")

		centerGui.Add("Button", "x378 ys+279 w160", translate("Save Setups")).OnEvent("Click", releaseSetups)
		centerGui.Add("Button", "x553 yp w23 h23 Center +0x200 vuploadSetupsButton").OnEvent("Click", uploadSetups)
		setButtonIcon(centerGui["uploadSetupsButton"], kIconsDirectory . "Upload.ico", 1, "L4 T4 R4 B4")
		centerGui.Add("Button", "xp+24 yp w23 h23 Center +0x200 vdownloadSetupsButton").OnEvent("Click", downloadSetups)
		setButtonIcon(centerGui["downloadSetupsButton"], kIconsDirectory . "Download.ico", 1, "L4 T4 R4 B4")

		centerTab.UseTab(6)

		centerGui.Add("Text", "x24 ys+36 w85 h20", translate("Lap"))
		centerGui.Add("Edit", "x106 yp-2 w50 h20 Limit3 Number vpitstopLapEdit")
		centerGui.Add("UpDown", "x138 yp-2 w18 h20 Range1-999")

		centerGui.Add("Button", "x240 yp w23 h23 Center +0x200 vpitstopSettingsButton").OnEvent("Click", pitstopSettings.Bind(centerGui))
		setButtonIcon(centerGui["pitstopSettingsButton"], kIconsDirectory . "Tools BW.ico", 1, "")

		centerGui.Add("Text", "x24 yp+30 w80 h23 +0x200", translate("Driver"))
		centerGui.Add("DropDownList", "x106 yp w157 vpitstopDriverDropDownMenu")

		centerGui.Add("Text", "x24 yp+30 w85 h20", translate("Refuel"))
		centerGui.Add("Edit", "x106 yp-2 w50 h20 Limit3 Number vpitstopRefuelEdit")
		centerGui.Add("UpDown", "x138 yp-2 w18 h20 Range0-999")
		centerGui.Add("Text", "x164 yp+2 w80 h20", getUnit("Volume", true))

		centerGui.Add("Text", "x24 yp+24 w85 h23 +0x200", translate("Tyre Change"))

		choices := collect(["No Tyre Change", normalizeCompound("Dry")], translate)

		centerGui.Add("DropDownList", "x106 yp w133 Choose1 vpitstopTyreCompoundDropDown", choices).OnEvent("Change", updateState)

		centerGui.Add("Button", "x240 yp w23 h23 Center +0x200 vcopyPressuresButton").OnEvent("Click", copyPressures)
		setButtonIcon(centerGui["copyPressuresButton"], kIconsDirectory . "Copy.ico", 1, "")

		centerGui.Add("Text", "x24 yp+26 w85 h20", translate("Tyre Set"))
		centerGui.Add("Edit", "x106 yp-2 w50 h20 Limit2 Number vpitstopTyreSetEdit")
		centerGui.Add("UpDown", "x138 yp w18 h20 Range0-99")

		centerGui.Add("Text", "x24 yp+24 w85 h20", translate("Pressures"))

		centerGui.Add("Edit", "x106 yp-2 w50 h20 Limit4 vpitstopPressureFLEdit").OnEvent("Change", validateNumber.Bind("pitstopPressureFLEdit"))
		centerGui.Add("Edit", "x160 yp w50 h20 Limit4 vpitstopPressureFREdit").OnEvent("Change", validateNumber.Bind("pitstopPressureFREdit"))
		centerGui.Add("Text", "x214 yp+2 w30 h20", getUnit("Pressure"))
		centerGui.Add("Edit", "x106 yp+20 w50 h20 Limit4 vpitstopPressureRLEdit").OnEvent("Change", validateNumber.Bind("pitstopPressureRLEdit"))
		centerGui.Add("Edit", "x160 yp w50 h20 Limit4 vpitstopPressureRREdit").OnEvent("Change", validateNumber.Bind("pitstopPressureRREdit"))
		centerGui.Add("Text", "x214 yp+2 w30 h20", getUnit("Pressure"))

		centerGui.Add("Text", "x24 yp+24 w85 h23 +0x200", translate("Repairs"))

		choices := collect(["No Repairs", "Bodywork & Aerodynamics", "Suspension & Chassis", "Engine", "Everything"], translate)

		centerGui.Add("DropDownList", "x106 yp w157 Choose5 vpitstopRepairsDropDown", choices)

		centerGui.Add("Button", "x66 ys+279 w160 Y:Move(0.8)", translate("Instruct Engineer")).OnEvent("Click", planPitstop)

		this.iPitstopsListView := centerGui.Add("ListView", "x270 ys+34 w331 h269 H:Grow(0.8) -Multi -LV0x10 AltSubmit Checked NoSort NoSortHdr", collect(["#", "Lap", "Driver", "Refuel", "Compound", "Set", "Pressures", "Repairs"], translate))
		this.iPitstopsListView.OnEvent("Click", choosePitstop)

		centerGui.Rules := ""

		this.iReportViewer := RaceReportViewer(centerGui, this.ChartViewer)

		centerGui.Add(RaceCenter.RaceCenterResizer(centerGui))
	}

	show() {
		local window := this.Window
		local x, y, w, h

		if getWindowPosition("Race Center", &x, &y)
			window.Show("AutoSize x" . x . " y" . y)
		else
			window.Show("AutoSize")

		if getWindowSize("Race Center", &w, &h)
			window.Resize("Initialize", w, h)

		this.startWorking(false)

		this.showDetails(false, false)
		this.showChart(false)

		this.initializeSession()

		this.updateState()
	}

	showMessage(message, prefix := false) {
		if !prefix
			prefix := translate("Task: ")

		this.Control["messageField"].Text := ((message && (message != "")) ? (translate(prefix) . message) : "")
	}

	connect(silent := false) {
		connectAsync(silent) {
			local window := this.Window
			local token, connection, serverURLs, settings, chosen

			if (!silent && GetKeyState("Ctrl", "P")) {
				window.Opt("+Disabled")

				try {
					token := loginDialog(this.Connector, this.ServerURL, window)

					if token {
						this.iServerToken := ((token = "") ? RaceCenter.kInvalidToken : token)

						window["serverTokenEdit"].Text := token
					}
					else
						return
				}
				finally {
					window.Opt("-Disabled")
				}
			}

			this.iSyncTask.pause()

			try {
				if (!this.ServerToken || (this.ServerToken = ""))
					throw "Invalid token detected..."

				this.Connector.Initialize(this.ServerURL, this.ServerToken)

				this.iConnection := true

				this.loadTeams()

				connection := this.Connector.Connect(this.ServerToken, SessionDatabase.ID, SessionDatabase.getUserName(), "Internal", this.SelectedSession[true])

				if connection {
					this.iConnection := connection

					settings := readMultiMap(kUserConfigDirectory . "Application Settings.ini")

					serverURLs := string2Values(";", getMultiMapValue(settings, "Team Server", "Server URLs", ""))

					if !inList(serverURLs, this.ServerURL) {
						serverURLs.Push(this.ServerURL)

						setMultiMapValue(settings, "Team Server", "Server URLs", values2String(";", serverURLs*))

						writeMultiMap(kUserConfigDirectory . "Application Settings.ini", settings)

						window["serverURLEdit"].Delete()
						window["serverURLEdit"].Add(serverURLs)
						window["serverURLEdit"].Choose(inList(serverURLs, this.ServerURL))
					}

					showMessage(translate("Successfully connected to the Team Server."))

					this.iSyncTask.resume()
				}
				else
					throw "Cannot connect to Team Server..."
			}
			catch Any as exception {
				this.iServerToken := RaceCenter.kInvalidToken
				this.iConnection := false

				window["serverTokenEdit"].Text := ""

				if !silent {
					OnMessage(0x44, translateOkButton)
					MsgBox((translate("Cannot connect to the Team Server.") . "`n`n" . translate("Error: ") . exception.Message), translate("Error"), 262160)
					OnMessage(0x44, translateOkButton, 0)
				}

				this.loadTeams()
			}
		}

		this.pushTask(connectAsync.Bind(silent))
	}

	keepAlive() {
		local connection := this.Connection

		if connection
			this.Connector.KeepAlive(connection)
	}

	loadTeams() {
		local teams := (this.Connected ? loadTeams(this.Connector) : Map())
		local names := getKeys(teams)
		local identifiers := getValues(teams)
		local chosen

		this.iTeams := teams

		this.Control["teamDropDownMenu"].Delete()
		this.Control["teamDropDownMenu"].Add(names)

		chosen := inList(identifiers, this.SelectedTeam[true])

		if ((chosen == 0) && (names.Length > 0))
			chosen := 1

		this.selectTeam((chosen == 0) ? false : identifiers[chosen])
	}

	selectTeam(identifier) {
		local chosen, names

		chosen := inList(getValues(this.Teams), identifier)

		this.Control["teamDropDownMenu"].Choose(chosen)

		names := getKeys(this.Teams)

		if (chosen > 0) {
			this.iTeamName := names[chosen]
			this.iTeamIdentifier := identifier
		}
		else {
			this.iTeamName := ""
			this.iTeamIdentifier := false
		}

		this.loadSessions()
	}

	loadSessions() {
		local teamIdentifier, sessions, names, identifiers, chosen

		teamIdentifier := this.SelectedTeam[true]

		sessions := ((this.Connected && teamIdentifier) ? loadSessions(this.Connector, teamIdentifier) : Map())

		this.iSessions := sessions

		names := getKeys(sessions)
		identifiers := getValues(sessions)

		this.Control["sessionDropDownMenu"].Delete()
		this.Control["sessionDropDownMenu"].Add(names)

		chosen := inList(identifiers, this.SelectedSession[true])

		if ((chosen == 0) && (names.Length > 0))
			chosen := 1

		this.selectSession((chosen == 0) ? false : identifiers[chosen])
	}

	loadSessionDrivers() {
		local teamIdentifier, drivers, session, selectedDrivers, ignore, driver, name, names

		if this.SessionActive {
			teamIdentifier := this.SelectedTeam[true]

			drivers := ((this.Connected && teamIdentifier) ? loadDrivers(this.Connector, teamIdentifier) : Map())

			session := this.SelectedSession[true]
		}
		else {
			drivers := CaseInsenseMap()

			for ignore, driver in this.Drivers {
				name := computeDriverName(driver.Forname, driver.Surname, driver.Nickname)

				drivers[name] := false
			}
		}

		this.iSessionDrivers := drivers

		names := getKeys(drivers)

		this.Control["setupDriverDropDownMenu"].Delete()
		this.Control["setupDriverDropDownMenu"].Add(names)
		this.Control["planDriverDropDownMenu"].Delete()
		this.Control["planDriverDropDownMenu"].Add(concatenate([translate("-")], names))
	}

	selectSession(identifier) {
		local chosen, names, sessionDB

		this.iSyncTask.pause()

		chosen := inList(getValues(this.Sessions), identifier)

		this.Control["sessionDropDownMenu"].Choose(chosen)

		names := getKeys(this.Sessions)

		if (chosen > 0) {
			this.iSessionName := names[chosen]
			this.iSessionIdentifier := identifier

			this.iConnection := this.Connector.Connect(this.ServerToken, SessionDatabase.ID, SessionDatabase.getUserName(), "Internal", identifier)
		}
		else {
			this.iSessionName := ""
			this.iSessionIdentifier := false

			this.iConnection := false
		}

		this.initializeSession()
		this.loadSessionDrivers()

		this.iSyncTask.resume()
	}

	selectDriver(driver, force := false) {
		if (force || (this.SelectedDrivers && !inList(this.SelectedDrivers, driver))
				  || (!this.SelectedDrivers && ((driver != true) && (driver != false)))) {
			if driver {
				this.Control["driverDropDown"].Choose(((driver = true) || (driver = false)) ? 1 : (inList(this.AvailableDrivers, driver) + 1))

				this.iSelectedDrivers := ((driver == true) ? false : [driver])
			}
			else {
				this.Control["driverDropDown"].Choose(0)

				this.iSelectedDrivers := false
			}

			this.updateReports()
		}
	}

	createDriver(driver) {
		local ignore, candidate, found

		if !driver.HasProp("Identifier")
			driver.Identifier := false

		if !driver.HasProp("Nr")
			driver.Nr := false

		if !driver.HasProp("ID")
			driver.ID := false

		for ignore, candidate in this.Drivers {
			found := false

			if (this.SessionActive && (candidate.Identifier == driver.Identifier))
				found := candidate
			else if ((candidate.Forname = driver.Forname) && (candidate.Surname = driver.Surname))
				found := candidate

			if found {
				if driver.ID {
					found.ID := driver.ID

					if !inList(this.iAvailableDrivers, driver.ID)
						this.iAvailableDrivers.Push(driver.ID)

					if this.Simulator
						SessionDatabase.registerDriver(this.Simulator, driver.ID, found.FullName)
				}

				return found
			}
		}

		driver.FullName := computeDriverName(driver.Forname, driver.Surname, driver.Nickname)
		driver.Laps := []
		driver.Stints := []
		driver.Accidents := 0
		driver.Penalties := 0

		if driver.ID {
			if !inList(this.iAvailableDrivers, driver.ID)
				this.iAvailableDrivers.Push(driver.ID)

			if this.Simulator
				SessionDatabase.registerDriver(this.Simulator, driver.ID, driver.FullName)
		}

		this.Drivers.Push(driver)

		return driver
	}

	getClasses(data) {
		local classes := CaseInsenseMap()
		local class

		loop getMultiMapValue(data, "Position Data", "Car.Count") {
			class := this.getClass(data, A_Index)

			if !classes.Has(class)
				classes[class] := true
		}

		return getKeys(classes)
	}

	getClass(data, car := false) {
		local categories := (this.ReportViewer.Settings.Has("CarCategories") ? this.ReportViewer.Settings["CarCategories"] : ["Class"])
		local carClass, carCategory

		if !car
			car := getMultiMapValue(data, "Position Data", "Driver.Car")

		if inList(categories, "Class") {
			carClass := getMultiMapValue(data, "Position Data", "Car." . car . ".Class", kUnknown)

			if inList(categories, "Cup") {
				carCategory := getMultiMapValue(data, "Position Data", "Car." . car . ".Category", kUndefined)

				return ((carCategory != kUndefined) ? (carClass . translate(" (") . carCategory . translate(")")) : carClass)
			}
			else
				return carClass
		}
		else
			return getMultiMapValue(data, "Position Data", "Car." . car . ".Category", kUnknown)
	}

	getCars(data, class := "Overall", sorted := false) {
		local classGrid := []
		local positions, ignore, position

		compareClassPositions(c1, c2) {
			local pos1 := c1[2]
			local pos2 := c2[2]

			if !isNumber(pos1)
				pos1 := 999

			if !isNumber(pos2)
				pos2 := 999

			return (pos1 > pos2)
		}

		if (class = "Class")
			class := this.getClass(data)
		else if (class = "Overall")
			class := false

		if sorted {
			positions := []

			loop getMultiMapValue(data, "Position Data", "Car.Count")
				if (!class || (class = this.getClass(data, A_Index)))
					positions.Push(Array(A_Index, getMultiMapValue(data, "Position Data", "Car." . A_Index . ".Position")))

			bubbleSort(&positions, compareClassPositions)

			for ignore, position in positions
				classGrid.Push(position[1])
		}
		else
			loop getMultiMapValue(data, "Position Data", "Car.Count")
				if (!class || (class = this.getClass(data, A_Index)))
					classGrid.Push(A_Index)

		return classGrid
	}

	getPosition(data, type := "Overall", car := false) {
		local position, candidate

		if !car
			if (type = "Overall")
				return getMultiMapValue(data, "Position Data", "Car." . getMultiMapValue(data, "Position Data", "Driver.Car") . ".Position", false)
			else
				car := getMultiMapValue(data, "Position Data", "Driver.Car")

		if (type != "Overall")
			for position, candidate in this.getCars(data, this.getClass(data, car), true)
				if (candidate = car)
					return position

		return getMultiMapValue(data, "Position Data", "Car." . car . ".Position", false)
	}

	updateState() {
		local window := this.Window
		local selected, stint, hasPitstops

		if (window["pitstopTyreCompoundDropDown"].Value > 1) {
			window["pitstopTyreSetEdit"].Enabled := true
			window["pitstopPressureFLEdit"].Enabled := true
			window["pitstopPressureFREdit"].Enabled := true
			window["pitstopPressureRLEdit"].Enabled := true
			window["pitstopPressureRREdit"].Enabled := true
		}
		else {
			window["pitstopTyreSetEdit"].Enabled := false
			window["pitstopPressureFLEdit"].Enabled := false
			window["pitstopPressureFREdit"].Enabled := false
			window["pitstopPressureRLEdit"].Enabled := false
			window["pitstopPressureRREdit"].Enabled := false
		}

		window["driverDropDown"].Enabled := false

		window["dataXDropDown"].Enabled := false
		window["dataY1DropDown"].Enabled := false
		window["dataY2DropDown"].Enabled := false
		window["dataY3DropDown"].Enabled := false
		window["dataY4DropDown"].Enabled := false
		window["dataY5DropDown"].Enabled := false
		window["dataY6DropDown"].Enabled := false

		if this.HasData {
			if inList(["Overview", "Drivers", "Positions", "Lap Times", "Performance", "Consistency", "Pace", "Pressures", "Brakes", "Temperatures", "Free"], this.SelectedReport)
				window["reportSettingsButton"].Enabled := true
			else
				window["reportSettingsButton"].Enabled := false

			if inList(["Pressures", "Brakes", "Temperatures", "Free"], this.SelectedReport) {
				window["chartTypeDropDown"].Enabled := true

				window["driverDropDown"].Enabled := true

				window["dataXDropDown"].Enabled := true
				window["dataY1DropDown"].Enabled := true
				window["dataY2DropDown"].Enabled := true
				window["dataY3DropDown"].Enabled := true

				if (this.SelectedChartType != "Bubble") {
					window["dataY4DropDown"].Enabled := true
					window["dataY5DropDown"].Enabled := true
					window["dataY6DropDown"].Enabled := true
				}
			}
			else {
				window["chartTypeDropDown"].Enabled := false
				window["chartTypeDropDown"].Choose(0)

				this.iSelectedChartType := false

				window["driverDropDown"].Choose(0)

				window["dataXDropDown"].Choose(0)
				window["dataY1DropDown"].Choose(0)
				window["dataY2DropDown"].Choose(0)
				window["dataY3DropDown"].Choose(0)
				window["dataY4DropDown"].Choose(0)
				window["dataY5DropDown"].Choose(0)
				window["dataY6DropDown"].Choose(0)
			}
		}
		else {
			window["reportSettingsButton"].Enabled := false

			window["driverDropDown"].Choose(0)

			window["dataXDropDown"].Choose(0)
			window["dataY1DropDown"].Choose(0)
			window["dataY2DropDown"].Choose(0)
			window["dataY3DropDown"].Choose(0)
			window["dataY4DropDown"].Choose(0)
			window["dataY5DropDown"].Choose(0)
			window["dataY6DropDown"].Choose(0)

			window["chartTypeDropDown"].Enabled := false
			window["chartTypeDropDown"].Choose(0)

			this.iSelectedChartType := false
		}

		this.updateSessionMenu()
		this.updatePlanMenu()
		this.updateStrategyMenu()
		this.updatePitstopMenu()

		hasPitstops := false

		loop this.PitstopsListView.GetCount() {
			hasPitstops := this.PitstopsListView.GetText(A_Index, 5)

			if (hasPitstops && (hasPitstops != "-"))
				break
			else
				hasPitstops := false
		}

		if (hasPitstops || this.SetupsListView.GetCount())
			window["copyPressuresButton"].Enabled := true
		else
			window["copyPressuresButton"].Enabled := false

		selected := this.SetupsListView.GetNext(0)

		if (selected != this.SelectedSetup) {
			this.iSelectedSetup := false

			selected := false

			this.SetupsListView.Modify(selected, "-Select")
		}

		if this.SetupsListView.GetCount()
			window["downloadSetupsButton"].Enabled := true
		else
			window["downloadSetupsButton"].Enabled := false

		if selected {
			window["setupDriverDropDownMenu"].Enabled := true
			window["setupWeatherDropDownMenu"].Enabled := true
			window["setupAirTemperatureEdit"].Enabled := true
			window["setupTrackTemperatureEdit"].Enabled := true
			window["setupCompoundDropDownMenu"].Enabled := true
			window["setupBasePressureFLEdit"].Enabled := true
			window["setupBasePressureFREdit"].Enabled := true
			window["setupBasePressureRLEdit"].Enabled := true
			window["setupBasePressureRREdit"].Enabled := true
			window["setupNotesEdit"].Enabled := true

			window["loadSetupButton"].Enabled := true
			window["copySetupButton"].Enabled := true
			window["deleteSetupButton"].Enabled := true

			stint := this.SetupsListView.GetText(selected, 1)
		}
		else {
			window["setupDriverDropDownMenu"].Enabled := false
			window["setupWeatherDropDownMenu"].Enabled := false
			window["setupAirTemperatureEdit"].Enabled := false
			window["setupTrackTemperatureEdit"].Enabled := false
			window["setupCompoundDropDownMenu"].Enabled := false
			window["setupBasePressureFLEdit"].Enabled := false
			window["setupBasePressureFREdit"].Enabled := false
			window["setupBasePressureRLEdit"].Enabled := false
			window["setupBasePressureRREdit"].Enabled := false
			window["setupNotesEdit"].Enabled := false

			window["loadSetupButton"].Enabled := false
			window["copySetupButton"].Enabled := false
			window["deleteSetupButton"].Enabled := false

			window["setupDriverDropDownMenu"].Choose(0)
			window["setupWeatherDropDownMenu"].Choose(0)
			window["setupCompoundDropDownMenu"].Choose(0)
			window["setupAirTemperatureEdit"].Text := ""
			window["setupTrackTemperatureEdit"].Text := ""
			window["setupBasePressureFLEdit"].Text := ""
			window["setupBasePressureFREdit"].Text := ""
			window["setupBasePressureRLEdit"].Text := ""
			window["setupBasePressureRREdit"].Text := ""
			window["setupNotesEdit"].Text := ""
		}

		selected := this.PlanListView.GetNext(0)

		if (selected && (selected != this.SelectedPlanStint)) {
			this.iSelectedPlanStint := false

			selected := false

			this.PlanListView.Modify(selected, "-Select")
		}

		if selected {
			window["planDriverDropDownMenu"].Enabled := true
			window["planTimeEdit"].Enabled := true
			window["actTimeEdit"].Enabled := true
			window["deletePlanButton"].Enabled := true

			stint := this.PlanListView.GetText(selected, 1)

			if (stint = 1) {
				window["planLapEdit"].Enabled := false
				window["actLapEdit"].Enabled := false
				window["planRefuelEdit"].Enabled := false
				window["planTyreCompoundDropDown"].Enabled := false

				window["planLapEdit"].Text := ""
				window["actLapEdit"].Text := ""
				window["planRefuelEdit"].Text := ""
				window["planTyreCompoundDropDown"].Choose(0)
			}
			else {
				window["planLapEdit"].Enabled := true
				window["actLapEdit"].Enabled := true
				window["planRefuelEdit"].Enabled := true
				window["planTyreCompoundDropDown"].Enabled := true
			}
		}
		else {
			window["planDriverDropDownMenu"].Enabled := false
			window["planTimeEdit"].Enabled := false
			window["actTimeEdit"].Enabled := false
			window["planLapEdit"].Enabled := false
			window["actLapEdit"].Enabled := false
			window["planRefuelEdit"].Enabled := false
			window["planTyreCompoundDropDown"].Enabled := false
			window["deletePlanButton"].Enabled := false

			window["planDriverDropDownMenu"].Choose(0)
			window["planTimeEdit"].Value := "20200101000000"
			window["actTimeEdit"].Value := "20200101000000"
			window["planLapEdit"].Text := ""
			window["actLapEdit"].Text := ""
			window["planRefuelEdit"].Text := ""
			window["planTyreCompoundDropDown"].Choose(0)
		}

		if this.UseTraffic {
			window["numScenariosEdit"].Enabled := true
			window["variationWindowEdit"].Enabled := true

			window["lapTimeVariationDropDown"].Enabled := true
			window["driverErrorsDropDown"].Enabled := true
			window["pitstopsDropDown"].Enabled := true
			window["overtakeDeltaEdit"].Enabled := true
			window["trafficConsideredEdit"].Enabled := true
		}
		else {
			window["numScenariosEdit"].Enabled := false
			window["variationWindowEdit"].Enabled := false

			window["lapTimeVariationDropDown"].Enabled := false
			window["driverErrorsDropDown"].Enabled := false
			window["pitstopsDropDown"].Enabled := false
			window["overtakeDeltaEdit"].Enabled := false
			window["trafficConsideredEdit"].Enabled := false
		}

		if (this.SessionActive && this.LastLap && InStr(this.LastLap.Telemetry, "[Setup Data]"))
			window["pitstopSettingsButton"].Enabled := true
		else
			window["pitstopSettingsButton"].Enabled := false
	}

	updateSessionMenu() {
		local synchronize

		synchronize := (this.Synchronize ? "(x) Synchronize" : "      Synchronize")

		this.Control["sessionMenuDropDown"].Delete()
		this.Control["sessionMenuDropDown"].Add(collect(["Session", "---------------------------------------------", "Connect", "Clear...", "---------------------------------------------", synchronize, "---------------------------------------------", "Select Team...", "---------------------------------------------", "Load Session...", "Save Session", "Save a Copy...", "---------------------------------------------", "Update Statistics", "---------------------------------------------", "Race Summary", "Driver Statistics"], translate))

		this.Control["sessionMenuDropDown"].Choose(1)
	}

	updatePlanMenu() {
		this.Control["planMenuDropDown"].Choose(1)
	}

	updateStrategyMenu() {
		local use1, use2, use3, use4


		use1 := (this.UseSessionData ? "(x) Use Session Data" : "      Use Session Data")
		use2 := (this.UseTelemetryDatabase ? "(x) Use Telemetry Database" : "      Use Telemetry Database")
		use3 := (this.UseCurrentMap ? "(x) Keep current Map" : "      Keep current Map")
		use4 := (this.UseTraffic ? "(x) Analyze Traffic" : "      Analyze Traffic")

		this.Control["strategyMenuDropDown"].Delete()
		this.Control["strategyMenuDropDown"].Add(collect(["Strategy", "---------------------------------------------", "Load current Race Strategy", "Load Strategy...", "Save Strategy...", "---------------------------------------------", "Strategy Summary", "---------------------------------------------", use1, use2, use3, use4, "---------------------------------------------", "Adjust Strategy (Simulation)", "---------------------------------------------", "Release Strategy", "Discard Strategy", "---------------------------------------------", "Instruct Strategist"], translate))

		this.Control["strategyMenuDropDown"].Choose(1)

		this.Control["useSessionDataDropDown"].Choose(this.UseSessionData ? 1 : 2)
		this.Control["useTelemetryDataDropDown"].Choose(this.UseTelemetryDatabase ? 1 : 2)
		this.Control["keepMapDropDown"].Choose(this.UseCurrentMap ? 1 : 2)
		this.Control["considerTrafficDropDown"].Choose(this.UseTraffic ? 1 : 2)
	}

	updatePitstopMenu() {
		local correct1, correct2, correct3

		correct1 := ((this.TyrePressureMode = "Reference") ? "(x) Adjust Pressures (Reference)" : "      Adjust Pressures (Reference)")
		correct2 := ((this.TyrePressureMode = "Relative") ? "(x) Adjust Pressures (Relative)" : "      Adjust Pressures (Relative)")
		correct3 := (this.CorrectPressureLoss ? "(x) Correct pressure loss" : "      Correct pressure loss")

		this.Control["pitstopMenuDropDown"].Delete()
		this.Control["pitstopMenuDropDown"].Add(collect(["Pitstop", "---------------------------------------------", "Select Team...", "---------------------------------------------", "Initialize from Session", "Load from Database...", "Clear Setups...", "---------------------------------------------", "Setups Summary", "Pitstops Summary", "---------------------------------------------", correct1, correct2, correct3, "---------------------------------------------", "Instruct Engineer"], translate))

		this.Control["pitstopMenuDropDown"].Choose(1)
	}

	initializeSetup(tyreCompound, tyreCompoundColor, flPressure, frPressure, rlPressure, rrPressure) {
		local chosen, row

		row := this.SetupsListView.GetNext(0)

		if row {
			this.Control["setupBasePressureFLEdit"].Text := displayValue("Float", convertUnit("Pressure", flPressure))
			this.Control["setupBasePressureFREdit"].Text := displayValue("Float", convertUnit("Pressure", frPressure))
			this.Control["setupBasePressureRLEdit"].Text := displayValue("Float", convertUnit("Pressure", rlPressure))
			this.Control["setupBasePressureRREdit"].Text := displayValue("Float", convertUnit("Pressure", rrPressure))

			tyreCompound := compound(tyreCompound, tyreCompoundColor)

			chosen := inList(SessionDatabase().getTyreCompounds(this.Simulator, this.Car, this.Track), tyreCompound)

			if chosen
				this.Control["setupCompoundDropDownMenu"].Choose(chosen)

			this.SetupsListView.Modify(row, "Col3", translate(tyreCompound), values2String(", ", this.Control["setupBasePressureFLEdit"].Text
																							   , this.Control["setupBasePressureFREdit"].Text
																							   , this.Control["setupBasePressureRLEdit"].Text
																							   , this.Control["setupBasePressureRREdit"].Text))

			this.updateState()
		}
	}

	addSetup() {
		if (this.SessionDrivers.Count > 0) {
			this.Control["setupDriverDropDownMenu"].Choose(1)
			this.Control["setupCompoundDropDownMenu"].Choose((this.TyreCompounds.Length > 0) ? 1 : 0)

			this.Control["setupWeatherDropDownMenu"].Choose(inList(kWeatherConditions, "Dry"))
			this.Control["setupAirTemperatureEdit"].Text := displayValue("Float", convertUnit("Temperature", 23), 0)
			this.Control["setupTrackTemperatureEdit"].Text := displayValue("Float", convertUnit("Temperature", 27), 0)

			this.Control["setupBasePressureFLEdit"].Text := displayValue("Float", convertUnit("Pressure", 25.5))
			this.Control["setupBasePressureFREdit"].Text := displayValue("Float", convertUnit("Pressure", 25.5))
			this.Control["setupBasePressureRLEdit"].Text := displayValue("Float", convertUnit("Pressure", 25.5))
			this.Control["setupBasePressureRREdit"].Text := displayValue("Float", convertUnit("Pressure", 25.5))

			this.Control["setupNotesEdit"].Text := ""

			this.SetupsListView.Modify(this.SetupsListView.Add("", getKeys(this.SessionDrivers)[1]
																 , translate("Dry") . A_Space . translate("(") . this.Control["setupAirTemperatureEdit"].Text . ", "
																											   . this.Control["setupTrackTemperatureEdit"].Text . translate(")")
																 , translate(normalizeCompound("Dry"))
																 , values2String(", ", this.Control["setupBasePressureFLEdit"].Text, this.Control["setupBasePressureFREdit"].Text
																					 , this.Control["setupBasePressureRLEdit"].Text, this.Control["setupBasePressureRREdit"].Text)
																 , ""), "Select Vis")

			this.iSelectedSetup := this.SetupsListView.GetCount()

			this.SetupsListView.ModifyCol()

			loop this.SetupsListView.GetCount("Col")
				this.SetupsListView.ModifyCol(A_Index, "AutoHdr")

			if (this.SelectedDetailReport = "Setups")
				this.showSetupsDetails()
		}

		this.updateState()
	}

	copySetup() {
		local row := this.SetupsListView.GetNext(0)

		if row {
			this.SetupsListView.Modify(this.SetupsListView.Add("", this.SetupsListView.GetText(row, 1), this.SetupsListView.GetText(row, 2)
																 , this.SetupsListView.GetText(row, 3), this.SetupsListView.GetText(row, 4)
																 , this.SetupsListView.GetText(row, 5)), "Select Vis")

			this.iSelectedSetup := this.SetupsListView.GetCount()

			this.SetupsListView.ModifyCol()

			loop this.SetupsListView.GetCount("Col")
				this.SetupsListView.ModifyCol(A_Index, "AutoHdr")

			if (this.SelectedDetailReport = "Setups")
				this.showSetupsDetails()
		}

		this.updateState()
	}

	deleteSetup() {
		local selected := this.SetupsListView.GetNext(0)

		if (selected && (selected != this.SelectedSetup)) {
			loop this.SetupsListView.GetCount()
				this.SetupsListView.Modify(A_Index, "-Select")

			this.iSelectedSetup := false

			selected := false
		}

		if selected
			this.SetupsListView.Delete(selected)

		if (this.SelectedDetailReport = "Setups")
			this.showSetupsDetails()

		this.updateState()
	}

	importSetups(fileName, clear) {
		local directory, ignore, entry

		if clear
			this.SessionStore.clear("Setups.Data")

		directory := temporaryFileName("Setups", "data")

		try {
			DirCreate(directory)

			try {
				FileCopy(fileName, directory . "\Setups.Data.CSV")
			}
			catch Any as exception {
				logError(exception)
			}

			for ignore, entry in Database(directory . "\", kSessionDataSchemas).Tables["Setups.Data"] {
				if !inList(getKeys(this.SessionDrivers), entry["Driver"]) {
					entry.Clone()

					entry["Driver"] := "John Doe (JD)"
				}

				this.SessionStore.add("Setups.Data", entry)
			}

			this.loadSetups()
		}
		finally {
			deleteDirectory(directory)
		}
	}

	clearSetups(verbose := true) {
		local delete, msgResult

		if (this.SetupsListView.GetCount() > 0) {
			delete := false

			if verbose {
				OnMessage(0x44, translateYesNoButtons)
				msgResult := MsgBox(translate("Do you really want to delete all driver specific setups?"), translate("Delete"), 262436)
				OnMessage(0x44, translateYesNoButtons, 0)

				if (msgResult = "Yes")
					delete := true
			}
			else
				delete := true

			if delete {
				this.iSetupsVersion := (A_Now . "")

				this.SetupsListView.Delete()

				this.SessionStore.clear("Setups.Data")

				this.iSelectedSetup := false

				if (this.SelectedDetailReport = "Setups")
					this.showSetupsDetails()

				this.updateState()
			}
		}
	}

	releaseSetups(verbose := true) {
		local session, version, info, fileName, setups

		if this.SessionActive {
			try {
				session := this.SelectedSession[true]

				version := (A_Now . "")

				this.iSetupsVersion := version

				info := newMultiMap()

				setMultiMapValue(info, "Setups", "Version", version)

				this.saveSetups(true)

				fileName := (this.SessionDirectory . "Setups.Data.CSV")

				if FileExist(fileName)
					setups := FileRead(fileName)
				else
					setups := "CLEAR"

				this.Connector.setSessionValue(session, "Setups Info", printMultiMap(info))
				this.Connector.setSessionValue(session, "Setups", setups)
				this.Connector.setSessionValue(session, "Setups Version", version)

				if verbose
					showMessage(translate("Setups has been saved for this Session."))
			}
			catch Any as exception {
				logError(exception)
			}
		}
		else if verbose {
			OnMessage(0x44, translateOkButton)
			MsgBox(translate("You are not connected to an active session."), translate("Information"), 262192)
			OnMessage(0x44, translateOkButton, 0)
		}
	}

	getPlanDrivers() {
		local drivers := CaseInsenseWeakMap()
		local stint, driver

		loop this.PlanListView.GetCount() {
			stint := this.PlanListView.GetText(A_Index, 1)
			driver := this.PlanListView.GetText(A_Index, 2)

			drivers[stint] := driver
		}

		return drivers
	}

	updatePlanFromStrategy() {
		local pitstops, pitstop, numStints, time, currentTime, last, lastTime, msgResult, translator
		local driver, forName, surName, nickName, found, ignore, candidate
		local sForName, sSurName, sNickName

		if this.Strategy {
			loop this.PlanListView.GetCount()
				this.PlanListView.Modify(A_Index, "-Select")

			this.iSelectedPlanStint := false

			pitstops := CaseInsenseWeakMap()
			numStints := 1

			for ignore, pitstop in this.Strategy.Pitstops {
				pitstops[pitstop.Nr] := pitstop
				numStints := Max(numStints, pitstop.Nr + 1)
			}

			if (numStints < this.PlanListView.GetCount()) {
				translator := translateMsgBoxButtons.Bind(["Beginning", "End", "Cancel"])

				OnMessage(0x44, translator)
				msgResult := MsgBox(translate("The plan has more stints than the strategy. Do you want to remove surplus stints from the beginning or from the end of the plan?"), translate("Plan"), 262179)
				OnMessage(0x44, translator, 0)

				if (msgResult = "Cancel")
					return

				if (msgResult = "Yes") {
					while (this.PlanListView.GetCount() > numStints)
						this.PlanListView.Delete(1)

					if (this.PlanListView.GetCount() > 0)
						this.PlanListView.Modify(1, "Col5", "-", "-", "-", "-")
				}

				if (msgResult = "No")
					while (this.PlanListView.GetCount() > numStints)
						this.PlanListView.Delete(this.PlanListView.GetCount())
			}

			if (this.PlanListView.GetCount() < numStints) {
				if (this.PlanListView.GetCount() > 0) {
					OnMessage(0x44, translateOkButton)
					MsgBox(translate("The plan has less stints than the strategy. Additional stints will be added at the end of the plan."), translate("Information"), 262192)
					OnMessage(0x44, translateOkButton, 0)
				}

				while (this.PlanListView.GetCount() < numStints) {
					if (this.PlanListView.GetCount() == 0)
						last := 0
					else
						last := this.PlanListView.GetText(this.PlanListView.GetCount(), 1)

					time := this.Time

					time := FormatTime(time, "HH:mm")

					if (last = 0)
						this.PlanListView.Add("", 1, "", time, "", "-", "-", "-", "-")
					else
						this.PlanListView.Add("", last + 1, "", time, "", "", "", "", "")
				}
			}

			if (this.PlanListView.GetCount() > 0) {
				time := this.PlanListView.GetText(1, 3)

				time := string2Values(":", time)

				currentTime := "20200101000000"

				if (time.Length = 2) {
					currentTime := DateAdd(currentTime, time[1], "Hours")
					currentTime := DateAdd(currentTime, time[2], "Minutes")
				}
			}

			lastTime := 0

			loop this.PlanListView.GetCount() {
				if ((A_Index > 1) && !pitstops.Has(A_Index - 1))
					continue
				else if ((A_Index = 1) && (pitstops.Count > 0) && !pitstops.Has(1))
					continue

				driver := ((A_Index = 1) ? this.Strategy.DriverName : pitstops[A_Index - 1].DriverName)

				forName := false
				surName := false
				nickName := false

				parseDriverName(driver, &forName, &surName, &nickName)

				found := false

				for ignore, candidate in getKeys(this.SessionDrivers) {
					sForName := false
					sSurName := false
					sNickName := false

					parseDriverName(candidate, &sForName, &sSurName, &sNickName)

					if ((sForName = forName) && (sSurName = surName)) {
						found := true
						driver := candidate

						break
					}
				}

				if !found
					driver := "-"

				this.PlanListView.Modify(A_Index, "Col2", driver)

				if ((A_Index > 1) && pitstops.Has(A_Index - 1)) {
					pitstop := pitstops[A_Index - 1]

					time := pitstop.Time
					time -= lastTime

					lastTime := pitstop.Time

					currentTime := DateAdd(currentTime, time, "Seconds")
					time := FormatTime(currentTime, "HH:mm")

					this.PlanListView.Modify(A_Index, "Col3", time)
					this.PlanListView.Modify(A_Index, "Col5", pitstop.Lap)
					this.PlanListView.Modify(A_Index, "Col7", (pitstop.RefuelAmount == 0) ? "-" : displayValue("Float", convertUnit("Volume", pitstop.RefuelAmount), 0))
					this.PlanListView.Modify(A_Index, "Col8", pitstop.TyreChange ? "x" : "")
				}
			}

			this.PlanListView.ModifyCol()

			loop 8
				this.PlanListView.ModifyCol(A_Index, "AutoHdr")

			if (this.SelectedDetailReport = "Plan")
				this.showPlanDetails()

			this.updateState()
		}
	}

	clearPlan(verbose := true) {
		local delete, msgResult

		if (this.PlanListView.GetCount() > 0) {
			delete := false

			if verbose {
				OnMessage(0x44, translateYesNoButtons)
				msgResult := MsgBox(translate("Do you really want to delete the current plan?"), translate("Delete"), 262436)
				OnMessage(0x44, translateYesNoButtons, 0)

				if (msgResult = "Yes")
					delete := true
			}
			else
				delete := true

			if delete {
				this.iPlanVersion := (A_Now . "")

				this.PlanListView.Delete()

				this.iSelectedPlanStint := false

				if (this.SelectedDetailReport = "Plan")
					this.showPlanDetails()

				this.updateState()
			}
		}
	}

	updatePlan(minutesOrStint) {
		local time, stintNr

		loop this.PlanListView.GetCount()
			this.PlanListView.Modify(A_Index, "-Select")

		this.iSelectedPlanStint := false

		if isObject(minutesOrStint) {
			if (this.PlanListView.GetCount() > 0) {
				time := this.computeStartTime(minutesOrStint)

				time := FormatTime(time, "HH:mm")

				loop this.PlanListView.GetCount() {
					stintNr := this.PlanListView.GetText(A_Index, 1)

					if (stintNr = minutesOrStint.Nr) {
						this.PlanListView.Modify(A_Index, "Col2", minutesOrStint.Driver.FullName)
						this.PlanListView.Modify(A_Index, "Col4", time)

						if (stintNr != 1)
							this.PlanListView.Modify(A_Index, "Col6", minutesOrStint.Lap)
					}
				}
			}
		}
		else
			loop this.PlanListView.GetCount() {
				time := this.PlanListView.GetText(A_Index, 3)

				time := string2Values(":", time)
				time := ("20200101" . time[1] . time[2] . "00")

				time := DateAdd(time, minutesOrStint, "Minutes")
				time := FormatTime(time, "HH:mm")

				this.PlanListView.Modify(A_Index, "Col3", time)
			}

		if (this.SelectedDetailReport = "Plan")
			this.showPlanDetails()

		this.updateState()
	}

	addPlan(position := "After") {
		local selected, stintNr, initial

		selected := this.PlanListView.GetNext(0)

		if (selected && (selected != this.SelectedPlanStint)) {
			loop this.PlanListView.GetCount()
				this.PlanListView.Modify(A_Index, "-Select")

			this.iSelectedPlanStint := false

			selected := false
		}

		if selected {
			position := ((position = "After") ? selected + 1 : selected)

			if (position > this.PlanListView.GetCount())
				position := false
		}
		else
			position := false

		if position
			stintNr := this.PlanListView.GetText(position, 1)
		else {
			if (this.PlanListView.GetCount() > 0) {
				stintNr := this.PlanListView.GetText(this.PlanListView.GetCount(), 1)

				stintNr += 1
			}
			else
				stintNr := 1
		}

		initial := ((stintNr = 1) ? "-" : "")

		if position {
			this.iSelectedPlanStint := position

			this.PlanListView.Insert(position, "", stintNr, "", "", "", initial, initial, initial, initial)
			this.PlanListView.Modify(position, "Select Vis")
		}
		else {
			this.iSelectedPlanStint := (this.PlanListView.GetCount() + 1)

			this.PlanListView.Modify(this.PlanListView.Add("", stintNr, "", "", "", initial, initial, initial, initial), "Select Vis")
		}

		this.Control["planDriverDropDownMenu"].Choose(1)
		this.Control["planTimeEdit"].Value := "20200101000000"
		this.Control["actTimeEdit"].Value := "20200101000000"
		this.Control["planLapEdit"].Text := ""
		this.Control["actLapEdit"].Text := ""
		this.Control["planRefuelEdit"].Text := 0
		this.Control["planTyreCompoundDropDown"].Choose(2)

		stintNr := this.PlanListView.GetText(1, 1)

		loop this.PlanListView.GetCount()
			this.PlanListView.Modify(A_Index, "", stintNr++)

		if (this.SelectedDetailReport = "Plan")
			this.showPlanDetails()

		this.updateState()
	}

	deletePlan() {
		local selected, stintNr

		selected := this.PlanListView.GetNext(0)

		if (selected && (selected != this.SelectedPlanStint)) {
			loop this.PlanListView.GetCount()
				this.PlanListView.Modify(A_Index, "-Select")

			this.iSelectedPlanStint := false

			selected := false
		}

		if selected {
			stintNr := this.PlanListView.GetText(selected, 1)

			this.PlanListView.Delete(selected)

			if (selected <= this.PlanListView.GetCount())
				loop this.PlanListView.GetCount()
					this.PlanListView.Modify(A_Index, "", stintNr++)
		}

		if (this.SelectedDetailReport = "Plan")
			this.showPlanDetails()

		this.updateState()
	}

	releasePlan(verbose := true) {
		local session, version, info, fileName, plan

		if this.SessionActive {
			try {
				session := this.SelectedSession[true]

				version := (A_Now . "")

				this.iPlanVersion := version

				info := newMultiMap()

				setMultiMapValue(info, "Plan", "Version", version)
				setMultiMapValue(info, "Plan", "Date", this.Date)
				setMultiMapValue(info, "Plan", "Time", this.Time)

				this.savePlan(true)

				fileName := (this.SessionDirectory . "Plan.Data.CSV")

				if FileExist(fileName)
					plan := FileRead(fileName)
				else
					plan := "CLEAR"

				this.Connector.setSessionValue(session, "Stint Plan Info", printMultiMap(info))
				this.Connector.setSessionValue(session, "Stint Plan", plan)
				this.Connector.setSessionValue(session, "Stint Plan Version", version)

				if verbose
					showMessage(translate("Plan has been saved for this Session."))
			}
			catch Any as exception {
				logError(exception)
			}
		}
		else if verbose {
			OnMessage(0x44, translateOkButton)
			MsgBox(translate("You are not connected to an active session."), translate("Information"), 262192)
			OnMessage(0x44, translateOkButton, 0)
		}
	}

	initializePitstopSettings(&lap, &refuel, &tyreCompound, &tyreCompoundColor) {
		local currentStint, nextStint, plannedLap, lastLap, refuelAmount, tyreChange, index, pitstop, stint

		currentStint := this.CurrentStint

		if currentStint {
			nextStint := (currentStint.Nr + 1)

			loop this.PlanListView.GetCount() {
				stint := this.PlanListView.GetText(A_Index, 1)

				if (stint = nextStint) {
					plannedLap := this.PlanListView.GetText(A_Index, 5)
					refuelAmount := this.PlanListView.GetText(A_Index, 7)
					tyreChange := this.PlanListView.GetText(A_Index, 8)

					lap := (isInteger(plannedLap) ? plannedLap : 0)

					if isNumber(internalValue("Float", refuelAmount))
						refuel := convertUnit("Volume", internalValue("Float", refuelAmount), false)
					else
						refuel := 0

					if (tyreChange != "x") {
						tyreCompound := false
						tyreCompoundColor := false
					}

					return
				}
			}

			if this.Strategy
				for index, pitstop in this.Strategy.Pitstops
					if (pitstop.Nr = currentStint.Nr) {
						lap := pitstop.Lap
						refuel := pitstop.RefuelAmount

						if !pitstop.TyreChange {
							tyreCompound := false
							tyreCompoundColor := false
						}

						return
					}

			lastLap := this.LastLap

			if lastLap {
				lap := (lastLap.Nr + 2)
				refuel := Round(this.CurrentStint.FuelConsumption + (lastLap.FuelConsumption * 2))
			}
		}
	}

	initializePitstopFromSession(targetLap := false, remote := false
							   , &pitStopLap := false, &pitstopDriver := false, &pitstopRefuel := false, &pitstopTyreSetup := false) {
		local stint := this.CurrentStint
		local drivers, index, key, pressuresDB, pressuresTable, last, pressures, coldPressures, pressuresLosses
		local lap, refuel, tyreCompound, tyreCompoundColor, flPressure, frPressure, rlPressure, rrPressure

		if stint {
			drivers := this.getPlanDrivers()

			if remote {
				if (drivers.Has(stint.Nr + 1) && inList(this.TeamDrivers, drivers[stint.Nr + 1]))
					pitstopDriver := drivers[stint.Nr + 1]
				else
					pitstopDriver := false
			}
			else
				if drivers.Has(stint.Nr + 1)
					this.Control["pitstopDriverDropDownMenu"].Choose(inList(this.TeamDrivers, drivers[stint.Nr + 1]) + 1)
				else
					this.Control["pitstopDriverDropDownMenu"].Choose(1)
		}

		pressuresDB := this.PressuresDatabase

		if pressuresDB {
			pressuresTable := pressuresDB.Database.Tables["Tyres.Pressures"]

			last := pressuresTable.Length

			if (last > 0) {
				pressures := pressuresTable[last]

				lap := targetLap
				refuel := 0
				tyreCompound := pressures["Compound"]
				tyreCompoundColor := pressures["Compound.Color"]

				if ((tyreCompound = "-") || (tyreCompoundColor = "-")) {
					tyreCompound := false
					tyreCompoundColor := false
				}

				this.initializePitstopSettings(&lap, &refuel, &tyreCompound, &tyreCompoundColor)

				if targetLap
					lap := targetLap

				if remote {
					pitstopLap := lap
					pitstopRefuel := refuel
				}
				else {
					this.Control["pitstopLapEdit"].Text := lap
					this.Control["pitstopRefuelEdit"].Text := displayValue("Float", convertValue("Volume", refuel), 0)
				}

				coldPressures := [displayNullValue(pressures["Tyre.Pressure.Cold.Front.Left"]), displayNullValue(pressures["Tyre.Pressure.Cold.Front.Right"])
								, displayNullValue(pressures["Tyre.Pressure.Cold.Rear.Left"]), displayNullValue(pressures["Tyre.Pressure.Cold.Rear.Right"])]

				if this.CorrectPressureLoss
					for index, key in ["Tyre.Pressure.Loss.Front.Left", "Tyre.Pressure.Loss.Front.Right"
									 , "Tyre.Pressure.Loss.Rear.Left", "Tyre.Pressure.Loss.Rear.Right"]
						if ((coldPressures[index] != "-") && !isNull(pressures[key]))
							coldPressures[index] -= pressures[key]

				flPressure := coldPressures[1]
				frPressure := coldPressures[2]
				rlPressure := coldPressures[3]
				rrPressure := coldPressures[4]

				this.initializePitstopTyreSetup(&tyreCompound, &tyreCompoundColor, &flPressure, &frPressure, &rlPressure, &rrPressure, remote)

				if remote
					pitstopTyreSetup := [tyreCompound, tyreCompoundColor, flPressure, frPressure, rlPressure, rrPressure]
			}
		}
	}

	getDriver(stintNr) {
		local stint, driver, ignore, candidate, forName, surName, nickName

		loop this.PlanListView.GetCount() {
			stint := this.PlanListView.GetText(A_Index, 1)

			if (stint = stintNr) {
				driver := this.PlanListView.GetText(A_Index, 2)

				for ignore, candidate in getKeys(this.SessionDrivers)
					if (driver = candidate) {
						forName := ""
						surName := ""
						nickName := ""

						parseDriverName(candidate, &forName, &surName, &nickName)

						return this.createDriver({Forname: forName, Surname: surName, Nickname: nickName, Identifier: this.SessionDrivers[candidate]})
					}
			}
		}

		return false
	}

	driverSetup(driver, weather, airTemperature, trackTemperature, compound, compoundColor) {
		local setup := false
		local weatherIndex := inList(kWeatherConditions, weather)
		local ignore, candidate, sWeatherIndex, cWeatherIndex

		this.saveSetups()

		for ignore, candidate in this.SessionStore.query("Setups.Data", {Where: CaseInsenseMap("Driver", driver.FullName
																							 , "Tyre.Compound", compound, "Tyre.Compound.Color", compoundColor)})
			if setup {
				sWeatherIndex := inList(kWeatherConditions, setup["Weather"])
				cWeatherIndex := inList(kWeatherConditions, candidate["Weather"])

				if (Abs(weatherIndex - cWeatherIndex) < Abs(weatherIndex - sWeatherIndex))
					setup := candidate
				else if ((Abs(candidate["Temperature.Air"] - airTemperature) < Abs(setup["Temperature.Air"] - airTemperature))
					  || (Abs(candidate["Temperature.Track"] - trackTemperature) < Abs(setup["Temperature.Track"] - trackTemperature)))
					setup := candidate
			}
			else
				setup := candidate

		return setup
	}

	driverSetups(driver, weather, compound, compoundColor) {
		this.saveSetups()

		return this.SessionStore.query("Setups.Data", {Where: CaseInsenseMap("Driver", driver.FullName, "Weather", weather
																		   , "Tyre.Compound", compound, "Tyre.Compound.Color", compoundColor)})
	}

	driverReferencePressure(driver, weather, airTemperature, trackTemperature, compound, compoundColor
						  , &pressureFL, &pressureFR, &pressureRL, &pressureRR) {
		local setup := this.driverSetup(driver, weather, airTemperature, trackTemperature, compound, compoundColor)
		local setups, index, tyreType, a, b
		local settings, correctionAir, correctionTrack, delta

		pressureCurve(setups, tyreType, &a, &b) {
			local xValues := []
			local yValues := []
			local ignore, setup

			for ignore, setup in setups {
				xValues.Push(setup["Temperature.Air"])
				yValues.Push(setup["Tyre.Pressure." . tyreType])
			}

			linRegression(xValues, yValues, &a, &b)
		}

		if setup {
			setups := this.driverSetups(driver, setup["Weather"], setup["Tyre.Compound"], setup["Tyre.Compound.Color"])

			if (setups.Length > 1) {
				for index, tyreType in ["Front.Left", "Front.Right", "Rear.Left", "Rear.Right"] {
					a := false
					b := false

					pressureCurve(setups, tyreType, &a, &b)

					%["pressureFL", "pressureFR", "pressureRL", "pressureRR"][index]% := (a + (b * airTemperature))
				}

				return true
			}
			else {
				settings := SettingsDatabase().loadSettings(this.Simulator, this.Car, this.Track, weather)

				correctionAir := getMultiMapValue(settings, "Session Settings", "Tyre.Pressure.Correction.Temperature.Air", -0.1)
				correctionTrack := getMultiMapValue(settings, "Session Settings", "Tyre.Pressure.Correction.Temperature.Track", -0.02)

				delta := (((airTemperature - setup["Temperature.Air"]) * correctionAir) + ((trackTemperature - setup["Temperature.Track"]) * correctionTrack))

				pressureFL := (setup["Tyre.Pressure.Front.Left"] + delta)
				pressureFR := (setup["Tyre.Pressure.Front.Right"] + delta)
				pressureRL := (setup["Tyre.Pressure.Rear.Left"] + delta)
				pressureRR := (setup["Tyre.Pressure.Rear.Right"] + delta)

				return true
			}
		}
		else
			return false
	}

	driverPressureDelta(currentDriver, nextDriver, weather, airTemperature, trackTemperature, tyreCompound, tyreCompoundColor
					  , &deltaFL, &deltaFR, &deltaRL, &deltaRR) {
		local currentDriverSetup, nextDriverSetup
		local currentBasePressureFL, currentBasePressureFR, currentBasePressureRL, currentBasePressureRR
		local nextBasePressureFL, nextBasePressureFR, nextBasePressureRL, nextBasePressureRR

		if (currentDriver = nextDriver) {
			deltaFL := 0
			deltaFR := 0
			deltaRL := 0
			deltaRR := 0

			return true
		}
		else {
			currentDriverSetup := this.driverSetup(currentDriver, weather, airTemperature, trackTemperature, tyreCompound, tyreCompoundColor)
			nextDriverSetup := this.driverSetup(nextDriver, weather, airTemperature, trackTemperature, tyreCompound, tyreCompoundColor)

			if (currentDriverSetup && nextDriverSetup) {
				currentBasePressureFL := false
				currentBasePressureFR := false
				currentBasePressureRL := false
				currentBasePressureRR := false

				nextBasePressureFL := false
				nextBasePressureFR := false
				nextBasePressureRL := false
				nextBasePressureRR := false

				this.driverReferencePressure(currentDriver, weather, airTemperature, trackTemperature, tyreCompound, tyreCompoundColor
										   , &currentBasePressureFL, &currentBasePressureFR, &currentBasePressureRL, &currentBasePressureRR)

				this.driverReferencePressure(nextDriver, weather, airTemperature, trackTemperature, tyreCompound, tyreCompoundColor
										   , &nextBasePressureFL, &nextBasePressureFR, &nextBasePressureRL, &nextBasePressureRR)

				deltaFL := (nextBasePressureFL - currentBasePressureFL)
				deltaFR := (nextBasePressureFR - currentBasePressureFR)
				deltaRL := (nextBasePressureRL - currentBasePressureRL)
				deltaRR := (nextBasePressureRR - currentBasePressureRR)

				return true
			}
			else
				return false
		}
	}

	adjustPitstopTyrePressures(tyrePressureMode, weather, airTemperature, trackTemperature, tyreCompound, tyreCompoundColor
							 , &flPressure, &frPressure, &rlPressure, &rrPressure) {
		local currentDriver := (this.CurrentStint ? this.CurrentStint.Driver : false)
		local nextDriver := (this.CurrentStint ? this.getDriver(this.CurrentStint.Nr + 1) : false)
		local pressureFL, pressureFR, pressureRL, pressureRR, deltaFL, deltaFR, deltaRL, deltaRR

		if (currentDriver && nextDriver) {
			if (tyrePressureMode = "Reference") {
				pressureFL := false
				pressureFR := false
				pressureRL := false
				pressureRR := false

				if this.driverReferencePressure(nextDriver, weather, airTemperature, trackTemperature, tyreCompound, tyreCompoundColor
											  , &pressureFL, &pressureFR, &pressureRL, &pressureRR) {
					flPressure := pressureFL
					frPressure := pressureFR
					rlPressure := pressureRL
					rrPressure := pressureRR
				}
			}
			else if (tyrePressureMode = "Relative") {
				deltaFL := false
				deltaFR := false
				deltaRL := false
				deltaRR := false

				if this.driverPressureDelta(currentDriver, nextDriver, weather, airTemperature, trackTemperature, tyreCompound, tyreCompoundColor
										  , &deltaFL, &deltaFR, &deltaRL, &deltaRR) {
					flPressure += deltaFL
					frPressure += deltaFR
					rlPressure += deltaRL
					rrPressure += deltaRR
				}
			}
			else
				throw "Unknown tyre pressure mode detected in RaceCenter.adjustPitstopTyrePressures..."
		}
	}

	initializePitstopTyreSetup(&tyreCompound, &tyreCompoundColor, &flPressure, &frPressure, &rlPressure, &rrPressure, remote := false) {
		local chosen

		if remote {
			if tyreCompound {
				if this.TyrePressureMode
					this.adjustPitstopTyrePressures(this.TyrePressureMode, this.Weather, this.AirTemperature, this.TrackTemperature
												  , tyreCompound, tyreCompoundColor, &flPressure, &frPressure, &rlPressure, &rrPressure)
			}
			else {
				tyreCompoundColor := false

				flPressure := false
				frPressure := false
				rlPressure := false
				rrPressure := false
			}
		}
		else {
			if tyreCompound {
				if this.TyrePressureMode
					this.adjustPitstopTyrePressures(this.TyrePressureMode, this.Weather, this.AirTemperature, this.TrackTemperature
												  , tyreCompound, tyreCompoundColor, &flPressure, &frPressure, &rlPressure, &rrPressure)

				chosen := inList(concatenate(["No Tyre Change"], this.TyreCompounds), compound(tyreCompound, tyreCompoundColor))

				this.Control["pitstopTyreCompoundDropDown"].Choose((chosen == 0) ? 1 : chosen)

				this.Control["pitstopPressureFLEdit"].Text := displayValue("Float", convertUnit("Pressure", flPressure))
				this.Control["pitstopPressureFREdit"].Text := displayValue("Float", convertUnit("Pressure", frPressure))
				this.Control["pitstopPressureRLEdit"].Text := displayValue("Float", convertUnit("Pressure", rlPressure))
				this.Control["pitstopPressureRREdit"].Text := displayValue("Float", convertUnit("Pressure", rrPressure))
			}
			else {
				this.Control["pitstopTyreCompoundDropDown"].Choose(1)

				this.Control["pitstopPressureFLEdit"].Text := ""
				this.Control["pitstopPressureFREdit"].Text := ""
				this.Control["pitstopPressureRLEdit"].Text := ""
				this.Control["pitstopPressureRREdit"].Text := ""
			}

			this.updateState()
		}
	}

	updateStrategy(instruct := false, verbose := true) {
		local strategy, session, lap

		if (this.Strategy && this.SessionActive)
			try {
				this.Strategy.setVersion(A_Now)

				strategy := newMultiMap()

				this.Strategy.saveToConfiguration(strategy)

				strategy := printMultiMap(strategy)

				session := this.SelectedSession[true]

				this.Connector.SetSessionValue(session, "Race Strategy", strategy)
				this.Connector.SetSessionValue(session, "Race Strategy Version", this.Strategy.Version)

				if verbose
					showMessage(translate("Strategy has been saved for this Session."))

				if instruct {
					lap := this.Connector.GetSessionLastLap(session)

					this.Connector.SetLapValue(lap, "Race Strategy", strategy)
					this.Connector.SetLapValue(lap, "Strategy Update", strategy)
					this.Connector.SetSessionValue(session, "Strategy Update", lap)

					if verbose
						showMessage(translate("Race Strategist will be instructed as fast as possible."))
				}
			}
			catch Any as exception {
				showMessage(translate("Session has not been started yet."))
			}
	}

	discardStrategy() {
		local session, lap

		this.selectStrategy(false)

		if this.SessionActive
			try {
				session := this.SelectedSession[true]

				this.Connector.SetSessionValue(session, "Race Strategy", "CANCEL")
				this.Connector.SetSessionValue(session, "Race Strategy Version", A_Now . "")

				lap := this.Connector.GetSessionLastLap(session)

				this.Connector.SetLapValue(lap, "Strategy Update", "CANCEL")
				this.Connector.SetSessionValue(session, "Strategy Update", lap)

				showMessage(translate("Race Strategist will be instructed as fast as possible."))
			}
			catch Any as exception {
				showMessage(translate("Session has not been started yet."))
			}
	}

	createPitstopPlan(remote := false, pitstopLap := false, pitstopDriver := false, pitstopRefuel := false
									 , pitstopTyreCompound := false, pitstopTyreCompoundColor := false, pitstopTyreSet := false
									 , pitstopPressureFL := false, pitstopPressureFR := false, pitstopPressureRL := false, pitstopPressureRR := false
									 , pitstopRepairs := []) {
		local sessionStore := this.SessionStore
		local pitstopPlan := newMultiMap()
		local repairBodywork := false
		local repairSuspension := false
		local repairEngine := false
		local stint, drivers, currentDriver, currentNr, nextNr

		if !remote {
			pitstopLap := this.Control["pitstopLapEdit"].Text

			pitstopDriver := this.Control["pitstopDriverDropDownMenu"].Text

			if (pitstopDriver = translate("No driver change"))
				pitstopDriver := false

			pitstopRefuel := this.Control["pitstopRefuelEdit"].Text

			pitstopTyreCompound := this.Control["pitstopTyreCompoundDropDown"].Value

			if (pitstopTyreCompound > 1)
				splitCompound(this.TyreCompounds[pitstopTyreCompound - 1], &pitstopTyreCompound, &pitstopTyreCompoundColor)
			else {
				pitstopTyreCompound := false
				pitstopTyreCompoundColor := false
			}

			pitstopTyreSet := this.Control["pitstopTyreSetEdit"].Text

			pitstopPressureFL := false
			pitstopPressureFR := false
			pitstopPressureRL := false
			pitstopPressureRR := false

			if isNumber(internalValue("Float", this.Control["pitstopPressureFLEdit"].Text))
				pitstopPressureFL := convertUnit("Pressure", internalValue("Float", this.Control["pitstopPressureFLEdit"].Text), false)
			if isNumber(internalValue("Float", this.Control["pitstopPressureFREdit"].Text))
				pitstopPressureFR := convertUnit("Pressure", internalValue("Float", this.Control["pitstopPressureFREdit"].Text), false)
			if isNumber(internalValue("Float", this.Control["pitstopPressureRLEdit"].Text))
				pitstopPressureRL := convertUnit("Pressure", internalValue("Float", this.Control["pitstopPressureRLEdit"].Text), false)
			if isNumber(internalValue("Float", this.Control["pitstopPressureRREdit"].Text))
				pitstopPressureRR := convertUnit("Pressure", internalValue("Float", this.Control["pitstopPressureRREdit"].Text), false)

			local pitstopRepairsDropDown := this.Control["pitstopRepairsDropDown"].Value

			repairBodywork := ((pitstopRepairsDropDown = 2) || (pitstopRepairsDropDown = 5))
			repairSuspension := ((pitstopRepairsDropDown = 3) || (pitstopRepairsDropDown = 5))
			repairEngine := ((pitstopRepairsDropDown = 4) || (pitstopRepairsDropDown = 5))

		}
		else {
			repairBodywork := inList(pitstopRepairs, "Bodywork")
			repairSuspension := inList(pitstopRepairs, "Suspension")
			repairEngine := inList(pitstopRepairs, "Engine")
		}

		if ((pitstopLap = "") || (pitstopLap <= 0))
			pitstopLap := (this.LastLap ? this.LastLap.Nr : 1)

		if (pitstopRefuel = "")
			pitstopRefuel := 0

		if (pitstopTyreSet = "")
			pitstopTyreSet := 0

		setMultiMapValue(pitstopPlan, "Pitstop", "Lap", pitstopLap)

		setMultiMapValue(pitstopPlan, "Pitstop", "Refuel", convertUnit("Volume", internalValue("Float", pitstopRefuel), false))

		stint := this.CurrentStint
		driverSelected := false

		if (stint && pitstopDriver) {
			nextNr := inList(this.TeamDrivers, pitstopDriver)

			if nextNr {
				currentDriver := stint.Driver.Fullname
				currentNr := inList(this.TeamDrivers, currentDriver)

				if currentNr
					setMultiMapValue(pitstopPlan, "Pitstop", "Driver", currentDriver . ":" . currentNr . "|" . pitstopDriver . ":" . nextNr)
				else {
					drivers := this.getPlanDrivers()

					if (drivers.Has(stint.Nr)) {
						currentDriver := drivers[stint.Nr]
						currentNr := inList(this.TeamDrivers, currentDriver)

						if currentNr
							setMultiMapValue(pitstopPlan, "Pitstop", "Driver", currentDriver . ":" . currentNr . "|" . pitstopDriver . ":" . nextNr)
					}
				}
			}
		}

		if pitstopTyreCompound {
			setMultiMapValue(pitstopPlan, "Pitstop", "Tyre.Change", true)

			if ((pitstopTyreSet = "") || (pitstopTyreSet = "-"))
				pitstopTyreSet := false

			setMultiMapValue(pitstopPlan, "Pitstop", "Tyre.Set", pitstopTyreSet)

			setMultiMapValue(pitstopPlan, "Pitstop", "Tyre.Compound", pitstopTyreCompound)
			setMultiMapValue(pitstopPlan, "Pitstop", "Tyre.Compound.Color", pitstopTyreCompoundColor)

			setMultiMapValue(pitstopPlan, "Pitstop", "Tyre.Pressures", values2String(",", pitstopPressureFL, pitstopPressureFR, pitstopPressureRL, pitstopPressureRR))
		}
		else
			setMultiMapValue(pitstopPlan, "Pitstop", "Tyre.Change", false)

		setMultiMapValue(pitstopPlan, "Pitstop", "Repair.Bodywork", repairBodywork)
		setMultiMapValue(pitstopPlan, "Pitstop", "Repair.Suspension", repairSuspension)
		setMultiMapValue(pitstopPlan, "Pitstop", "Repair.Engine", repairEngine)

		return pitstopPlan
	}

	updatePitstopPlan(pitstopPlan) {
		local sessionStore := this.SessionStore
		local pitstopLap := getMultiMapValue(pitstopPlan, "Pitstop", "Lap")
		local fuel := getMultiMapValue(pitstopPlan, "Pitstop", "Refuel")
		local tyreCompound := getMultiMapValue(pitstopPlan, "Pitstop", "Tyre.Compound")
		local tyreCompoundColor := getMultiMapValue(pitstopPlan, "Pitstop", "Tyre.Compound.Color")
		local repairBodywork := getMultiMapValue(pitstopPlan, "Pitstop", "Repair.Bodywork")
		local repairSuspension := getMultiMapValue(pitstopPlan, "Pitstop", "Repair.Suspension")
		local repairEngine := getMultiMapValue(pitstopPlan, "Pitstop", "Repair.Engine")
		local currentDriver := kNull
		local nextDriver := kNull
		local pressures, displayPressures, tyreSet, displayFuel, requestDriver

		sessionStore.remove("Pitstop.Data", {Status: "Planned"}, always.Bind(true))

		loop this.PitstopsListView.GetCount()
			if (this.PitstopsListView.GetNext(A_Index - 1, "C") != A_Index) {
				this.PitstopsListView.Delete(A_Index)

				break
			}

		if (tyreCompound && (tyreCompound != "-")) {
			tyreSet := getMultiMapValue(pitstopPlan, "Pitstop", "Tyre.Set")
			pressures := string2Values(",", getMultiMapValue(pitstopPlan, "Pitstop", "Tyre.Pressures"))

			displayPressures := values2String(", ", displayValue("Float", convertUnit("Pressure", pressures[1]))
												  , displayValue("Float", convertUnit("Pressure", pressures[2]))
												  , displayValue("Float", convertUnit("Pressure", pressures[3]))
												  , displayValue("Float", convertUnit("Pressure", pressures[4])))

			pressures := values2String(", ", pressures*)
		}
		else {
			tyreCompound := "-"
			tyreCompoundColor := false

			tyreSet := "-"
			pressures := "-, -, -, -"

			displayPressures := pressures
		}

		requestDriver := getMultiMapValue(pitstopPlan, "Pitstop", "Driver", kUndefined)

		if (requestDriver != kUndefined) {
			requestDriver := string2Values("|", requestDriver)

			currentDriver := string2Values(":", requestDriver[1])[1]
			nextDriver := string2Values(":", requestDriver[2])[1]
		}

		if isNumber(fuel) {
			if (fuel = 0)
				displayFuel := "-"
			else
				displayFuel := displayValue("Float", convertUnit("Volume", fuel))
		}
		else
			displayFuel := fuel

		this.PitstopsListView.Add("", this.PitstopsListView.GetCount() + 1, pitstopLap, displayNullValue(nextDriver), displayFuel
									, (tyreCompound = "-") ? tyreCompound : translate(compound(tyreCompound, tyreCompoundColor)), (tyreSet != 0) ? tyreSet : "-"
									, displayPressures, this.computeRepairs(repairBodywork, repairSuspension, repairEngine))

		this.PitstopsListView.ModifyCol()

		loop this.PitstopsListView.GetCount("Col")
			this.PitstopsListView.ModifyCol(A_index, "AutoHdr")

		pressures := string2Values(",", pressures)

		sessionStore.add("Pitstop.Data"
					   , Database.Row("Lap", pitstopLap - 1, "Fuel", fuel
									, "Tyre.Compound", tyreCompound, "Tyre.Compound.Color", tyreCompoundColor, "Tyre.Set", tyreSet
									, "Tyre.Pressure.Cold.Front.Left", pressures[1], "Tyre.Pressure.Cold.Front.Right", pressures[2]
									, "Tyre.Pressure.Cold.Rear.Left", pressures[3], "Tyre.Pressure.Cold.Rear.Right", pressures[4]
									, "Repair.Bodywork", repairBodywork, "Repair.Suspension", repairSuspension, "Repair.Engine", repairEngine
									, "Driver.Current", currentDriver, "Driver.Next", nextDriver, "Status", "Planned"
									, "Stint", this.CurrentStint.Nr + 1))
	}

	planPitstop() {
		local pitstopPlan, session, lap

		try {
			if this.SessionActive {
				pitstopPlan := this.createPitstopPlan()

				session := this.SelectedSession[true]

				lap := this.Connector.GetSessionLastLap(session)

				if (lap && (lap != "")) {
					this.Connector.SetLapValue(lap, "Pitstop Plan", printMultiMap(pitstopPlan))
					this.Connector.SetSessionValue(session, "Pitstop Plan", lap)

					this.updatePitstopPlan(pitstopPlan)

					showMessage(translate("Race Engineer will be instructed as fast as possible."))
				}
				else
					throw "No active session..."
			}
			else
				throw "No active session..."
		}
		catch Any as exception {
			logError(exception)

			OnMessage(0x44, translateOkButton)
			MsgBox(translate("You must be connected to an active session to plan a pitstop."), translate("Error"), 262192)
			OnMessage(0x44, translateOkButton, 0)
		}
	}

	planDriverSwap(lap := false, repairBodywork := true, repairSuspension := true, repairEngine := true) {
		local pitstopPlan
		local pitstopLap, pitstopDriver, pitstopRefuel, pitstopTyreCompound, pitstopTyreCompoundColor, pitstopTyreSet
		local pitstopPressureFL, pitstopPressureFR, pitstopPressureRL, pitstopPressureRR, pitstopRepairs
		local pitstopTyreSetup

		if this.SessionActive {
			try {
				pitstopRepairs := []

				if repairBodywork
					pitstopRepairs.Push("Bodywork")

				if repairSuspension
					pitstopRepairs.Push("Suspension")

				if repairEngine
					pitstopRepairs.Push("Engine")

				this.initializePitstopFromSession(lap, true, &pitStopLap, &pitstopDriver, &pitstopRefuel, &pitstopTyreSetup)

				pitstopPlan := this.createPitstopPlan(true, pitstopLap, pitstopDriver, pitstopRefuel,
															pitstopTyreSetup[1], pitstopTyreSetup[2], false
														  , pitstopTyreSetup[3], pitstopTyreSetup[4], pitstopTyreSetup[5], pitstopTyreSetup[6]
														  , pitstopRepairs)

				if pitstopPlan {
					this.Connector.SetSessionValue(this.SelectedSession[true], "Race Engineer Driver Swap Plan", printMultiMap(pitstopPlan))

					this.updatePitstopPlan(pitstopPlan)
				}
			}
			catch Any as exception {
				logError(exception)
			}
		}
	}

	chooseSessionMenu(line) {
		local msgResult, synchronizeMenu, ignore, seconds

		switch line {
			case 3: ; Connect...
				this.iServerURL := this.Control["serverURLEdit"].Text
				this.iServerToken := ((this.Control["serverTokenEdit"].Text = "") ? RaceCenter.kInvalidToken : this.Control["serverTokenEdit"].Text)

				this.connect()
			case 4: ; Clear...
				if this.SessionActive {
					title :=

					OnMessage(0x44, translateYesNoButtons)
					msgResult := MsgBox(translate("Do you really want to delete all data from the currently active session? This can take quite a while..."), translate("Delete"), 262436)
					OnMessage(0x44, translateYesNoButtons, 0)

					if (msgResult = "Yes")
						this.clearSession()
				}
				else {
					OnMessage(0x44, translateOkButton)
					MsgBox(translate("You are not connected to an active session."), translate("Information"), 262192)
					OnMessage(0x44, translateOkButton, 0)
				}
			case 6: ; Synchronize
				if GetKeyState("Ctrl", "P") {
					synchronizeMenu := Menu()

					synchronizeMenu.Add(translate("Synchronize each..."), (*) => {})
					synchronizeMenu.Disable(translate("Synchronize each..."))

					synchronizeMenu.Add()

					synchronizeMenu.Add(translate("Off"), (*) => (this.iSynchronize := false))

					if !this.Synchronize
						synchronizeMenu.Check(translate("Off"))

					for ignore, seconds in [4, 5, 6, 8, 10, 12, 14, 16, 20, 25, 30, 40, 50, 60] {
						setSynchronize(seconds, *) {
							this.iSynchronize := seconds
						}

						synchronizeMenu.Add(seconds . translate(" seconds"), setSynchronize.Bind(seconds))

						if (seconds = this.Synchronize)
							synchronizeMenu.Check(seconds . translate(" seconds"))
					}

					synchronizeMenu.Show()
				}
				else if this.Synchronize
					this.iSynchronize := false
				else
					this.iSynchronize := 10

				this.updateState()
			case 8:
				this.manageTeam()
			case 10: ; Load Session...
				this.loadSession()
			case 11: ; Save Session
				if this.HasData {
					if this.SessionActive
						this.saveSession()
					else {
						OnMessage(0x44, translateOkButton)
						MsgBox(translate("You are not connected to an active session. Use `"Save a Copy...`" instead."), translate("Information"), 262192)
						OnMessage(0x44, translateOkButton, 0)
					}
				}
				else {
					OnMessage(0x44, translateOkButton)
					MsgBox(translate("There is no session data to be saved."), translate("Information"), 262192)
					OnMessage(0x44, translateOkButton, 0)
				}
			case 12: ; Save Session Copy...
				if this.HasData
					this.saveSession(true)
				else {
					OnMessage(0x44, translateOkButton)
					MsgBox(translate("There is no session data to be saved."), translate("Information"), 262192)
					OnMessage(0x44, translateOkButton, 0)
				}
			case 14: ; Update Statistics
				this.updateStatistics()
			case 16: ; Race Summary
				this.showSessionSummary()
			case 17: ; Driver Statistics
				this.showDriverStatistics()
		}

		this.updateSessionMenu()
	}

	chooseStrategyMenu(line) {
		local strategy, simulator, car, track, simulatorCode, dirName, fileName, configuration, fileName, name, msgResult
		local directory

		if this.Simulator {
			simulator := this.Simulator
			car := this.Car
			track := this.Track

			if (car && track) {
				directory := SessionDatabase.DatabasePath
				simulatorCode := SessionDatabase.getSimulatorCode(simulator)

				dirName := directory . "User\" . simulatorCode . "\" . car . "\" . track . "\Race Strategies"

				DirCreate(dirName)
			}
			else
				dirName := ""
		}
		else
			dirName := ""

		switch line {
			case 3:
				fileName := kUserConfigDirectory . "Race.strategy"

				if FileExist(fileName) {
					configuration := readMultiMap(fileName)

					if (configuration.Count > 0)
						this.selectStrategy(this.createStrategy(configuration, false, false), true)
				}
				else {
					OnMessage(0x44, translateOkButton)
					MsgBox(translate("There is no active Race Strategy."), translate("Information"), 262192)
					OnMessage(0x44, translateOkButton, 0)
				}
			case 4:
				this.Window.Opt("+OwnDialogs")

				OnMessage(0x44, translateLoadCancelButtons)
				fileName := FileSelect(1, dirName, translate("Load Race Strategy..."), "Strategy (*.strategy)")
				OnMessage(0x44, translateLoadCancelButtons, 0)

				if (fileName != "") {
					configuration := readMultiMap(fileName)

					if (configuration.Count > 0)
						this.selectStrategy(this.createStrategy(configuration, false, false), true)
				}
			case 5: ; "Save Strategy..."
				if this.Strategy {
					this.Window.Opt("+OwnDialogs")

					OnMessage(0x44, translateYesNoButtons)
					fileName := FileSelect("S17", dirName . "\" . this.Strategy.Name . ".strategy", translate("Save Race Strategy..."), "Strategy (*.strategy)")
					OnMessage(0x44, translateYesNoButtons, 0)

					if (fileName != "") {
						if !InStr(fileName, ".")
							fileName .= ".strategy"

						SplitPath(fileName, , , , &name)

						this.Strategy.setName(name)

						configuration := newMultiMap()

						this.Strategy.saveToConfiguration(configuration)

						writeMultiMap(fileName, configuration)
					}
				}
				else {
					OnMessage(0x44, translateOkButton)
					MsgBox(translate("There is no current Strategy."), translate("Information"), 262192)
					OnMessage(0x44, translateOkButton, 0)
				}
			case 7: ; Strategy Summary
				if this.Strategy {
					this.StrategyViewer.showStrategyInfo(this.Strategy)

					this.iSelectedDetailReport := "Strategy"
				}
				else {
					OnMessage(0x44, translateOkButton)
					MsgBox(translate("There is no current Strategy."), translate("Information"), 262192)
					OnMessage(0x44, translateOkButton, 0)
				}
			case 9: ; Use Session Data
				this.iUseSessionData := !this.UseSessionData

				this.updateState()
			case 10: ; Use Telemetry Database
				this.iUseTelemetryDatabase := !this.UseTelemetryDatabase

				this.updateState()
			case 11: ; Use current Map
				this.iUseCurrentMap := !this.UseCurrentMap

				this.updateState()
			case 12: ; Use Traffic
				this.iUseTraffic := !this.UseTraffic

				this.updateState()
			case 14: ; Run Simulation
				if this.Strategy {
					if (this.UseTraffic && !this.SessionActive) {
						OnMessage(0x44, translateOkButton)
						MsgBox(translate("A traffic-based strategy simulation is only possible in an active session."), translate("Information"), 262192)
						OnMessage(0x44, translateOkButton, 0)

						this.iUseTraffic := false

						this.updateState()
					}

					this.runSimulation(this.Strategy.SessionType)
				}
				else {
					OnMessage(0x44, translateOkButton)
					MsgBox(translate("There is no current Strategy."), translate("Information"), 262192)
					OnMessage(0x44, translateOkButton, 0)
				}
			case 16, 19: ; Release Strategy
				if this.Strategy {
					if this.SessionActive
						this.updateStrategy(line == 19)
					else {
						OnMessage(0x44, translateOkButton)
						MsgBox(translate("You are not connected to an active session."), translate("Information"), 262192)
						OnMessage(0x44, translateOkButton, 0)
					}
				}
				else {
					OnMessage(0x44, translateOkButton)
					MsgBox(translate("There is no current Strategy."), translate("Information"), 262192)
					OnMessage(0x44, translateOkButton, 0)
				}
			case 17: ; Discard Strategy
				if this.Strategy {
					if this.SessionActive {
						OnMessage(0x44, translateYesNoButtons)
						msgResult := MsgBox(translate("Do you really want to discard the active strategy? Strategist will be instructed immediately..."), translate("Strategy"), 262436)
						OnMessage(0x44, translateYesNoButtons, 0)

						if (msgResult = "Yes") {
							this.discardStrategy()

							if (this.SelectedDetailReport = "Strategy")
								this.showDetails(false, false)
						}
					}
					else {
						OnMessage(0x44, translateOkButton)
						MsgBox(translate("You are not connected to an active session."), translate("Information"), 262192)
						OnMessage(0x44, translateOkButton, 0)
					}
				}
				else {
					OnMessage(0x44, translateOkButton)
					MsgBox(translate("There is no current Strategy."), translate("Information"), 262192)
					OnMessage(0x44, translateOkButton, 0)
				}
		}

		this.updateStrategyMenu()
	}

	choosePlanMenu(line) {
		switch line {
			case 3:
				this.pushTask(ObjBindMethod(this, "updatePlanFromStrategy"))
			case 4:
				this.pushTask(ObjBindMethod(this, "clearPlan"))
			case 6:
				this.showPlanDetails()

				this.iSelectedDetailReport := "Plan"
			case 8:
				if this.SessionActive
					this.releasePlan()
				else {
					OnMessage(0x44, translateOkButton)
					MsgBox(translate("You are not connected to an active session."), translate("Information"), 262192)
					OnMessage(0x44, translateOkButton, 0)
				}
		}

		this.updatePlanMenu()
	}

	choosePitstopMenu(line) {
		local exePath, options, simulator

		switch line {
			case 3: ; Manage Team
				this.manageTeam()
			case 5:
				this.initializePitstopFromSession()
			case 6:
				exePath := kBinariesDirectory . "Session Database.exe"

				this.iPressuresRequest := "Pitstop"

				try {
					options := ["-Setup", ProcessExist()]

					if (this.Simulator && this.Car && this.Track) {
						simulator := SessionDatabase.getSimulatorName(this.Simulator)

						options := concatenate(options, ["-Simulator", "`"" . simulator . "`"", "-Car", "`"" . this.Car . "`"", "-Track", "`"" . this.Track . "`""
													   , "-Weather", this.Weather
													   , "-AirTemperature", Round(this.AirTemperature), "-TrackTemperature", Round(this.TrackTemperature)])
					}

					options := values2String(A_Space, options*)

					Run("`"" . exePath . "`" " . options, kBinariesDirectory)
				}
				catch Any as exception {
					logMessage(kLogCritical, translate("Cannot start the Session Database tool (") . exePath . translate(") - please rebuild the applications in the binaries folder (") . kBinariesDirectory . translate(")"))

					showMessage(substituteVariables(translate("Cannot start the Session Database tool (%exePath%) - please check the configuration..."), {exePath: exePath})
							  , translate("Modular Simulator Controller System"), "Alert.png", 5000, "Center", "Bottom", 800)
				}
			case 7:
				this.pushTask(ObjBindMethod(this, "clearSetups"))
			case 9:
				this.showSetupsDetails()

				this.iSelectedDetailReport := "Setups"
			case 10:
				this.showPitstopsDetails()

				this.iSelectedDetailReport := "Pitstops"
			case 12:
				this.iTyrePressureMode := ((this.TyrePressureMode = "Reference") ? false : "Reference")

				this.updateState()
			case 13:
				this.iTyrePressureMode := ((this.TyrePressureMode = "Relative") ? false : "Relative")

				this.updateState()
			case 14:
				this.iCorrectPressureLoss := !this.CorrectPressureLoss

				this.updateState()
			case 16:
				this.planPitstop()
		}

		this.updatePitstopMenu()
	}

	withExceptionHandler(function, arguments*) {
		try {
			return function.Call(arguments*)
		}
		catch Any as exception {
			logError(exception, false)

			OnMessage(0x44, translateOkButton)
			MsgBox((translate("Error while executing command.") . "`n`n" . translate("Error: ") . exception.Message), translate("Error"), 262160)
			OnMessage(0x44, translateOkButton, 0)
		}
	}

	pushTask(theTask) {
		RaceCenterTask(theTask).start()
	}

	createStrategy(nameOrConfiguration, driver := false, simulation := true) {
		local name := nameOrConfiguration
		local theStrategy

		if !isObject(nameOrConfiguration)
			nameOrConfiguration := false

		theStrategy := ((simulation && this.UseTraffic) ? RaceCenter.SessionTrafficStrategy(this, nameOrConfiguration, driver)
														: RaceCenter.SessionStrategy(this, nameOrConfiguration, driver))

		if (name && !isObject(name))
			theStrategy.setName(name)

		theStrategy.setVersion(A_Now)

		return theStrategy
	}

	selectStrategy(strategy, show := false) {
		if this.Strategy
			this.Strategy.dispose()

		this.iStrategy := strategy

		if strategy
			this.initializeSimulator(strategy.Simulator, strategy.Car, strategy.Track)

		if (show || (this.SelectedDetailReport = "Strategy") || !this.SelectedDetailReport)
			if strategy {
				this.StrategyViewer.showStrategyInfo(this.Strategy)

				this.iSelectedDetailReport := "Strategy"
			}
			else {
				this.showDetails(false, false)

				this.iSelectedDetailReport := false
			}
	}

	getStintDriver(stintNumber, &driverID, &driverName) {
		local driver := this.getDriver(stintNumber)

		if (driver && driver.ID) {
			driverID := driver.ID
			driverName := driver.Fullname
		}
		else {
			if this.Strategy {
				if (stintNumber = 1) {
					driverID := this.Strategy.Driver
					driverName := this.Strategy.DriverName
				}
				else if this.Strategy.Pitstops.Has(stintNumber - 1) {
					driverID := this.Strategy.Pitstops[stintNumber - 1].Driver
					driverName := this.Strategy.Pitstops[stintNumber - 1].DriverName
				}
			}
			else {
				driverID := false
				driverName := "John Doe (JD)"
			}
		}

		return true
	}

	runSimulation(sessionType) {
		RaceCenterSimulationTask(ObjBindMethod(this, "runSimulationAsync", sessionType)).start()
	}

	runSimulationAsync(sessionType) {
		local telemetryDB, simulation

		this.showMessage(translate("Saving session"))

		this.syncSessionStore(true)

		this.showMessage(translate("Running simulation"))

		telemetryDB := RaceCenter.RaceCenterTelemetryDatabase.SimulationTelemetryDatabase(this, this.Simulator, this.Car, this.Track)

		this.iSimulationTelemetryDatabase := telemetryDB

		try {
			if this.UseTraffic
				simulation := TrafficSimulation(this, sessionType, telemetryDB)
			else
				simulation := VariationSimulation(this, sessionType, telemetryDB)

			Task.CurrentTask.Simulation := simulation

			simulation.runSimulation(true)
		}
		finally {
			this.iSimulationTelemetryDatabase := false
		}

		this.showMessage(false)
	}

	getPreviousLap(lap) {
		local laps := this.Laps

		lap := (lap.Nr - 1)

		while (lap > 0)
			if laps.Has(lap)
				return laps[lap]
			else
				lap -= 1

		return false
	}

	getStintSetup(stintNr, carryOver, &fuel, &tyreCompound, &tyreCompoundColor, &tyreSet, &tyrePressures) {
		local sessionStore := this.SessionStore
		local lap := this.Stints[stintNr].Laps[1]
		local pressureTable, pressures, pressure, theCompound, pitstop

		tyrePressures := false
		fuel := lap.FuelRemaining

		splitCompound(lap.Compound, &tyreCompound, &tyreCompoundColor)

		if lap.Telemetry
			tyreSet := getMultiMapValue(parseMultiMap(lap.Telemetry), "Car Data", "TyreSet", false)
		else
			tyreSet := false

		loop {
			if (stintNr <= 1) {
				pressuresTable := this.PressuresDatabase.Database.Tables["Tyres.Pressures"]

				if (pressuresTable.Length >= 1) {
					pressures := pressuresTable[1]

					tyrePressures := [pressures["Tyre.Pressure.Cold.Front.Left"], pressures["Tyre.Pressure.Cold.Front.Right"]
									, pressures["Tyre.Pressure.Cold.Rear.Left"], pressures["Tyre.Pressure.Cold.Rear.Right"]]

					loop 4
						if isNull(tyrePressures[A_Index]) {
							tyrePressures := false

							break
						}
				}

				break
			}
			else {
				pitstop := sessionStore.query("Pitstop.Data", {Where: {Stint: stintNr}})

				if (pitstop.Length > 0) {
					pitstop := pitstop[1]

					theCompound := pitstop["Tyre.Compound"]

					if (theCompound != "-") {
						tyreSet := pitstop["Tyre.Set"]

						tyrePressures := []

						tyrePressures.Push(pitstop["Tyre.Pressure.Cold.Front.Left"])
						tyrePressures.Push(pitstop["Tyre.Pressure.Cold.Front.Right"])
						tyrePressures.Push(pitstop["Tyre.Pressure.Cold.Rear.Left"])
						tyrePressures.Push(pitstop["Tyre.Pressure.Cold.Rear.Right"])

						break
					}
					else if !carryOver {
						tyreCompound := false
						tyreCompoundColor := false
						tyreSet := false
						tyrePressures := false

						break
					}
				}
				else {
					if (this.PitstopsListView.GetCount() >= (stintNr - 1)) {
						theCompound := this.PitstopsListView.GetText(stintNr - 1, 5)

						if (theCompound != "-") {
							if !tyreSet {
								tyreSet := this.PitstopsListView.GetText(stintNr - 1, 6)

								if (tyreSet = "-")
									tyreSet := 0
							}

							pressures := this.PitstopsListView.GetText(stintNr - 1, 7)

							tyrePressures := string2Values(", ", pressures)

							loop 4 {
								pressure := tyrePressures[A_Index]

								if isNumber(pressure)
									tyrePressures[A_Index] := convertUnit("Pressure", internalValue("Float", pressure), false)
							}

							break
						}
						else if !carryOver {
							tyreCompound := false
							tyreCompoundColor := false
							tyreSet := false
							tyrePressures := false

							break
						}
					}
				}
			}

			stintNr -= 1
		}
	}

	getStrategySettings(&simulator, &car, &track, &weather, &airTemperature, &trackTemperature
					  , &sessionType, &sessionLength
					  , &maxTyreLaps, &tyreCompound, &tyreCompoundColor, &tyrePressures) {
		local strategy := this.Strategy
		local telemetryDB, candidate

		if strategy {
			if this.Simulator {
				simulator := SessionDatabase().getSimulatorName(this.Simulator)
				car := this.Car
				track := this.Track
			}
			else {
				simulator := strategy.Simulator
				car := strategy.Car
				track := strategy.Track
			}

			if this.Weather {
				weather := this.Weather
				airTemperature := this.AirTemperature
				trackTemperature := this.TrackTemperature
			}
			else {
				weather := strategy.Weather
				airTemperature := strategy.AirTemperature
				trackTemperature := strategy.TrackTemperature
			}

			if this.TyreCompound {
				tyreCompound := this.TyreCompound
				tyreCompoundColor := this.TyreCompoundColor
			}
			else {
				tyreCompound := strategy.TyreCompound
				tyreCompoundColor := strategy.TyreCompoundColor
			}

			telemetryDB := this.SimulationTelemetryDatabase

			if !telemetryDB.suitableTyreCompound(simulator, car, track, weather, compound(tyreCompound, tyreCompoundColor)) {
				candidate := telemetryDB.optimalTyreCompound(simulator, car, track, weather, airTemperature, trackTemperature
														   , getKeys(this.computeAvailableTyreSets(strategy.AvailableTyreSets)))

				if candidate
					splitCompound(candidate, &tyreCompound, &tyreCompoundColor)
			}

			sessionType := strategy.SessionType
			sessionLength := strategy.SessionLength
			maxTyreLaps := strategy.MaxTyreLaps
			tyrePressures := strategy.TyrePressures

			return true
		}
		else
			return false
	}

	getSessionSettings(&stintLength, &formationLap, &postRaceLap, &fuelCapacity, &safetyFuel
					 , &pitstopDelta, &pitstopFuelService, &pitstopTyreService, &pitstopServiceOrder) {
		local strategy := this.Strategy

		if strategy {
			stintLength := strategy.StintLength
			formationLap := strategy.FormationLap
			postRaceLap := strategy.PostRaceLap

			fuelCapacity := strategy.FuelCapacity
			safetyFuel := strategy.SafetyFuel

			pitstopDelta := strategy.PitstopDelta
			pitstopFuelService := strategy.PitstopFuelService
			pitstopTyreService := strategy.PitstopTyreService
			pitstopServiceOrder := strategy.PitstopServiceOrder

			return true
		}
		else
			return false
	}

	getSessionWeather(minute, &weather, &airTemperature, &trackTemperature) {
		local strategy

		if this.Weather {
			if (minute >= 30)
				weather := this.Weather30Min
			else if (minute >= 10)
				weather := this.Weather10Min
			else
				weather := this.Weather

			airTemperature := this.AirTemperature
			trackTemperature := this.TrackTemperature
		}
		else {
			strategy := this.Strategy

			if strategy
				return strategy.getWeather(minute, weather, airTemperature, trackTemperature)
			else {
				weather := "Dry"
				airTemperature := 23
				trackTemperature := 27
			}
		}

		return false
	}

	getTrafficSettings(&randomFactor, &numScenarios, &variationWindow
					 , &useLapTimeVariation, &useDriverErrors, &usePitstops
					 , &overTakeDelta, &consideredTraffic) {
		local window := this.Window

		randomFactor := window["randomFactorEdit"].Text
		numScenarios := window["numScenariosEdit"].Text
		variationWindow := window["variationWindowEdit"].Text

		useLapTimeVariation := (window["lapTimeVariationDropDown"].Value == 1)
		useDriverErrors := (window["driverErrorsDropDown"].Value == 1)
		usePitstops := (window["pitstopsDropDown"].Value == 1)
		overTakeDelta := window["overtakeDeltaEdit"].Text
		consideredTraffic := window["trafficConsideredEdit"].Text

		return true
	}

	getStartConditions(&initialStint, &initialLap, &initialStintTime, &initialSessionTime
					 , &initialTyreLaps, &initialFuelAmount
					 , &initialMap, &initialFuelConsumption, &initialAvgLapTime) {
		local lastLap, tyresTable, lap, ignore, stint, telemetryDB
		local strategy, simulator, car, track, weather, tyreCompound, tyreCompoundColor

		lastLap := this.LastLap

		initialStint := 1
		initialLap := 0
		initialSessionTime := 0
		initialStintTime := 0
		initialTyreLaps := 0
		initialFuelAmount := 0
		initialMap := "n/a"
		initialFuelConsumption := 0
		initialAvgLapTime := 0.0

		if lastLap {
			telemetryDB := this.SimulationTelemetryDatabase

			initialStint := lastLap.Stint.Nr
			initialLap := lastLap.Nr
			initialFuelAmount := lastLap.FuelRemaining
			initialMap := lastLap.Map
			initialFuelConsumption := lastLap.FuelConsumption
			initialAvgLapTime := this.CurrentStint.AvgLapTime

			initialStintTime := this.computeDuration(this.CurrentStint)

			loop this.CurrentStint.Nr
				if this.Stints.Has(A_Index)
					initialSessionTime += this.computeDuration(this.Stints[A_Index])

			strategy := this.Strategy

			if this.Simulator {
				simulator := SessionDatabase().getSimulatorName(this.Simulator)
				car := this.Car
				track := this.Track
			}
			else {
				simulator := strategy.Simulator
				car := strategy.Car
				track := strategy.Track
			}

			if this.Weather
				weather := this.Weather
			else
				weather := strategy.Weather

			if this.TyreCompound {
				tyreCompound := this.TyreCompound
				tyreCompoundColor := this.TyreCompoundColor
			}
			else {
				tyreCompound := strategy.TyreCompound
				tyreCompoundColor := strategy.TyreCompoundColor
			}

			if !telemetryDB.suitableTyreCompound(simulator, car, track, weather, compound(tyreCompound, tyreCompoundColor))
				initialTyreLaps := 999
			else {
				tyresTable := telemetryDB.Database.Tables["Tyres"]

				if (tyresTable.Length >= lastLap.Nr)
					initialTyreLaps := tyresTable[lastLap.Nr]["Tyre.Laps"]
				else
					initialTyreLaps := 0
			}
		}
	}

	getSimulationSettings(&useInitialConditions, &useTelemetryData
						, &consumptionVariation, &initialFuelVariation, &tyreUsageVariation, &tyreCompoundVariation) {
		local strategy := this.Strategy

		useInitialConditions := false
		useTelemetryData := true

		initialFuelVariation := 0

		if strategy {
			consumptionVariation := strategy.ConsumptionVariation
			tyreUsageVariation := strategy.TyreUsageVariation
			tyreCompoundVariation := strategy.TyreCompoundVariation
		}
		else {
			consumptionVariation := 0
			tyreUsageVariation := 0
			tyreCompoundVariation := 0
		}

		if (tyreUsageVariation = 0)
			tyreUsageVariation := this.Control["randomFactorEdit"].Text

		if (tyreCompoundVariation = 0)
			tyreCompoundVariation := this.Control["randomFactorEdit"].Text

		return (strategy != false)
	}

	getPitstopRules(&validator, &pitstopRule, &refuelRule, &tyreChangeRule, &tyreSets) {
		local strategy := this.Strategy

		if strategy {
			validator := strategy.Validator
			pitstopRule := strategy.PitstopRule
			refuelRule := strategy.RefuelRule
			tyreChangeRule := strategy.TyreChangeRule
			tyreSets := strategy.TyreSets

			if isInteger(pitstopRule)
				if (pitstopRule > 0)
					pitstopRule := Max(0, pitstopRule - this.PitstopsListView.GetCount())

			return true
		}
		else
			return false
	}

	getAvgLapTime(numLaps, map, remainingFuel, fuelConsumption, weather, tyreCompound, tyreCompoundColor, tyreLaps, default := false) {
		return Task.CurrentTask.Simulation.calcAvgLapTime(numLaps, map, remainingFuel, fuelConsumption, weather
														, tyreCompound, tyreCompoundColor, tyreLaps
														, default ? default : this.Strategy.AvgLapTime, this.SimulationTelemetryDatabase)
	}

	computeAvailableTyreSets(availableTyreSets) {
		local compound, translatedCompounds, index, count

		availableTyreSets := availableTyreSets.Clone()

		translatedCompounds := collect(this.TyreCompounds, translate)

		loop this.PitstopsListView.GetCount() {
			index := inList(translatedCompounds, this.PitstopsListView.GetText(A_Index, 5))

			if index {
				compound := this.TyreCompounds[index]

				if availableTyreSets.Has(compound) {
					count := (availableTyreSets[compound] - 1)

					if (count > 0)
						availableTyreSets[compound] := count
					else
						availableTyreSets.Delete(compound)
				}
			}
		}

		return availableTyreSets
	}

	initializeAvailableTyreSets(strategy) {
		strategy.AvailableTyreSets := this.computeAvailableTyreSets(strategy.AvailableTyreSets)
	}

	getTrafficScenario(strategy, targetPitstop, randomFactor, numScenarios, useLapTimeVariation, useDriverErrors, usePitstops, overTakeDelta) {
		local lastLap := this.LastLap
		local targetLap := targetPitstop.Lap + 1
		local pitstopWindow := this.Window["variationWindowEdit"].Text
		local pitstops := CaseInsenseMap()
		local carStatistics := CaseInsenseMap()
		local positions, startLap, endLap, avgLapTime, driver, stintLength, formationLap, postRaceLap
		local fuelCapacity, safetyFuel, pitstopDelta, pitstopFuelService, pitstopTyreService, pitstopServiceOrder
		local lastPositions, lastRunnings, count, laps, consideredLaps, curLap, carPositions, nextRunnings
		local lapTime, potential, raceCraft, speed, consistency, carControl
		local rnd, delta, running, nr, position, ignore, nextPositions, runnings, car

		carPitstop(car, lap) {
			local stintLength := 0
			local carPitstops

			if !pitstops.Has(car) {
				carPitstops := this.Pitstops[getMultiMapValue(positions, "Position Data", "Car." . A_Index . ".ID", 0)]

				if (carPitstops.Length > 0) {
					loop carPitstops.Length
						stintLength += (carPitstops[A_Index].Lap - ((A_Index > 1) ? carPitstops[A_Index - 1].Lap : 0))

					if (Abs(carPitstops[carPitstops.Length].Lap + Round(stintLength / carPitstops.Length) - lap) < pitstopWindow) {
						pitstops[car] := true

						return true
					}
				}
				else {
					rnd := Random(0.0, 1.0)

					if (rnd < (randomFactor / 100)) {
						pitstops[car] := true

						return true
					}
				}
			}

			return false
		}

		if (this.SessionActive && lastLap) {
			positions := lastLap.Positions

			if positions {
				startLap := lastLap.Nr
				endLap := targetLap
				avgLapTime := Min(lastLap.Laptime, this.CurrentStint.AvgLapTime)

				positions := parseMultiMap(positions)

				driver := getMultiMapValue(positions, "Position Data", "Driver.Car")

				stintLength := false
				formationLap := false
				postRaceLap := false
				fuelCapacity := false
				safetyFuel := false
				pitstopDelta := false
				pitstopFuelService := false
				pitstopTyreService := false
				pitstopServiceOrder := "Simultaneous"

				this.getSessionSettings(&stintLength, &formationLap, &postRaceLap, &fuelCapacity, &safetyFuel
									  , &pitstopDelta, &pitstopFuelService, &pitstopTyreService, &pitstopServiceOrder)

				lastPositions := []
				lastRunnings := []

				count := getMultiMapValue(positions, "Position Data", "Car.Count", 0)

				loop count {
					lastPositions.Push(getMultiMapValue(positions, "Position Data", "Car." . A_Index . ".Position", 0))
					lastRunnings.Push(getMultiMapValue(positions, "Position Data", "Car." . A_Index . ".Lap", 0)
									+ getMultiMapValue(positions, "Position Data", "Car." . A_Index . ".Lap.Running", 0))
				}

				laps := CaseInsenseWeakMap()

				consideredLaps := []

				loop Min(startLap, 10)
					consideredLaps.Push(startLap - (A_Index - 1))

				loop count {
					this.computeCarStatistics(A_Index, consideredLaps, &lapTime, &potential, &raceCraft, &speed, &consistency, &carControl)

					carStatistics[A_Index] := [lapTime, potential, raceCraft, speed, consistency, carControl]
				}

				loop (endLap - startLap) {
					curLap := A_Index

					carPositions := []
					nextRunnings := []

					loop count {
						lapTime := true
						potential := true
						raceCraft := true
						speed := true
						consistency := true
						carControl := true

						lapTime := carStatistics[A_Index][1]
						potential := carStatistics[A_Index][2]
						raceCraft := carStatistics[A_Index][3]
						speed := carStatistics[A_Index][4]
						consistency := carStatistics[A_Index][5]
						carControl := carStatistics[A_Index][6]

						if useLapTimeVariation {
							rnd := Random(-1.0, 1.0)

							lapTime += (rnd * ((5 - consistency) / 5) * (randomFactor / 100))
						}

						if useDriverErrors {
							rnd := Random(0.0, 1.0)

							lapTime += (rnd * ((5 - carControl) / 5) * (randomFactor / 100))
						}

						if (usePitstops && (A_Index != driver) && carPitstop(A_Index, (startLap + curLap)))
							lapTime += strategy.calcPitstopDuration(fuelCapacity, true)

						if ((A_Index == driver) && ((startLap + curLap) == targetLap))
							lapTime += strategy.calcPitstopDuration(targetPitstop.RefuelAmount, targetPitstop.TyreChange)

						if lapTime
							delta := (((avgLapTime + lapTime) / lapTime) - 1)
						else
							delta := 0

						running := (lastRunnings[A_Index] + delta)

						nextRunnings.Push(running)
						carPositions.Push(Array(A_Index, lapTime, running))
					}

					bubbleSort(&carPositions, (a, b) => a[3] < b[3])

					for nr, position in carPositions
						position[3] += ((lastPositions[position[1]] - nr) * (overTakeDelta / (position[2] ? position[2] : 0.01)))

					bubbleSort(&carPositions, (a, b) => a[3] < b[3])

					nextPositions := []

					loop count
						nextPositions.Push(false)

					for nr, position in carPositions {
						car := position[1]

						nextPositions[car] := nr
						nextRunnings[car] := position[3]
					}

					runnings := []

					for ignore, running in nextRunnings
						runnings.Push(running - Floor(running))

					laps[startLap + A_Index] := {Positions: nextPositions, Runnings: runnings}

					lastPositions := nextPositions
					lastRunnings := nextRunnings
				}

				return {Driver: driver, Laps: laps}
			}
		}

		return false
	}

	getTrafficPositions(trafficScenario, targetLap, &driver, &positions, &runnings) {
		if (trafficScenario && trafficScenario.Laps.Has(targetLap)) {
			if driver
				driver := trafficScenario.Driver

			if positions
				positions := trafficScenario.Laps[targetLap].Positions

			if runnings
				runnings := trafficScenario.Laps[targetLap].Runnings

			return true
		}
		else {
			if driver
				driver := false

			if positions
				positions := []

			if runnings
				runnings := []

			return false
		}
	}

	chooseScenario(strategy) {
		if strategy {
			if this.Strategy
				strategy.PitstopRule := this.Strategy.PitstopRule

			this.selectStrategy(strategy, true)
		}
	}

	startWorking(state := true) {
		local start := false
		local document := this.WaitViewer.document
		local html, curAutoActivate

		if state {
			start := (this.iWorking == 0)

			this.iWorking += 1

			if !start
				return false
		}
		else {
			this.iWorking -= 1

			if (this.iWorking > 0)
				return
			else
				this.iWorking := 0
		}

		if state {
			this.Window.Opt("+Disabled")

			this.WaitViewer.Show()
		}
		else {
			this.WaitViewer.Hide()

			curAutoActivate := this.Window.AutoActivate

			try {
				this.Window.AutoActivate := false

				this.Window.Opt("-Disabled")
			}
			finally {
				this.Window.AutoActivate := curAutoActivate
			}
		}

		return (start || (this.iWorking == 0))
	}

	finishWorking() {
		this.startWorking(false)
	}

	isWorking() {
		return (this.iWorking > 0)
	}

	initializeSession() {
		local directory, reportDirectory

		this.iSessionFinished := false
		this.iSessionLoaded := false

		if this.SessionActive {
			directory := this.SessionDirectory

			deleteDirectory(directory)

			DirCreate(directory)

			reportDirectory := (directory . "Race Report")

			deleteDirectory(reportDirectory)

			DirCreate(reportDirectory)

			this.ReportViewer.setReport(reportDirectory)
		}

		pitstopSettings(kClose)

		this.SetupsListView.Delete()

		this.iSelectedSetup := false

		this.PlanListView.Delete()

		this.iSelectedPlanStint := false

		this.StintsListView.Delete()

		this.LapsListView.Delete()

		this.PitstopsListView.Delete()

		this.Control["driverDropDown"].Delete()

		this.iAvailableDrivers := []
		this.iSelectedDrivers := false

		if this.SessionActive
			this.loadSessionDrivers()
		else {
			this.Control["setupDriverDropDownMenu"].Delete()
			this.Control["planDriverDropDownMenu"].Delete()
		}

		this.Control["pitstopDriverDropDownMenu"].Delete()
		this.Control["pitstopDriverDropDownMenu"].Add([translate("No driver change")])
		this.Control["pitstopDriverDropDownMenu"].Choose(1)

		this.iTeamDrivers := []
		this.iTeamDriversVersion := false

		this.iDrivers := []
		this.iStints := CaseInsenseWeakMap()
		this.iLaps := CaseInsenseWeakMap()

		this.iPitstops := CaseInsenseMap()
		this.iLastPitstopUpdate := false

		this.iLastLap := false
		this.iCurrentStint := false

		this.iTelemetryDatabase := false
		this.iPressuresDatabase := false
		this.iSessionStore := false

		this.iSelectedReport := false
		this.iSelectedChartType := false
		this.iSelectedDetailReport := false

		this.iSetupsVersion := false
		this.iSelectedSetup := false

		this.iPlanVersion := false
		this.iDate := this.Control["sessionDateCal"].Value
		this.iTime := this.Control["sessionTimeEdit"].Value
		this.iSelectedPlanStint := false

		this.iSimulator := false
		this.iCar := false
		this.iTrack := false

		this.iWeather := false
		this.iWeather10Min := false
		this.iWeather30Min := false
		this.iAirTemperature := false
		this.iTrackTemperature := false

		this.iTyreCompound := false
		this.iTyreCompoundColor := false

		this.iStrategy := false

		this.showChart(false)
		this.showDetails(false, false)
	}

	initializeSimulator(simulator, car, track, force := false) {
		local row, compound

		if (force || !this.Simulator || (this.Simulator != simulator) || (this.Car != car) || (this.Track != track)) {
			this.iSimulator := simulator
			this.iCar := car
			this.iTrack := track

			if (this.Simulator = "") {
				this.iSimulator := false
				this.iCar := false
				this.iTrack := false
			}

			if this.Simulator {
				compounds := SessionDatabase.getTyreCompounds(simulator, car, track)

				this.iTyreCompounds := compounds

				this.Control["setupCompoundDropDownMenu"].Delete()
				this.Control["setupCompoundDropDownMenu"].Add(collect(compounds, translate))

				row := this.SetupsListView.GetNext(0)

				if row
					this.Control["setupCompoundDropDownMenu"].Choose(inList(collect(this.TyreCompounds, translate), normalizeCompound(this.SetupsListView.GetText(row, 3))))
				else
					this.Control["setupCompoundDropDownMenu"].Choose((compounds.Length > 0) ? 1 : 0)

				this.Control["pitstopTyreCompoundDropDown"].Delete()
				this.Control["pitstopTyreCompoundDropDown"].Add(collect(concatenate(["No Tyre Change"], compounds), translate))
				this.Control["pitstopTyreCompoundDropDown"].Choose(1)
			}
		}
	}

	initializeReports() {
		local raceData, drivers, positions, times

		if !this.Simulator {
			raceData := true
			drivers := false
			positions := false
			times := false

			this.ReportViewer.loadReportData(false, &raceData, &drivers, &positions, &times)

			this.initializeSimulator(getMultiMapValue(raceData, "Session", "Simulator", false)
								   , getMultiMapValue(raceData, "Session", "Car")
								   , getMultiMapValue(raceData, "Session", "Track"))
		}
	}

	computeRepairs(bodywork, suspension, engine) {
		local repairs := ""

		if bodywork
			repairs := translate("Bodywork")

		if suspension {
			if (StrLen(repairs) > 0)
				repairs .= ", "

			repairs .= translate("Suspension")
		}

		if engine {
			if (StrLen(repairs) > 0)
				repairs .= ", "

			repairs .= translate("Engine")
		}

		return ((StrLen(repairs) > 0) ? repairs : "-")
	}

	loadNewStints(currentStint) {
		local session := this.SelectedSession[true]
		local newStints := []
		local ignore, identifier, newStint, time, identifier, driver, message, stint

		if (!this.CurrentStint || (currentStint.Nr > this.CurrentStint.Nr)) {
			for ignore, identifier in string2Values(";", this.Connector.GetSessionStints(session))
				if !this.Stints.Has(identifier) {
					newStint := parseObject(this.Connector.GetStint(identifier))
					newStint.Nr := (newStint.Nr + 0)

					try {
						time := this.Connector.GetStintValue(identifier, "Time")
					}
					catch Any as exception {
						time := false
					}

					if (!time || (time == ""))
						newStint.StartTime := ((newStint.Nr == 1) ? (A_Now . "") : false)
					else
						newStint.StartTime := time

					try {
						newStint.ID := this.Connector.GetStintValue(identifier, "ID")

						if (newStint.ID = "")
							newStint.ID := false
					}
					catch Any as exception {
						newStint.ID := false
					}

					newStints.Push(newStint)
				}

			loop newStints.Length {
				stint := newStints[A_Index]
				identifier := stint.Identifier

				driver := parseObject(this.Connector.GetDriver(this.Connector.GetStintDriver(identifier)))
				driver.ID := stint.ID

				driver := this.createDriver(driver)

				message := (translate("Load stint (Stint: ") . stint.Nr . translate(", Driver: ") . driver.FullName . translate(")"))

				this.showMessage(message)

				logMessage(kLogInfo, message)

				stint.Driver := driver
				driver.Stints.Push(stint)
				stint.FuelConsumption := 0.0
				stint.Accidents := 0
				stint.Penalties := 0
				stint.Weather := "-"
				stint.Compound := "-"
				stint.StartPosition := "-"
				stint.EndPosition := "-"
				stint.AvgLaptime := "-"
				stint.Potential := "-"
				stint.RaceCraft := "-"
				stint.Speed := "-"
				stint.Consistency := "-"
				stint.CarControl := "-"

				stint.Laps := []

				this.Stints[identifier] := stint
				this.Stints[stint.Nr] := stint
			}
		}

		bubbleSort(&newStints, (a, b) => a.Nr > b.Nr)

		return newStints
	}

	loadNewLaps(stint) {
		local stintLaps := string2Values(";" , this.Connector.GetStintLaps(stint.Identifier))
		local newLaps := []
		local newTelemetry := false
		local ignore, identifier, newLap, count, lap, tries, rawData, data, damage, ignore, value
		local fuelConsumption, car, pLap

		for ignore, identifier in stintLaps
			if !this.Laps.Has(identifier) {
				newLap := parseObject(this.Connector.GetLap(identifier))
				newLap.Nr := (newLap.Nr + 0)

				if !this.Laps.Has(newLap.Nr)
					newLaps.Push(newLap)
			}

		bubbleSort(&newLaps, (a, b) => a.Nr > b.Nr)

		count := newLaps.Length

		loop count {
			lap := newLaps[A_Index]
			identifier := lap.Identifier

			lap.Stint := stint

			tries := ((A_Index == count) ? 30 : 5)

			while (tries > 0) {
				rawData := this.Connector.GetLapValue(identifier, "Telemetry Data")

				if (!rawData || (rawData == "")) {
					tries -= 1

					this.showMessage(translate("Waiting for data"))

					if (tries <= 0) {
						this.showMessage(translate("Give up - use default values"))

						newLaps.RemoveAt(lap.Nr, newLaps.Length - lap.Nr + 1)

						return newLaps
					}
					else
						Sleep(400)
				}
				else {
					this.showMessage(translate("Load lap data (Lap: ") . lap.Nr . translate(")"))

					if (getLogLevel() <= kLogInfo)
						logMessage(kLogInfo, translate("Load lap data (Lap: ") . lap.Nr . translate("), Data: `n`n") . rawData . "`n")

					break
				}
			}

			data := parseMultiMap(rawData)

			lap.Telemetry := rawData

			newTelemetry := data

			damage := 0

			for ignore, value in string2Values(",", getMultiMapValue(data, "Car Data", "BodyworkDamage"))
				damage += value

			for ignore, value in string2Values(",", getMultiMapValue(data, "Car Data", "SuspensionDamage"))
				damage += value

			lap.Damage := damage

			if ((lap.Nr == 1) && (damage > 0))
				lap.Accident := true
			else {
				pLap := this.getPreviousLap(lap)

				if ((lap.Nr > 1) && pLap && (damage > pLap.Damage))
					lap.Accident := true
				else
					lap.Accident := false
			}

			lap.Penalty := getMultiMapValue(data, "Stint Data", "Penalty", false)

			lap.EngineDamage := getMultiMapValue(data, "Car Data", "EngineDamage", 0)

			lap.FuelRemaining := Round(getMultiMapValue(data, "Car Data", "FuelRemaining"), 1)

			if ((lap.Nr == 1) || ((stint.Laps.Length > 0) && (stint.Laps[1] == lap)))
				lap.FuelConsumption := "-"
			else {
				pLap := this.getPreviousLap(lap)

				fuelConsumption := (pLap ? (pLap.FuelRemaining - lap.FuelRemaining) : 0)

				lap.FuelConsumption := ((fuelConsumption > 0) ? Round(fuelConsumption, 2) : "-")
			}

			lap.Laptime := Round(getMultiMapValue(data, "Stint Data", "LapLastTime") / 1000, 1)

			lap.RemainingSessionTime := getMultiMapValue(data, "Session Data", "SessionTimeRemaining")
			lap.RemainingDriverTime := getMultiMapValue(data, "Stint Data", "DriverTimeRemaining", "-")

			if (lap.RemainingDriverTime != "-")
				lap.RemainingDriverTime := Round(lap.RemainingDriverTime / 1000)

			lap.RemainingStintTime := getMultiMapValue(data, "Stint Data", "StintTimeRemaining", "-")

			if (lap.RemainingStintTime != "-")
				lap.RemainingStintTime := Round(lap.RemainingStintTime / 1000)

			lap.Map := getMultiMapValue(data, "Car Data", "Map")
			lap.TC := getMultiMapValue(data, "Car Data", "TC")
			lap.ABS := getMultiMapValue(data, "Car Data", "ABS")

			lap.Weather := getMultiMapValue(data, "Weather Data", "Weather")
			lap.Weather10Min := getMultiMapValue(data, "Weather Data", "Weather10Min")
			lap.Weather30Min := getMultiMapValue(data, "Weather Data", "Weather30Min")
			lap.AirTemperature := Round(getMultiMapValue(data, "Weather Data", "Temperature"), 1)
			lap.TrackTemperature := Round(getMultiMapValue(data, "Track Data", "Temperature"), 1)
			lap.Grip := getMultiMapValue(data, "Track Data", "Grip")

			lap.Compound := compound(getMultiMapValue(data, "Car Data", "TyreCompound")
								   , getMultiMapValue(data, "Car Data", "TyreCompoundColor"))

			try {
				tries := ((A_Index == count) ? 30 : 5)

				while (tries > 0) {
					rawData := this.Connector.GetLapValue(identifier, "Positions Data")

					if (!rawData || (rawData = "")) {
						tries -= 1

						this.showMessage(translate("Waiting for data"))

						if (tries <= 0) {
							this.showMessage(translate("Give up - use default values"))

							throw "No data..."
						}
						else
							Sleep(400)
					}
					else
						break
				}

				data := parseMultiMap(rawData)

				lap.Positions := rawData

				this.updatePitstopState(lap, data)

				car := getMultiMapValue(data, "Position Data", "Driver.Car")

				if car
					lap.Position := getMultiMapValue(data, "Position Data", "Car." . car . ".Position")
				else
					throw "No data..."
			}
			catch Any as exception {
				if (exception != "No data...")
					logError(exception)

				if (lap.Nr > 1) {
					pLap := this.getPreviousLap(lap)

					if pLap {
						lap.Positions := pLap.Positions
						lap.Position := pLap.Position
					}
					else {
						lap.Positions := ""
						lap.Position := "-"
					}
				}
				else
					lap.Position := "-"
			}

			if (stint.Laps.Length == 0)
				stint.Lap := lap.Nr

			stint.Laps.Push(lap)
			stint.Driver.Laps.Push(lap)

			this.Laps[identifier] := lap
			this.Laps[lap.Nr] := lap
		}

		if (newTelemetry && newTelemetry.Has("Setup Data"))
			this.updatePitstopSettings(getMultiMapValues(newTelemetry, "Setup Data"))

		return newLaps
	}

	updatePitstops() {
		local lap, identifier, rawData

		if this.LastLap {
			lap := this.LastLap
			identifier := lap.Identifier

			try {
				rawData := this.Connector.GetLapValue(identifier, "Positions Data")

				if (rawData && (rawData != ""))
					this.updatePitstopState(lap, parseMultiMap(rawData))

				if pitstopSettings("Visible") {
					rawData := this.Connector.GetLapValue(identifier, "Telemetry Data")

					if (rawData && (rawData != "") && InStr(rawData, "[Setup Data]"))
						this.updatePitstopSettings(getMultiMapValues(parseMultiMap(rawData), "Setup Data"))
				}
			}
			catch Any as exception {
				logError(exception)
			}
		}
	}

	updatePitstopSettings(settings) {
		pitstopSettings("Update", settings)
	}

	updatePitstopState(lap, data) {
		local carID, delta, pitstops, pitstop

		if !this.iLastPitstopUpdate {
			this.iLastPitstopUpdate := Round(lap.RemainingSessionTime / 1000)

			delta := 0
		}
		else {
			delta := (this.iLastPitstopUpdate - Round(lap.RemainingSessionTime / 1000))

			this.iLastPitstopUpdate -= delta
		}

		loop getMultiMapValue(data, "Position Data", "Car.Count", 0) {
			if (getMultiMapValue(data, "Position Data", "Car." . A_Index . ".InPitlane", false)
			 || getMultiMapValue(data, "Position Data", "Car." . A_Index . ".InPit", false)) {
				carID := getMultiMapValue(data, "Position Data", "Car." . A_Index . ".ID", A_Index)

				pitstops := this.Pitstops[carID]

				if (pitstops.Length = 0)
					pitstops.Push(RaceCenter.Pitstop(carID, this.iLastPitstopUpdate, lap.Nr))
				else {
					pitstop := pitstops[pitstops.Length]

					if ((pitstop.Time - pitstop.Duration - (delta + 20)) < this.iLastPitstopUpdate)
						pitstop.Duration := (pitstop.Duration + delta)
					else
						pitstops.Push(RaceCenter.Pitstop(carID, this.iLastPitstopUpdate, lap.Nr))
				}
			}
		}
	}

	updateStint(stint) {
		local laps, numLaps, lapTimes, airTemperatures, trackTemperatures
		local ignore, lap, consumption, weather

		stint.FuelConsumption := 0.0
		stint.Accidents := 0
		stint.Penalties := 0
		stint.Weather := ""

		laps := stint.Laps
		numLaps := laps.Length

		lapTimes := []
		airTemperatures := []
		trackTemperatures := []

		for ignore, lap in laps {
			if (lap.Nr > 1) {
				consumption := lap.FuelConsumption

				if isNumber(consumption)
					stint.FuelConsumption += ((this.getPreviousLap(lap).FuelConsumption = "-") ? (consumption * 2) : consumption)
			}

			if lap.Accident
				stint.Accidents += 1

			if lap.Penalty
				stint.Penalties += 1

			lapTimes.Push(lap.Laptime)
			airTemperatures.Push(lap.AirTemperature)
			trackTemperatures.Push(lap.TrackTemperature)

			if (A_Index == 1) {
				stint.Compound := lap.Compound
				stint.StartPosition := lap.Position
			}
			else if (A_Index == numLaps)
				stint.EndPosition := lap.Position

			weather := lap.Weather

			if (stint.Weather = "")
				stint.Weather := weather
			else if !inList(string2Values(",", stint.Weather), weather)
				stint.Weather .= (", " . weather)
		}

		stint.AvgLaptime := Round(average(laptimes), 1)
		stint.BestLaptime := Round(minimum(laptimes), 1)
		stint.FuelConsumption := Round(stint.FuelConsumption, 2)
		stint.AirTemperature := Round(average(airTemperatures), 1)
		stint.TrackTemperature := Round(average(trackTemperatures), 1)

		this.StintsListView.Modify(stint.Row, "", stint.Nr, stint.Driver.FullName, values2String(", ", collect(string2Values(",", stint.Weather), translate)*)
												, translate(stint.Compound), stint.Laps.Length, stint.StartPosition, stint.EndPosition, lapTimeDisplayValue(stint.AvgLaptime)
												, displayValue("Float", convertUnit("Volume", stint.FuelConsumption)), stint.Accidents, stint.Penalties
												, stint.Potential, stint.RaceCraft, stint.Speed, stint.Consistency, stint.CarControl)

		this.updatePlan(stint)
	}

	syncLaps(lastLap) {
		local session := this.SelectedSession[true]
		local message, currentStint, first, newData, newStints, updatedStints, ignore, stint, lap
		local selected, remainingFuel, fuelConsumption, penalty

		message := (translate("Syncing laps (Lap: ") . lastLap.Nr . translate(")"))

		this.showMessage(message)

		if (getLogLevel() <= kLogInfo)
			logMessage(kLogInfo, message)

		try {
			currentStint := this.Connector.GetSessionCurrentStint(session)

			if currentStint {
				currentStint := parseObject(this.Connector.GetStint(currentStint))
				currentStint.Nr := (currentStint.Nr + 0)
			}
		}
		catch Any as exception {
			currentStint := false
		}

		first := (!this.CurrentStint || !this.LastLap)

		if (!currentStint
		 || (!lastLap && this.CurrentStint && !((currentStint.Nr = (this.CurrentStint.Nr + 1)) && (currentStint.Lap == this.LastLap.Nr)))
		 || (this.CurrentStint && ((currentStint.Nr < this.CurrentStint.Nr)
								|| ((currentStint.Nr = this.CurrentStint.Nr) && (currentStint.Identifier != this.CurrentStint.Identifier))))
		 || (this.LastLap && (lastLap.Nr < this.LastLap.Nr))) {
			this.initializeSession()

			first := true
		}

		newData := first

		if (!this.LastLap || (lastLap.Nr > this.LastLap.Nr)) {
			try {
				newStints := this.loadNewStints(currentStint)

				currentStint := this.Stints[currentStint.Identifier]

				updatedStints := []

				if this.CurrentStint
					updatedStints := [this.CurrentStint]

				for ignore, stint in newStints {
					this.StintsListView.Add("", stint.Nr, stint.Driver.FullName, values2String(", ", collect(string2Values(",", stint.Weather), translate)*)
											  , translate(stint.Compound), stint.Laps.Length, stint.StartPosition, stint.EndPosition, lapTimeDisplayValue(stint.AvgLaptime)
											  , displayValue("Float", convertUnit("Volume", stint.FuelConsumption)), stint.Accidents, stint.Penalties
											  , stint.Potential, stint.RaceCraft, stint.Speed, stint.Consistency, stint.CarControl)

					stint.Row := this.StintsListView.GetCount()

					updatedStints.Push(stint)
				}

				if first {
					this.StintsListView.ModifyCol()

					loop this.StintsListView.GetCount("Col")
						this.StintsListView.ModifyCol(A_Index, "AutoHdr")
				}

				for ignore, stint in updatedStints {
					for ignore, lap in this.loadNewLaps(stint) {
						newData := true

						remainingFuel := lap.FuelRemaining

						if isNumber(remainingFuel)
							remainingFuel := displayValue("Float", convertUnit("Volume", remainingFuel))

						fuelConsumption := lap.FuelConsumption

						if isNumber(fuelConsumption)
							fuelConsumption := displayValue("Float", convertUnit("Volume", fuelConsumption))

						penalty := ""

						if lap.Penalty {
							penalty := lap.Penalty

							if (InStr(penalty, "SG") = 1) {
								penalty := ((StrLen(penalty) > 2) ? (A_Space . SubStr(penalty, 3)) : "")

								penalty := (translate("Stop and Go") . penalty)
							}
							else if (penalty = "Time")
								penalty := translate("Time")
							else if (penalty = "DT")
								penalty := translate("Drive Through")
							else if (penalty == true)
								penalty := "x"
						}

						this.LapsListView.Add("", lap.Nr, stint.Nr, stint.Driver.FullName, lap.Position, translate(lap.Weather), translate(lap.Grip)
												, lapTimeDisplayValue(lap.Laptime), displayNullValue(fuelConsumption), remainingFuel, "-, -, -, -"
												, lap.Accident ? translate("x") : "", penalty)

						lap.Row := this.LapsListView.GetCount()
					}
				}

				if !newData
					return false

				if first {
					this.LapsListView.ModifyCol()

					loop this.LapsListView.GetCount("Col")
						this.LapsListView.ModifyCol(A_Index, "AutoHdr")
				}

				for ignore, stint in updatedStints
					this.updateStint(stint)

				this.iLastLap := this.Laps[lastLap.Nr]
				this.iCurrentStint := currentStint

				lastLap := this.LastLap

				if lastLap {
					this.iWeather := lastLap.Weather
					this.iAirTemperature := lastLap.AirTemperature
					this.iTrackTemperature := lastLap.TrackTemperature

					if lastLap.HasProp("Weather10Min") {
						this.iWeather10Min := lastLap.Weather10Min
						this.iWeather30Min := lastLap.Weather30Min
					}
					else {
						this.iWeather10Min := lastLap.Weather
						this.iWeather30Min := lastLap.Weather
					}
				}

				currentStint := this.CurrentStint

				if currentStint {
					this.iTyreCompound := compound(currentStint.Compound)
					this.iTyreCompoundColor := compoundColor(currentStint.Compound)
				}
			}
			catch Any as exception {
				logError(exception)

				return newData
			}
		}

		return newData
	}

	syncRaceReport() {
		local lastLap := this.LastLap
		local directory, data, lap, message, raceInfo, pitstops, newData, missingLaps, lapData, key, value
		local times, positions, laps, drivers
		local mTimes, mPositions, mLaps, mDrivers, newLine, line, fileName

		if lastLap
			lastLap := lastLap.Nr
		else
			return

		directory := this.SessionDirectory . "Race Report"

		DirCreate(directory)

		directory .= "\"

		data := readMultiMap(directory . "Race.data")

		if (data.Count == 0)
			lap := 1
		else
			lap := (getMultiMapValue(data, "Laps", "Count") + 1)

		if (lap == 1) {
			try {
				try {
					if this.Laps.Has(lap)
						raceInfo := this.Connector.getLapValue(this.Laps[lap].Identifier, "Race Strategist Race Info")
					else
						raceInfo := false
				}
				catch Any as exception {
					logError(exception)

					raceInfo := false
				}

				if (!raceInfo || (raceInfo == ""))
					return false

				if !FileExist(directory . "Race.data")
					FileAppend(raceInfo, directory . "Race.data")
			}
			catch Any as exception {
				logError(exception)
			}

			data := readMultiMap(directory . "Race.data")

			if (getMultiMapValue(data, "Cars", "Count") = kNotInitialized)
				setMultiMapValue(data, "Cars", "Count", 0)

			if (getMultiMapValue(data, "Cars", "Driver") = kNotInitialized)
				setMultiMapValue(data, "Cars", "Driver", 0)
		}
		else {
			message := (translate("Syncing race report (Lap: ") . (lap - 1) . translate(")"))

			this.showMessage(message)

			if (getLogLevel() <= kLogInfo)
				logMessage(kLogInfo, message)
		}

		pitstops := false
		newData := false
		missingLaps := 0

		while (lap <= lastLap) {
			try {
				if this.Laps.Has(lap)
					lapData := this.Connector.getLapValue(this.Laps[lap].Identifier, "Race Strategist Race Lap")
				else
					lapData := false

				if (lapData && (lapData != "")) {
					this.showMessage(translate("Updating race report (Lap: ") . lap . translate(")"))

					if (getLogLevel() <= kLogInfo)
						logMessage(kLogInfo, translate("Updating race report (Lap: ") . lap . translate("), Data: `n`n") . lapData . "`n")

					lapData := parseMultiMap(lapData)
				}
				else if (lap = lastLap)
					throw "No data..."
				else {
					missingLaps +=1
					lap += 1

					continue
				}
			}
			catch Any as exception {
				if (exception != "No data...")
					logError(exception)

				if newData
					writeMultiMap(directory . "Race.data", data)

				return newData
			}

			if (lapData.Count == 0)
				return newData

			for key, value in getMultiMapValues(lapData, "Lap")
				setMultiMapValue(data, "Laps", key, value)

			pitstops := getMultiMapValue(lapData, "Pitstop", "Laps", "")

			setMultiMapValue(data, "Laps", "Pitstops", pitstops)

			times := getMultiMapValue(lapData, "Times", lap)
			positions := getMultiMapValue(lapData, "Positions", lap)
			laps := getMultiMapValue(lapData, "Laps", lap)
			drivers := getMultiMapValue(lapData, "Drivers", lap)

			if (missingLaps > 0) {
				mTimes := times
				mPositions := positions
				mLaps := laps
				mDrivers := drivers

				loop missingLaps {
					times .= ("`n" . mTimes)
					positions .= ("`n" . mPositions)
					laps .= ("`n" . mLaps)
					drivers .= ("`n" . mDrivers)
				}
			}

			missingLaps := 0

			newLine := ((lap > 1) ? "`n" : "")

			line := (newLine . times)

			FileAppend(line, directory . "Times.CSV")

			line := (newLine . positions)

			FileAppend(line, directory . "Positions.CSV")

			line := (newLine . laps)

			FileAppend(line, directory . "Laps.CSV")

			line := (newLine . drivers)
			fileName := (directory . "Drivers.CSV")

			FileAppend(line, fileName, "UTF-16")

			removeMultiMapValue(data, "Laps", "Lap")
			setMultiMapValue(data, "Laps", "Count", lap)

			newData := true
			lap += 1
		}

		if newData
			writeMultiMap(directory . "Race.data", data)

		return newData
	}

	syncTrackMap() {
		local rawData

		if this.LastLap {
			rawData := this.Connector.GetLapValue(this.LastLap.Identifier, "Telemetry Update")

			if (rawData && (rawData != "")) {
				this.LastLap.Telemetry := rawData

				return true
			}
		}

		return false
	}

	syncTelemetry(load := false) {
		local lastLap := this.LastLap
		local tyreChange := true
		local newData, message, session, telemetryDB, tyresTable, lap, runningLap, driverID
		local telemetryData, pressures, temperatures, wear, lapPressures, pressure

		wasPitstop(lap, &tyreChange := false) {
			local fuel, tyreCompound, tyreCompoundColor, tyreSet, tyrePressures

			lap := this.Laps[lap]

			if (Abs(lap.Stint.Lap - lap.Nr) <= 1) {
				this.getStintSetup(lap.Stint.Nr, false, &fuel, &tyreCompound, &tyreCompoundColor, &tyreSet, &tyrePressures)

				tyreChange := (tyreCompound != false)

				return true
			}
			else
				return false
		}

		if lastLap
			lastLap := lastLap.Nr
		else
			return false

		static fails := 0

		newData := false

		if !load {
			message := (translate("Syncing telemetry data (Lap: ") . lastLap . translate(")"))

			this.showMessage(message)

			if (getLogLevel() <= kLogInfo)
				logMessage(kLogInfo, message)

			session := this.SelectedSession[true]
			telemetryDB := this.TelemetryDatabase

			tyresTable := telemetryDB.Database.Tables["Tyres"]

			lap := tyresTable.Length

			if (lap > 0)
				runningLap := tyresTable[lap]["Tyre.Laps"]
			else
				runningLap := 0

			lap += 1

			while (lap <= lastLap) {
				if !this.Laps.Has(lap) {
					lap += 1

					continue
				}

				driverID := this.Laps[lap].Stint.ID

				pitstop := false

				try {
					telemetryData := this.Connector.GetSessionLapValue(session, lap, "Race Strategist Telemetry")

					if (!telemetryData || (telemetryData == ""))
						throw "No data..."
					else {
						this.showMessage(translate("Updating telemetry data (Lap: ") . lap . translate(")"))

						if (getLogLevel() <= kLogInfo)
							logMessage(kLogInfo, translate("Updating telemetry data (Lap: ") . lap . translate("), Data: `n`n") . telemetryData . "`n")
					}

					fails := 0
				}
				catch Any as exception {
					if (exception != "No data...")
						logError(exception)

					if ((lap = lastLap) && (fails++ < 3))
						return false
					else
						fails := 0

					telemetryData := values2String(";", "-", "-", "-", "-", "-", "-", "-", "-", "-", wasPitstop(lap), "n/a", "n/a", "n/a", "-", "-", ",,,", ",,,", "null,null,null,null")
				}

				telemetryData := string2Values(";", telemetryData)

				if (telemetryData.Length = 15)
					telemetryData.Push(",,,")

				if (telemetryData.Length = 16)
					telemetryData.Push(",,,")

				if (telemetryData.Length = 17)
					telemetryData.Push("null,null,null,null")

				if telemetryData[10] {
					telemetryData := ["-", "-", "-", "-", "-", "-", "-", "-", "-", true, "n/a", "n/a", "n/a", "-", "-", ",,,", ",,,", "null,null,null,null"]

					if (runningLap > 2) {
						wasPitstop(lap, &tyreChange)

						if tyreChange
							runningLap := 0
					}
				}

				runningLap += 1

				pressures := string2Values(",", telemetryData[16])
				temperatures := string2Values(",", telemetryData[17])

				if (telemetryData.Length >= 18)
					wear := string2Values(",", telemetryData[18])
				else
					wear := [kNull, kNull, kNull, kNull]

				telemetryDB.addElectronicEntry(telemetryData[4], telemetryData[5], telemetryData[6], telemetryData[14], telemetryData[15]
											 , telemetryData[11], telemetryData[12], telemetryData[13], telemetryData[7], telemetryData[8], telemetryData[9]
											 , driverID)

				telemetryDB.addTyreEntry(telemetryData[4], telemetryData[5], telemetryData[6], telemetryData[14], telemetryData[15], runningLap
									   , pressures[1], pressures[2], pressures[4], pressures[4]
									   , temperatures[1], temperatures[2], temperatures[3], temperatures[4]
									   , wear[1], wear[2], wear[3], wear[4]
									   , telemetryData[7], telemetryData[8], telemetryData[9]
									   , driverID)

				lapPressures := this.LapsListView.GetText(this.Laps[lap].Row, 10)

				if (lapPressures = "-, -, -, -")
					this.LapsListView.Modify(this.Laps[lap].Row, "Col10", values2String(", ", collect(pressures, p => isNumber(p) ? displayValue("Float", convertUnit("Pressure", p)) : "-")*))

				newData := true
				lap += 1
			}
		}

		return newData
	}

	syncTyrePressures(load := false) {
		local lastLap, tyresTable, ignore, pressureData, pressureFL, pressureFR, pressureRL, pressureRR, tyres
		local row, session, pressuresDB, message, newData, lap, flush, driverID
		local lapPressures, coldPressures, hotPressures, pressuresLosses, pressuresTable, pressures, pressure

		static fails := 0

		if load {
			lastLap := this.LastLap

			if lastLap
				lastLap := (lastLap.Nr + 0)

			tyresTable := this.TelemetryDatabase.Database.Tables["Tyres"]

			for ignore, pressureData in this.PressuresDatabase.Database.Tables["Tyres.Pressures"] {
				if !this.Laps.Has(A_Index)
					continue

				pressureFL := pressureData["Tyre.Pressure.Hot.Front.Left"]
				pressureFR := pressureData["Tyre.Pressure.Hot.Front.Right"]
				pressureRL := pressureData["Tyre.Pressure.Hot.Rear.Left"]
				pressureRR := pressureData["Tyre.Pressure.Hot.Rear.Right"]

				if (tyresTable.Length >= lastLap) {
					tyres := tyresTable[A_Index]

					if (isNull(pressureFL))
						pressureFL := tyres["Tyre.Pressure.Front.Left"]
					if (isNull(pressureFR))
						pressureFR := tyres["Tyre.Pressure.Front.Right"]
					if (isNull(pressureRL))
						pressureRL := tyres["Tyre.Pressure.Rear.Left"]
					if (isNull(pressureRR))
						pressureRR := tyres["Tyre.Pressure.Rear.Right"]
				}

				if this.Laps.Has(A_Index) {
					row := this.Laps[A_Index].Row

					if isNumber(pressureFL)
						pressureFL := displayValue("Float", convertUnit("Pressure", pressureFL))
					if isNumber(pressureFR)
						pressureFR := displayValue("Float", convertUnit("Pressure", pressureFR))
					if isNumber(pressureRL)
						pressureRL := displayValue("Float", convertUnit("Pressure", pressureRL))
					if isNumber(pressureRR)
						pressureRR := displayValue("Float", convertUnit("Pressure", pressureRR))

					this.LapsListView.Modify(row, "Col10", values2String(", ", displayNullValue(pressureFL), displayNullValue(pressureFR)
																			 , displayNullValue(pressureRL), displayNullValue(pressureRR)))
				}
			}

			return false
		}
		else {
			session := this.SelectedSession[true]
			pressuresDB := this.PressuresDatabase
			lastLap := this.LastLap

			if lastLap
				lastLap := lastLap.Nr
			else
				return

			message := (translate("Syncing tyre pressures (Lap: ") . lastLap . translate(")"))

			this.showMessage(message)

			if (getLogLevel() <= kLogInfo)
				logMessage(kLogInfo, message)

			pressuresTable := pressuresDB.Database.Tables["Tyres.Pressures"]
			lap := pressuresTable.Length

			newData := false
			lap += 1

			flush := (Abs(lastLap - lap) <= 2)

			while (lap <= lastLap) {
				if !this.Laps.Has(lap) {
					lap += 1

					continue
				}

				driverID := this.Laps[lap].Stint.ID

				try {
					lapPressures := this.Connector.GetSessionLapValue(session, lap, "Race Engineer Pressures")

					if (!lapPressures || (lapPressures == ""))
						throw "No data..."
					else {
						this.showMessage(translate("Updating tyre pressures (Lap: ") . lap . translate(")"))

						if (getLogLevel() <= kLogInfo)
							logMessage(kLogInfo, translate("Updating tyre pressures (Lap: ") . lap . translate("), Data: `n`n") . lapPressures . "`n")

						fails := 0
					}
				}
				catch Any as exception {
					if (exception != "No data...")
						logError(exception)

					if ((lap = lastLap) && (fails++ < 3))
						return false
					else
						fails := 0

					lapPressures := values2String(";", "-", "-", "-", "-", "-", "-", "-", "-", "-,-,-,-", "-,-,-,-", "-,-,-,-")
				}

				lapPressures := string2Values(";", lapPressures)

				while (lapPressures.Length < 11)
					lapPressures.Push("-,-,-,-")

				if (lapPressures[1] != "-")
					this.initializeSimulator(lapPressures[1], lapPressures[2], lapPressures[3])

				coldPressures := string2Values(",", lapPressures[9])
				hotPressures := string2Values(",", lapPressures[10])
				pressuresLosses := string2Values(",", lapPressures[11])

				coldPressures := collect(coldPressures, null)
				hotPressures := collect(hotPressures, null)
				pressuresLosses := collect(pressuresLosses, null)

				pressuresDB.updatePressures(lapPressures[4], lapPressures[5], lapPressures[6]
										  , lapPressures[7], lapPressures[8], coldPressures, hotPressures, pressuresLosses, driverID, flush)

				pressures := string2Values(",", lapPressures[10])

				loop 4 {
					pressure := pressures[A_Index]

					if isNumber(pressure)
						pressures[A_Index] := displayValue("Float", convertUnit("Pressure", pressure))
				}

				this.LapsListView.Modify(this.Laps[lap].Row, "Col10", values2String(", ", pressures*))

				newData := true
				lap += 1
			}

			if (newData && !flush)
				pressuresDB.Database.flush()

			return newData
		}
	}

	syncPitstops(newLaps := false) {
		local sessionStore := this.SessionStore
		local session := this.SelectedSession[true]
		local nextStop := (this.PitstopsListView.GetCount() + 1)
		local wasEmpty := (nextStop == 1)
		local newData := false
		local currentDriver := false
		local nextDriver := false
		local session, lap, fuel, tyreCompound, tyreCompoundColor, tyreSet
		local pressureFL, pressureFR, pressureRL, pressureRR, repairBodywork, repairSuspension, repairEngine
		local pressures, displayPressures, displayFuel, driverRequest, tries, pitstopNr, stint

		loop this.PitstopsListView.GetCount()
			if (this.PitstopsListView.GetNext(A_Index - 1, "C") != A_Index) {
				nextStop -= 1

				break
			}

		this.showMessage(translate("Updating pitstops"))

		if newLaps {
			try {
				state := this.Connector.GetSessionValue(session, "Race Engineer State")
			}
			catch Any as exception {
				logError(exception)
			}

			if (state && (state != "")) {
				if (getLogLevel() <= kLogInfo)
					logMessage(kLogInfo, translate("Updating pitstops, State: `n`n") . state . "`n")

				state := parseMultiMap(state)

				loop {
					lap := getMultiMapValue(state, "Session State", "Pitstop." . nextStop . ".Lap", false)

					if lap {
						fuel := Round(getMultiMapValue(state, "Session State", "Pitstop." . nextStop . ".Fuel", 0))
						tyreCompound := getMultiMapValue(state, "Session State", "Pitstop." . nextStop . ".Tyre.Compound", false)
						tyreCompoundColor := getMultiMapValue(state, "Session State", "Pitstop." . nextStop . ".Tyre.Compound.Color", false)
						tyreSet := getMultiMapValue(state, "Session State", "Pitstop." . nextStop . ".Tyre.Set", "-")
						pressureFL := getMultiMapValue(state, "Session State", "Pitstop." . nextStop . ".Tyre.Pressure.FL", "-")
						pressureFR := getMultiMapValue(state, "Session State", "Pitstop." . nextStop . ".Tyre.Pressure.FR", "-")
						pressureRL := getMultiMapValue(state, "Session State", "Pitstop." . nextStop . ".Tyre.Pressure.RL", "-")
						pressureRR := getMultiMapValue(state, "Session State", "Pitstop." . nextStop . ".Tyre.Pressure.RR", "-")
						repairBodywork := getMultiMapValue(state, "Session State", "Pitstop." . nextStop . ".Repair.Bodywork", false)
						repairSuspension := getMultiMapValue(state, "Session State", "Pitstop." . nextStop . ".Repair.Suspension", false)
						repairEngine := getMultiMapValue(state, "Session State", "Pitstop." . nextStop . ".Repair.Engine", false)
						driverRequest := getMultiMapValue(state, "Session State", "Pitstop." . nextStop . ".Driver.Request", false)

						if (tyreCompound && (tyreCompound != "-")) {
							pressures := values2String(", ", Round(pressureFL, 1), Round(pressureFR, 1)
														   , Round(pressureRL, 1), Round(pressureRR, 1))

							displayPressures := values2String(", ", displayValue("Float", convertUnit("Pressure", pressureFL))
																  , displayValue("Float", convertUnit("Pressure", pressureFR))
																  , displayValue("Float", convertUnit("Pressure", pressureRL))
																  , displayValue("Float", convertUnit("Pressure", pressureRR)))
						}
						else {
							tyreCompound := "-"
							tyreCompoundColor := false

							tyreSet := "-"
							pressures := "-, -, -, -"
							displayPressures := pressures
						}

						if isNumber(fuel) {
							if (fuel = 0)
								displayFuel := "-"
							else
								displayFuel := displayValue("Float", convertUnit("Volume", fuel))
						}
						else
							displayFuel := fuel

						if driverRequest {
							driverRequest := string2Values("|", driverRequest)

							currentDriver := string2Values(":", driverRequest[1])[1]
							nextDriver := string2Values(":", driverRequest[2])[1]
						}
						else {
							if (lap > 1) {
								if this.Laps.Has(lap - 1) {
									currentDriver := this.Laps[lap - 1].Stint.Driver.FullName

									if this.Laps.Has(lap + 1)
										nextDriver := this.Laps[lap + 1].Stint.Driver.FullName
									else if this.CurrentStint
										nextDriver := this.CurrentStint.Driver.FullName
									else
										nextDriver := false
								}
							}
							else {
								if this.Laps.Has(1)
									currentDriver := this.Laps[1].Stint.Driver.FullName

								if this.Laps.Has(2)
									nextDriver := this.Laps[2].Stint.Driver.FullName
								else if this.CurrentStint
									nextDriver := this.CurrentStint.Driver.FullName
								else
									nextDriver := false
							}

							if !currentDriver
								currentDriver := kNull

							if !nextDriver
								nextDriver := currentDriver
						}

						loop this.PitstopsListView.GetCount()
							if (this.PitstopsListView.GetNext(A_Index - 1, "C") != A_Index) {
								this.PitstopsListView.Delete(A_Index)

								break
							}

						this.PitstopsListView.Add("Check", nextStop, lap + 1, displayNullValue(nextDriver), displayFuel
														 , (tyreCompound = "-") ? tyreCompound : translate(compound(tyreCompound, tyreCompoundColor))
														 , ((tyreSet = 0) ? "-" : tyreSet), displayPressures
														 , this.computeRepairs(repairBodywork, repairSuspension, repairEngine))

						pressures := string2Values(",", pressures)

						sessionStore.remove("Pitstop.Data", {Status: "Planned"}, always.Bind(true))

						if this.Laps.Has(lap)
							stint := this.Laps[lap].Stint
						else
							stint := this.CurrentStint

						sessionStore.add("Pitstop.Data"
									   , Database.Row("Lap", lap, "Fuel", fuel, "Tyre.Compound", tyreCompound, "Tyre.Compound.Color", tyreCompoundColor, "Tyre.Set", tyreSet
													, "Tyre.Pressure.Cold.Front.Left", pressures[1], "Tyre.Pressure.Cold.Front.Right", pressures[2]
													, "Tyre.Pressure.Cold.Rear.Left", pressures[3], "Tyre.Pressure.Cold.Rear.Right", pressures[4]
													, "Repair.Bodywork", repairBodywork, "Repair.Suspension", repairSuspension, "Repair.Engine", repairEngine
													, "Driver.Current", currentDriver, "Driver.Next", nextDriver, "Status", "Performed"
													, "Stint", stint.Nr + 1))

						newData := true

						nextStop += 1
					}
					else if (nextStop >= getMultiMapValue(state, "Session State", "Pitstop.Last", 0))
						break
					else {
						this.PitstopsListView.Add("Check", nextStop, "-", "-", "-", "-", "-", "-, -, -, -", this.computeRepairs(false, false, false))

						sessionStore.add("Pitstop.Data"
									   , Database.Row("Lap", "-", "Fuel", "-", "Tyre.Compound", "-", "Tyre.Compound.Color", false, "Tyre.Set", "-"
													, "Tyre.Pressure.Cold.Front.Left", "-", "Tyre.Pressure.Cold.Front.Right", "-"
													, "Tyre.Pressure.Cold.Rear.Left", "-", "Tyre.Pressure.Cold.Rear.Right", "-"
													, "Repair.Bodywork", false, "Repair.Suspension", false, "Repair.Engine", false
													, "Driver.Current", kNull, "Driver.Next", kNull, "Status", "Performed"
													, "Stint", "-"))

						newData := true

						nextStop += 1
					}
				}
			}
		}

		if (!newData && this.LastLap) {
			try {
				state := this.Connector.GetLapValue(this.LastLap.Identifier, "Race Engineer Pitstop Pending")

				if ((!state || (state == "")) && (this.LastLap.Nr > 1))
					state := this.Connector.GetLapValue(this.Laps[this.LastLap.Nr - 1].Identifier, "Race Engineer Pitstop Pending")

				if (state && (state != "")) {
					state := parseMultiMap(state)

					pitstopNr := getMultiMapValue(state, "Pitstop Pending", "Pitstop.Planned.Nr", false)

					if (pitstopNr && (pitstopNr > this.PitstopsListView.GetCount())) {
						newData := true

						lap := getMultiMapValue(state, "Pitstop Pending", "Pitstop.Planned.Lap", "-")

						if !lap
							lap := "-"

						fuel := Round(getMultiMapValue(state, "Pitstop Pending", "Pitstop.Planned.Fuel", 0))
						tyreCompound := getMultiMapValue(state, "Pitstop Pending", "Pitstop.Planned.Tyre.Compound", false)
						tyreCompoundColor := getMultiMapValue(state, "Pitstop Pending", "Pitstop.Planned.Tyre.Compound.Color", false)
						tyreSet := getMultiMapValue(state, "Pitstop Pending", "Pitstop.Planned.Tyre.Set", "-")
						pressureFL := getMultiMapValue(state, "Pitstop Pending", "Pitstop.Planned.Tyre.Pressure.FL", "-")
						pressureFR := getMultiMapValue(state, "Pitstop Pending", "Pitstop.Planned.Tyre.Pressure.FR", "-")
						pressureRL := getMultiMapValue(state, "Pitstop Pending", "Pitstop.Planned.Tyre.Pressure.RL", "-")
						pressureRR := getMultiMapValue(state, "Pitstop Pending", "Pitstop.Planned.Tyre.Pressure.RR", "-")
						repairBodywork := getMultiMapValue(state, "Pitstop Pending", "Pitstop.Planned.Repair.Bodywork", false)
						repairSuspension := getMultiMapValue(state, "Pitstop Pending", "Pitstop.Planned.Repair.Suspension", false)
						repairEngine := getMultiMapValue(state, "Pitstop Pending", "Pitstop.Planned.Repair.Engine", false)
						driverRequest := getMultiMapValue(state, "Pitstop Pending", "Pitstop.Planned.Driver.Request", false)

						if (tyreCompound && (tyreCompound != "-")) {
							pressures := values2String(", ", Round(pressureFL, 1), Round(pressureFR, 1)
														   , Round(pressureRL, 1), Round(pressureRR, 1))

							displayPressures := values2String(", ", displayValue("Float", convertUnit("Pressure", pressureFL))
																  , displayValue("Float", convertUnit("Pressure", pressureFR))
																  , displayValue("Float", convertUnit("Pressure", pressureRL))
																  , displayValue("Float", convertUnit("Pressure", pressureRR)))
						}
						else {
							tyreCompound := "-"
							tyreCompoundColor := false

							tyreSet := "-"
							pressures := "-, -, -, -"
							displayPressures := pressures
						}

						if driverRequest {
							driverRequest := string2Values("|", driverRequest)

							currentDriver := string2Values(":", driverRequest[1])[1]
							nextDriver := string2Values(":", driverRequest[2])[1]
						}
						else {
							if this.Laps.Has(this.LastLap.Nr)
								currentDriver := this.Laps[this.LastLap.Nr].Stint.Driver.FullName

							if !currentDriver
								currentDriver := kNull

							nextDriver := currentDriver
						}

						if isNumber(fuel) {
							if (fuel = 0)
								displayFuel := "-"
							else
								displayFuel := displayValue("Float", convertUnit("Volume", fuel))
						}
						else
							displayFuel := fuel

						loop this.PitstopsListView.GetCount()
							if (this.PitstopsListView.GetNext(A_Index - 1, "C") != A_Index) {
								this.PitstopsListView.Delete(A_Index)

								break
							}

						this.PitstopsListView.Add("", this.PitstopsListView.GetCount() + 1, (lap = "-") ? "-" : (lap + 1), displayNullValue(nextDriver), displayFuel
													, (tyreCompound = "-") ? tyreCompound : translate(compound(tyreCompound, tyreCompoundColor)), ((tyreSet = 0) ? "-" : tyreSet)
													, displayPressures, this.computeRepairs(repairBodywork, repairSuspension, repairEngine))

						pressures := string2Values(",", pressures)

						sessionStore.remove("Pitstop.Data", {Status: "Planned"}, always.Bind(true))

						sessionStore.add("Pitstop.Data"
									   , Database.Row("Lap", lap, "Fuel", fuel, "Tyre.Compound", tyreCompound, "Tyre.Compound.Color", tyreCompoundColor, "Tyre.Set", tyreSet
													, "Tyre.Pressure.Cold.Front.Left", pressures[1], "Tyre.Pressure.Cold.Front.Right", pressures[2]
													, "Tyre.Pressure.Cold.Rear.Left", pressures[3], "Tyre.Pressure.Cold.Rear.Right", pressures[4]
													, "Repair.Bodywork", repairBodywork, "Repair.Suspension", repairSuspension, "Repair.Engine", repairEngine
													, "Driver.Current", currentDriver, "Driver.Next", nextDriver, "Status", "Planned"
													, "Stint", this.CurrentStint.Nr + 1))
					}
				}
			}
			catch Any as exception {
				if (exception != "No data...")
					logError(exception)
			}
		}

		if newData {
			if wasEmpty {
				this.PitstopsListView.ModifyCol()

				loop this.PitstopsListView.GetCount("Col")
					this.PitstopsListView.ModifyCol(A_Index, "AutoHdr")
			}

			if (this.SelectedDetailReport = "Pitstops")
				this.showPitstopsDetails()
		}

		return newData
	}

	syncPitstopsDetails(full := false) {
		local sessionStore := this.SessionStore
		local lastlap := this.LastLap
		local lastPitstop := sessionStore.Tables["Pitstop.Data"].Length
		local startLap := 1
		local newData := false
		local modifiedPitstops := []
		local hasServiceData, hasTyreData, nextLap, startLapCandidate, state, pitstop, pitstopNr
		local driver, laps, tyreCompound, tyreCompoundColor, tyreSet, ignore, tyre, nextPitstop, nextLap, pitstopLap

		if lastLap
			lastLap := lastLap.Nr

		loop {
			if (!full && (A_Index > 1))
				break
			else if full {
				nextPitstop := A_Index

				if (nextPitstop > lastPitstop)
					break
			}
			else
				nextPitstop := lastPitstop

			if (nextPitstop != 0) {
				hasServiceData := (sessionStore.query("Pitstop.Service.Data", {Where: {Pitstop: nextPitstop}}).Length > 0)
				hasTyreData := (sessionStore.query("Pitstop.Tyre.Data", {Where: {Pitstop: nextPitstop}}).Length > 0)

				if (!hasServiceData || !hasTyreData) {
					pitstopLap := sessionStore.Tables["Pitstop.Data"][nextPitstop]["Lap"]

					if (pitstopLap != "-") {
						nextLap := (full ? startLap : Max(startLap, pitstopLap - 1))

						loop {
							startLap := nextLap
							nextLap += 1

							if (nextLap > lastLap)
								break

							if !this.Laps.Has(nextLap)
								continue

							if (!full && hasServiceData && hasTyreData)
								break

							state := false

							try {
								state := this.Connector.GetLapValue(this.Laps[nextLap].Identifier, "Race Engineer Pitstop State")
							}
							catch Any as exception {
								logError(exception)
							}

							if (state && (state != "")) {
								state := parseMultiMap(state)

								pitstop := getMultiMapValue(state, "Pitstop Data", "Pitstop", kUndefined)

								if ((full || !hasServiceData)
								 && (getMultiMapValue(state, "Pitstop Data", "Service.Lap", kUndefined) != kUndefined)) {
									hasServiceData := true
									newData := true

									modifiedPitstops.Push(pitstop)

									sessionStore.add("Pitstop.Service.Data"
												   , Database.Row("Pitstop", pitstop
																, "Lap", getMultiMapValue(state, "Pitstop Data", "Service.Lap", false)
																, "Time", getMultiMapValue(state, "Pitstop Data", "Service.Time", false)
																, "Driver.Previous", getMultiMapValue(state, "Pitstop Data", "Service.Driver.Previous", false)
																, "Driver.Next", getMultiMapValue(state, "Pitstop Data", "Service.Driver.Next", false)
																, "Fuel", getMultiMapValue(state, "Pitstop Data", "Service.Refuel", 0)
																, "Tyre.Compound", getMultiMapValue(state, "Pitstop Data", "Service.Tyre.Compound", false)
																, "Tyre.Compound.Color", getMultiMapValue(state, "Pitstop Data", "Service.Tyre.Compound.Color", false)
																, "Tyre.Set", getMultiMapValue(state, "Pitstop Data", "Service.Tyre.Set", false)
																, "Tyre.Pressures", getMultiMapValue(state, "Pitstop Data", "Service.Tyre.Pressures", "")
																, "Bodywork.Repair", getMultiMapValue(state, "Pitstop Data", "Service.Bodywork.Repair", false)
																, "Suspension.Repair", getMultiMapValue(state, "Pitstop Data", "Service.Suspension.Repair", false)
																, "Engine.Repair", getMultiMapValue(state, "Pitstop Data", "Service.Engine.Repair", false)))
								}

								if ((full || !hasTyreData)
								 && (getMultiMapValue(state, "Pitstop Data", "Tyre.Compound", kUndefined) != kUndefined)) {
									hasTyreData := true
									newData := true

									modifiedPitstops.Push(pitstop)

									driver := getMultiMapValue(state, "Pitstop Data", "Tyre.Driver")
									laps := getMultiMapValue(state, "Pitstop Data", "Tyre.Laps", false)
									tyreCompound := getMultiMapValue(state, "Pitstop Data", "Tyre.Compound", "Dry")
									tyreCompoundColor := getMultiMapValue(state, "Pitstop Data", "Tyre.Compound.Color", "Black")
									tyreSet := getMultiMapValue(state, "Pitstop Data", "Tyre.Set", "-")

									for ignore, tyre in ["Front.Left", "Front.Right", "Rear.Left", "Rear.Right"]
										sessionStore.add("Pitstop.Tyre.Data"
													   , Database.Row("Pitstop", pitstop, "Driver", driver, "Laps", laps
																	, "Compound", tyreCompound, "Compound.Color", tyreCompoundColor
																	, "Set", tyreSet, "Tyre", tyre
																	, "Tread", getMultiMapValue(state, "Pitstop Data", "Tyre.Tread." . tyre, "-")
																	, "Wear", getMultiMapValue(state, "Pitstop Data", "Tyre.Wear." . tyre, 0)
																	, "Grain", getMultiMapValue(state, "Pitstop Data", "Tyre.Grain." . tyre, "-")
																	, "Blister", getMultiMapValue(state, "Pitstop Data", "Tyre.Blister." . tyre, "-")
																	, "FlatSpot", getMultiMapValue(state, "Pitstop Data", "Tyre.FlatSpot." . tyre, "-")))
								}

								startLap += 1

								break
							}
						}
					}

					if (hasServiceData && hasTyreData)
						if (this.SelectedDetailReport = "Pitstops")
							this.showPitstopsDetails()
						else if (this.SelectedDetailReport = "Pitstop") {
							pitstopNr := this.PitstopsListView.GetNext()

							if inList(modifiedPitstops, pitstopNr)
								this.showPitstopDetails(pitstopNr)
						}
				}
			}
		}

		return newData
	}

	syncStrategy() {
		local strategy, session, version, fileName, configuration

		try {
			session := this.SelectedSession[true]

			version := this.Connector.GetSessionValue(session, "Race Strategy Version")

			if (version && (version != "")) {
				if (!this.Strategy || !this.Strategy.Version || (version > this.Strategy.Version)) {
					this.showMessage(translate("Syncing session strategy"))

					if (getLogLevel() <= kLogInfo)
						logMessage(kLogInfo, translate("Syncing session strategy (Version: ") . version . translate(")"))

					strategy := this.Connector.GetSessionValue(session, "Race Strategy")

					this.showMessage(translate("Updating session strategy"))

					if (getLogLevel() <= kLogInfo)
						logMessage(kLogInfo, translate("Updating session strategy, Strategy: `n`n") . strategy . "`n")

					this.selectStrategy((strategy = "CANCEL") ? false : this.createStrategy(parseMultiMap(strategy), false, false))
				}
			}
			else if (!this.Strategy && !this.LastLap) {
				fileName := (kUserConfigDirectory . "Race.strategy")

				if FileExist(fileName) {
					configuration := readMultiMap(fileName)

					if (configuration.Count > 0)
						this.selectStrategy(this.createStrategy(configuration, false, false), true)
				}
			}
		}
		catch Any as exception {
			logError(exception)
		}
	}

	syncSetups() {
		local session, version, info, setups

		try {
			session := this.SelectedSession[true]

			version := this.Connector.GetSessionValue(session, "Setups Version")

			if (version && (version != "")) {
				if (!this.SetupsVersion || (this.SetupsVersion < version)) {
					this.showMessage(translate("Syncing setups"))

					if (getLogLevel() <= kLogInfo)
						logMessage(kLogInfo, translate("Syncing setups (Version: ") . version . translate(")"))

					info := this.Connector.GetSessionValue(session, "Setups Info")
					setups := this.Connector.GetSessionValue(session, "Setups")

					if (setups = "CLEAR") {
						if (this.SetupsVersion && (this.SetupsListView.GetCount() > 0)) {
							this.showMessage(translate("Clearing setups"))

							if (getLogLevel() <= kLogInfo)
								logMessage(kLogInfo, translate("Clearing setups, Info: `n`n") . info . "`n")

							this.clearSetups(false)
						}
						else
							this.iSetupsVersion := version
					}
					else {
						this.showMessage(translate("Updating setups"))

						if (getLogLevel() <= kLogInfo)
							logMessage(kLogInfo, translate("Updating setups, Info: `n`n") . info . translate(" `nSetups: `n`n") . setups . "`n")

						this.loadSetups(info, setups)
					}

					this.iSelectedSetup := false
				}
			}
		}
		catch Any as exception {
			logError(exception)
		}
	}

	syncTeamDrivers() {
		local session, version, teamDrivers

		try {
			session := this.SelectedSession[true]

			version := this.Connector.GetSessionValue(session, "Team Drivers Version")

			if (version && (version != "")) {
				if (!this.TeamDriversVersion || (this.TeamDriversVersion < version)) {
					this.showMessage(translate("Syncing team drivers"))

					if (getLogLevel() <= kLogInfo)
						logMessage(kLogInfo, translate("Syncing team drivers (Version: ") . version . translate(")"))

					this.iTeamDriversVersion := version

					try {
						teamDrivers := this.Connector.GetSessionValue(session, "Team Drivers")
					}
					catch Any as exception {
						teamDrivers := ""
					}

					if (teamDrivers && (teamDrivers != ""))
						teamDrivers := string2Values("###", teamDrivers)
					else
						teamDrivers := []

					this.iTeamDrivers := teamDrivers

					this.Control["pitstopDriverDropDownMenu"].Delete()
					this.Control["pitstopDriverDropDownMenu"].Add(concatenate([translate("No driver change")], teamDrivers))
					this.Control["pitstopDriverDropDownMenu"].Choose(1)
				}
			}
		}
		catch Any as exception {
			logError(exception)
		}
	}

	syncPlan() {
		local session, version, info, plan

		try {
			session := this.SelectedSession[true]

			version := this.Connector.GetSessionValue(session, "Stint Plan Version")

			if (version && (version != "")) {
				if (!this.PlanVersion || (this.PlanVersion < version)) {
					this.showMessage(translate("Syncing stint plan"))

					if (getLogLevel() <= kLogInfo)
						logMessage(kLogInfo, translate("Syncing stint plan (Version: ") . version . translate(")"))

					info := this.Connector.GetSessionValue(session, "Stint Plan Info")
					plan := this.Connector.GetSessionValue(session, "Stint Plan")

					if (plan = "CLEAR") {
						if (this.PlanVersion && (this.PlanListView.GetCount() > 0)) {
							this.showMessage(translate("Clearing stint plan"))

							if (getLogLevel() <= kLogInfo)
								logMessage(kLogInfo, translate("Clearing stint plan, Info: `n`n") . info . "`n")

							this.PlanListView.Delete()
						}
					}
					else {
						this.showMessage(translate("Updating stint plan"))

						if (getLogLevel() <= kLogInfo)
							logMessage(kLogInfo, translate("Updating stint plan, Info: `n`n") . info . translate(" `nPlan: `n`n") . plan . "`n")

						this.loadPlan(info, plan)
					}

					this.iSelectedPlanStint := false
				}
			}
		}
		catch Any as exception {
			logError(exception)
		}
	}

	syncSession() {
		local initial := !this.LastLap
		local strategy, session, lastLap, simulator, car, track, newLaps, newData, newReports, finished, message, forcePitstopUpdate
		local selectedLap, selectedStint, currentStint, driverSwapRequest

		static hadLastLap := false
		static nextPitstopUpdate := false

		if (this.SessionActive && this.Synchronize) {
			session := this.SelectedSession[true]

			try {
				this.showMessage(translate("Syncing session"))

				if (getLogLevel() <= kLogInfo)
					logMessage(kLogInfo, translate("Syncing session"))

				try {
					lastLap := this.Connector.GetSessionLastLap(session)

					if lastLap {
						lastLap := parseObject(this.Connector.GetLap(lastLap))
						lastLap.Nr := (lastLap.Nr + 0)
					}
				}
				catch Any as exception {
					logError(exception)

					lastLap := false
				}

				if (hadLastLap && !lastLap) {
					this.initializeSession()

					hadLastLap := false
					nextPitstopUpdate := false

					return
				}
				else if lastLap
					hadLastLap := true

				currentStint := this.CurrentStint

				simulator := this.Connector.GetSessionValue(session, "Simulator")
				car := this.Connector.GetSessionValue(session, "Car")
				track := this.Connector.GetSessionValue(session, "Track")

				if (simulator && (simulator != ""))
					try {
						this.initializeSimulator(simulator, car, track)
					}
					catch Any as exception {
						logError(exception)
					}

				this.syncSetups()
				this.syncTeamDrivers()
				this.syncPlan()
				this.syncStrategy()

				newLaps := false
				newData := false

				selectedLap := this.LapsListView.GetNext()

				if selectedLap
					selectedLap := (selectedLap == this.LapsListView.GetCount())

				selectedStint := this.StintsListView.GetNext()

				if selectedStint
					selectedStint := (selectedStint == this.StintsListView.GetCount())

				if lastLap
					newLaps := this.syncLaps(lastLap)

				if this.syncRaceReport() {
					newData := true

					newReports := true
				}
				else
					newReports := false

				if this.syncPitstops(newLaps) {
					newData := true

					nextPitstopUpdate := (this.LastLap.Nr + 2)
				}

				if this.syncTelemetry()
					newData := true

				if this.syncTyrePressures()
					newData := true

				this.updatePitstops()

				forcePitstopUpdate := (this.LastLap && (this.LastLap.Nr = nextPitstopUpdate))

				if this.syncPitstopsDetails(forcePitstopUpdate || initial)
					newData := true

				if forcePitstopUpdate
					nextPitstopUpdate := false

				if (this.LastLap && (this.SelectedReport == "Track"))
					if this.syncTrackMap()
						newData := true

				if newLaps {
					this.showMessage(translate("Saving session"))

					this.syncSessionStore()
				}

				if (newData || newLaps)
					this.updateReports()

				if newLaps {
					if (selectedLap && (this.SelectedDetailReport = "Lap")) {
						this.LapsListView.Modify(this.LapsListView.GetCount(), "Select Vis")

						this.showLapDetails(this.LastLap)
					}

					if (selectedStint && (this.SelectedDetailReport = "Stint")) {
						this.StintsListView.Modify(this.StintsListView.GetCount(), "Select Vis")

						this.showStintDetails(this.CurrentStint)
					}

					if (this.SelectedDetailReport = "Plan") {
						if (currentStint != this.CurrentStint)
							this.showPlanDetails()
					}
					else if (this.SelectedDetailReport = "Session")
						this.showSessionSummary()
					else if (this.SelectedDetailReport = "Drivers")
						this.showDriverStatistics()
				}
				else if newReports {
					if (selectedLap && (this.SelectedDetailReport = "Lap")) {
						this.LapsListView.Modify(this.LapsListView.GetCount(), "Select Vis")

						this.showLapDetails(this.LastLap)
					}
				}
				else if (!newLaps && !this.SessionFinished) {
					finished := parseObject(this.Connector.GetSession(this.SelectedSession[true])).Finished

					if (finished && (finished = "true")) {
						this.saveSession()

						this.iSessionFinished := true
					}
				}

				this.updateState()
			}
			catch Any as exception {
				logError(exception)

				message := (isObject(exception) ? exception.Message : exception)

				this.showMessage(translate("Cannot connect to the Team Server.") . A_Space . translate("Retry in 10 seconds."), translate("Error: ") . message)

				if (getLogLevel() <= kLogWarn)
					logMessage(kLogWarn, message)

				Sleep(2000)
			}

			try {
				driverSwapRequest := this.Connector.GetSessionValue(session, "Race Engineer Driver Swap Request")

				if (StrLen(driverSwapRequest) > 0) {
					this.Connector.DeleteSessionValue(session, "Race Engineer Driver Swap Request")

					this.pushTask(ObjBindMethod(this, "planDriverSwap", string2Values(";", driverSwapRequest)*))
				}
			}
			catch Any as exception {
				logError(exception)
			}

			this.showMessage(false)
		}
	}

	updateReports(redraw := false) {
		local selectedLap, selectedStint

		if this.HasData {
			if !this.SelectedReport
				this.iSelectedReport := "Overview"

			this.showReport(this.SelectedReport, true)
		}
		else if redraw
			this.showChart(false)

		if (!this.SelectedDetailReport && this.Strategy)
			this.StrategyViewer.showStrategyInfo(this.Strategy)
		else if redraw {
			switch this.SelectedDetailReport, false {
				case "Plan":
					this.showPlanDetails()
				case "Setups":
					this.showSetupsDetails()
				case "Session":
					this.showSessionSummary()
				case "Drivers":
					this.showDriverStatistics()
				case "Pitstops":
					this.showPitstopsDetails()
				default:
					selectedLap := this.LapsListView.GetNext(0)

					if (selectedLap && (this.SelectedDetailReport = "Lap"))
						this.showLapDetails(this.Laps[selectedLap])
					else {
						selectedStint := this.StintsListView.GetNext(0)

						if (selectedStint && (this.SelectedDetailReport = "Stint"))
							this.showStintDetails(this.Stints[selectedStint])
						else if ((this.SelectedDetailReport = "Strategy") && this.Strategy)
							this.StrategyViewer.showStrategyInfo(this.Strategy)
						else if (this.SelectedDetailReport && this.iSelectedDetailHTML) {
							this.DetailsViewer.document.open()
							this.DetailsViewer.document.write(this.iSelectedDetailHTML)
							this.DetailsViewer.document.close()
						}
					}
			}
		}
	}

	getCar(lap, carID, &car, &carNumber, &carName, &driverForname, &driverSurname, &driverNickname) {
		return this.ReportViewer.getCar(lap.Nr, &carID, &car, &carNumber, &carName, &driverForname, &driverSurname, &driverNickname)
	}

	getStandings(lap, &cars, &ids, &overallPositions, &classPositions, &carNumbers, &carNames
					, &driverFornames, &driverSurnames, &driverNicknames, &driverCategories) {
		local tCars := true
		local tIDs := true
		local tOPositions := true
		local tCPositions := true
		local tCarNumbers := carNumbers
		local tCarNames := carNames
		local tDriverFornames := driverFornames
		local tDriverSurnames := driverSurnames
		local tDriverNicknames := driverNicknames
		local tDriverCategories := driverNicknames
		local index, multiClass

		multiClass := this.ReportViewer.getStandings(lap.Nr, &tCars, &tIDs, &tOPositions, &tCPositions, &tCarNumbers, &tCarNames
														   , &tDriverFornames, &tDriverSurnames, &tDriverNicknames, &tDriverCategories)

		if cars
			cars := []

		if ids
			ids := []

		if overallPositions
			overallPositions := []

		if classPositions
			classPositions := []

		if carNumbers
			carNumbers := []

		if carNames
			carNames := []

		if driverFornames
			driverFornames := []

		if driverSurnames
			driverSurnames := []

		if driverNicknames
			driverNicknames := []

		if driverCategories
			driverCategories := []

		if (tCars.Length > 0)
			loop tOPositions.Length {
				index := inList(tOPositions, A_Index)

				if index {
					if cars
						cars.Push(tCars[index])

					if ids
						ids.Push(tIDs[index])

					if overallPositions
						overallPositions.Push(tOPositions[index])

					if classPositions
						classPositions.Push(tCPositions[index])

					if carNumbers
						carNumbers.Push(tCarNumbers[index])

					if carNames
						carNames.Push(tCarNames[index])

					if driverFornames
						driverFornames.Push(tDriverFornames[index])

					if driverSurnames
						driverSurnames.Push(tDriverSurnames[index])

					if driverNicknames
						driverNicknames.Push(tDriverNicknames[index])

					if driverCategories
						driverCategories.Push(tDriverCategories[index])
				}
			}

		return multiClass
	}

	computeDriverTime(driver) {
		local duration := 0
		local stint

		if this.CurrentStint
			loop this.CurrentStint.Nr {
				stint := this.Stints[A_Index]

				if (stint.Driver == driver)
					duration += this.computeDuration(stint)
			}

		return duration
	}

	computeDuration(stint) {
		local duration, ignore, lap

		if stint.HasProp("Duration")
			return stint.Duration
		else {
			duration := 0

			for ignore, lap in stint.Laps
				duration += lap.LapTime

			if (stint != this.CurrentStint)
				stint.Duration := duration

			return duration
		}
	}

	computeEndTime(stint, update := false) {
		local time, duration

		if stint.HasProp("EndTime")
			return stint.EndTime
		else {
			time := this.computeStartTime(stint)
			duration := this.computeDuration(stint)

			time := DateAdd(time, duration, "Seconds")

			if update
				stint.EndTime := time

			return time
		}
	}

	computeStartTime(stint) {
		local time

		if stint.HasProp("StartTime")
			return stint.StartTime
		else {
			if (stint.Nr = 1) {
				stint.StartTime := (A_Now . "")

				time := stint.StartTime
			}
			else
				time := this.computeEndTime(this.Stints[stint.Nr - 1], true)

			if (stint != this.CurrentStint)
				stint.StartTime := time

			return time
		}
	}

	computeLapStatistics(driver, laps, &potential, &raceCraft, &speed, &consistency, &carControl) {
		local raceData := true
		local drivers := false
		local positions := true
		local times := true
		local car, cars, potentials, raceCrafts, speeds, consistencies, carControls, count, oldLapSettings

		this.ReportViewer.loadReportData(laps, &raceData, &drivers, &positions, &times)

		car := getMultiMapValue(raceData, "Cars", "Driver", false)

		if car {
			cars := []

			loop getMultiMapValue(raceData, "Cars", "Count")
				cars.Push(A_Index)

			potentials := false
			raceCrafts := false
			speeds := false
			consistencies := false
			carControls := false

			count := laps.Length
			laps := []

			loop count
				laps.Push(A_Index)

			oldLapSettings := (this.ReportViewer.Settings.Has("Laps") ? this.ReportViewer.Settings["Laps"] : false)

			try {
				this.ReportViewer.Settings["Laps"] := laps

				this.ReportViewer.getDriverStatistics(raceData, cars, positions, times, &potentials, &raceCrafts, &speeds, &consistencies, &carControls)
			}
			finally {
				if oldLapSettings
					this.ReportViewer.Settings["Laps"] := oldLapSettings
				else
					this.ReportViewer.Settings.Delete("Laps")
			}

			potential := Round(potentials[car], 2)
			raceCraft := Round(raceCrafts[car], 2)
			speed := Round(speeds[car], 2)
			consistency := Round(consistencies[car], 2)
			carControl := Round(carControls[car], 2)
		}
		else {
			potential := 0.0
			raceCraft := 0.0
			speed := 0.0
			consistency := 0.0
			carControl := 0.0
		}
	}

	updateStintStatistics(stint) {
		local laps := []
		local ignore, lap, potential, raceCraft, speed, consistency, carControl

		for ignore, lap in stint.Laps
			laps.Push(lap.Nr)

		potential := false
		raceCraft := false
		speed := false
		consistency := false
		carControl := false

		this.computeLapStatistics(stint.Driver, laps, &potential, &raceCraft, &speed, &consistency, &carControl)

		stint.Potential := potential
		stint.RaceCraft := raceCraft
		stint.Speed := speed
		stint.Consistency := consistency
		stint.CarControl := carControl
	}

	updateDriverStatistics(driver) {
		local laps := []
		local accidents := 0
		local penalties := 0
		local ignore, lap, potential, raceCraft, speed, consistency, carControl

		for ignore, lap in driver.Laps {
			laps.Push(lap.Nr)

			if lap.Accident
				accidents += 1

			if lap.Penalty
				penalties += 1
		}

		potential := false
		raceCraft := false
		speed := false
		consistency := false
		carControl := false

		this.computeLapStatistics(driver, laps, &potential, &raceCraft, &speed, &consistency, &carControl)

		driver.Potential := potential
		driver.RaceCraft := raceCraft
		driver.Speed := speed
		driver.Consistency := consistency
		driver.CarControl := carControl
		driver.Accidents := accidents
		driver.Penalties := penalties
	}

	manageTeam() {
		manageTeamAsync() {
			this.Window.Opt("+Disabled")

			try {
				local teamDrivers := manageTeam(this, (this.TeamDrivers.Length = 0) ? removeDuplicates(getValues(this.getPlanDrivers()))
																					: this.TeamDrivers)
				local session, version, ignore, driver, nr, name

				if teamDrivers {
					if this.SessionActive {
						session := this.SelectedSession[true]

						version := (A_Now . "")

						this.iTeamDriversVersion := version

						this.Connector.setSessionValue(session, "Team Drivers Version", version)
						this.Connector.SetSessionValue(session, "Team Drivers", values2String("###", teamDrivers*))
					}

					this.iTeamDrivers := teamDrivers

					for ignore, driver in this.Drivers
						driver.Nr := false

					for nr, name in teamDrivers
						for ignore, driver in this.Drivers
							if (driver.FullName = name)
								driver.Nr := nr

					this.Control["pitstopDriverDropDownMenu"].Delete()
					this.Control["pitstopDriverDropDownMenu"].Add(concatenate([translate("No driver change")], teamDrivers))
					this.Control["pitstopDriverDropDownMenu"].Choose(1)
				}
			}
			finally {
				this.Window.Opt("-Disabled")
			}
		}

		this.pushTask(manageTeamAsync)
	}

	updateStatistics() {
		updateStatisticsAsync() {
			local progressWindow := showProgress({color: "Green", title: translate("Updating Stint Statistics")})
			local currentStint := this.CurrentStint
			local count, stint, ignore, driver

			if currentStint {
				count := currentStint.Nr

				loop count {
					showProgress({progress: Round((A_Index / count) * 50), color: "Green", message: translate("Stint: ") . A_Index})

					if this.Stints.Has(A_Index) {
						stint := this.Stints[A_Index]

						this.updateStintStatistics(stint)

						this.StintsListView.Modify(stint.Row, "Col12", stint.Potential, stint.RaceCraft, stint.Speed, stint.Consistency, stint.CarControl)
					}

					Sleep(200)
				}
			}

			showProgress({title: translate("Updating Driver Statistics"), message: translate("...")})

			count := this.Drivers.Length

			for ignore, driver in this.Drivers {
				showProgress({progress: 50 + Round((A_Index / count) * 50), color: "Green", message: translate("Driver: ") . driver.FullName})

				this.updateDriverStatistics(driver)

				Sleep(200)
			}

			hideProgress()
		}

		this.pushTask(updateStatisticsAsync)
	}

	saveSetups(flush := false) {
		local sessionStore := this.SessionStore
		local driver, conditions, tyreCompound, tyreCompoundColor, pressures, notes, temperatures

		sessionStore.clear("Setups.Data")

		loop this.SetupsListView.GetCount() {
			driver := this.SetupsListView.GetText(A_Index, 1)
			conditions := this.SetupsListView.GetText(A_Index, 2)
			tyreCompound := this.SetupsListView.GetText(A_Index, 3)
			pressures := this.SetupsListView.GetText(A_Index, 4)
			notes := this.SetupsListView.GetText(A_Index, 5)

			conditions := string2Values(translate("("), conditions)
			temperatures := string2Values(", ", StrReplace(conditions[2], translate(")"), ""))

			tyreCompoundColor := false

			splitCompound(this.TyreCompounds[inList(collect(this.TyreCompounds, translate), tyreCompound)]
						, &tyreCompound, &tyreCompoundColor)

			pressures := string2Values(", ", pressures)

			sessionStore.add("Setups.Data"
						   , Database.Row("Driver", driver, "Weather", kWeatherConditions[inList(collect(kWeatherConditions, translate), conditions[1])]
										, "Temperature.Air", convertUnit("Temperature", internalValue("Float", temperatures[1]), false, false)
										, "Temperature.Track", convertUnit("Temperature", internalValue("Float", temperatures[2]), false, false)
										, "Tyre.Compound", tyreCompound, "Tyre.Compound.Color", tyreCompoundColor
										, "Tyre.Pressure.Front.Left", convertUnit("Pressure", internalValue("Float", pressures[1]), false, false)
										, "Tyre.Pressure.Front.Right", convertUnit("Pressure", internalValue("Float", pressures[2]), false, false)
										, "Tyre.Pressure.Rear.Left", convertUnit("Pressure", internalValue("Float", pressures[3]), false, false)
										, "Tyre.Pressure.Rear.Right", convertUnit("Pressure", internalValue("Float", pressures[4]), false, false)
										, "Notes", StrReplace(StrReplace(StrReplace(StrReplace(notes, "`n", A_Space), "`t", A_Space), ";", ","), "`r", "")))
		}

		if flush
			sessionStore.flush("Setups.Data")
	}

	savePlan(flush := false) {
		local sessionStore := this.SessionStore
		local stint, driver, timePlanned, timeActual, lapPlanned, lapActual, refuelAmount, tyreChange

		sessionStore.clear("Plan.Data")

		loop this.PlanListView.GetCount() {
			stint := this.PlanListView.GetText(A_Index, 1)
			driver := this.PlanListView.GetText(A_Index, 2)
			timePlanned := this.PlanListView.GetText(A_Index, 3)
			timeActual := this.PlanListView.GetText(A_Index, 4)
			lapPlanned := this.PlanListView.GetText(A_Index, 5)
			lapActual := this.PlanListView.GetText(A_Index, 6)
			refuelAmount := this.PlanListView.GetText(A_Index, 7)
			tyreChange := this.PlanListView.GetText(A_Index, 8)

			sessionStore.add("Plan.Data", Database.Row("Stint", stint, "Driver", driver
													 , "Time.Planned", timePlanned, "Time.Actual", timeActual
													 , "Lap.Planned", lapPlanned, "Lap.Actual", lapActual
													 , "Fuel.Amount", convertUnit("Volume", internalValue("Float", refuelAmount), false, false)
													 , "Tyre.Change", tyreChange))
		}

		if flush
			sessionStore.flush("Plan.Data")
	}

	saveSession(copy := false) {
		saveSessionAsync(copy := false) {
			local info, directory, translator, folder, session

			this.showMessage(translate("Saving session"))

			if this.SessionActive {
				this.syncSessionStore(true)

				info := newMultiMap()

				setMultiMapValue(info, "Session", "Team", this.SelectedTeam)
				setMultiMapValue(info, "Session", "Session", this.SelectedSession)
				setMultiMapValue(info, "Session", "Date", this.Date)
				setMultiMapValue(info, "Session", "Time", this.Time)
				setMultiMapValue(info, "Session", "Simulator", this.Simulator)
				setMultiMapValue(info, "Session", "Car", this.Car)
				setMultiMapValue(info, "Session", "Track", this.Track)

				setMultiMapValue(info, "Weather", "Weather", this.Weather)
				setMultiMapValue(info, "Weather", "Weather10Min", this.Weather10Min)
				setMultiMapValue(info, "Weather", "Weather30Min", this.Weather30Min)
				setMultiMapValue(info, "Weather", "AirTemperature", this.AirTemperature)
				setMultiMapValue(info, "Weather", "TrackTemperature", this.TrackTemperature)

				writeMultiMap(this.SessionDirectory . "Session.info", info)
			}
			else {
				this.saveSetups()
				this.savePlan()

				this.SessionStore.flush()
			}

			if copy {
				directory := (this.SessionLoaded ? this.SessionLoaded : this.SessionDirectory)

				this.Window.Opt("+OwnDialogs")

				translator := translateMsgBoxButtons.Bind(["Select", "Select", "Cancel"])

				OnMessage(0x44, translator)
				folder := DirSelect("*" directory, 0, translate("Select target folder..."))
				OnMessage(0x44, translator, 0)

				if (folder != "")
					try {
						DirCopy(directory, folder . "\" . this.SelectedSession, 1)
					}
					catch Any as exception {
						logError(exception)
					}
			}

			this.showMessage(false)
		}

		this.pushTask(saveSessionAsync.Bind(copy))
	}

	loadDrivers() {
		local ignore, driver

		this.iDrivers := []

		for ignore, driver in this.SessionStore.Tables["Driver.Data"]
			this.createDriver({Forname: driver["Forname"], Surname: driver["Surname"], Nickname: driver["Nickname"]
							 , Fullname: computeDriverName(driver["Forname"], driver["Surname"], driver["Nickname"])
							 , Nr: driver["Nr"], ID: driver["ID"]})
	}

	loadLaps() {
		local ignore, lap, newLap, engineDamage

		this.iLaps := CaseInsenseWeakMap()

		for ignore, lap in this.SessionStore.Tables["Lap.Data"] {
			newLap := {Nr: lap["Nr"], Stint: lap["Stint"], Laptime: lap["Lap.Time"], Position: lap["Position"], Grip: lap["Grip"]
					 , Map: lap["Map"], TC: lap["TC"], ABS: lap["ABS"]
					 , Weather: lap["Weather"], AirTemperature: lap["Temperature.Air"], TrackTemperature: lap["Temperature.Track"]
					 , FuelRemaining: lap["Fuel.Remaining"], FuelConsumption: lap["Fuel.Consumption"]
					 , Damage: lap["Damage"], EngineDamage: lap["EngineDamage"]
					 , Accident: lap["Accident"], Penalty: ((lap["Penalty"] != kNull) ? lap["Penalty"] : false)
					 , Compound: compound(lap["Tyre.Compound"], lap["Tyre.Compound.Color"])
					 , RemainingDriverTime: lap["Time.Driver.Remaining"], RemainingStintTime: lap["Time.Stint.Remaining"]
					 , Telemetry: false}

			if (isNull(newLap.Map))
				newLap.Map := "n/a"

			if (isNull(newLap.TC))
				newLap.TC := "n/a"

			if (isNull(newLap.ABS))
				newLap.ABS := "n/a"

			if (isNull(newLap.EngineDamage))
				newLap.EngineDamage := 0

			if (isNull(newLap.Position))
				newLap.Position := "-"

			if (isNull(newLap.Laptime))
				newLap.Laptime := "-"

			if (isNull(newLap.FuelConsumption))
				newLap.FuelConsumption := "-"

			if (isNull(newLap.FuelRemaining))
				newLap.FuelRemaining := "-"

			if (isNull(newLap.AirTemperature))
				newLap.AirTemperature := "-"

			if (isNull(newLap.TrackTemperature))
				newLap.TrackTemperature := "-"

			if (isNull(newLap.RemainingDriverTime))
				newLap.RemainingDriverTime := "-"

			if (isNull(newLap.RemainingStintTime))
				newLap.RemainingStintTime := "-"

			this.Laps[newLap.Nr] := newLap
			this.iLastLap := newLap
		}
	}

	loadStints() {
		local ignore, stint, newStint, driver, laps, lap, stintNr, stintLap, airTemperatures, trackTemperatures
		local currentStint, lastLap, remainingFuel, fuelConsumption, penalty

		this.iStints := CaseInsenseWeakMap()

		for ignore, stint in this.SessionStore.Tables["Stint.Data"] {
			driver := this.createDriver({Forname: stint["Driver.Forname"], Surname: stint["Driver.Surname"], Nickname: stint["Driver.Nickname"], ID: stint["Driver.ID"]})

			newStint := {Nr: stint["Nr"], Lap: stint["Lap"], Driver: driver
					   , Weather: stint["Weather"], Compound: normalizeCompound(stint["Compound"])
					   , AvgLaptime: stint["Lap.Time.Average"], BestLaptime: stint["Lap.Time.Best"], FuelConsumption: stint["Fuel.Consumption"]
					   , Accidents: stint["Accidents"], Penalties: stint["Penalties"], StartPosition: stint["Position.Start"], EndPosition: stint["Position.End"]
					   , StartTime: stint["Time.Start"], EndTime: stint["Time.End"]}

			if (isNull(newStint.StartTime))
				newStint.StartTime := false

			if (isNull(newStint.EndTime))
				newStint.EndTime := false

			driver.Stints.Push(newStint)
			laps := []

			newStint.Laps := laps

			stintNr := newStint.Nr
			stintLap := newStint.Lap

			airTemperatures := []
			trackTemperatures := []

			loop {
				if !this.Laps.Has(stintLap)
					break

				lap := this.Laps[stintLap]

				airTemperatures.Push(lap.AirTemperature)
				trackTemperatures.Push(lap.TrackTemperature)

				if isObject(lap.Stint)
					newStint.Lap := (stintLap + 1)
				else
					if (lap.Stint != stintNr)
						break
					else {
						lap.Stint := newStint
						laps.Push(lap)

						driver.Laps.Push(lap)
					}

				stintLap += 1
			}

			newStint.AirTemperature := Round(average(airTemperatures), 1)
			newStint.TrackTemperature := Round(average(trackTemperatures), 1)

			newStint.Potential := "-"
			newStint.RaceCraft := "-"
			newStint.Speed := "-"
			newStint.Consistency := "-"
			newStint.CarControl := "-"

			if (isNull(newStint.AvgLaptime))
				newStint.AvgLaptime := "-"

			if (isNull(newStint.BestLaptime))
				newStint.BestLaptime := "-"

			if (isNull(newStint.FuelConsumption))
				newStint.FuelConsumption := "-"

			if (isNull(newStint.StartPosition))
				newStint.StartPosition := "-"

			if (isNull(newStint.EndPosition))
				newStint.EndPosition := "-"

			this.Stints[newStint.Nr] := newStint

			this.iCurrentStint := newStint

			this.updatePlan(newStint)
		}

		currentStint := this.CurrentStint

		if currentStint
			loop currentStint.Nr
				if this.Stints.Has(A_Index) {
					stint := this.Stints[A_Index]
					stint.Row := (this.StintsListView.GetCount() + 1)

					this.StintsListView.Add("", stint.Nr, stint.Driver.FullName, values2String(", ", collect(string2Values(",", stint.Weather), translate)*)
											  , translate(stint.Compound), stint.Laps.Length, stint.StartPosition, stint.EndPosition
											  , lapTimeDisplayValue(stint.AvgLaptime)
											  , isNumber(stint.FuelConsumption) ? displayValue("Float", convertUnit("Volume", stint.FuelConsumption)) : stint.FuelConsumption
											  , stint.Accidents, stint.Penalties, stint.Potential, stint.RaceCraft, stint.Speed, stint.Consistency, stint.CarControl)
				}

		this.StintsListView.ModifyCol()

		loop this.StintsListView.GetCount("Col")
			this.StintsListView.ModifyCol(A_Index, "AutoHdr")

		lastLap := this.LastLap

		if lastLap
			loop lastLap.Nr
				if this.Laps.Has(A_Index) {
					lap := this.Laps[A_Index]
					lap.Row := (this.LapsListView.GetCount() + 1)

					remainingFuel := lap.FuelRemaining

					if isNumber(remainingFuel)
						remainingFuel := displayValue("Float", convertUnit("Volume", remainingFuel))

					fuelConsumption := lap.FuelConsumption

					if isNumber(fuelConsumption)
						fuelConsumption := displayValue("Float", convertUnit("Volume", fuelConsumption))

					penalty := ""

					if lap.Penalty {
						penalty := lap.Penalty

						if (InStr(penalty, "SG") = 1) {
							penalty := ((StrLen(penalty) > 2) ? (A_Space . SubStr(penalty, 3)) : "")

							penalty := (translate("Stop and Go") . penalty)
						}
						else if (penalty = "Time")
							penalty := translate("Time")
						else if (penalty = "DT")
							penalty := translate("Drive Through")
						else if (penalty == true)
							penalty := "x"
					}

					this.LapsListView.Add("", lap.Nr, lap.Stint.Nr, lap.Stint.Driver.FullName, lap.Position, translate(lap.Weather), translate(lap.Grip)
											, lapTimeDisplayValue(lap.Laptime), displayNullValue(fuelConsumption), remainingFuel, "-, -, -, -"
											, lap.Accident ? translate("x") : "", penalty)
				}

		this.LapsListView.ModifyCol()

		loop this.LapsListView.GetCount("Col")
			this.LapsListView.ModifyCol(A_Index, "AutoHdr")
	}

	loadSetups(info := false, setups := false) {
		local fileName, ignore, setup, conditions

		if info {
			info := parseMultiMap(info)

			this.iSetupsVersion := getMultiMapValue(info, "Setups", "Version")
		}

		this.SetupsListView.Delete()

		this.iSelectedSetup := false

		if setups {
			fileName := (this.SessionDirectory . "Setups.Data.CSV")

			deleteFile(fileName)

			FileAppend(setups, fileName, "UTF-16")

			this.SessionStore.reload("Setups.Data", false)
		}

		for ignore, setup in this.SessionStore.Tables["Setups.Data"] {
			conditions := (translate(setup["Weather"]) . A_Space
						 . translate("(") . displayValue("Float", convertUnit("Temperature", setup["Temperature.Air"]), 0) . ", "
										  . displayValue("Float", convertUnit("Temperature", setup["Temperature.Track"]), 0) . translate(")"))

			this.SetupsListView.Add("", setup["Driver"], conditions, translate(compound(setup["Tyre.Compound"], setup["Tyre.Compound.Color"]))
									  , values2String(", ", displayValue("Float", convertUnit("Pressure", setup["Tyre.Pressure.Front.Left"]))
														  , displayValue("Float", convertUnit("Pressure", setup["Tyre.Pressure.Front.Right"]))
														  , displayValue("Float", convertUnit("Pressure", setup["Tyre.Pressure.Rear.Left"]))
														  , displayValue("Float", convertUnit("Pressure", setup["Tyre.Pressure.Rear.Right"])))
									  , displayNullValue(setup["Notes"], ""))
		}

		this.SetupsListView.ModifyCol()

		loop this.SetupsListView.GetCount("Col")
			this.SetupsListView.ModifyCol(A_Index, "AutoHdr")

		if (this.SelectedDetailReport = "Setups")
			this.showSetupsDetails()
	}

	loadPlan(info := false, plan := false) {
		local fileName, ignore, refuel, lapActual, timeActual

		if info {
			info := parseMultiMap(info)

			this.iPlanVersion := getMultiMapValue(info, "Plan", "Version")
			this.iDate := getMultiMapValue(info, "Plan", "Date")
			this.iTime := getMultiMapValue(info, "Plan", "Time")

			this.Control["sessionDateCal"].Value := this.Date
			this.Control["sessionTimeEdit"].Value := this.Time
		}

		this.PlanListView.Delete()

		this.iSelectedPlanStint := false

		if plan {
			fileName := (this.SessionDirectory . "Plan.Data.CSV")

			deleteFile(fileName)

			FileAppend(plan, fileName, "UTF-16")

			this.SessionStore.reload("Plan.Data", false)
		}

		for ignore, plan in this.SessionStore.Tables["Plan.Data"] {
			refuel := (isNumber(plan["Fuel.Amount"]) ? displayValue("Float", convertUnit("Volume", plan["Fuel.Amount"]), 0) : plan["Fuel.Amount"])

			timeActual := ""
			lapActual := ""

			this.PlanListView.Add("", plan["Stint"], plan["Driver"], plan["Time.Planned"], timeActual, plan["Lap.Planned"], lapActual, (refuel = 0) ? "-" : refuel, plan["Tyre.Change"])
		}

		this.PlanListView.ModifyCol()

		loop this.PlanListView.GetCount("Col")
			this.PlanListView.ModifyCol(A_Index, "AutoHdr")

		if (this.SelectedDetailReport = "Plan")
			this.showPlanDetails()
	}

	loadPitstops() {
		local ignore, pitstop, repairBodywork, repairSuspension, repairEngine, pressures, pressure
		local tyreCompound, tyreCompoundColor, tyreSet, fuel

		for ignore, pitstop in this.SessionStore.Tables["Pitstop.Data"] {
			repairBodywork := pitstop["Repair.Bodywork"]
			repairSuspension := pitstop["Repair.Suspension"]
			repairEngine := pitstop["Repair.Engine"]
			pressures := [pitstop["Tyre.Pressure.Cold.Front.Left"], pitstop["Tyre.Pressure.Cold.Front.Right"]
						, pitstop["Tyre.Pressure.Cold.Rear.Left"], pitstop["Tyre.Pressure.Cold.Rear.Right"]]

			tyreCompound := pitstop["Tyre.Compound"]
			tyreCompoundColor := pitstop["Tyre.Compound.Color"]

			if (!tyreCompound || (tyreCompound = "-")) {
				tyreCompound := "-"
				tyreCompoundColor := false
			}

			loop 4 {
				pressure := pressures[A_Index]

				if isNumber(pressure)
					pressures[A_Index] := displayValue("Float", convertUnit("Pressure", pressure))
			}

			fuel := pitstop["Fuel"]

			if isNumber(fuel)
				if (fuel = 0)
					fuel := "-"
				else
					fuel := displayValue("Float", convertUnit("Volume", fuel))

			tyreSet := pitstop["Tyre.Set"]

			this.PitstopsListView.Add((pitstop["Status"] = "Planned") ? "" : "Check", A_Index
									, (pitstop["Lap"] = "-") ? "-" : (pitstop["Lap"] + 1), displayNullValue(pitstop["Driver.Next"]), fuel
									, (tyreCompound = "-") ? tyreCompound : translate(compound(tyreCompound, tyreCompoundColor)), (tyreSet = 0) ? "-" : tyreSet
									, values2String(", ", pressures*), this.computeRepairs(repairBodywork, repairSuspension, repairEngine))
		}

		this.PitstopsListView.ModifyCol()

		loop this.PitstopsListView.GetCount("Col")
			this.PitstopsListView.ModifyCol(A_Index, "AutoHdr")
	}

	clearSession() {
		clearSessionAsync() {
			local session := this.SelectedSession[true]

			if session {
				try {
					this.Connector.ClearSession(session)
				}
				catch Any as exception {
					logError(exception)
				}

				this.initializeSession()
				this.updateState()
			}
		}

		this.pushTask(clearSessionAsync)
	}

	loadSession() {
		loadSessionAsync() {
			local directory := (this.SessionLoaded ? this.SessionLoaded : this.iSessionDirectory)
			local folder, info, lastLap, currentStint, translator

			this.Window.Opt("+OwnDialogs")

			translator := translateMsgBoxButtons.Bind(["Select", "Select", "Cancel"])

			OnMessage(0x44, translator)
			folder := DirSelect("*" . directory, 0, translate("Select Session folder..."))
			OnMessage(0x44, translator, 0)

			if (folder != "") {
				folder := (folder . "\")

				info := readMultiMap(folder . "Session.info")

				if (info.Count == 0) {
					OnMessage(0x44, translateOkButton)
					MsgBox(translate("This is not a valid folder with a saved session."), translate("Error"), 262160)
					OnMessage(0x44, translateOkButton, 0)
				}
				else {
					this.iSyncTask.pause()

					this.iConnection := false

					this.initializeSession()

					this.iSessionLoaded := folder

					this.iTeamName := getMultiMapValue(info, "Session", "Team")
					this.iTeamIdentifier := false

					this.iSessionName := getMultiMapValue(info, "Session", "Session")
					this.iSessionIdentifier := false

					this.iDate := getMultiMapValue(info, "Session", "Date", A_Now)
					this.iTime := getMultiMapValue(info, "Session", "Time", A_Now)

					this.iWeather := getMultiMapValue(info, "Weather", "Weather", false)
					this.iWeather10Min := getMultiMapValue(info, "Weather", "Weather10Min", false)
					this.iWeather30Min := getMultiMapValue(info, "Weather", "Weather30Min", false)
					this.iAirTemperature := getMultiMapValue(info, "Weather", "AirTemperature", false)
					this.iTrackTemperature := getMultiMapValue(info, "Weather", "TrackTemperature", false)

					this.Control["sessionDateCal"].Value := this.Date
					this.Control["sessionTimeEdit"].Value := this.Time

					this.Control["teamDropDownMenu"].Delete()
					this.Control["teamDropDownMenu"].Add([this.iTeamName])
					this.Control["teamDropDownMenu"].Choose(1)

					this.Control["sessionDropDownMenu"].Delete()
					this.Control["sessionDropDownMenu"].Add([this.iSessionName])
					this.Control["sessionDropDownMenu"].Choose(1)

					this.loadDrivers()
					this.loadSessionDrivers()
					this.loadSetups()
					this.loadPlan()
					this.loadLaps()
					this.loadStints()
					this.loadPitstops()

					this.syncTelemetry(true)
					this.syncTyrePressures(true)

					this.ReportViewer.setReport(folder . "Race Report")

					this.initializeReports()

					if !this.Weather {
						lastLap := this.LastLap

						if lastLap {
							this.iWeather := lastLap.Weather
							this.iAirTemperature := lastLap.AirTemperature
							this.iTrackTemperature := lastLap.TrackTemperature

							if lastLap.HasProp("Weather10Min") {
								this.iWeather10Min := lastLap.Weather10Min
								this.iWeather30Min := lastLap.Weather30Min
							}
							else {
								this.iWeather10Min := lastLap.Weather
								this.iWeather30Min := lastLap.Weather
							}
						}
					}

					if !this.TyreCompound {
						currentStint := this.CurrentStint

						if currentStint {
							this.iTyreCompound := compound(currentStint.Compound)
							this.iTyreCompoundColor := compoundColor(currentStint.Compound)
						}
					}

					this.updateReports()

					this.updateState()
				}
			}
		}

		this.pushTask(loadSessionAsync)
	}

	showChart(drawChartFunction) {
		local before, after, html

		this.ChartViewer.document.open()

		if (drawChartFunction && (drawChartFunction != "")) {
			before := "
			(
			<html>
			    <meta charset='utf-8'>
				<head>
					<style>
						.headerStyle { height: 25; font-size: 11px; font-weight: 500; background-color: #%headerBackColor%; }
						.rowStyle { font-size: 11px; background-color: #%evenRowBackColor%; }
						.oddRowStyle { font-size: 11px; background-color: #%oddRowBackColor%; }
					</style>
					<script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>
					<script type="text/javascript">
						google.charts.load('current', {'packages':['corechart', 'table', 'scatter']}).then(drawChart);
			)"

			before := substituteVariables(before, {headerBackColor: this.Window.Theme.ListBackColor["Header"]
												 , evenRowBackColor: this.Window.Theme.ListBackColor["EvenRow"]
												 , oddRowBackColor: this.Window.Theme.ListBackColor["OddRow"]})

			after := "
			(
					</script>
				</head>
				<body style='background-color: #%backColor%' style='overflow: auto' leftmargin='0' topmargin='0' rightmargin='0' bottommargin='0'>
					<style>
						.headerStyle { height: 25; font-size: 11px; font-weight: 500; background-color: #%headerBackColor%; }
						.rowStyle { font-size: 11px; background-color: #%evenRowBackColor%; }
						.oddRowStyle { font-size: 11px; background-color: #%oddRowBackColor%; }
					</style>
					<div id="chart_id" style="width: %width%px; height: %height%px"></div>
				</body>
			</html>
			)"

			html := (before . drawChartFunction . substituteVariables(after, {width: (this.ChartViewer.getWidth() - 5)
																			, height: (this.ChartViewer.getHeight() - 5)
																			, backColor: this.Window.AltBackColor
																			, headerBackColor: this.Window.Theme.ListBackColor["Header"]
																			, evenRowBackColor: this.Window.Theme.ListBackColor["EvenRow"]
																			, oddRowBackColor: this.Window.Theme.ListBackColor["OddRow"]}))

			this.ChartViewer.document.write(html)
		}
		else {
			html := "<html><body style='background-color: #%backColor%' style='overflow: auto' leftmargin='0' topmargin='0' rightmargin='0' bottommargin='0'></body></html>"

			this.ChartViewer.document.write(substituteVariables(html, {backColor: this.Window.AltBackColor}))
		}

		this.ChartViewer.document.close()
	}

	showDataPlot(data, xAxis, yAxises) {
		local double := (yAxises.Length > 1)
		local minValue := kUndefined
		local maxValue := kUndefined
		local drawChartFunction := ""
		local ignore, yAxis, settingsLaps, laps, ignore, lap, first, values, value, minValue, maxValue
		local series, vAxis, index

		drawChartFunction .= "function drawChart() {"
		drawChartFunction .= "`nvar data = new google.visualization.DataTable();"

		if (this.SelectedChartType = "Bubble")
			drawChartFunction .= ("`ndata.addColumn('string', 'ID');")

		drawChartFunction .= ("`ndata.addColumn('number', '" . xAxis . "');")

		for ignore, yAxis in yAxises {
			drawChartFunction .= ("`ndata.addColumn('number', '" . yAxis . "');")
		}

		settingsLaps := (this.ReportViewer.Settings.Has("Laps") ? this.ReportViewer.Settings["Laps"] : false)
		laps := false

		if (settingsLaps && (settingsLaps.Length > 0)) {
			laps := CaseInsenseWeakMap()

			for ignore, lap in settingsLaps
				laps[lap] := lap
		}

		drawChartFunction .= "`ndata.addRows(["
		first := true

		for ignore, values in data {
			if (laps && !laps.Has(A_Index))
				continue

			if !first
				drawChartFunction .= ",`n"

			first := false
			value := ((this.SelectedDrivers && !inList(this.SelectedDrivers, this.Stints[values["Stint"]].Driver.ID)) ? kNull : values[xAxis])

			if ((value = "n/a") || (isNull(value)))
				value := kNull

			if (this.SelectedChartType = "Bubble")
				drawChartFunction .= ("['', " . convertValue(xAxis, value))
			else
				drawChartFunction .= ("[" . convertValue(xAxis, value))

			for ignore, yAxis in yAxises {
				value := values[yAxis]

				if ((value = "n/a") || (isNull(value)))
					value := kNull
				else {
					minValue := ((minValue == kUndefined) ? value : Min(minValue, value))
					maxValue := ((maxValue == kUndefined) ? value : Max(maxValue, value))
				}

				drawChartFunction .= (", " . convertValue(yAxis, value))
			}

			drawChartFunction .= "]"
		}

		drawChartFunction .= "`n]);"

		series := "series: {"
		vAxis := "vAxis: { "

		for ignore, yAxis in yAxises {
			if (A_Index > 1) {
				series .= ", "
				vAxis .= ", "
			}

			if (A_Index > 2)
				break

			index := A_Index - 1

			series .= (index . ": {targetAxisIndex: " . index . "}")
			vAxis .= (index . ": {title: '" . translate(yAxis) . "'}")
		}

		series .= "}"
		vAxis .= "}"

		if (this.SelectedChartType = "Scatter") {
			drawChartFunction .= ("`nvar options = { legend: {position: 'bottom'}, chartArea: { left: '10%', right: '10%', top: '10%', bottom: '30%' }, backgroundColor: '#" . this.Window.AltBackColor . "', hAxis: { title: '" . translate(xAxis) . "' }, " . series . ", " . vAxis . "};")

			drawChartFunction := drawChartFunction . "`nvar chart = new google.visualization.ScatterChart(document.getElementById('chart_id')); chart.draw(data, options); }"
		}
		else if (this.SelectedChartType = "Bar") {
			if (minValue == kUndefined)
				minValue := 0
			else
				minValue := Min(0, minValue)

			if (maxValue == kUndefined)
				maxValue := 0

			drawChartFunction .= ("`nvar options = { legend: {position: 'bottom'}, chartArea: { left: '10%', right: '10%', top: '10%', bottom: '30%' }, backgroundColor: '#" . this.Window.AltBackColor . "', hAxis: { viewWindow: {min: " . minValue . ", max: " . maxValue . "} }, vAxis: { viewWindowMode: 'pretty' } };")

			drawChartFunction := drawChartFunction . "`nvar chart = new google.visualization.BarChart(document.getElementById('chart_id')); chart.draw(data, options); }"
		}
		else if (this.SelectedChartType = "Bubble") {
			drawChartFunction .= ("`nvar options = { legend: {position: 'bottom'}, chartArea: { left: '10%', right: '10%', top: '10%', bottom: '30%' }, backgroundColor: '#" . this.Window.AltBackColor . "', hAxis: { title: '" . translate(xAxis) . "', viewWindowMode: 'pretty' }, vAxis: { title: '" . translate(yAxises[1]) . "', viewWindowMode: 'pretty' }, colorAxis: { legend: {position: 'none'}, colors: ['blue', 'red'] }, sizeAxis: { maxSize: 15 } };")

			drawChartFunction := drawChartFunction . "`nvar chart = new google.visualization.BubbleChart(document.getElementById('chart_id')); chart.draw(data, options); }"
		}
		else if (this.SelectedChartType = "Line") {
			drawChartFunction .= ("`nvar options = { legend: {position: 'bottom'}, chartArea: { left: '10%', right: '10%', top: '10%', bottom: '30%' }, backgroundColor: '#" . this.Window.AltBackColor . "' };")

			drawChartFunction := drawChartFunction . "`nvar chart = new google.visualization.LineChart(document.getElementById('chart_id')); chart.draw(data, options); }"
		}

		this.showChart(drawChartFunction)
	}

	showDetails(report, details, charts*) {
		local chartID := 1
		local html := (details ? details : "")
		local script, ignore, chart

		this.iSelectedDetailReport := report

		if details {
			script := "
			(
				<meta charset='utf-8'>
				<head>
					<style>
						.headerStyle { height: 25; font-size: 11px; font-weight: 500; background-color: #%headerBackColor%; }
						.rowStyle { font-size: 11px; background-color: #%evenRowBackColor%; }
						.oddRowStyle { font-size: 11px; background-color: #%oddRowBackColor%; }
						%tableCSS%
					</style>
					<script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>
					<script type="text/javascript">
						google.charts.load('current', {'packages':['corechart', 'table', 'scatter']}).then(drawCharts);

						function drawCharts() {
			)"

			script := substituteVariables(script, {tableCSS: this.StrategyViewer.getTableCSS()
												 , headerBackColor: this.Window.Theme.ListBackColor["Header"]
												 , evenRowBackColor: this.Window.Theme.ListBackColor["EvenRow"]
												 , oddRowBackColor: this.Window.Theme.ListBackColor["OddRow"]})

			for ignore, chart in charts
				script .= (A_Space . "drawChart" . chart[1] . "();")

			script .= "}`n"

			for ignore, chart in charts {
				if (A_Index > 0)
					script .= "`n"

				script .= chart[2]
			}

			script .= "</script></head>"
		}
		else
			script := ""

		html := ("<html>" . script . "<body style='background-color: #" . this.Window.AltBackColor . "' style='overflow: auto' leftmargin='0' topmargin='0' rightmargin='0' bottommargin='0'><style> div, table { font-family: Arial, Helvetica, sans-serif; font-size: 11px }</style><style> #header { font-size: 12px; }</style><div>" . html . "</div></body></html>")

		this.iSelectedDetailHTML := html

		this.DetailsViewer.document.open()
		this.DetailsViewer.document.write(html)
		this.DetailsViewer.document.close()
	}

	selectReport(report) {
		if report {
			this.ReportsListView.Modify(inList(kSessionReports, report), "+Select")

			this.iSelectedReport := report
		}
		else {
			loop this.ReportsListView.GetCount()
				this.ReportsListView.Modify(A_Index, "-Select")

			this.iSelectedReport := false
		}
	}

	showOverviewReport() {
		this.selectReport("Overview")

		this.ReportViewer.showOverviewReport()

		this.updateState()
	}

	editOverviewReportSettings() {
		this.Window.Opt("+Disabled")

		try {
			return this.ReportViewer.editReportSettings("Classes")
		}
		finally {
			this.Window.Opt("-Disabled")
		}
	}

	showCarReport() {
		this.selectReport("Car")

		this.ReportViewer.showCarReport()

		this.updateState()
	}

	showDriverReport() {
		this.selectReport("Drivers")

		this.ReportViewer.showDriverReport()

		this.updateState()
	}

	editDriverReportSettings() {
		this.Window.Opt("+Disabled")

		try {
			return this.ReportViewer.editReportSettings("Laps", "Drivers", "Classes")
		}
		finally {
			this.Window.Opt("-Disabled")
		}
	}

	showPositionsReport() {
		this.selectReport("Positions")

		this.ReportViewer.showPositionsReport()

		this.updateState()
	}

	editPositionsReportSettings() {
		this.Window.Opt("+Disabled")

		try {
			return this.ReportViewer.editReportSettings("Laps", "Classes")
		}
		finally {
			this.Window.Opt("-Disabled")
		}
	}

	showLapTimesReport() {
		this.selectReport("Lap Times")

		this.ReportViewer.showLapTimesReport()

		this.updateState()
	}

	editLapTimesReportSettings() {
		this.Window.Opt("+Disabled")

		try {
			return this.ReportViewer.editReportSettings("Laps", "Cars", "Classes")
		}
		finally {
			this.Window.Opt("-Disabled")
		}
	}

	showConsistencyReport() {
		this.selectReport("Consistency")

		this.ReportViewer.showConsistencyReport()

		this.updateState()
	}

	editConsistencyReportSettings() {
		this.Window.Opt("+Disabled")

		try {
			return this.ReportViewer.editReportSettings("Laps", "Cars", "Classes")
		}
		finally {
			this.Window.Opt("-Disabled")
		}
	}

	showPaceReport() {
		this.selectReport("Pace")

		this.ReportViewer.showPaceReport()

		this.updateState()
	}

	editPaceReportSettings() {
		this.Window.Opt("+Disabled")

		try {
			return this.ReportViewer.editReportSettings("Laps", "Cars", "Classes")
		}
		finally {
			this.Window.Opt("-Disabled")
		}
	}

	showPerformanceReport() {
		this.selectReport("Performance")

		this.ReportViewer.showPerformanceReport()

		this.updateState()
	}

	editPerformanceReportSettings() {
		this.Window.Opt("+Disabled")

		try {
			return this.ReportViewer.editReportSettings("Laps", "Cars", "Classes")
		}
		finally {
			this.Window.Opt("-Disabled")
		}
	}

	showTrackMap() {
		local html := false
		local lastLap := this.LastLap
		local hasLeader := false
		local hasAhead := false
		local hasBehind := false
		local sessionDB, trackMap, fileName, width, height, scale, offsetX, offsetY, marginX, marginY
		local imgWidth, imgHeight, imgScale, telemetry, positions, token, bitmap, graphics, brushCar, brushGray
		local carIndices, driverIndex, driverID, driverOverallPosition, driverClassPosition, driverClass
		local leaderBrush, aheadBrush, behindBrush
		local r, coordinates, carID, carIndex, carPosition, carClass, x, y, brush
		local imageAreaWidth, script

		this.initializeReports()

		if this.Simulator {
			sessionDB := SessionDatabase()

			trackMap := sessionDB.getTrackMap(this.Simulator, this.Track)
			fileName := sessionDB.getTrackImage(this.Simulator, this.Track)

			if (trackMap && fileName) {
				width := this.ChartViewer.getWidth()
				height := this.ChartViewer.getHeight()

				scale := getMultiMapValue(trackMap, "Map", "Scale")

				offsetX := getMultiMapValue(trackMap, "Map", "Offset.X")
				offsetY := getMultiMapValue(trackMap, "Map", "Offset.Y")
				marginX := getMultiMapValue(trackMap, "Map", "Margin.X")
				marginY := getMultiMapValue(trackMap, "Map", "Margin.Y")

				imgWidth := ((getMultiMapValue(trackMap, "Map", "Width") + (2 * marginX)) * scale)
				imgHeight := ((getMultiMapValue(trackMap, "Map", "Height") + (2 * marginY)) * scale)

				imgScale := Min(width / imgWidth, height / imgHeight)

				if (this.SessionActive && lastLap) {
					telemetry := lastLap.Telemetry
					positions := lastLap.Positions

					if telemetry {
						telemetry := parseMultiMap(telemetry)

						if positions
							positions := parseMultiMap(positions)

						token := Gdip_Startup()

						bitmap := Gdip_CreateBitmapFromFile(fileName)

						graphics := Gdip_GraphicsFromImage(bitmap)

						Gdip_SetSmoothingMode(graphics, 4)

						brushCar := Gdip_BrushCreateSolid(0xff000000)
						brushGray := Gdip_BrushCreateSolid(0xffBBBBBB)

						carIndices := CaseInsenseWeakMap()

						if positions {
							loop getMultiMapValue(positions, "Position Data", "Car.Count")
								carIndices[getMultiMapValue(positions, "Position Data", "Car." . A_Index . ".ID", A_Index)] := A_Index

							driverIndex := getMultiMapValue(positions, "Position Data", "Driver.Car", 0)
							driverID := getMultiMapValue(positions, "Position Data", "Car." . driverIndex . ".ID", driverIndex)
							driverOverallPosition := this.getPosition(positions)
							driverClassPosition := this.getPosition(positions, "Class")
							driverClass := this.getClass(positions)

							leaderBrush := Gdip_BrushCreateSolid(0xff0000ff)
							aheadBrush := Gdip_BrushCreateSolid(0xff006400)
							behindBrush := Gdip_BrushCreateSolid(0xffff0000)
						}
						else {
							driverIndex := false
							driverID := false
							driverOverallPosition := false
						}

						r := Round(15 / (imgScale * 3))

						loop {
							coordinates := getMultiMapValue(telemetry, "Track Data", "Car." . A_Index . ".Position", false)

							if coordinates {
								carID := getMultiMapValue(telemetry, "Track Data", "Car." . A_Index . ".ID", A_Index)

								if (carID = driverID)
									continue

								carIndex := (carIndices.Has(carID) ? carIndices[carID] : false)

								coordinates := string2Values(",", coordinates)

								x := Round((marginX + offsetX + coordinates[1]) * scale)
								y := Round((marginX + offsetY + coordinates[2]) * scale)

								brush := brushGray

								if ((!hasLeader || !hasAhead || !hasBehind) && positions && driverClassPosition && carIndex) {
									carClass := this.getClass(positions, carIndex)

									if (driverClass = carClass) {
										carPosition := this.getPosition(positions, "Class", carIndex)

										if (!hasAhead && (carPosition + 1) = driverClassPosition) {
											brush := aheadBrush

											hasAhead := true
										}

										if (!hasBehind && (carPosition - 1) = driverClassPosition) {
											brush := behindBrush

											hasBehind := true
										}

										if (!hasLeader && (carPosition == 1) && (driverClassPosition != 1)) {
											brush := leaderBrush

											hasLeader := true
										}
									}
								}

								Gdip_FillEllipse(graphics, brush, x - r, y - r, r * 2, r * 2)
							}
							else
								break
						}

						loop
							if (driverID = getMultiMapValue(telemetry, "Track Data", "Car." . A_Index . ".ID", A_Index)) {
								coordinates := getMultiMapValue(telemetry, "Track Data", "Car." . A_Index . ".Position", false)

								if coordinates {
									coordinates := string2Values(",", coordinates)

									x := Round((marginX + offsetX + coordinates[1]) * scale)
									y := Round((marginX + offsetY + coordinates[2]) * scale)

									Gdip_FillEllipse(graphics, brushCar, x - r, y - r, r * 2, r * 2)
								}

								break
							}

						Gdip_DeleteBrush(brushGray)
						Gdip_DeleteBrush(brushCar)

						if driverOverallPosition {
							Gdip_DeleteBrush(leaderBrush)
							Gdip_DeleteBrush(aheadBrush)
							Gdip_DeleteBrush(behindBrush)
						}

						fileName := (kTempDirectory . "TrackMap.png")

						Gdip_SaveBitmapToFile(bitmap, fileName)

						Gdip_DisposeImage(bitmap)

						Gdip_DeleteGraphics(graphics)

						Gdip_Shutdown(token)
					}
				}

				imgWidth *= imgScale
				imgHeight *= imgScale

				scale := 0.99

				imgAreaWidth := (width / 2)

				while (imgWidth > imgAreaWidth) {
					imgWidth := Floor(imgWidth * scale)
					imgHeight := Floor(imgHeight * scale)
				}

				html := ("<div class=`"lbox`"><img width=`"" . imgWidth . "`" height=`"" . imgHeight . "`" src=`"" . fileName . "`"></div>")
			}
		}

		this.ChartViewer.document.open()

		if html {
			this.selectReport("Track")

			html .= "<div class=`"rbox`">"

			html .= ("<br><br><br><br><br><br><div style=`"text-align: left;`" id=`"header`"><i>" . translate("Deltas") . "</i></div>")
			html .= ("<br>" . this.createLapDeltas(lastLap, hasLeader ? "0000ff" : false, hasAhead ? "006400" : false, hasBehind ? "ff0000" : false))

			html .= "</div>"

			script := "
			(
				<meta charset='utf-8'>
				<head>
					<style>
						.lbox { float: left; text-align: center; width: %hWidth%; }
						.rbox { float: right; }
						.headerStyle { height: 25; font-size: 11px; font-weight: 500; background-color: #%headerBackColor%; }
						.rowStyle { font-size: 11px; background-color: #%evenRowBackColor%; }
						.oddRowStyle { font-size: 11px; background-color: #%oddRowBackColor%; }
						%tableCSS%
					</style>
				</head>
			)"

			script := substituteVariables(script, {tableCSS: this.StrategyViewer.getTableCSS(), hWidth: Round(width / 2.5)
												 , headerBackColor: this.Window.Theme.ListBackColor["Header"]
												 , evenRowBackColor: this.Window.Theme.ListBackColor["EvenRow"]
												 , oddRowBackColor: this.Window.Theme.ListBackColor["OddRow"]})

			html := ("<html>" . script . "<body style='background-color: #" . this.Window.AltBackColor . "' style='overflow: auto' leftmargin='0' topmargin='0' rightmargin='0' bottommargin='0'><style> div, table { font-family: Arial, Helvetica, sans-serif; font-size: 11px }</style><style> #header { font-size: 12px; } </style><div>" . html . "</div></body></html>")

			this.ChartViewer.document.write(html)
		}
		else {
			this.selectReport(false)

			this.ChartViewer.document.write("<html><body style='background-color: #" . this.Window.AltBackColor . "' style='overflow: auto' leftmargin='0' topmargin='0' rightmargin='0' bottommargin='0'></body></html>")
		}

		this.ChartViewer.document.close()

		this.updateState()
	}

	showRaceReport(report) {
		local raceData, drivers, ignore

		switch report, false {
			case "Overview":
				this.showOverviewReport()
			case "Car":
				this.showCarReport()
			case "Drivers":
				if !this.ReportViewer.Settings.Has("Drivers") {
					raceData := true

					this.ReportViewer.loadReportData(false, &raceData, &ignore := false, &ignore := false, &ignore := false)

					drivers := []

					loop Min(5, getMultiMapValue(raceData, "Cars", "Count"))
						drivers.Push(A_Index)

					if !this.ReportViewer.Settings.Has("Drivers")
						this.ReportViewer.Settings["Drivers"] := drivers
				}

				this.showDriverReport()
			case "Positions":
				this.showPositionsReport()
			case "Lap Times":
				this.showLapTimesReport()
			case "Consistency":
				if !this.ReportViewer.Settings.Has("Drivers") {
					raceData := true

					this.ReportViewer.loadReportData(false, &raceData, &ingore := false, &ingore := false, &ingore := false)

					drivers := []

					loop Min(5, getMultiMapValue(raceData, "Cars", "Count"))
						drivers.Push(A_Index)

					if !this.ReportViewer.Settings.Has("Drivers")
						this.ReportViewer.Settings["Drivers"] := drivers
				}

				this.showConsistencyReport()
			case "Pace":
				this.showPaceReport()
			case "Performance":
				this.showPerformanceReport()
		}
	}

	showTelemetryReport() {
		local window := this.Window
		local xAxis, yAxises

		xAxis := this.iXColumns[window["dataXDropDown"].Value]
		yAxises := Array(this.iY1Columns[window["dataY1DropDown"].Value])

		if (window["dataY2DropDown"].Value > 1)
			yAxises.Push(this.iY2Columns[window["dataY2DropDown"].Value - 1])

		if (window["dataY3DropDown"].Value > 1)
			yAxises.Push(this.iY3Columns[window["dataY3DropDown"].Value - 1])

		if (window["dataY4DropDown"].Value > 1)
			yAxises.Push(this.iY4Columns[window["dataY4DropDown"].Value - 1])

		if (window["dataY5DropDown"].Value > 1)
			yAxises.Push(this.iY5Columns[window["dataY5DropDown"].Value - 1])

		if (window["dataY6DropDown"].Value > 1)
			yAxises.Push(this.iY6Columns[window["dataY6DropDown"].Value - 1])

		this.showDataPlot(this.SessionStore.Tables["Lap.Data"], xAxis, yAxises)

		this.updateState()
	}

	showPressuresReport() {
		this.selectReport("Pressures")

		this.showTelemetryReport()

		this.updateState()
	}

	editPressuresReportSettings() {
		this.Window.Opt("+Disabled")

		try {
			return this.ReportViewer.editReportSettings("Laps")
		}
		finally {
			this.Window.Opt("-Disabled")
		}
	}

	showBrakesReport() {
		this.selectReport("Brakes")

		this.showTelemetryReport()

		this.updateState()
	}

	editBrakesReportSettings() {
		this.Window.Opt("+Disabled")

		try {
			return this.ReportViewer.editReportSettings("Laps")
		}
		finally {
			this.Window.Opt("-Disabled")
		}
	}

	showTemperaturesReport() {
		this.selectReport("Temperatures")

		this.showTelemetryReport()

		this.updateState()
	}

	editTemperaturesReportSettings() {
		this.Window.Opt("+Disabled")

		try {
			return this.ReportViewer.editReportSettings("Laps")
		}
		finally {
			this.Window.Opt("-Disabled")
		}
	}

	showCustomReport() {
		this.selectReport("Free")

		this.showTelemetryReport()

		this.updateState()
	}

	editCustomReportSettings() {
		this.Window.Opt("+Disabled")

		try {
			return this.ReportViewer.editReportSettings("Laps")
		}
		finally {
			this.Window.Opt("-Disabled")
		}
	}

	updateSeriesSelector(report, force := false) {
		local window := this.Window
		local xChoices, y1Choices, y2Choices, y3Choices, y4Choices, y5Choices, y6Choices
		local sessionDB, selected, names, ignore, id, found, index, driver

		if (force || (report != this.SelectedReport) || (window["dataXDropDown"].Value == 0)) {
			xChoices := []
			y1Choices := []
			y2Choices := []
			y3Choices := []
			y4Choices := []
			y5Choices := []
			y6Choices := []

			if (report = "Pressures") {
				xChoices := ["Stint", "Lap", "Lap.Time", "Tyre.Wear.Average"]

				y1Choices := ["Temperature.Air", "Temperature.Track", "Fuel.Remaining", "Tyre.Laps"
							, "Tyre.Pressure.Cold.Average", "Tyre.Pressure.Cold.Front.Average", "Tyre.Pressure.Cold.Rear.Average"
							, "Tyre.Pressure.Hot.Average", "Tyre.Pressure.Hot.Front.Average", "Tyre.Pressure.Hot.Rear.Average"
							, "Tyre.Pressure.Cold.Front.Left", "Tyre.Pressure.Cold.Front.Right", "Tyre.Pressure.Cold.Rear.Left", "Tyre.Pressure.Cold.Rear.Right"
							, "Tyre.Pressure.Hot.Front.Left", "Tyre.Pressure.Hot.Front.Right", "Tyre.Pressure.Hot.Rear.Left", "Tyre.Pressure.Hot.Rear.Right"
							, "Tyre.Pressure.Loss.Front.Left", "Tyre.Pressure.Loss.Front.Right", "Tyre.Pressure.Loss.Rear.Left", "Tyre.Pressure.Loss.Rear.Right"
							, "Tyre.Wear.Average", "Tyre.Wear.Front.Average", "Tyre.Wear.Rear.Average"
							, "Tyre.Wear.Front.Left", "Tyre.Wear.Front.Right", "Tyre.Wear.Rear.Left", "Tyre.Wear.Rear.Right"]

				y2Choices := y1Choices
				y3Choices := y1Choices
				y4Choices := y1Choices
				y5Choices := y1Choices
				y6Choices := y1Choices
			}
			else if (report = "Brakes") {
				xChoices := ["Stint", "Lap", "Lap.Time", "Brake.Wear.Average"]

				y1Choices := ["Temperature.Air", "Temperature.Track", "Fuel.Remaining"
							, "Brake.Temperature.Average", "Brake.Temperature.Front.Average", "Brake.Temperature.Rear.Average"
							, "Brake.Temperature.Front.Left", "Brake.Temperature.Front.Right", "Brake.Temperature.Rear.Left", "Brake.Temperature.Rear.Right"
							, "Brake.Wear.Average", "Brake.Wear.Front.Average", "Brake.Wear.Rear.Average"
							, "Brake.Wear.Front.Left", "Brake.Wear.Front.Right", "Brake.Wear.Rear.Left", "Brake.Wear.Rear.Right"]

				y2Choices := y1Choices
				y3Choices := y1Choices
				y4Choices := y1Choices
				y5Choices := y1Choices
				y6Choices := y1Choices
			}
			else if (report = "Temperatures") {
				xChoices := ["Stint", "Lap", "Lap.Time", "Tyre.Wear.Average", "Brake.Wear.Average"]

				y1Choices := ["Temperature.Air", "Temperature.Track", "Fuel.Remaining", "Tyre.Laps"
							, "Tyre.Pressure.Hot.Average", "Tyre.Pressure.Hot.Front.Average", "Tyre.Pressure.Hot.Rear.Average"
							, "Tyre.Pressure.Hot.Front.Left", "Tyre.Pressure.Hot.Front.Right", "Tyre.Pressure.Hot.Rear.Left", "Tyre.Pressure.Hot.Rear.Right"
							, "Tyre.Pressure.Loss.Front.Left", "Tyre.Pressure.Loss.Front.Right", "Tyre.Pressure.Loss.Rear.Left", "Tyre.Pressure.Loss.Rear.Right"
							, "Tyre.Temperature.Average", "Tyre.Temperature.Front.Average", "Tyre.Temperature.Rear.Average"
							, "Tyre.Temperature.Front.Left", "Tyre.Temperature.Front.Right", "Tyre.Temperature.Rear.Left", "Tyre.Temperature.Rear.Right"
							, "Tyre.Wear.Average", "Tyre.Wear.Front.Average", "Tyre.Wear.Rear.Average"
							, "Tyre.Wear.Front.Left", "Tyre.Wear.Front.Right", "Tyre.Wear.Rear.Left", "Tyre.Wear.Rear.Right"
							, "Brake.Temperature.Average", "Brake.Temperature.Front.Average", "Brake.Temperature.Rear.Average"
							, "Brake.Temperature.Front.Left", "Brake.Temperature.Front.Right", "Brake.Temperature.Rear.Left", "Brake.Temperature.Rear.Right"
							, "Brake.Wear.Average", "Brake.Wear.Front.Average", "Brake.Wear.Rear.Average"
							, "Brake.Wear.Front.Left", "Brake.Wear.Front.Right", "Brake.Wear.Rear.Left", "Brake.Wear.Rear.Right"]

				y2Choices := y1Choices
				y3Choices := y1Choices
				y4Choices := y1Choices
				y5Choices := y1Choices
				y6Choices := y1Choices
			}
			else if (report = "Free") {
				xChoices := ["Stint", "Lap", "Lap.Time", "Tyre.Laps", "Map", "TC", "ABS", "Temperature.Air", "Temperature.Track", "Tyre.Wear.Average", "Brake.Wear.Average"]

				y1Choices := ["Temperature.Air", "Temperature.Track", "Fuel.Remaining", "Fuel.Consumption", "Lap.Time", "Tyre.Laps", "Map", "TC", "ABS"
							, "Tyre.Pressure.Cold.Average", "Tyre.Pressure.Cold.Front.Average", "Tyre.Pressure.Cold.Rear.Average"
							, "Tyre.Pressure.Hot.Average", "Tyre.Pressure.Hot.Front.Average", "Tyre.Pressure.Hot.Rear.Average"
							, "Tyre.Pressure.Hot.Front.Left", "Tyre.Pressure.Hot.Front.Right", "Tyre.Pressure.Hot.Rear.Left", "Tyre.Pressure.Hot.Rear.Right"
							, "Tyre.Pressure.Loss.Front.Left", "Tyre.Pressure.Loss.Front.Right", "Tyre.Pressure.Loss.Rear.Left", "Tyre.Pressure.Loss.Rear.Right"
							, "Tyre.Temperature.Average", "Tyre.Temperature.Front.Average", "Tyre.Temperature.Rear.Average"
							, "Tyre.Temperature.Front.Left", "Tyre.Temperature.Front.Right", "Tyre.Temperature.Rear.Left", "Tyre.Temperature.Rear.Right"
							, "Tyre.Wear.Average", "Tyre.Wear.Front.Average", "Tyre.Wear.Rear.Average"
							, "Tyre.Wear.Front.Left", "Tyre.Wear.Front.Right", "Tyre.Wear.Rear.Left", "Tyre.Wear.Rear.Right"
							, "Brake.Temperature.Average", "Brake.Temperature.Front.Average", "Brake.Temperature.Rear.Average"
							, "Brake.Temperature.Front.Left", "Brake.Temperature.Front.Right", "Brake.Temperature.Rear.Left", "Brake.Temperature.Rear.Right"
							, "Brake.Wear.Average", "Brake.Wear.Front.Average", "Brake.Wear.Rear.Average"
							, "Brake.Wear.Front.Left", "Brake.Wear.Front.Right", "Brake.Wear.Rear.Left", "Brake.Wear.Rear.Right"]

				y2Choices := y1Choices
				y3Choices := y1Choices
				y4Choices := y1Choices
				y5Choices := y1Choices
				y6Choices := y1Choices
			}

			this.iXColumns := xChoices
			this.iY1Columns := y1Choices
			this.iY2Columns := y2Choices
			this.iY3Columns := y3Choices
			this.iY4Columns := y3Choices
			this.iY5Columns := y3Choices
			this.iY6Columns := y3Choices

			window["dataXDropDown"].Delete()
			window["dataXDropDown"].Add(xChoices)
			window["dataY1DropDown"].Delete()
			window["dataY1DropDown"].Add(y1Choices)
			window["dataY2DropDown"].Delete()
			window["dataY2DropDown"].Add(concatenate([translate("None")], y2Choices))
			window["dataY3DropDown"].Delete()
			window["dataY3DropDown"].Add(concatenate([translate("None")], y3Choices))
			window["dataY4DropDown"].Delete()
			window["dataY4DropDown"].Add(concatenate([translate("None")], y4Choices))
			window["dataY5DropDown"].Delete()
			window["dataY5DropDown"].Add(concatenate([translate("None")], y5Choices))
			window["dataY6DropDown"].Delete()
			window["dataY6DropDown"].Add(concatenate([translate("None")], y6Choices))

			local dataXChoice := 0
			local dataY1Choice := 0
			local dataY2Choice := 0
			local dataY3Choice := 0
			local dataY4Choice := 0
			local dataY5Choice := 0
			local dataY6Choice := 0

			if (report = "Pressures") {
				window["chartTypeDropDown"].Choose(4)

				this.iSelectedChartType := "Line"

				dataXChoice := inList(xChoices, "Lap")
				dataY1Choice := inList(y1Choices, "Temperature.Air")
				dataY2Choice := inList(y2Choices, "Tyre.Pressure.Cold.Average") + 1
				dataY3Choice := inList(y3Choices, "Tyre.Pressure.Hot.Average") + 1
				dataY4Choice := 1
				dataY5Choice := 1
				dataY6Choice := 1
			}
			else if (report = "Brakes") {
				window["chartTypeDropDown"].Choose(4)

				this.iSelectedChartType := "Line"

				dataXChoice := inList(xChoices, "Lap")
				dataY1Choice := inList(y1Choices, "Temperature.Air")
				dataY2Choice := inList(y2Choices, "Brake.Temperature.Front.Average") + 1
				dataY3Choice := inList(y3Choices, "Brake.Temperature.Rear.Average") + 1
				dataY4Choice := inList(y4Choices, "Brake.Wear.Front.Average") + 1
				dataY5Choice := inList(y5Choices, "Brake.Wear.Rear.Average") + 1
				dataY6Choice := 1
			}
			else if (report = "Temperatures") {
				window["chartTypeDropDown"].Choose(1)

				this.iSelectedChartType := "Scatter"

				dataXChoice := inList(xChoices, "Lap")
				dataY1Choice := inList(y1Choices, "Temperature.Air")
				dataY2Choice := inList(y2Choices, "Tyre.Temperature.Front.Average") + 1
				dataY3Choice := inList(y3Choices, "Tyre.Temperature.Rear.Average") + 1
				dataY4Choice := 1
				dataY5Choice := 1
				dataY6Choice := 1
			}
			else if (report = "Free") {
				window["chartTypeDropDown"].Choose(4)

				this.iSelectedChartType := "Line"

				dataXChoice := inList(xChoices, "Lap")
				dataY1Choice := inList(y1Choices, "Lap.Time")
				dataY2Choice := inList(y2Choices, "Tyre.Laps") + 1
				dataY3Choice := inList(y3Choices, "Temperature.Air") + 1
				dataY4Choice := inList(y4Choices, "Temperature.Track") + 1
				dataY5Choice := inList(y5Choices, "Tyre.Pressure.Cold.Average") + 1
				dataY6Choice := inList(y6Choices, "Tyre.Pressure.Hot.Average") + 1
			}

			sessionDB := SessionDatabase()
			selected := false
			names := []

			if this.SelectedDrivers
				selected := this.SelectedDrivers[1]

			for index, id in this.AvailableDrivers {
				found := false

				for ignore, driver in this.Drivers
					if (driver.ID = id) {
						names.Push(driver.Fullname)

						found := true

						break
					}

				if !found
					names.Push(values2String(",", sessionDB.getDriverNames(this.SelectedSimulator, id)*))

				if (id = selected)
					selected := A_Index
			}

			if !isInteger(selected) {
				selected := false

				this.iSelectedDrivers := false
			}

			window["driverDropDown"].Delete()
			window["driverDropDown"].Add(concatenate([translate("All")], names))
			window["driverDropDown"].Choose(selected + 1)

			window["dataXDropDown"].Choose(dataXChoice)
			window["dataY1DropDown"].Choose(dataY1Choice)
			window["dataY2DropDown"].Choose(dataY2Choice)
			window["dataY3DropDown"].Choose(dataY3Choice)
			window["dataY4DropDown"].Choose(dataY4Choice)
			window["dataY5DropDown"].Choose(dataY5Choice)
			window["dataY6DropDown"].Choose(dataY6Choice)
		}
	}

	syncSessionStore(forSave := false) {
		local session := this.SelectedSession[true]
		local sessionStore := this.SessionStore
		local lastLap := this.LastLap
		local pressuresTable, tyresTable, newLap, lap, lapData, pressures, tyres
		local pressureFL, pressureFR, pressureRL, pressureRR
		local pressureLossFL, pressureLossFR, pressureLossRL, pressureLossRR
		local temperatureFL, temperatureFR, temperatureRL, temperatureRR
		local wearFL, wearFR, wearRL, wearRR
		local telemetry, brakeTemperatures, ignore, field, brakeWears
		local currentListView, lapPressures, entry, standingsData, prefix, driver, category
		local currentStint, newStint, stint, stintData, tries, carIDs, positions

		if lastLap
			lastLap := lastLap.Nr

		if lastLap {
			pressuresTable := this.PressuresDatabase.Database.Tables["Tyres.Pressures"]
			tyresTable := this.TelemetryDatabase.Database.Tables["Tyres"]

			newLap := (sessionStore.Tables["Lap.Data"].Length + 1)

			while (newLap <= lastLap) {
				if !this.Laps.Has(newLap) {
					newLap += 1

					continue
				}

				lap := this.Laps[newLap]

				if ((pressuresTable.Length < newLap) || (tyresTable.Length < newLap))
					return

				lapData := Database.Row("Nr", newLap, "Lap", newLap, "Stint", lap.Stint.Nr, "Lap.Time", null(lap.Laptime), "Position", null(lap.Position)
									  , "Damage", lap.Damage, "EngineDamage", lap.EngineDamage, "Accident", lap.Accident, "Penalty", lap.Penalty
									  , "Fuel.Consumption", null(lap.FuelConsumption), "Fuel.Remaining", null(lap.FuelRemaining)
									  , "Weather", lap.Weather, "Temperature.Air", null(lap.AirTemperature), "Temperature.Track", null(lap.TrackTemperature)
									  , "Grip", lap.Grip, "Map", null(lap.Map), "TC", null(lap.TC), "ABS", null(lap.ABS)
									  , "Tyre.Compound", compound(lap.Compound), "Tyre.Compound.Color", compoundColor(lap.Compound)
									  , "Time.Stint.Remaining", lap.RemainingStintTime, "Time.Driver.Remaining", lap.RemainingDriverTime)

				pressures := pressuresTable[newLap]
				tyres := tyresTable[newLap]

				pressureFL := pressures["Tyre.Pressure.Cold.Front.Left"]
				pressureFR := pressures["Tyre.Pressure.Cold.Front.Right"]
				pressureRL := pressures["Tyre.Pressure.Cold.Rear.Left"]
				pressureRR := pressures["Tyre.Pressure.Cold.Rear.Right"]

				lapData["Tyre.Pressure.Cold.Front.Left"] := null(pressureFL)
				lapData["Tyre.Pressure.Cold.Front.Right"] := null(pressureFR)
				lapData["Tyre.Pressure.Cold.Rear.Left"] := null(pressureRL)
				lapData["Tyre.Pressure.Cold.Rear.Right"] := null(pressureRR)
				lapData["Tyre.Pressure.Cold.Average"] := null(average([pressureFL, pressureFR, pressureRL, pressureRR]))
				lapData["Tyre.Pressure.Cold.Front.Average"] := null(average([pressureFL, pressureFR]))
				lapData["Tyre.Pressure.Cold.Rear.Average"] := null(average([pressureRL, pressureRR]))

				pressureFL := pressures["Tyre.Pressure.Hot.Front.Left"]
				pressureFR := pressures["Tyre.Pressure.Hot.Front.Right"]
				pressureRL := pressures["Tyre.Pressure.Hot.Rear.Left"]
				pressureRR := pressures["Tyre.Pressure.Hot.Rear.Right"]

				if (isNull(pressureFL))
					pressureFL := tyres["Tyre.Pressure.Front.Left"]
				if (isNull(pressureFR))
					pressureFR := tyres["Tyre.Pressure.Front.Right"]
				if (isNull(pressureRL))
					pressureRL := tyres["Tyre.Pressure.Rear.Left"]
				if (isNull(pressureRR))
					pressureRR := tyres["Tyre.Pressure.Rear.Right"]

				lapData["Tyre.Pressure.Hot.Front.Left"] := null(pressureFL)
				lapData["Tyre.Pressure.Hot.Front.Right"] := null(pressureFR)
				lapData["Tyre.Pressure.Hot.Rear.Left"] := null(pressureRL)
				lapData["Tyre.Pressure.Hot.Rear.Right"] := null(pressureRR)
				lapData["Tyre.Pressure.Hot.Average"] := null(average([pressureFL, pressureFR, pressureRL, pressureRR]))
				lapData["Tyre.Pressure.Hot.Front.Average"] := null(average([pressureFL, pressureFR]))
				lapData["Tyre.Pressure.Hot.Rear.Average"] := null(average([pressureRL, pressureRR]))

				pressureLossFL := pressures["Tyre.Pressure.Loss.Front.Left"]
				pressureLossFR := pressures["Tyre.Pressure.Loss.Front.Right"]
				pressureLossRL := pressures["Tyre.Pressure.Loss.Rear.Left"]
				pressureLossRR := pressures["Tyre.Pressure.Loss.Rear.Right"]

				lapData["Tyre.Pressure.Loss.Front.Left"] := null(pressureLossFL)
				lapData["Tyre.Pressure.Loss.Front.Right"] := null(pressureLossFR)
				lapData["Tyre.Pressure.Loss.Rear.Left"] := null(pressureLossRL)
				lapData["Tyre.Pressure.Loss.Rear.Right"] := null(pressureLossRR)

				tyres := tyresTable[newLap]

				lapData["Tyre.Laps"] := null(tyres["Tyre.Laps"])

				temperatureFL := tyres["Tyre.Temperature.Front.Left"]
				temperatureFR := tyres["Tyre.Temperature.Front.Right"]
				temperatureRL := tyres["Tyre.Temperature.Rear.Left"]
				temperatureRR := tyres["Tyre.Temperature.Rear.Right"]

				lapData["Tyre.Temperature.Front.Left"] := null(temperatureFL)
				lapData["Tyre.Temperature.Front.Right"] := null(temperatureFR)
				lapData["Tyre.Temperature.Rear.Left"] := null(temperatureRL)
				lapData["Tyre.Temperature.Rear.Right"] := null(temperatureRR)
				lapData["Tyre.Temperature.Average"] := null(average([temperatureFL, temperatureFR, temperatureRL, temperatureRR]))
				lapData["Tyre.Temperature.Front.Average"] := null(average([temperatureFL, temperatureFR]))
				lapData["Tyre.Temperature.Rear.Average"] := null(average([temperatureRL, temperatureRR]))

				wearFL := tyres["Tyre.Wear.Front.Left"]
				wearFR := tyres["Tyre.Wear.Front.Right"]
				wearRL := tyres["Tyre.Wear.Rear.Left"]
				wearRR := tyres["Tyre.Wear.Rear.Right"]

				lapData["Tyre.Wear.Front.Left"] := null(wearFL)
				lapData["Tyre.Wear.Front.Right"] := null(wearFR)
				lapData["Tyre.Wear.Rear.Left"] := null(wearRL)
				lapData["Tyre.Wear.Rear.Right"] := null(wearRR)
				lapData["Tyre.Wear.Average"] := ((wearFL = kNull) ? kNull : null(average([wearFL, wearFR, wearRL, wearRR])))
				lapData["Tyre.Wear.Front.Average"] := ((wearFL = kNull) ? kNull : null(average([wearFL, wearFR])))
				lapData["Tyre.Wear.Rear.Average"] := ((wearFL = kNull) ? kNull : null(average([wearRL, wearRR])))

				telemetry := parseMultiMap(lap.Telemetry)

				if (telemetry.Count > 0) {
					brakeTemperatures := string2Values(",", getMultiMapValue(telemetry, "Car Data", "BrakeTemperature", ""))

					if (brakeTemperatures.Length = 4) {
						temperatureFL := brakeTemperatures[1]
						temperatureFR := brakeTemperatures[2]
						temperatureRL := brakeTemperatures[3]
						temperatureRR := brakeTemperatures[4]

						lapData["Brake.Temperature.Front.Left"] := null(temperatureFL)
						lapData["Brake.Temperature.Front.Right"] := null(temperatureFR)
						lapData["Brake.Temperature.Rear.Left"] := null(temperatureRL)
						lapData["Brake.Temperature.Rear.Right"] := null(temperatureRR)
						lapData["Brake.Temperature.Average"] := null(average([temperatureFL, temperatureFR, temperatureRL, temperatureRR]))
						lapData["Brake.Temperature.Front.Average"] := null(average([temperatureFL, temperatureFR]))
						lapData["Brake.Temperature.Rear.Average"] := null(average([temperatureRL, temperatureRR]))
					}
					else
						for ignore, field in ["Brake.Temperature.Front.Left", "Brake.Temperature.Front.Right", "Brake.Temperature.Rear.Left", "Brake.Temperature.Rear.Right"
											, "Brake.Temperature.Average", "Brake.Temperature.Front.Average", "Brake.Temperature.Rear.Average"]
							lapData[field] := kNull

					brakeWears := string2Values(",", getMultiMapValue(telemetry, "Car Data", "BrakeWear", ""))

					if (brakeWears.Length = 4) {
						wearFL := brakeWears[1]
						wearFR := brakeWears[2]
						wearRL := brakeWears[3]
						wearRR := brakeWears[4]

						lapData["Brake.Wear.Front.Left"] := null(wearFL)
						lapData["Brake.Wear.Front.Right"] := null(wearFR)
						lapData["Brake.Wear.Rear.Left"] := null(wearRL)
						lapData["Brake.Wear.Rear.Right"] := null(wearRR)
						lapData["Brake.Wear.Average"] := ((wearFL = kNull) ? kNull : null(average([wearFL, wearFR, wearRL, wearRR])))
						lapData["Brake.Wear.Front.Average"] := ((wearFL = kNull) ? kNull : null(average([wearFL, wearFR])))
						lapData["Brake.Wear.Rear.Average"] := ((wearFL = kNull) ? kNull : null(average([wearRL, wearRR])))
					}
					else
						for ignore, field in ["Brake.Wear.Front.Left", "Brake.Wear.Front.Right", "Brake.Wear.Rear.Left", "Brake.Wear.Rear.Right"
											, "Brake.Wear.Average", "Brake.Wear.Front.Average", "Brake.Wear.Rear.Average"]
							lapData[field] := kNull
				}

				sessionStore.add("Lap.Data", lapData)

				lapPressures := this.LapsListView.GetText(lap.Row, 10)

				if (lapPressures = "-, -, -, -") {
					if isNumber(pressureFL)
						pressureFL := displayValue("Float", convertUnit("Pressure", pressureFL))
					if isNumber(pressureFR)
						pressureFR := displayValue("Float", convertUnit("Pressure", pressureFR))
					if isNumber(pressureRL)
						pressureRL := displayValue("Float", convertUnit("Pressure", pressureRL))
					if isNumber(pressureRR)
						pressureRR := displayValue("Float", convertUnit("Pressure", pressureRR))

					this.LapsListView.Modify(lap.Row, "Col10", values2String(", ", displayNullValue(pressureFL), displayNullValue(pressureFR)
																				 , displayNullValue(pressureRL), displayNullValue(pressureRR)))
				}

				newLap += 1
			}

			if this.SessionActive {
				lap := 0

				for ignore, entry in sessionStore.Tables["Delta.Data"]
					lap := Max(lap, entry["Lap"])

				lap += 1

				while (lap <= lastLap) {
					if !this.Laps.Has(lap) {
						lap += 1

						continue
					}

					try {
						tries := ((lap == lastLap) ? 30 : 5)

						while (tries > 0) {
							standingsData := this.Connector.GetSessionLapValue(session, lap, "Race Strategist Race Standings")

							if (!standingsData || (standingsData == "")) {
								tries -= 1

								this.showMessage(translate("Waiting for data"))

								if (tries <= 0) {
									this.showMessage(translate("Give up - use default values"))

									throw "No data..."
								}
								else
									Sleep(400)
							}
							else
								break
						}

						standingsData := parseMultiMap(standingsData)
					}
					catch Any as exception {
						if (exception != "No data...")
							logError(exception)

						standingsData := newMultiMap()
					}

					if (standingsData.Count > 0) {
						positions := this.Laps[lap].Positions

						if (positions && (positions != "")) {
							positions := parseMultiMap(positions)

							carIDs := CaseInsenseWeakMap()

							loop getMultiMapValue(positions, "Position Data", "Car.Count")
								carIDs[A_Index] := getMultiMapValue(positions, "Position Data", "Car." . A_Index . ".ID")

							sessionStore.add("Delta.Data"
										   , Database.Row("Lap", lap, "Type", "Standings.Behind"
														, "Car", getDeprecatedValue(standingsData, "Position"
																								 , "Position.Standings.Class.Behind.Car", "Position.Standings.Behind.Car")
														, "ID", carIDs[getDeprecatedValue(standingsData, "Position"
																									   , "Position.Standings.Class.Behind.Car", "Position.Standings.Behind.Car")]
														, "Delta", Round(getDeprecatedValue(standingsData, "Position"
																										 , "Position.Standings.Class.Behind.Delta"
																										 , "Position.Standings.Behind.Delta") / 1000, 2)
														, "Distance", Round(getDeprecatedValue(standingsData, "Position"
																											, "Position.Standings.Class.Behind.Distance"
																											, "Position.Standings.Behind.Distance"), 2)))

							sessionStore.add("Delta.Data"
										   , Database.Row("Lap", lap, "Type", "Standings.Ahead"
														, "Car", getDeprecatedValue(standingsData, "Position"
																								 , "Position.Standings.Class.Ahead.Car", "Position.Standings.Ahead.Car")
														, "ID", carIDs[getDeprecatedValue(standingsData, "Position"
																									   , "Position.Standings.Class.Ahead.Car", "Position.Standings.Ahead.Car")]
														, "Delta", Round(getDeprecatedValue(standingsData, "Position"
																										 , "Position.Standings.Class.Ahead.Delta"
																										 , "Position.Standings.Ahead.Delta") / 1000, 2)
														, "Distance", Round(getDeprecatedValue(standingsData, "Position"
																											, "Position.Standings.Class.Ahead.Distance"
																											, "Position.Standings.Ahead.Distance"), 2)))

							sessionStore.add("Delta.Data"
										   , Database.Row("Lap", lap, "Type", "Standings.Leader"
														, "Car", getDeprecatedValue(standingsData, "Position"
																								 , "Position.Standings.Class.Leader.Car", "Position.Standings.Leader.Car")
														, "ID", carIDs[getDeprecatedValue(standingsData, "Position"
																									   , "Position.Standings.Class.Leader.Car", "Position.Standings.Leader.Car")]
														, "Delta", Round(getDeprecatedValue(standingsData, "Position"
																										 , "Position.Standings.Class.Leader.Delta"
																										 , "Position.Standings.Leader.Delta") / 1000, 2)
														, "Distance", Round(getDeprecatedValue(standingsData, "Position"
																											, "Position.Standings.Class.Leader.Distance"
																											, "Position.Standings.Leader.Distance"), 2)))

							sessionStore.add("Delta.Data"
										   , Database.Row("Lap", lap, "Type", "Track.Behind"
														, "Car", getMultiMapValue(standingsData, "Position", "Position.Track.Behind.Car")
														, "ID", carIDs[getMultiMapValue(standingsData, "Position", "Position.Track.Behind.Car")]
														, "Delta", Round(getMultiMapValue(standingsData, "Position", "Position.Track.Behind.Delta") / 1000, 2)
														, "Distance", Round(getMultiMapValue(standingsData, "Position", "Position.Track.Behind.Distance"), 2)))

							sessionStore.add("Delta.Data"
										   , Database.Row("Lap", lap, "Type", "Track.Ahead"
														, "Car", getMultiMapValue(standingsData, "Position", "Position.Track.Ahead.Car")
														, "ID", carIDs[getMultiMapValue(standingsData, "Position", "Position.Track.Ahead.Car")]
														, "Delta", Round(getMultiMapValue(standingsData, "Position", "Position.Track.Ahead.Delta") / 1000, 2)
														, "Distance", Round(getMultiMapValue(standingsData, "Position", "Position.Track.Ahead.Distance"), 2)))

							prefix := ("Standings.Lap." . lap . ".Car.")

							loop getMultiMapValue(standingsData, "Standings", prefix . "Count") {
								driver := computeDriverName(getMultiMapValue(standingsData, "Standings", prefix . A_Index . ".Driver.Forname")
														  , getMultiMapValue(standingsData, "Standings", prefix . A_Index . ".Driver.Surname")
														  , getMultiMapValue(standingsData, "Standings", prefix . A_Index . ".Driver.Nickname"))
								category := getMultiMapValue(standingsData, "Standings", prefix . A_Index . ".Driver.Category", "Unknown")

								if (category = "Unknown")
									category := kNull

								sessionStore.add("Standings.Data"
											   , Database.Row("Lap", lap, "Car", A_Index, "ID", carIDs[A_Index], "Driver", driver, "Category", category
															, "Position", getMultiMapValue(standingsData, "Standings", prefix . A_Index . ".Position")
															, "Time", Round(getMultiMapValue(standingsData, "Standings", prefix . A_Index . ".Time") / 1000, 1)
															, "Laps", Round(getMultiMapValue(standingsData, "Standings", prefix . A_Index . ".Laps"), 1)
															, "Delta", Round(getMultiMapValue(standingsData, "Standings", prefix . A_Index . ".Delta") / 1000, 2)))
							}
						}
					}

					lap += 1
				}
			}
		}

		if forSave {
			this.saveSetups(this.SessionFinished)
			this.savePlan(this.SessionFinished)

			currentStint := this.CurrentStint

			if currentStint {
				sessionStore.clear("Stint.Data")
				newStint := 1

				while (newStint <= currentStint.Nr) {
					if this.Stints.Has(newStint) {
						stint := this.Stints[newStint]

						stintData := Database.Row("Nr", newStint, "Lap", stint.Lap
												, "Driver.Forname", stint.Driver.Forname, "Driver.Surname", stint.Driver.Surname, "Driver.Nickname", stint.Driver.Nickname
												, "Weather", stint.Weather, "Compound", stint.Compound
												, "Lap.Time.Average", null(stint.AvgLaptime), "Lap.Time.Best", null(stint.BestLapTime)
												, "Fuel.Consumption", null(stint.FuelConsumption), "Accidents", stint.Accidents, "Penalties", stint.Penalties
												, "Position.Start", null(stint.StartPosition), "Position.End", null(stint.EndPosition)
												, "Time.Start", this.computeStartTime(stint), "Time.End", this.computeEndTime(stint), "Driver.ID", stint.ID)

						sessionStore.add("Stint.Data", stintData)
					}

					newStint += 1
				}
			}

			if (this.Drivers.Length != sessionStore.Tables["Driver.Data"].Length) {
				sessionStore.clear("Driver.Data")

				for ignore, driver in this.Drivers
					sessionStore.add("Driver.Data", Database.Row("Forname", driver.Forname, "Surname", driver.Surname, "Nickname", driver.Nickname, "ID", driver.ID))
			}

			sessionStore.flush()
		}
	}

	reportSettings(report) {
		switch report, false {
			case "Overview":
				if this.editOverviewReportSettings()
					this.showOverviewReport()
			case "Drivers":
				if this.editDriverReportSettings()
					this.showDriverReport()
			case "Positions":
				if this.editPositionsReportSettings()
					this.showPositionsReport()
			case "Lap Times":
				if this.editLapTimesReportSettings()
					this.showLapTimesReport()
			case "Consistency":
				if this.editConsistencyReportSettings()
					this.showConsistencyReport()
			case "Pace":
				if this.editPaceReportSettings()
					this.showPaceReport()
			case "Performance":
				if this.editPerformanceReportSettings()
					this.showPerformanceReport()
			case "Pressures":
				if this.editPressuresReportSettings()
					this.showPressuresReport()
			case "Brakes":
				if this.editBrakesReportSettings()
					this.showBrakesReport()
			case "Temperatures":
				if this.editTemperaturesReportSettings()
					this.showTemperaturesReport()
			case "Free":
				if this.editCustomReportSettings()
					this.showCustomReport()
		}
	}

	showReport(report, force := false) {
		showReportAsync(report) {
			this.updateSeriesSelector(report)

			if (report = "Track")
				this.showTrackMap()
			else if inList(kRaceReports, report)
				this.showRaceReport(report)
			else if (report = "Pressures")
				this.showPressuresReport()
			else if (report = "Brakes")
				this.showBrakesReport()
			else if (report = "Temperatures")
				this.showTemperaturesReport()
			else if (report = "Free")
				this.showCustomReport()
		}

		if (force || (report != this.SelectedReport)) {
			this.pushTask(ObjBindMethod(this, "syncSessionStore"))

			this.pushTask(showReportAsync.Bind(report))
		}
	}

	selectChartType(chartType, force := false) {
		if (force || (chartType != this.SelectedChartType)) {
			this.Control["chartTypeDropDown"].Choose(inList(["Scatter", "Bar", "Bubble", "Line"], chartType))

			this.iSelectedChartType := chartType

			this.showTelemetryReport()
		}
	}

	createStintHeader(stint) {
		local startTime := this.computeStartTime(stint)
		local endTime := this.computeEndTime(stint)
		local duration := 0
		local ignore, lap, html

		for ignore, lap in stint.Laps
			duration += lap.Laptime

		if startTime
			startTime := FormatTime(startTime, "Time")
		else
			startTime := "-"

		if endTime
			endTime := FormatTime(endTime, "Time")
		else
			endTime := "-"

		html := "<table>"
		html .= ("<tr><td><b>" . translate("Driver:") . "</b></div></td><td>" . StrReplace(stint.Driver.FullName, "'", "\'") . "</td></tr>")
		html .= ("<tr><td><b>" . translate("Start:") . "</b></div></td><td>" . startTime . "</td></tr>")
		html .= ("<tr><td><b>" . translate("End:") . "</b></div></td><td>" . endTime . "</td></tr>")
		html .= ("<tr><td><b>" . translate("Duration:") . "</b></div></td><td>" . Round(duration / 60) . A_Space . translate("Minutes") . "</td></tr>")
		html .= ("<tr><td><b>" . translate("Start Position:") . "</b></div></td><td>" . stint.StartPosition . "</td></tr>")
		html .= ("<tr><td><b>" . translate("End Position:") . "</b></div></td><td>" . stint.EndPosition . "</td></tr>")
		html .= ("<tr><td><b>" . translate("Temperatures (A / T):") . "</b></td><td>" . displayValue("Float", convertUnit("Temperature", stint.AirTemperature)) . ", " . displayValue("Float", convertUnit("Temperature", stint.TrackTemperature)) . "</td></tr>")
		html .= ("<tr><td><b>" . translate("Consumption:") . "</b></div></td><td>" . displayValue("Float", convertUnit("Volume", stint.FuelConsumption)) . "</td></tr>")
		html .= "</table>"

		return html
	}

	createLapDetailsChart(chartID, width, height, lapSeries, positionSeries, lapTimeSeries, fuelSeries, tempSeries) {
		local drawChartFunction := ("function drawChart" . chartID . "() {`nvar data = new google.visualization.DataTable();")
		local ignore, time, fuel, temperature

		drawChartFunction .= ("`ndata.addColumn('number', '" . translate("Lap") . "');")
		drawChartFunction .= ("`ndata.addColumn('number', '" . translate("Position") . "');")
		drawChartFunction .= ("`ndata.addColumn('number', '" . translate("Lap Time") . "');")
		drawChartFunction .= ("`ndata.addColumn('number', '" . translate("Consumption") . "');")
		drawChartFunction .= ("`ndata.addColumn('number', '" . translate("Tyre Temperatures") . "');")

		drawChartFunction .= "`ndata.addRows(["

		for ignore, time in lapSeries {
			if (A_Index > 1)
				drawChartFunction .= ", "

			fuel := fuelSeries[A_Index]

			if isNumber(fuel)
				fuel := convertUnit("Volume", fuel)

			temperature := tempSeries[A_Index]

			if isNumber(temperature)
				temperature := convertUnit("Temperature", temperature)

			drawChartFunction .= ("[" . values2String(", ", lapSeries[A_Index]
														  , chartValue(null(positionSeries[A_Index]))
														  , chartValue(null(lapTimeSeries[A_Index]))
														  , chartValue(null(fuel))
														  , chartValue(null(temperature)))
								. "]")
		}

		drawChartFunction .= ("]);`nvar options = { legend: { position: 'Right' }, chartArea: { left: '10%', top: '5%', right: '25%', bottom: '20%' }, hAxis: { title: '" . translate("Lap") . "', gridlines: {count: 0} }, vAxis: { viewWindow: { min: 0 }, gridlines: {count: 0} }, backgroundColor: '" . this.Window.AltBackColor . "' };`n")

		drawChartFunction .= ("`nvar chart = new google.visualization.LineChart(document.getElementById('chart_" . chartID . "')); chart.draw(data, options); }")

		return drawChartFunction
	}

	createStintPerformanceChart(chartID, width, height, stint) {
		local drawChartFunction := ""
		local minValue, maxValue

		this.updateStintStatistics(stint)

		drawChartFunction .= "function drawChart" . chartID . "() {"
		drawChartFunction .= "`nvar data = google.visualization.arrayToDataTable(["
		drawChartFunction .= "`n['" . values2String("', '", translate("Category"), StrReplace(stint.Driver.FullName, "'", "\'")) . "'],"

		drawChartFunction .= "`n[" . values2String(", ", "'" . translate("Potential") . "'", stint.Potential) . "],"
		drawChartFunction .= "`n[" . values2String(", ", "'" . translate("Race Craft") . "'", stint.RaceCraft) . "],"
		drawChartFunction .= "`n[" . values2String(", ", "'" . translate("Speed") . "'", stint.Speed) . "],"
		drawChartFunction .= "`n[" . values2String(", ", "'" . translate("Consistency") . "'", stint.Consistency) . "],"
		drawChartFunction .= "`n[" . values2String(", ", "'" . translate("Car Control") . "'", stint.CarControl) . "]"

		drawChartFunction .= ("`n]);")

		minValue := Min(0, stint.Potential, stint.RaceCraft, stint.Speed, stint.Consistency, stint.CarControl)
		maxValue := Max(stint.Potential, stint.RaceCraft, stint.Speed, stint.Consistency, stint.CarControl)

		drawChartFunction := drawChartFunction . "`nvar options = { bars: 'horizontal', legend: 'none', backgroundColor: '" . this.Window.AltBackColor . "', chartArea: { left: '20%', top: '5%', right: '10%', bottom: '10%' }, hAxis: {viewWindowMode: 'explicit', viewWindow: {min: " . minValue . ", max: " . maxValue . "}, gridlines: {count: 0} }, vAxis: {gridlines: {count: 0}} };"
		drawChartFunction := drawChartFunction . "`nvar chart = new google.visualization.BarChart(document.getElementById('chart_" . chartID . "')); chart.draw(data, options); }"

		return drawChartFunction
	}

	createStintConsistencyChart(chartID, width, height, stint, laps, lapTimes) {
		local drawChartFunction := "function drawChart" . chartID . "() {"
		local validLaps := []
		local validTimes := []
		local ignore, lap, time, theMin, avg, theMax, delta, window, consistency, time, title

		for ignore, lap in laps {
			if (A_Index > 1) {
				time := lapTimes[A_Index]

				if isNumber(time) {
					validLaps.Push(lap)
					validTimes.Push(time)
				}
			}
		}

		drawChartFunction .= "`nvar data = google.visualization.arrayToDataTable(["

		drawChartFunction .= "`n['" . values2String("', '", translate("Lap"), translate("Lap Time")
														  , translate("Max"), translate("Avg"), translate("Min"))
						   . "']"

		theMin := minimum(validTimes)
		avg := average(validTimes)
		theMax := maximum(validTimes)

		for ignore, lap in validLaps
			drawChartFunction .= ",`n[" . values2String(", ", lap, validTimes[A_Index], theMax, avg, theMin) . "]"

		drawChartFunction .= ("`n]);")

		delta := (theMax - theMin)

		theMin := Max(avg - (3 * delta), 0)
		theMax := Min(avg + (2 * delta), theMax)

		if (theMin = 0)
			theMin := (avg / 3)

		window := ("baseline: " . theMin . ", viewWindow: {min: " . theMin . ", max: " . theMax . "}, ")
		consistency := 0

		for ignore, time in validTimes
			consistency += (100 - Abs(avg - time))

		consistency := Round(consistency / ((validTimes.Length = 0) ? 0.01 : validTimes.Length), 2)

		title := ("title: '" . translate("Consistency: ") . consistency . translate(" %") . "', titleTextStyle: {bold: false}, ")

		drawChartFunction .= ("`nvar options = {" . title . "seriesType: 'bars', series: {1: {type: 'line'}, 2: {type: 'line'}, 3: {type: 'line'}}, backgroundColor: '#" . this.Window.AltBackColor . "', vAxis: {" . window . "title: '" . translate("Lap Time") . "', gridlines: {count: 0}}, hAxis: {title: '" . translate("Laps") . "', gridlines: {count: 0}}, chartArea: { left: '20%', top: '15%', right: '15%', bottom: '15%' } };")

		drawChartFunction .= ("`nvar chart = new google.visualization.ComboChart(document.getElementById('chart_" . chartID . "')); chart.draw(data, options); }")

		return drawChartFunction
	}

	createLapDetails(stint) {
		local html := "<table>"
		local lapData := []
		local mapData := []
		local lapTimeData := []
		local fuelConsumptionData := []
		local accidentData := []
		local penaltyData := []
		local ignore, lap, fuelConsumption

		html .= ("<tr><td><b>" . translate("Average:") . "</b></td><td>" . lapTimeDisplayValue(stint.AvgLapTime) . "</td></tr>")
		html .= ("<tr><td><b>" . translate("Best:") . "</b></td><td>" . lapTimeDisplayValue(stint.BestLapTime) . "</td></tr>")
		html .= "</table>"

		for ignore, lap in stint.Laps {
			lapData.Push("<th class=`"th-std`">" . lap.Nr . "</th>")
			mapData.Push("<td class=`"td-std`">" . lap.Map . "</td>")
			lapTimeData.Push("<td class=`"td-std`">" . lapTimeDisplayValue(lap.Laptime) . "</td>")

			fuelConsumption := lap.FuelConsumption

			if isNumber(fuelConsumption)
				fuelConsumption := displayValue("Float", convertUnit("Volume", fuelConsumption))

			penalty := ""

			if lap.Penalty {
				penalty := lap.Penalty

				if (InStr(penalty, "SG") = 1) {
					penalty := ((StrLen(penalty) > 2) ? (A_Space . SubStr(penalty, 3)) : "")

					penalty := (translate("Stop and Go") . penalty)
				}
				else if (penalty = "Time")
					penalty := translate("Time")
				else if (penalty = "DT")
					penalty := translate("Drive Through")
				else if (penalty == true)
					penalty := "x"
			}

			fuelConsumptionData.Push("<td class=`"td-std`">" . displayNullValue(fuelConsumption) . "</td>")
			accidentData.Push("<td class=`"td-std`">" . (lap.Accident ? "x" : "") . "</td>")
			penaltyData.Push("<td class=`"td-std`">" . penalty . "</td>")
		}

		html .= "<br><table class=`"table-std`">"

		html .= ("<tr><th class=`"th-std`">" . translate("Lap") . "</th>"
				   . "<th class=`"th-std`">" . translate("Map") . "</th>"
				   . "<th class=`"th-std`">" . translate("Lap Time") . "</th>"
				   . "<th class=`"th-std`">" . translate("Consumption") . "</th>"
				   . "<th class=`"th-std`">" . translate("Accident") . "</th>"
				   . "<th class=`"th-std`">" . translate("Penalty") . "</th>"
			   . "</tr>")

		loop lapData.Length
			html .= ("<tr>" . lapData[A_Index]
							. mapData[A_Index]
							. lapTimeData[A_Index]
							. fuelConsumptionData[A_Index]
							. accidentData[A_Index]
							. penaltyData[A_Index]
				   . "</tr>")

		html .= "</table>"

		return html
	}

	showStintDetails(stint) {
		showStintDetailsAsync(stint) {
			local html := ("<div id=`"header`"><b>" . translate("Stint: ") . stint.Nr . "</b></div>")
			local laps := []
			local positions := []
			local lapTimes := []
			local fuelConsumptions := []
			local temperatures := []
			local lapTable := this.SessionStore.Tables["Lap.Data"]
			local ignore, lap, width, chart1, chart2, chart3

			html .= ("<br><br><div id=`"header`"><i>" . translate("Overview") . "</i></div>")

			html .= ("<br>" . this.createStintHeader(stint))

			html .= ("<br><br><div id=`"header`"><i>" . translate("Laps") . "</i></div>")

			html .= ("<br>" . this.createLapDetails(stint))

			html .= ("<br><br><div id=`"header`"><i>" . translate("Telemetry") . "</i></div>")

			for ignore, lap in stint.Laps {
				laps.Push(lap.Nr)
				positions.Push(lap.Position)
				lapTimes.Push(lap.Laptime)
				fuelConsumptions.Push(lap.FuelConsumption)
				temperatures.Push(lapTable[lap.Nr]["Tyre.Temperature.Average"])
			}

			width := (this.DetailsViewer.getWidth() - 20)

			chart1 := this.createLapDetailsChart(1, width, 248, laps, positions, lapTimes, fuelConsumptions, temperatures)

			html .= ("<br><br><div id=`"chart_1`" style=`"width: " . width . "px; height: 248px`"></div>")

			html .= ("<br><br><div id=`"header`"><i>" . translate("Statistics") . "</i></div>")

			chart2 := this.createStintPerformanceChart(2, width, 248, stint)

			html .= ("<br><div id=`"chart_2`" style=`"width: " . width . "px; height: 248px`"></div>")

			html .= ("<br><br><div id=`"header`"><i>" . translate("Consistency") . "</i></div>")

			chart3 := this.createStintConsistencyChart(3, width, 248, stint, laps, lapTimes)

			html .= ("<br><div id=`"chart_3`" style=`"width: " . width . "px; height: 248px`"></div>")

			this.showDetails("Stint", html, [1, chart1], [2, chart2], [3, chart3])
		}

		this.pushTask(ObjBindMethod(this, "syncSessionStore"))

		this.pushTask(showStintDetailsAsync.Bind(stint))
	}

	createLapOverview(lap) {
		local html := "<table>"
		local hotPressures := "-, -, -, -"
		local coldPressures := "-, -, -, -"
		local pressuresLosses := "-, -, -, -"
		local hasColdPressures := false
		local pressuresDB := this.PressuresDatabase
		local pressuresTable, pressures, coldPressures, hotPressures, pressuresLosses, tyresTable, tyres
		local stintNr, fuel, tyreCompound, tyreCompoundColor, tyreSet, tyrePressures, pressureCorrections, pressure
		local fuelConsumption, remainingFuel, remainingDriverTime, remainingStintTime

		if pressuresDB {
			pressuresTable := pressuresDB.Database.Tables["Tyres.Pressures"]

			if (pressuresTable.Length >= lap.Nr) {
				pressures := pressuresTable[lap.Nr]

				coldPressures := [displayNullValue(pressures["Tyre.Pressure.Cold.Front.Left"]), displayNullValue(pressures["Tyre.Pressure.Cold.Front.Right"])
								, displayNullValue(pressures["Tyre.Pressure.Cold.Rear.Left"]), displayNullValue(pressures["Tyre.Pressure.Cold.Rear.Right"])]

				this.getStintSetup(lap.Stint.Nr, true, &fuel, &tyreCompound, &tyreCompoundColor, &tyreSet, &tyrePressures)

				if tyrePressures {
					loop 4 {
						coldPressure := coldPressures[A_Index]

						if (coldPressure != "-") {
							tyrePressures[A_Index] := Round(coldPressure - tyrePressures[A_Index], 1)

							if (tyrePressures[A_Index] = 0)
								tyrePressures[A_Index] := displayNullValue(kNull)
							else if (tyrePressures[A_Index] > 0)
								tyrePressures[A_Index] := ("+ " . displayValue("Float", convertUnit("Pressure", tyrePressures[A_Index])))
							else if (tyrePressures[A_Index] < 0)
								tyrePressures[A_Index] := ("- " . displayValue("Float", convertUnit("Pressure", Abs(tyrePressures[A_Index]))))

							hasColdPressures := true
						}
						else
							tyrePressures[A_Index] := displayNullValue(kNull)
					}

					pressureCorrections := (translate(" (") . values2String(", ", tyrePressures*) . translate(")"))
				}
				else
					pressureCorrections := ""

				loop 4 {
					pressure := coldPressures[A_Index]

					if isNumber(pressure)
						coldPressures[A_Index] := displayValue("Float", convertUnit("Pressure", pressure))
				}

				coldPressures := values2String(", ", coldPressures*)

				hasColdPressures := (hasColdPressures || (coldPressures != "-, -, -, -"))

				coldPressures := (coldPressures . pressureCorrections)

				hotPressures := [displayNullValue(pressures["Tyre.Pressure.Hot.Front.Left"]), displayNullValue(pressures["Tyre.Pressure.Hot.Front.Right"])
							   , displayNullValue(pressures["Tyre.Pressure.Hot.Rear.Left"]), displayNullValue(pressures["Tyre.Pressure.Hot.Rear.Right"])]

				loop 4 {
					pressure := hotPressures[A_Index]

					if isNumber(pressure)
						hotPressures[A_Index] := displayValue("Float", convertUnit("Pressure", pressure))
				}

				hotPressures := values2String(", ", hotPressures*)

				pressuresLosses := [displayNullValue(pressures["Tyre.Pressure.Loss.Front.Left"]), displayNullValue(pressures["Tyre.Pressure.Loss.Front.Right"])
								  , displayNullValue(pressures["Tyre.Pressure.Loss.Rear.Left"]), displayNullValue(pressures["Tyre.Pressure.Loss.Rear.Right"])]

				loop 4 {
					pressure := pressuresLosses[A_Index]

					if isNumber(pressure)
						pressuresLosses[A_Index] := displayValue("Float", convertUnit("Pressure", pressure))
				}

				pressuresLosses := values2String(", ", pressuresLosses*)

				if (hotPressures = "-, -, -, -") {
					tyresTable := this.TelemetryDatabase.Database.Tables["Tyres"]

					if (tyresTable.Length >= lap.Nr) {
						tyres := tyresTable[lap.Nr]

						hotPressures := [displayNullValue(tyres["Tyre.Pressure.Front.Left"]), displayNullValue(tyres["Tyre.Pressure.Front.Right"])
									   , displayNullValue(tyres["Tyre.Pressure.Rear.Left"]), displayNullValue(tyres["Tyre.Pressure.Rear.Right"])]

						loop 4 {
							pressure := hotPressures[A_Index]

							if isNumber(pressure)
								hotPressures[A_Index] := displayValue("Float", convertUnit("Pressure", pressure))
						}

						hotPressures := values2String(", ", hotPressures*)
					}
				}
			}
		}

		remainingFuel := lap.FuelRemaining

		if isNumber(remainingFuel)
			remainingFuel := displayValue("Float", convertUnit("Volume", remainingFuel))

		fuelConsumption := lap.FuelConsumption

		if isNumber(fuelConsumption)
			fuelConsumption := displayValue("Float", convertUnit("Volume", fuelConsumption))

		html .= ("<tr><td><b>" . translate("Position:") . "</b></td><td>" . lap.Position . "</td></tr>")
		html .= ("<tr><td><b>" . translate("Lap Time:") . "</b></td><td>" . lapTimeDisplayValue(lap.LapTime) . "</td></tr>")
		html .= ("<tr><td><b>" . translate("Consumption:") . "</b></td><td>" . displayNullValue(fuelConsumption) . "</td></tr>")
		html .= ("<tr><td><b>" . translate("Fuel Level:") . "</b></td><td>" . remainingFuel . "</td></tr>")
		html .= ("<tr><td><b>" . translate("Temperatures (A / T):") . "</b></td><td>" . displayValue("Float", convertUnit("Temperature", lap.AirTemperature)) . ", " . displayValue("Float", convertUnit("Temperature", lap.TrackTemperature)) . "</td></tr>")

		if (hotPressures != "-, -, -, -")
			html .= ("<tr><td><b>" . translate("Pressures (hot):") . "</b></td><td>" . hotPressures . "</td></tr>")

		if hasColdPressures
			html .= ("<tr><td><b>" . translate("Pressures (cold, recommended):") . "</b></td><td>" . coldPressures . "</td></tr>")

		if (pressuresLosses != "-, -, -, -")
			html .= ("<tr><td><b>" . translate("Pressures (loss):") . "</b></td><td>" . pressuresLosses . "</td></tr>")

		html .= ("<tr><td></td><td></td></tr>")

		remainingStintTime := lap.RemainingStintTime
		remainingDriverTime := lap.RemainingDriverTime

		if (remainingStintTime != "-")
			remainingStintTime := (Round(remainingStintTime / 60) . A_Space . translate("Minutes"))

		if (remainingDriverTime != "-")
			remainingDriverTime := (Round(remainingDriverTime / 60) . A_Space . translate("Minutes"))

		html .= ("<tr><td><b>" . translate("Remaining Stint Time:") . "</b></td><td>" . remainingStintTime . "</td></tr>")
		html .= ("<tr><td><b>" . translate("Remaining Driver Time:") . "</b></td><td>" . remainingDriverTime . "</td></tr>")

		html .= "</table>"

		return html
	}

	createLapDeltas(lap, leaderColor := false, aheadColor := false, behindColor := false) {
		local sessionStore := this.SessionStore
		local html := "<table class=`"table-std`">"
		local labels := [translate("Leader"), translate("Standings (Ahead)"), translate("Standings (Behind)")
					   , translate("Track (Ahead)"), translate("Track (Behind)")]
		local rowIndices := CaseInsenseMap("Standings.Leader", 1, "Standings.Front", 2, "Standings.Ahead", 2, "Standings.Behind", 3
										 , "Track.Front", 4, "Track.Ahead", 4, "Track.Behind", 5)
		local telemetryDB := this.TelemetryDatabase
		local rows := [1, 2, 3, 4, 5]
		local deltas, ignore, entry, carNumber, carName, driverFullName, delta, row
		local driverForname, driverSurname, driverNickname, entryType, index, label
		local car, carID

		html .= ("<tr><th class=`"th-std`">" . "" . "</th>"
				   . "<th class=`"th-std`">" . translate("Nr.") . "</th>"
				   . "<th class=`"th-std`">" . translate("Driver") . "</th>"
				   . "<th class=`"th-std`">" . translate("Car") . "</th>"
				   . "<th class=`"th-std`">" . translate("Delta") . "</th>"
			   . "</tr>")

		deltas := sessionStore.query("Delta.Data", {Where: {Lap: lap.Nr}})

		if (deltas.Length > 0) {
			for ignore, entry in deltas {
				carNumber := "-"
				carName := "-"
				driverFullname := "-"
				delta := "-"

				if ((entry["Car"] && (entry["Car"] != kNull)) || (entry["ID"] && (entry["ID"] != kNull))) {
					driverForname := false
					driverSurname := false
					driverNickname := false

					car := entry["Car"]

					if this.getCar(lap, (entry["ID"] != kNull) ? entry["ID"] : false, &car, &carNumber, &carName, &driverForname, &driverSurname, &driverNickname) {
						driverFullname := computeDriverName(driverForname, driverSurname, driverNickname)

						delta := entry["Delta"]
					}
				}

				entryType := entry["Type"]

				index := rowIndices[entryType]

				if (leaderColor && (entryType = "Standings.Leader"))
					label := ("<p style=`"color:#" . leaderColor . "`";>" . labels[index] . "</p>")
				else if (aheadColor && ((entryType = "Standings.Front") || (entryType = "Standings.Ahead")))
					label := ("<p style=`"color:#" . aheadColor . "`";>" . labels[index] . "</p>")
				else if (behindColor && (entryType = "Standings.Behind"))
					label := ("<p style=`"color:#" . behindColor . "`";>" . labels[index] . "</p>")
				else
					label := labels[index]

				rows[index] := ("<tr><th class=`"th-std th-left`">" . label . "</th>"
							  . "<td class=`"td-std`">" . values2String("</td><td class=`"td-std`">" , carNumber, driverFullname, telemetryDB.getCarName(this.Simulator, carName), delta)
							  . "</td></tr>")
			}

			for ignore, row in rows
				html .= row
		}

		html .= "</table>"

		return html
	}

	createLapStandings(lap) {
		local sessionStore := this.SessionStore
		local telemetryDB := this.TelemetryDatabase
		local html := "<table class=`"table-std`">"
		local lapNr := lap.Nr
		local cars := true
		local carIDs := true
		local overallPositions := true
		local classPositions := true
		local carNumbers := true
		local carNames := true
		local driverFornames := true
		local driverSurnames := true
		local driverNicknames := true
		local driverCategories := (this.ReportViewer.Settings.Has("DriverCategories") && this.ReportViewer.Settings["DriverCategories"])
		local index, position, lapTime, laps, delta, result, multiClass, numPitstops, ignore, pitstop, pitstops, pitstopLaps

		multiClass := this.getStandings(lap, &cars, &carIDs, &overallPositions, &classPositions, &carNumbers, &carNames
										   , &driverFornames, &driverSurnames, &driverNicknames, &driverCategories)

		html .= ("<tr><th class=`"th-std`">" . translate("#") . "</th>"
				   . "<th class=`"th-std`">" . translate("Nr.") . "</th>"
				   . "<th class=`"th-std`">" . translate("Driver") . "</th>"
				   . "<th class=`"th-std`">" . translate("Car") . "</th>")

		if multiClass
			html .= ("<th class=`"th-std`">" . translate("Position") . "</th>")

		html .= ("<th class=`"th-std`">" . translate("Lap Time") . "</th>"
			   . "<th class=`"th-std`">" . translate("Laps") . "</th>"
			   . "<th class=`"th-std`">" . translate("Delta") . "</th>"
			   . "<th class=`"th-std`">" . translate("Pitstops") . "</th>"
			   . "</tr>")

		for index, position in overallPositions
			if (position && carIDs.Has(index)) {
				lapTime := "-"
				laps := "-"
				delta := "-"

				result := sessionStore.query("Standings.Data", {Select: ["Time", "Laps", "Delta"], Where: {Lap: lap.Nr, ID: carIDs[index]}})

				if (result.Length = 0)
					result := sessionStore.query("Standings.Data", {Select: ["Time", "Laps", "Delta"], Where: {Lap: lap.Nr, Car: cars[index]}})

				if (result.Length > 0) {
					lapTime := result[1]["Time"]
					laps := result[1]["Laps"]
					delta := Round(result[1]["Delta"], 1)
				}

				driver := computeDriverName(driverFornames[index] , driverSurnames[index], driverNickNames[index])

				if (driverCategories && (driverCategories[index] != "Unknown"))
					driver .= (translate(" [") . translate(driverCategories[index]) . translate("]"))

				html .= ("<tr><th class=`"th-std`">" . position . "</th>")
				html .= ("<td class=`"td-std`">" . values2String("</td><td class=`"td-std`">", carNumbers[index], driver
																							 , telemetryDB.getCarName(this.Simulator, carNames[index]))
					   . "</td>")

				if multiClass
					html .= ("<td class=`"td-std`">" . classPositions[index] . "</td>")

				html .= ("<td class=`"td-std`">" . values2String("</td><td class=`"td-std`">", lapTimeDisplayValue(lapTime), laps, delta) . "</td>")

				pitstops := this.Pitstops[carIDs[index]]
				numPitstops := 0

				if (pitstops.Length > 0) {
					pitstopLaps := []

					for ignore, pitstop in pitstops
						if (pitstop.Lap <= lapNr) {
							numPitstops += 1

							pitstopLaps.Push(pitstop.Lap)

							if (pitstopLaps.Length > 3)
								pitstopLaps.RemoveAt(1)
						}

					if (numPitstops > 0) {
						pitstops := (numPitstops . translate(":   ["))

						if (numPitstops > 3)
							pitstops .= (translate("...") . translate(", "))

						pitstops .= (values2String(", ", pitstopLaps*) . translate("]"))
					}
					else
						pitstops := "-"
				}
				else
					pitstops := "-"

				html .= ("<td class=`"td-std td-left`">" . pitstops . "</td></tr>")
			}

		html .= "</table>"

		return html
	}

	showLapDetails(lap) {
		showLapDetailsAsync(lap) {
			local html := ("<div id=`"header`"><b>" . translate("Lap: ") . lap.Nr . "</b></div>")

			this.initializeReports()

			html .= ("<br><br><div id=`"header`"><i>" . translate("Overview") . "</i></div>")

			html .= ("<br>" . this.createLapOverview(lap))

			html .= ("<br><br><div id=`"header`"><i>" . translate("Deltas") . "</i></div>")

			html .= ("<br>" . this.createLapDeltas(lap))

			html .= ("<br><br><div id=`"header`"><i>" . translate("Standings") . "</i></div>")

			html .= ("<br>" . this.createLapStandings(lap))

			this.showDetails("Lap", html)
		}

		this.pushTask(ObjBindMethod(this, "syncSessionStore"))

		this.pushTask(showLapDetailsAsync.Bind(lap))
	}

	createPitstopPlanDetails(pitstopNr) {
		local html := "<table>"
		local pitstopData := this.SessionStore.Tables["Pitstop.Data"][pitstopNr]
		local pressures := [pitstopData["Tyre.Pressure.Cold.Front.Left"], pitstopData["Tyre.Pressure.Cold.Front.Right"]
						  , pitstopData["Tyre.Pressure.Cold.Rear.Left"], pitstopData["Tyre.Pressure.Cold.Rear.Right"]]
		local repairBodywork := pitstopData["Repair.Bodywork"]
		local repairSuspension := pitstopData["Repair.Suspension"]
		local repairEngine := pitstopData["Repair.Engine"]
		local repairs := this.computeRepairs(repairBodyWork, repairSuspension, repairEngine)
		local tyreCompound, tyreSet, pressure

		loop 4 {
			pressure := pressures[A_Index]

			if isNumber(pressure)
				pressures[A_Index] := displayValue("Float", convertUnit("Pressure", pressure))
		}

		pressures := values2String(", ", pressures*)

		html .= ("<tr><td><b>" . translate("Lap:") . "</b></div></td><td>" . ((pitstopData["Lap"] = "-") ? "-" : (pitstopData["Lap"] + 1)) . "</td></tr>")

		if (pitstopData["Driver.Current"] != kNull)
			html .= ("<tr><td><b>" . translate("Last Driver:") . "</b></div></td><td>" . pitstopData["Driver.Current"] . "</td></tr>")

		if (pitstopData["Driver.Next"] != kNull)
			html .= ("<tr><td><b>" . translate("Next Driver:") . "</b></div></td><td>" . pitstopData["Driver.Next"] . "</td></tr>")

		if ((pitstopData["Fuel"] != "-") && (pitstopData["Fuel"] > 0))
			html .= ("<tr><td><b>" . translate("Refuel:") . "</b></div></td><td>" . displayValue("Float", convertUnit("Volume", pitstopData["Fuel"])) . "</td></tr>")

		tyreCompound := translate(compound(pitstopData["Tyre.Compound"], pitstopData["Tyre.Compound.Color"]))

		if (tyreCompound != "-") {
			tyreSet := pitstopData["Tyre.Set"]

			html .= ("<tr><td><b>" . translate("Tyre Compound:") . "</b></div></td><td>" . tyreCompound . "</td></tr>")

			if ((tyreSet != false) && (tyreSet != "-"))
				html .= ("<tr><td><b>" . translate("Tyre Set:") . "</b></div></td><td>" . pitstopData["Tyre.Set"] . "</td></tr>")

			html .= ("<tr><td><b>" . translate("Tyre Pressures:") . "</b></div></td><td>" . pressures . "</td></tr>")
		}

		if (repairs != "-")
			html .= ("<tr><td><b>" . translate("Repairs:") . "</b></div></td><td>" . repairs . "</td></tr>")

		html .= "</table>"

		return html
	}

	createPitstopServiceDetails(pitstopNr) {
		local html := "<table>"
		local pitstopData := this.SessionStore.Tables["Pitstop.Data"][pitstopNr]
		local pressures := [pitstopData["Tyre.Pressure.Cold.Front.Left"], pitstopData["Tyre.Pressure.Cold.Front.Right"]
						  , pitstopData["Tyre.Pressure.Cold.Rear.Left"], pitstopData["Tyre.Pressure.Cold.Rear.Right"]]
		local repairBodywork := pitstopData["Repair.Bodywork"]
		local repairSuspension := pitstopData["Repair.Suspension"]
		local repairEngine := pitstopData["Repair.Engine"]
		local repairs := this.computeRepairs(repairBodyWork, repairSuspension, repairEngine)
		local serviceData := this.SessionStore.query("Pitstop.Service.Data", {Where: {Pitstop: pitstopNr}})
		local tyreCompound, tyreSet, name, key, pressure

		if (serviceData.Length > 0) {
			loop 4 {
				pressure := pressures[A_Index]

				if isNumber(pressure)
					pressures[A_Index] := displayValue("Float", convertUnit("Pressure", pressure))
			}

			pressures := values2String(", ", pressures*)

			serviceData := serviceData[1]

			if serviceData["Lap"]
				html .= ("<tr><td><b>" . translate("Lap:") . "</b></div></td><td>" . (serviceData["Lap"] + 1) . "</td></tr>")

			if serviceData["Time"]
				html .= ("<tr><td><b>" . translate("Service Time:") . "</b></div></td><td>" . displayValue("Float", serviceData["Time"], 1) . "</td></tr>")

			if serviceData["Driver.Previous"]
				html .= ("<tr><td><b>" . translate("Last Driver:") . "</b></div></td><td>" . serviceData["Driver.Previous"] . "</td></tr>")

			if serviceData["Driver.Next"]
				html .= ("<tr><td><b>" . translate("Next Driver:") . "</b></div></td><td>" . serviceData["Driver.Next"] . "</td></tr>")

			if (pitstopData["Fuel"] > 0)
				html .= ("<tr><td><b>" . translate("Refuel:") . "</b></div></td><td>" . displayValue("Float", convertUnit("Volume", pitstopData["Fuel"])) . "</td></tr>")

			tyreCompound := translate(compound(pitstopData["Tyre.Compound"], pitstopData["Tyre.Compound.Color"]))

			if (tyreCompound != "-") {
				tyreSet := pitstopData["Tyre.Set"]

				html .= ("<tr><td><b>" . translate("Tyre Compound:") . "</b></div></td><td>" . tyreCompound . "</td></tr>")

				if ((tyreSet != false) && (tyreSet != "-"))
					html .= ("<tr><td><b>" . translate("Tyre Set:") . "</b></div></td><td>" . serviceData["Tyre.Set"] . "</td></tr>")

				html .= ("<tr><td><b>" . translate("Tyre Pressures:") . "</b></div></td><td>" . pressures . "</td></tr>")
			}

			if (repairs != "-")
				html .= ("<tr><td><b>" . translate("Repairs:") . "</b></div></td><td>" . repairs . "</td></tr>")

			html .= "</table>"

			return html
		}
		else
			return ""
	}

	computeTyreWearColor(damage) {
		if (damage < 50)
			return "bgcolor=`"Green`" style=`"color:#FFFFFF`""
		else if (damage < 70)
			return "bgcolor=`"Yellow`" style=`"color:#000000`""
		else if (damage < 80)
			return "bgcolor=`"Orange`" style=`"color:#000000`""
		else if (damage < 90)
			return "bgcolor=`"Red`" style=`"color:#FFFFFF`""
		else
			return "bgcolor=`"DarkRed`" style=`"color:#FFFFFF`""
	}

	computeTyreDamageColor(damage) {
		if ((damage = "-") || (damage < 15))
			return "bgcolor=`"Green`" style=`"color:#FFFFFF`""
		else if (damage < 25)
			return "bgcolor=`"Yellow`" style=`"color:#000000`""
		else if (damage < 40)
			return "bgcolor=`"Orange`" style=`"color:#000000`""
		else if (damage < 80)
			return "bgcolor=`"Red`" style=`"color:#FFFFFF`""
		else
			return "bgcolor=`"DarkRed`" style=`"color:#FFFFFF`""
	}

	createTyreWearDetails(pitstopNr) {
		local html := "<table>"
		local driver := false
		local laps := false
		local tyreCompound := false
		local tyreSet := false
		local tyreNames := []
		local treadData := []
		local wearData := []
		local grainData := []
		local blisterData := []
		local flatSpotData := []
		local hasTread := false
		local hasWear := false
		local hasGrain := false
		local hasBlister := false
		local hasFlatSpot := false
		local tyres := CaseInsenseWeakMap()
		local ignore, tyreData, tyre, key, wear, tread, grain, blister, flatSpot

		for ignore, tyreData in this.SessionStore.query("Pitstop.Tyre.Data", {Where: {Pitstop: pitstopNr}})
			tyres[tyreData["Tyre"]] := tyreData

		for tyre, key in Map("FL", "Front.Left", "FR", "Front.Right", "RL", "Rear.Left", "RR", "Rear.Right") {
			if !driver
				driver := tyres[key]["Driver"]

			if !laps
				laps := tyres[key]["Laps"]

			if !tyreCompound
				tyreCompound := translate(compound(tyres[key]["Compound"], tyres[key]["Compound.Color"]))

			if !tyreSet
				tyreSet := tyres[key]["Set"]

			tyreNames.Push("<th class=`"th-std`">" . translate(tyre) . "</th>")

			wear := tyres[key]["Wear"]
			wearData.Push("<td class=`"td-std`" " . this.computeTyreWearColor(tyres[key]["Wear"]) . ">" . wear . "</td>")

			if (wear != "-")
				hasWear := true

			tread := tyres[key]["Tread"]
			if hasWear
				treadData.Push("<td class=`"td-std`" " . this.computeTyreWearColor(tyres[key]["Wear"]) . ">"
							 . values2String(", ", string2Values(",", tread)*) . "</td>")
			else
				treadData.Push("<td class=`"td-std`">" . values2String(", ", string2Values(",", tread)*) . "</td>")

			if (tread != "-")
				hasTread := true

			grain := tyres[key]["Grain"]
			grainData.Push("<td class=`"td-std`" " . this.computeTyreDamageColor(grain) . ">" . grain . "</td>")

			if (grain != "-")
				hasGrain := true

			blister := tyres[key]["Blister"]
			blisterData.Push("<td class=`"td-std`" " . this.computeTyreDamageColor(blister) . ">" . blister . "</td>")

			if (blister != "-")
				hasBlister := true

			flatSpot := tyres[key]["FlatSpot"]
			flatSpotData.Push("<td class=`"td-std`" " . this.computeTyreDamageColor(flatSpot) . ">" . flatSpot . "</td>")

			if (flatSpot != "-")
				hasFlatSpot := true
		}

		if driver
			html .= ("<tr><td><b>" . translate("Driver:") . "</b></div></td><td>" . driver . "</td></tr>")

		if laps
			html .= ("<tr><td><b>" . translate("Laps:") . "</b></div></td><td>" . laps . "</td></tr>")

		if tyreCompound
			html .= ("<tr><td><b>" . translate("Tyre Compound:") . "</b></div></td><td>" . tyreCompound . "</td></tr>")

		if tyreSet
			html .= ("<tr><td><b>" . translate("Tyre Set:") . "</b></div></td><td>" . tyreSet . "</td></tr>")

		html .= "</table><br><br>"

		html .= "<table class=`"table-std`">"
		html .= ("<tr><th class=`"th-std th-left`">" . translate("Tyre") . "</th>" . values2String("", tyreNames*) . "</tr>")

		if hasTread
			html .= ("<tr><th class=`"th-std th-left`">" . translate("Tread (mm)") . "</th>" . values2String("", treadData*) . "</tr>")
		else if hasWear
			html .= ("<tr><th class=`"th-std th-left`">" . translate("Wear (%)") . "</th>" . values2String("", wearData*) . "</tr>")

		if hasGrain
			html .= ("<tr><th class=`"th-std th-left`">" . translate("Grain (%)") . "</th>" . values2String("", grainData*) . "</tr>")

		if hasBlister
			html .= ("<tr><th class=`"th-std th-left`">" . translate("Blister (%)") . "</th>" . values2String("", blisterData*) . "</tr>")

		if hasFlatSpot
			html .= ("<tr><th class=`"th-std th-left`">" . translate("Flat Spot (%)") . "</th>" . values2String("", flatSpotData*) . "</tr>")

		html .= "</table>"

		return html
	}

	showPitstopDetails(pitstopNr) {
		showPitstopDetailsAsync(pitstopNr) {
			local pitstopData := this.SessionStore.Tables["Pitstop.Data"][pitstopNr]
			local html

			if (pitstopData["Lap"] != "-") {
				html := ("<div id=`"header`"><b>" . translate("Pitstop: ") . pitstopNr . "</b></div>")
				html .= ("<br><br><div id=`"header`"><i>" . translate("Service") . "</i></div>")

				if (this.SessionStore.query("Pitstop.Service.Data", {Where: {Pitstop: pitstopNr}}).Length = 0)
					html .= ("<br>" . this.createPitstopPlanDetails(pitstopNr))
				else
					html .= ("<br>" . this.createPitstopServiceDetails(pitstopNr))

				if (this.SessionStore.query("Pitstop.Tyre.Data", {Where: {Pitstop: pitstopNr}}).Length > 0) {
					html .= ("<br><br><div id=`"header`"><i>" . translate("Tyre Wear") . "</i></div>")

					html .= ("<br>" . this.createTyreWearDetails(pitstopNr))
				}

				this.showDetails("Pitstop", html)
			}
			else
				loop this.PitstopsListView.GetCount()
					this.PitstopsListView.Modify(A_Index, "-Select")
		}

		this.pushTask(ObjBindMethod(this, "syncSessionStore"))

		this.pushTask(showPitstopDetailsAsync.Bind(pitstopNr))
	}

	createPitstopsServiceDetails() {
		local html := "<table class=`"table-std`">"
		local headers := []
		local pitstopNRs := []
		local lapData := []
		local timeData := []
		local previousDriverData := []
		local nextDriverData := []
		local refuelData := []
		local tyreCompoundData := []
		local tyreSetData := []
		local tyrePressuresData := []
		local repairsData := []
		local tyreCompound, tyreSet, index, pitstopData, serviceData, pressures, repairBodywork, repairSuspension, repairs
		local name, key, tyrePressures, header, repairEngine

		for index, pitstopData in this.SessionStore.Tables["Pitstop.Data"] {
			pitstopNRs.Push("<th class=`"th-std`">" . index . "</th>")

			serviceData := this.SessionStore.query("Pitstop.Service.Data", {Where: {Pitstop: index}})

			if (serviceData.Length = 0) {
				timeData.Push("<td class=`"td-std`">" . "-" . "</td>")
				previousDriverData.Push("<td class=`"td-std`">" . displayNullValue(pitstopData["Driver.Current"]) . "</td>")
				nextDriverData.Push("<td class=`"td-std`">" . displayNullValue(pitstopData["Driver.Next"]) . "</td>")

				pressures := [pitstopData["Tyre.Pressure.Cold.Front.Left"], pitstopData["Tyre.Pressure.Cold.Front.Right"]
							, pitstopData["Tyre.Pressure.Cold.Rear.Left"], pitstopData["Tyre.Pressure.Cold.Rear.Right"]]

				loop 4 {
					pressure := pressures[A_Index]

					if isNumber(pressure)
						pressures[A_Index] := displayValue("Float", convertUnit("Pressure", pressure))
				}

				pressures := values2String(", ", pressures*)

				repairBodywork := pitstopData["Repair.Bodywork"]
				repairSuspension := pitstopData["Repair.Suspension"]
				repairEngine := pitstopData["Repair.Engine"]

				repairs := this.computeRepairs(repairBodywork, repairSuspension, repairEngine)

				repairsData.Push("<td class=`"td-std`">" . repairs . "</td>")

				lapData.Push("<td class=`"td-std`">" . (!isNumber(pitstopData["Lap"]) ? "-" : (pitstopData["Lap"] + 1)) . "</td>")
				refuelData.Push("<td class=`"td-std`">" . (isNumber(pitstopData["Fuel"]) ? ((pitstopData["Fuel"] != 0) ? displayValue("Float", convertUnit("Volume", pitstopData["Fuel"])) : "-") : "-") . "</td>")

				tyreCompound := translate(compound(pitstopData["Tyre.Compound"], pitstopData["Tyre.Compound.Color"]))

				tyreCompoundData.Push("<td class=`"td-std`">" . tyreCompound . "</td>")

				tyreSet := pitstopData["Tyre.Set"]

				if (tyreCompound = "-") {
					tyreSet := "-"
					pressures := "-, -, -, -"
				}

				tyreSetData.Push("<td class=`"td-std`">" . tyreSet . "</td>")
				tyrePressuresData.Push("<td class=`"td-std`">" . pressures . "</td>")
			}
			else {
				serviceData := serviceData[1]

				repairs := this.computeRepairs(serviceData["Bodywork.Repair"]
											 , serviceData["Suspension.Repair"]
											 , serviceData["Engine.Repair"])

				repairsData.Push("<td class=`"td-std`">" . repairs . "</td>")

				lapData.Push("<td class=`"td-std`">" . (serviceData["Lap"] ? serviceData["Lap"] : "-") . "</td>")
				timeData.Push("<td class=`"td-std`">" . (serviceData["Time"] ? displayValue("Float", serviceData["Time"], 1) : "-") . "</td>")
				previousDriverData.Push("<td class=`"td-std`">" . (serviceData["Driver.Previous"] ? serviceData["Driver.Previous"] : "-") . "</td>")
				nextDriverData.Push("<td class=`"td-std`">" . (serviceData["Driver.Next"] ? serviceData["Driver.Next"] : "-") . "</td>")
				refuelData.Push("<td class=`"td-std`">" . (serviceData["Fuel"] ? ((isInteger(pitstopData["Fuel"]) && (pitstopData["Fuel"] != 0)) ? displayValue("Float", convertUnit("Volume", pitstopData["Fuel"])) : "-") : "-") . "</td>")

				tyreCompound := translate(compound(serviceData["Tyre.Compound"], serviceData["Tyre.Compound.Color"]))

				tyreCompoundData.Push("<td class=`"td-std`">" . tyreCompound . "</td>")

				tyreSet := serviceData["Tyre.Set"]
				tyrePressures := serviceData["Tyre.Pressures"]

				if (tyreCompound = "-") {
					tyreSet := "-"
					tyrePressures := "-, -, -, -"
				}
				else {
					tyrePressures := string2Values(",", tyrePressures)

					loop 4 {
						pressure := tyrePressures[A_Index]

						if isNumber(pressure)
							tyrePressures[A_Index] := displayValue("Float", convertUnit("Pressure", pressure))
					}

					tyrePressures := values2String(", ", tyrePressures*)
				}

				tyreSetData.Push("<td class=`"td-std`">" . tyreSet . "</td>")
				tyrePressuresData.Push("<td class=`"td-std`">" . tyrePressures . "</td>")
			}
		}

		for ignore, header in ["Pitstop", "Lap", "Service Time", "Last Driver", "Next Driver", "Refuel", "Tyre Compound", "Tyre Set", "Tyre Pressures", "Repairs"]
			headers.Push("<th class=`"th-std`">" . translate(header) . "</th>")

		html .= ("<tr>" . values2String("", headers*) . "</tr>")

		loop pitstopNRs.Length
			html .= ("<tr>" . pitstopNRs[A_Index] . lapData[A_Index] . timeData[A_Index]
							. previousDriverData[A_Index] . nextDriverData[A_Index] . refuelData[A_Index]
							. tyreCompoundData[A_Index] . tyreSetData[A_Index] . tyrePressuresData[A_Index]
							. repairsData[A_Index]
				   . "</tr>")

		html .= "</table>"

		return html
	}

	showPitstopsDetails() {
		showPitstopsDetailsAsync() {
			local html := ("<div id=`"header`"><b>" . translate("Pitstops Summary") . "</b></div>")

			html .= ("<br><br><div id=`"header`"><i>" . translate("Service") . "</i></div>")

			html .= ("<br>" . this.createPitstopsServiceDetails())

			if (this.SessionStore.Tables["Pitstop.Tyre.Data"].Length > 0)
				loop this.SessionStore.Tables["Pitstop.Data"].Length
					if (this.SessionStore.query("Pitstop.Tyre.Data", {Where: {Pitstop: A_Index}}).Length > 0) {
						html .= ("<br><br><div id=`"header`"><i>" . translate("Tyre Wear (Pitstop: ") . A_Index . translate(")") . "</i></div>")

						html .= ("<br>" . this.createTyreWearDetails(A_Index))
					}

			this.showDetails("Pitstops", html)
		}

		this.pushTask(ObjBindMethod(this, "syncSessionStore"))

		this.pushTask(showPitstopsDetailsAsync)
	}

	createDriverDetails(drivers) {
		local driverData := []
		local stintsData := []
		local lapsData := []
		local drivingTimesData := []
		local avgLapTimesData := []
		local avgFuelConsumptionsData := []
		local accidentsData := []
		local penaltiesData := []
		local ignore, driver, lapAccidents, lapPenalties, lapTimes, fuelConsumptions, ignore, lap, html

		for ignore, driver in drivers {
			driverData.Push("<th class=`"th-std`">" . StrReplace(driver.FullName, "'", "\'") . "</th>")
			stintsData.Push("<td class=`"td-std`">" . driver.Stints.Length . "</td>")
			lapsData.Push("<td class=`"td-std`">" . driver.Laps.Length . "</td>")

			lapAccidents := 0
			lapPenalties := 0
			lapTimes := []
			fuelConsumptions := []

			for ignore, lap in driver.Laps {
				lapTimes.Push(lap.Laptime)
				fuelConsumptions.Push(lap.FuelConsumption)

				if lap.Accident
					lapAccidents += 1

				if lap.Penalty
					lapPenalties += 1
			}

			drivingTimesData.Push("<td class=`"td-std`">" . Round(this.computeDriverTime(driver) / 60) . "</td>")
			avgLapTimesData.Push("<td class=`"td-std`">" . lapTimeDisplayValue(Round(average(lapTimes), 1)) . "</td>")
			avgFuelConsumptionsData.Push("<td class=`"td-std`">" . displayValue("Float", convertUnit("Volume", average(fuelConsumptions))) . "</td>")
			accidentsData.Push("<td class=`"td-std`">" . lapAccidents . "</td>")
			penaltiesData.Push("<td class=`"td-std`">" . lapPenalties . "</td>")
		}

		html := "<table class=`"table-std`">"
		html .= ("<tr><th class=`"th-std th-left`">" . translate("Driver") . "</th>" . values2String("", driverData*) . "</tr>")
		html .= ("<tr><th class=`"th-std th-left`">" . translate("Stints") . "</th>" . values2String("", stintsData*) . "</tr>")
		html .= ("<tr><th class=`"th-std th-left`">" . translate("Laps") . "</th>" . values2String("", lapsData*) . "</tr>")
		html .= ("<tr><th class=`"th-std th-left`">" . translate("Driving Time") . "</th>" . values2String("", drivingTimesData*) . "</tr>")
		html .= ("<tr><th class=`"th-std th-left`">" . translate("Avg. Lap Time") . "</th>" . values2String("", avgLapTimesData*) . "</tr>")
		html .= ("<tr><th class=`"th-std th-left`">" . translate("Avg. Consumption") . "</th>" . values2String("", avgFuelConsumptionsData*) . "</tr>")
		html .= ("<tr><th class=`"th-std th-left`">" . translate("Accidents") . "</th>" . values2String("", accidentsData*) . "</tr>")
		html .= ("<tr><th class=`"th-std th-left`">" . translate("Penalties") . "</th>" . values2String("", penaltiesData*) . "</tr>")
		html .= "</table>"

		return html
	}

	createDriverPaceChart(chartID, width, height, drivers) {
		local drawChartFunction := "function drawChart" . chartID . "() {`nvar array = [`n"
		local length := 2000000
		local lapTimes := []
		local validDriverTimes := []
		local ignore, driver, lap, value, driverTimes, avg, stdDev, index, time, validTimes, text

		for ignore, driver in drivers
			length := Min(length, driver.Laps.Length)

		if (length = 2000000)
			return ""

		for ignore, driver in drivers {
			driverTimes := []

			for ignore, lap in driver.Laps {
				if (A_Index > length)
					break

				value := chartValue(null(lap.Laptime))

				if !isNull(value)
					driverTimes.Push(value)
			}

			loop 2 {
				avg := average(driverTimes)
				stdDev := stdDeviation(driverTimes)

				for index, time in driverTimes
					if ((time <= 0) || ((time > avg) && (Abs(time - avg) > (stdDev / 2))))
						driverTimes[index] := false

				validTimes := []

				for ignore, time in driverTimes
					if time
						validTimes.Push(time)

				driverTimes := validTimes
			}

			length := Min(length, driverTimes.Length)

			validDriverTimes.Push(driverTimes)
		}

		for index, driver in drivers {
			validTimes := validDriverTimes[index]
			driverTimes := []

			loop length
				driverTimes.Push(validTimes[A_Index])

			driverTimes.InsertAt(1, "'" . driver.FullName . "'")

			lapTimes.Push("[" . values2String(", ", driverTimes*) . "]")
		}

		drawChartFunction .= (values2String("`n, ", lapTimes*) . "];")

		drawChartFunction .= "`nvar data = new google.visualization.DataTable();"
		drawChartFunction .= "`ndata.addColumn('string', '" . translate("Driver") . "');"

		loop length
			drawChartFunction .= "`ndata.addColumn('number', '" . translate("Lap") . A_Space . A_Index . "');"

		text := "
		(
		data.addColumn({id:'max', type:'number', role:'interval'});
		data.addColumn({id:'min', type:'number', role:'interval'});
		data.addColumn({id:'firstQuartile', type:'number', role:'interval'});
		data.addColumn({id:'median', type:'number', role:'interval'});
		data.addColumn({id:'mean', type:'number', role:'interval'});
		data.addColumn({id:'thirdQuartile', type:'number', role:'interval'});
		)"

		drawChartFunction .= ("`n" . text)

		drawChartFunction .= ("`n" . "data.addRows(getBoxPlotValues(array, " . (length + 1) . "));")

		drawChartFunction .= ("`n" . getBoxAndWhiskerJSFunctions())

		text := "
		(
		var options = {
			backgroundColor: '//backColor//', chartArea: { left: '10`%', top: '5`%', right: '5`%', bottom: '20`%' },
			legend: { position: 'none' },
		)"

		drawChartFunction .= StrReplace(text, "//backColor//", this.Window.AltBackColor)

		text := "
		(
			hAxis: { title: '%drivers%', gridlines: {count: 0} },
			vAxis: { title: '%seconds%', gridlines: {count: 0} },
			lineWidth: 0,
			series: [ { 'color': '%backColor%' } ],
			intervals: { barWidth: 1, boxWidth: 1, lineWidth: 2, style: 'boxes' },
			interval: { max: { style: 'bars', fillOpacity: 1, color: '#777' },
						min: { style: 'bars', fillOpacity: 1, color: '#777' },
						mean: { style: 'points', color: 'grey', pointsize: 5 } }
		};
		)"

		drawChartFunction .= ("`n" . substituteVariables(text, {drivers: translate("Drivers"), seconds: translate("Seconds")
															  , backColor: this.Window.AltBackColor}))

		drawChartFunction .= ("`nvar chart = new google.visualization.LineChart(document.getElementById('chart_" . chartID . "')); chart.draw(data, options); }")

		return drawChartFunction
	}

	createDriverPerformanceChart(chartID, width, height, drivers) {
		local drawChartFunction := "function drawChart" . chartID . "() {"
		local driverNames := []
		local potentialsData := []
		local raceCraftsData := []
		local speedsData := []
		local consistenciesData := []
		local carControlsData := []
		local ignore, driver, minValue, maxValue

		for ignore, driver in drivers {
			driverNames.Push(StrReplace(driver.FullName, "'", "\'"))
			potentialsData.Push(driver.Potential)
			raceCraftsData.Push(driver.RaceCraft)
			speedsData.Push(driver.Speed)
			consistenciesData.Push(driver.Consistency)
			carControlsData.Push(driver.CarControl)
		}

		drawChartFunction .= "`nvar data = google.visualization.arrayToDataTable(["
		drawChartFunction .= "`n['" . values2String("', '", translate("Category"), driverNames*) . "'],"
		drawChartFunction .= "`n[" . values2String(", ", "'" . translate("Potential") . "'", potentialsData*) . "],"
		drawChartFunction .= "`n[" . values2String(", ", "'" . translate("Race Craft") . "'", raceCraftsData*) . "],"
		drawChartFunction .= "`n[" . values2String(", ", "'" . translate("Speed") . "'", speedsData*) . "],"
		drawChartFunction .= "`n[" . values2String(", ", "'" . translate("Consistency") . "'", consistenciesData*) . "],"
		drawChartFunction .= "`n[" . values2String(", ", "'" . translate("Car Control") . "'", carControlsData*) . "]"

		drawChartFunction .= ("`n]);")

		minValue := Min(0, minimum(potentialsData), minimum(raceCraftsData), minimum(speedsData), minimum(consistenciesData), minimum(carControlsData))
		maxValue := Max(maximum(potentialsData), maximum(raceCraftsData), maximum(speedsData), maximum(consistenciesData), maximum(carControlsData))

		drawChartFunction .= "`nvar options = { bars: 'horizontal', backgroundColor: '" . this.Window.AltBackColor . "', chartArea: { left: '15%', top: '5%', right: '30%', bottom: '10%' }, hAxis: {viewWindowMode: 'explicit', viewWindow: {min: " . minValue . ", max: " . maxValue . "}, gridlines: {count: 0} }, vAxis: {gridlines: {count: 0}} };"
		drawChartFunction .= ("`nvar chart = new google.visualization.BarChart(document.getElementById('chart_" . chartID . "')); chart.draw(data, options); }")

		return drawChartFunction
	}

	showDriverStatistics() {
		local html := ("<div id=`"header`"><b>" . translate("Driver Statistics") . "</b></div>")
		local ignore, driver, width, chart1, chart2

		for ignore, driver in this.Drivers
			this.updateDriverStatistics(driver)

		html .= ("<br><br><div id=`"header`"><i>" . translate("Overview") . "</i></div>")

		html .= ("<br>" . this.createDriverDetails(this.Drivers))

		width := (this.DetailsViewer.getWidth() - 20)

		html .= ("<br><br><div id=`"header`"><i>" . translate("Pace") . "</i></div>")

		chart1 := this.createDriverPaceChart(1, width, 248, this.Drivers)

		html .= ("<br><br><div id=`"chart_1`" style=`"width: " . width . "px; height: 248px`"></div>")

		html .= ("<br><br><div id=`"header`"><i>" . translate("Performance") . "</i></div>")

		chart2 := this.createDriverPerformanceChart(2, width, 248, this.Drivers)

		html .= ("<br><br><div id=`"chart_2`" style=`"width: " . width . "px; height: 248px`"></div>")

		this.showDetails("Drivers", html, [1, chart1], [2, chart2])
	}

	createSessionSummaryChart(chartID, width, height, lapSeries, positionSeries, fuelSeries, tyreSeries) {
		local drawChartFunction := ("function drawChart" . chartID . "() {")
		local ignore, time, fuel

		drawChartFunction .= "`nvar data = new google.visualization.DataTable();"
		drawChartFunction .= ("`ndata.addColumn('number', '" . translate("Lap") . "');")
		drawChartFunction .= ("`ndata.addColumn('number', '" . translate("Position") . "');")
		drawChartFunction .= ("`ndata.addColumn('number', '" . translate("Fuel Level") . "');")
		drawChartFunction .= ("`ndata.addColumn('number', '" . translate("Tyre Laps") . "');")
		drawChartFunction .= "`ndata.addRows(["

		for ignore, time in lapSeries {
			if (A_Index > 1)
				drawChartFunction .= ", "

			fuel := fuelSeries[A_Index]

			if isNumber(fuel)
				fuel := convertUnit("Volume", fuel)

			drawChartFunction .= ("[" . values2String(", ", lapSeries[A_Index]
														  , chartValue(null(positionSeries[A_Index]))
														  , chartValue(null(fuel))
														  , chartValue(null(tyreSeries[A_Index])))
								. "]")
		}

		drawChartFunction .= ("]);`nvar options = { legend: { position: 'Right' }, chartArea: { left: '10%', top: '5%', right: '25%', bottom: '20%' }, hAxis: { title: '" . translate("Lap") . "', gridlines: {count: 0} }, vAxis: { viewWindow: { min: 0 }, gridlines: {count: 0} }, backgroundColor: '" . this.Window.AltBackColor . "' };`n")

		drawChartFunction .= ("`nvar chart = new google.visualization.LineChart(document.getElementById('chart_" . chartID . "')); chart.draw(data, options); }")

		return drawChartFunction
	}

	showSessionSummary() {
		local telemetryDB := this.TelemetryDatabase
		local html := ("<div id=`"header`"><b>" . translate("Race Summary") . "</b></div>")
		local stints := []
		local drivers := []
		local laps := []
		local durations := []
		local numLaps := []
		local positions := []
		local avgLapTimes := []
		local fuelConsumptions := []
		local accidents := []
		local penalties := []
		local currentStint := this.CurrentStint
		local positions := []
		local remainingFuels := []
		local tyreLaps := []
		local lastLap := this.LastLap
		local lapDataTable := this.SessionStore.Tables["Lap.Data"]
		local stint, duration, ignore, lap, width, chart1
		local simulator, carName, trackName, sessionDate, sessionTime, fuelConsumption

		simulator := this.Simulator
		carName := this.Car
		carName := (carName ? telemetryDB.getCarName(simulator, carName) : "-")
		trackName := this.Track
		trackName := (trackName ? telemetryDB.getTrackName(simulator, trackName) : "-")

		sessionDate := this.Date

		if sessionDate
			sessionDate := FormatTime(sessionDate, "ShortDate")
		else
			sessionDate := "-"

		sessionTime := this.Time

		if sessionTime
			sessionTime := FormatTime(sessionTime, "Time")
		else
			sessionTime := "-"

		html .= "<br><br><table>"
		html .= ("<tr><td><b>" . translate("Simulator:") . "</b></td><td>" . (simulator ? simulator : "-") . "</td></tr>")
		html .= ("<tr><td><b>" . translate("Car:") . "</b></td><td>" . carName . "</td></tr>")
		html .= ("<tr><td><b>" . translate("Track:") . "</b></td><td>" . trackName . "</td></tr>")
		html .= ("<tr><td><b>" . translate("Date:") . "</b></td><td>" . sessionDate . "</td></tr>")
		html .= ("<tr><td><b>" . translate("Time:") . "</b></td><td>" . sessionTime . "</td></tr>")
		html .= "</table>"

		html .= ("<br><br><div id=`"header`"><i>" . translate("Stints") . "</i></div>")

		if currentStint
			loop currentStint.Nr {
				stint := this.Stints[A_Index]

				stints.Push("<th class=`"th-std`">" . stint.Nr . "</th>")
				drivers.Push("<td class=`"td-std`">" . StrReplace(stint.Driver.Fullname, "'", "\'") . "</td>")
				laps.Push("<td class=`"td-std`">" . stint.Lap . "</td>")

				duration := 0

				for ignore, lap in stint.Laps
					duration += lap.Laptime

				durations.Push("<td class=`"td-std`">" . Round(duration / 60) . "</td>")
				numLaps.Push("<td class=`"td-std`">" . stint.Laps.Length . "</td>")
				positions.Push("<td class=`"td-std`">" . stint.StartPosition . translate(" -> ") . stint.EndPosition . "</td>")
				avgLapTimes.Push("<td class=`"td-std`">" . lapTimeDisplayValue(stint.AvgLaptime) . "</td>")

				fuelConsumption := stint.FuelConsumption

				if isNumber(fuelConsumption)
					fuelConsumption := displayValue("Float", convertUnit("Volume", fuelConsumption))

				fuelConsumptions.Push("<td class=`"td-std`">" . displayNullValue(fuelConsumption) . "</td>")
				accidents.Push("<td class=`"td-std`">" . stint.Accidents . "</td>")
				penalties.Push("<td class=`"td-std`">" . stint.Penalties . "</td>")
			}

		html .= "<br><table class=`"table-std`">"

		html .= ("<tr><th class=`"th-std`">" . translate("Stint") . "</th>"
				   . "<th class=`"th-std`">" . translate("Driver") . "</th>"
				   . "<th class=`"th-std`">" . translate("Lap") . "</th>"
			       . "<th class=`"th-std`">" . translate("Duration") . "</th>"
			       . "<th class=`"th-std`">" . translate("Laps") . "</th>"
			       . "<th class=`"th-std`">" . translate("Position") . "</th>"
			       . "<th class=`"th-std`">" . translate("Avg. Lap Time") . "</th>"
			       . "<th class=`"th-std`">" . translate("Consumption") . "</th>"
			       . "<th class=`"th-std`">" . translate("Accidents") . "</th>"
			       . "<th class=`"th-std`">" . translate("Penalties") . "</th>"
			   . "</tr>")

		loop stints.Length
			html .= ("<tr>" . stints[A_Index]
							. drivers[A_Index]
							. laps[A_Index]
							. durations[A_Index]
							. numLaps[A_Index]
							. positions[A_Index]
							. avgLapTimes[A_Index]
							. fuelConsumptions[A_Index]
							. accidents[A_Index]
							. penalties[A_Index]
				   . "</tr>")

		html .= "</table>"

		html .= ("<br><br><div id=`"header`"><i>" . translate("Race Course") . "</i></div>")

		laps := []
		positions := []

		if lastLap
			loop lastLap.Nr {
				lap := this.Laps[A_Index]

				laps.Push(A_Index)
				positions.Push(lap.Position)
				remainingFuels.Push(lap.FuelRemaining)

				if lapDataTable.Has(A_Index)
					tyreLaps.Push(lapDataTable[A_Index]["Tyre.Laps"])
				else
					tyreLaps.Push(kNull)
			}

		width := (this.DetailsViewer.getWidth() - 20)

		chart1 := this.createSessionSummaryChart(1, width, 248, laps, positions, remainingFuels, tyreLaps)

		html .= ("<br><br><div id=`"chart_1`" style=`"width: " . width . "px; height: 248px`"></div>")

		this.showDetails("Session", html, [1, chart1])
	}

	showPlanDetails() {
		local html := ("<div id=`"header`"><b>" . translate("Plan Summary") . "</b></div>")
		local telemetryDB := this.TelemetryDatabase
		local window := this.Window
		local currentListView, stint, driver, timePlanned, timeActual, lapPlanned, lapActual, refuelAmount, tyreChange
		local simulator, carName, trackName, sessionDate, sessionTime

		simulator := this.Simulator
		carName := this.Car
		carName := (carName ? telemetryDB.getCarName(simulator, carName) : "-")
		trackName := this.Track
		trackName := (trackName ? telemetryDB.getTrackName(simulator, trackName) : "-")

		sessionDate := this.Date

		if sessionDate
			sessionDate := FormatTime(sessionDate, "ShortDate")
		else
			sessionDate := "-"

		sessionTime := this.Time

		if sessionTime
			sessionTime := FormatTime(sessionTime, "Time")
		else
			sessionTime := "-"

		html .= "<br><br><table>"
		html .= ("<tr><td><b>" . translate("Simulator:") . "</b></td><td>" . (simulator ? simulator : "-") . "</td></tr>")
		html .= ("<tr><td><b>" . translate("Car:") . "</b></td><td>" . carName . "</td></tr>")
		html .= ("<tr><td><b>" . translate("Track:") . "</b></td><td>" . trackName . "</td></tr>")
		html .= ("<tr><td><b>" . translate("Date:") . "</b></td><td>" . sessionDate . "</td></tr>")
		html .= ("<tr><td><b>" . translate("Time:") . "</b></td><td>" . sessionTime . "</td></tr>")
		html .= "</table><br>"

		html .= "<br><br><table class=`"table-std`">"

		html .= ("<tr><th class=`"th-std`">" . translate("Stint") . "</th>"
				   . "<th class=`"th-std`">" . translate("Driver") . "</th>"
				   . "<th class=`"th-std`">" . translate("Time (est.)") . "</th>"
				   . "<th class=`"th-std`">" . translate("Time (act.)") . "</th>"
				   . "<th class=`"th-std`">" . translate("Lap (est.)") . "</th>"
				   . "<th class=`"th-std`">" . translate("Lap (act.)") . "</th>"
				   . "<th class=`"th-std`">" . translate("Refuel") . "</th>"
				   . "<th class=`"th-std`">" . translate("Tyre Change") . "</th>"
			   . "</tr>")

		loop this.PlanListView.GetCount() {
			stint := this.PlanListView.GetText(A_Index, 1)
			driver := this.PlanListView.GetText(A_Index, 2)
			timePlanned := this.PlanListView.GetText(A_Index, 3)
			timeActual := this.PlanListView.GetText(A_Index, 4)
			lapPlanned := this.PlanListView.GetText(A_Index, 5)
			lapActual := this.PlanListView.GetText(A_Index, 6)
			refuelAmount := this.PlanListView.GetText(A_Index, 7)
			tyreChange := this.PlanListView.GetText(A_Index, 8)

			html .= ("<tr><th class=`"th-std`">" . stint . "</th>"
					   . "<td class=`"td-std`">" . driver . "</td>"
					   . "<td class=`"td-std`">" . timePlanned . "</td>"
					   . "<td class=`"td-std`">" . timeActual . "</td>"
					   . "<td class=`"td-std`">" . lapPlanned . "</td>"
					   . "<td class=`"td-std`">" . lapActual . "</td>"
					   . "<td class=`"td-std`">" . (refuelAmount ? refuelAmount : "-") . "</td>"
					   . "<td class=`"td-std`">" . tyreChange . "</td>"
				   . "</tr>")
		}

		html .= "</table>"

		this.showDetails("Plan", html)
	}

	showSetupsDetails() {
		local html := ("<div id=`"header`"><b>" . translate("Setups Summary") . "</b></div>")
		local window := this.Window
		local currentListView, driver, conditions, tyreCompound, pressures, notes

		html .= "<br><br><table class=`"table-std`">"

		html .= ("<tr>"
			   . "<th class=`"th-std`">" . translate("Driver") . "</th>"
			   . "<th class=`"th-std`">" . translate("Conditions") . "</th>"
			   . "<th class=`"th-std`">" . translate("Compound") . "</th>"
			   . "<th class=`"th-std`">" . translate("Prs. FL") . "</th>"
			   . "<th class=`"th-std`">" . translate("Prs. FR") . "</th>"
			   . "<th class=`"th-std`">" . translate("Prs. RL") . "</th>"
			   . "<th class=`"th-std`">" . translate("Prs. RR") . "</th>"
			   . "<th class=`"th-std`">" . translate("Notes") . "</th>"
			   . "</tr>")

		loop this.SetupsListView.GetCount() {
			driver := this.SetupsListView.GetText(A_Index, 1)
			conditions := this.SetupsListView.GetText(A_Index, 2)
			tyreCompound := this.SetupsListView.GetText(A_Index, 3)
			pressures := this.SetupsListView.GetText(A_Index, 4)
			notes := this.SetupsListView.GetText(A_Index, 5)

			pressures := string2Values(", ", pressures)

			html .= ("<tr>"
				   . "<td class=`"td-std`">" . driver . "</td>"
				   . "<td class=`"td-std`">" . conditions . "</td>"
				   . "<td class=`"td-std`">" . tyreCompound . "</td>"
				   . "<td class=`"td-std`">" . pressures[1] . "</td>"
				   . "<td class=`"td-std`">" . pressures[2] . "</td>"
				   . "<td class=`"td-std`">" . pressures[3] . "</td>"
				   . "<td class=`"td-std`">" . pressures[4] . "</td>"
				   . "<td class=`"td-std`">" . notes . "</td>"
				   . "</tr>")
		}

		html .= "</table>"

		this.showDetails("Setups", html)
	}

	computeCarStatistics(car, laps, &lapTime, &potential, &raceCraft, &speed, &consistency, &carControl) {
		local raceData := true
		local drivers := false
		local positions := true
		local times := true
		local cars := []
		local count := 0
		local potentials := false
		local raceCrafts := false
		local speeds := false
		local consistencies := false
		local carControls := false
		local oldLapSettings

		lapTime := 0

		this.ReportViewer.loadReportData(laps, &raceData, &drivers, &positions, &times)

		loop getMultiMapValue(raceData, "Cars", "Count")
			cars.Push(A_Index)

		loop laps.Length
			if times[A_Index].Has(car) {
				lapTime += times[A_Index][car]
				count += 1
			}

		if (count > 0)
			lapTime := ((lapTime / count) / 1000)

		laps := []

		loop laps.Length
			laps.Push(A_Index)

		oldLapSettings := (this.ReportViewer.Settings.Has("Laps") ? this.ReportViewer.Settings["Laps"] : false)

		try {
			this.ReportViewer.Settings["Laps"] := laps

			this.ReportViewer.getDriverStatistics(raceData, cars, positions, times, &potentials, &raceCrafts, &speeds, &consistencies, &carControls)
		}
		finally {
			if oldLapSettings
				this.ReportViewer.Settings["Laps"] := oldLapSettings
			else
				this.ReportViewer.Settings.Delete("Laps")
		}

		potential := Round(potentials[car], 2)
		raceCraft := Round(raceCrafts[car], 2)
		speed := Round(speeds[car], 2)
		consistency := Round(consistencies[car], 2)
		carControl := Round(carControls[car], 2)
	}
}


;;;-------------------------------------------------------------------------;;;
;;;                   Private Function Declaration Section                  ;;;
;;;-------------------------------------------------------------------------;;;

getDeprecatedValue(data, section, newKey, oldKey, default := false) {
	local value := getMultiMapValue(data, section, newKey, kUndefined)

	if (value != kUndefined)
		return value
	else
		return getMultiMapValue(data, section, oldKey, default)
}

convertValue(name, value) {
	if (value = kNull)
		return value
	else if InStr(name, "Fuel")
		return convertUnit("Volume", value)
	else if InStr(name, "Temperature")
		return convertUnit("Temperature", value)
	else if InStr(name, "Pressure")
		return convertUnit("Pressure", value)
	else
		return value
}

manageTeam(raceCenterOrCommand, teamDrivers := false, arguments*) {
	local x, y, row, driver, ignore, name, connection

	static result := false

	static teamGui

	static availableDriversListView
	static selectedDriversListView

	static selectDriverButton
	static deselectDriverButton
	static upDriverButton
	static downDriverButton

	static connectedDrivers := []

	if (raceCenterOrCommand = kCancel)
		result := kCancel
	else if (raceCenterOrCommand = kOk)
		result := kOk
	else if (raceCenterOrCommand = "SelectDriver") {
		row := availableDriversListView.GetNext(0)

		driver := availableDriversListView.GetText(row, 1)
		availableDriversListView.Delete(row)

		selectedDriversListView.Modify(selectedDriversListView.Add("", driver, inList(connectedDrivers, driver) ? translate("x") : ""), "Select Vis")

		manageTeam("UpdateState")
	}
	else if (raceCenterOrCommand = "DeselectDriver") {
		row := selectedDriversListView.GetNext(0)

		driver := selectedDriversListView.GetText(row, 1)
		selectedDriversListView.Delete(row)

		availableDriversListView.Modify(availableDriversListView.Add("", driver, inList(connectedDrivers, driver) ? translate("x") : ""), "Vis")

		manageTeam("UpdateState")
	}
	else if (raceCenterOrCommand = "UpDriver") {
		row := selectedDriversListView.GetNext(0)

		driver := selectedDriversListView.GetText(row, 1)
		selectedDriversListView.Delete(row)

		selectedDriversListView.Insert(row - 1, "", driver, inList(connectedDrivers, driver) ? translate("x") : "")
		selectedDriversListView.Modify(row - 1, "Select Vis")

		manageTeam("UpdateState")
	}
	else if (raceCenterOrCommand = "DownDriver") {
		row := selectedDriversListView.GetNext(0)

		driver := selectedDriversListView.GetText(row, 1)
		selectedDriversListView.Delete(row)

		selectedDriversListView.Insert(row + 1, "", driver, inList(connectedDrivers, driver) ? translate("x") : "")
		selectedDriversListView.Modify(row + 1, "Select Vis")

		manageTeam("UpdateState")
	}
	else if (raceCenterOrCommand = "UpdateState") {
		if availableDriversListView.GetNext(0)
			selectDriverButton.Enabled := true
		else
			selectDriverButton.Enabled := false

		row := selectedDriversListView.GetNext(0)

		if row {
			deselectDriverButton.Enabled := true

			if (row > 1)
				upDriverButton.Enabled := true
			else
				upDriverButton.Enabled := false

			if (row < selectedDriversListView.GetCount())
				downDriverButton.Enabled := true
			else
				downDriverButton.Enabled := false
		}
		else {
			deselectDriverButton.Enabled := false
			upDriverButton.Enabled := false
			downDriverButton.Enabled := false
		}
	}
	else {
		result := false

		teamGui := Window({Descriptor: "Race Center.Team Manager", Options: "0x400000"})

		teamGui.Opt("+Owner" . raceCenterOrCommand.Window.Hwnd)

		teamGui.SetFont("s10 Bold", "Arial")

		teamGui.Add("Text", "w392 Center", translate("Modular Simulator Controller System")).OnEvent("Click", moveByMouse.Bind(teamGui, "Race Center.Team Manager"))

		teamGui.SetFont("s9 Norm", "Arial")

		teamGui.Add("Documentation", "x148 YP+20 w112 Center", translate("Team Selection")
				  , "https://github.com/SeriousOldMan/Simulator-Controller/wiki/Team-Server#session--stint-planning")

		teamGui.SetFont("s8 Norm", "Arial")

		connectedDrivers := []

		if raceCenterOrCommand.SessionActive
			for ignore, connection in string2Values(";", raceCenterOrCommand.Connector.GetSessionConnections(raceCenterOrCommand.SelectedSession[true])) {
				connection := parseObject(raceCenterOrCommand.Connector.GetConnection(connection))

				if (connection.Name && (connection.Name != "") && (connection.Type = "Driver"))
					connectedDrivers.Push(connection.Name)
			}

		availableDriversListView := teamGui.Add("ListView", "x16 yp+30 w160 h184 AltSubmit -Multi -LV0x10 NoSort NoSortHdr  Section", collect(["Available Driver", "Online"], translate))
		availableDriversListView.OnEvent("Click", manageTeam.Bind("UpdateState"))

		if !teamDrivers
			teamDrivers := raceCenterOrCommand.TeamDrivers

		for name, ignore in raceCenterOrCommand.SessionDrivers
			if !inList(teamDrivers, name)
				availableDriversListView.Add("", name, inList(connectedDrivers, name) ? translate("x") : "")

		availableDriversListView.ModifyCol()
		availableDriversListView.ModifyCol(1, "AutoHdr")
		availableDriversListView.ModifyCol(2, "AutoHdr Center")

		selectedDriversListView := teamGui.Add("ListView", "x230 ys w160 h184 AltSubmit -Multi -LV0x10 NoSort NoSortHdr", collect(["Selected Driver", "Online"], translate))
		selectedDriversListView.OnEvent("Click", manageTeam.Bind("UpdateState"))

		for ignore, name in teamDrivers
			selectedDriversListView.Add("", name, inList(connectedDrivers, name) ? translate("x") : "")

		selectedDriversListView.ModifyCol()
		selectedDriversListView.ModifyCol(1, "AutoHdr")
		selectedDriversListView.ModifyCol(2, "AutoHdr Center")

		teamGui.SetFont("s10 Bold", "Arial")

		selectDriverButton := teamGui.Add("Button", "x183 ys+75 w40", ">")
		selectDriverButton.OnEvent("Click", manageTeam.Bind("SelectDriver"))
		deselectDriverButton := teamGui.Add("Button", "x183 yp+30 w40", "<")
		deselectDriverButton.OnEvent("Click", manageTeam.Bind("DeselectDriver"))

		upDriverButton := teamGui.Add("Button", "x205 ys+25 w23 h23")
		upDriverButton.OnEvent("Click", manageTeam.Bind("UpDriver"))
		downDriverButton := teamGui.Add("Button", "x205 ys+161 w23 h23")
		downDriverButton.OnEvent("Click", manageTeam.Bind("DownDriver"))

		setButtonIcon(upDriverButton, kIconsDirectory . "Up Arrow.ico", 1, "W12 H12 L6 T6 R6 B6")
		setButtonIcon(downDriverButton, kIconsDirectory . "Down Arrow.ico", 1, "W12 H12 L4 T4 R4 B4")

		teamGui.SetFont("s8 Norm", "Arial")

		teamGui.Add("Text", "x8 ys+194 w392 0x10")

		teamGui.Add("Button", "x120 yp+10 w80 h23 Default", translate("Ok")).OnEvent("Click", manageTeam.Bind(kOk))
		teamGui.Add("Button", "x208 yp w80 h23", translate("&Cancel")).OnEvent("Click", manageTeam.Bind(kCancel))

		if getWindowPosition("Race Center.Team Manager", &x, &y)
			teamGui.Show("x" . x . " y" . y)
		else
			teamGui.Show()

		manageTeam("UpdateState")

		loop
			Sleep(100)
		until result

		if (result = kOk) {
			result := []

			loop selectedDriversListView.GetCount() {
				driver := selectedDriversListView.GetText(A_Index, 1)

				result.Push(driver)
			}
		}
		else
			result := false

		teamGui.Destroy()

		return result
	}
}

pitstopSettings(raceCenterOrCommand := false, arguments*) {
	static rCenter := false
	static isOpen := false

	static settingsGui := false

	static settingsListView := false

	noSelect(*) {
		loop settingsListView.GetCount()
			settingsListView.Modify(A_Index, "-Select")
	}

	if !rCenter
		rCenter := RaceCenter.Instance

	try {
		if (raceCenterOrCommand = "Visible")
			return isOpen
		else if (raceCenterOrCommand = kClose) {
			if isOpen {
				settingsGui.Hide()

				isOpen := false
			}
		}
		else if (raceCenterOrCommand = "Update") {
			if isOpen {
				if !settingsListView
					pitstopSettings()

				settingsListView.Delete()

				if arguments[1].Has("FuelAmount")
					settingsListView.Add("", translate("Refuel"), displayValue("Float", convertUnit("Volume", arguments[1]["FuelAmount"])))

				if arguments[1].Has("TyreCompound")
					if arguments[1]["TyreCompound"]
						settingsListView.Add("", translate("Tyre Compound"), compound(arguments[1]["TyreCompound"], arguments[1]["TyreCompoundColor"])
											   . (inList(["ACC", "Assetto Corsa Competizione"], rCenter.Simulator) ? translate(" (probably)") : ""))

				if arguments[1].Has("TyreSet")
					if (arguments[1].Has("TyreCompound") && arguments[1]["TyreCompound"])
						settingsListView.Add("", translate("Tyre Set"), arguments[1]["TyreSet"] ? arguments[1]["TyreSet"] : "-")

				if arguments[1].Has("TyrePressureFL")
					if (arguments[1].Has("TyreCompound") && arguments[1]["TyreCompound"])
						settingsListView.Add("", translate("Tyre Pressures"), values2String(", ", displayValue("Float", convertUnit("Pressure", arguments[1]["TyrePressureFL"]))
																								, displayValue("Float", convertUnit("Pressure", arguments[1]["TyrePressureFR"]))
																								, displayValue("Float", convertUnit("Pressure", arguments[1]["TyrePressureRL"]))
																								, displayValue("Float", convertUnit("Pressure", arguments[1]["TyrePressureRR"]))))

				if (arguments[1].Has("RepairBodywork") || arguments[1].Has("RepairSuspension") || arguments[1].Has("RepairEngine"))
					settingsListView.Add("", translate("Repairs"), rCenter.computeRepairs(arguments[1].Has("RepairBodywork") ? arguments[1]["RepairBodywork"] : false
																						, arguments[1].Has("RepairSuspension") ? arguments[1]["RepairSuspension"] : false
																						, arguments[1].Has("RepairEngine") ? arguments[1]["RepairEngine"] : false))

				settingsListView.ModifyCol()

				settingsListView.ModifyCol(1, "AutoHdr")
				settingsListView.ModifyCol(2, "AutoHdr")
			}
		}
		else if (settingsListView && !isOpen) {
			settingsGui.Show({Descriptor: "Race Center.Pitstop Settings", Options: "0x400000"})

			isOpen := true
		}
		else {
			settingsGui := Window({Options: "0x400000"}, "")

			settingsGui.SetFont("s10 Bold", "Arial")

			settingsGui.Add("Text", "w292 Center", translate("Modular Simulator Controller System")).OnEvent("Click", moveByMouse.Bind(settingsGui, "Race Center.Pitstop Settings"))

			settingsGui.SetFont("s9 Norm", "Arial")

			settingsGui.Add("Documentation", "x68 YP+20 w172 Center", translate("Pitstop Settings")
						  , "https://github.com/SeriousOldMan/Simulator-Controller/wiki/Team-Server#initiating-a-pitstop-for-the-current-driver")

			settingsGui.SetFont("s8 Norm", "Arial")

			settingsListView := settingsGui.Add("ListView", "x16 yp+30 w284 h184 AltSubmit -Multi -LV0x10 NoSort NoSortHdr  Section", collect(["Setting", "Value"], translate))
			settingsListView.OnEvent("Click", noSelect)
			settingsListView.OnEvent("DoubleClick", noSelect)

			settingsGui.Add("Button", "x120 yp+200 w80 h23 Default", translate("Close")).OnEvent("Click", pitstopSettings.Bind(kClose))

			if ((arguments.Length = 0) || arguments[1]) {
				if getWindowPosition("Race Center.Pitstop Settings", &x, &y)
					settingsGui.Show("x" . x . " y" . y)
				else
					settingsGui.Show()

				isOpen := true
			}
			else {
				if getWindowPosition("Race Center.Pitstop Settings", &x, &y)
					settingsGui.Show("x" . x . " y" . y . " Hide")
				else
					settingsGui.Show("Hide")
			}

		}
	}
}

loginDialog(connectorOrCommand := false, teamServerURL := false, owner := false, *) {
	local loginGui

	static name := ""
	static password := ""

	static result := false
	static nameEdit
	static passwordEdit

	if (connectorOrCommand == kOk)
		result := kOk
	else if (connectorOrCommand == kCancel)
		result := kCancel
	else {
		result := false

		loginGui := Window({Options: "0x400000"}, "")

		loginGui.SetFont("Norm", "Arial")

		loginGui.Add("Text", "x16 y16 w90 h23 +0x200", translate("Server URL"))
		loginGui.Add("Text", "x110 yp w160 h23 +0x200", teamServerURL)

		loginGui.Add("Text", "x16 yp+30 w90 h23 +0x200", translate("Name"))
		nameEdit := loginGui.Add("Edit", "x110 yp+1 w160 h21", name)

		loginGui.Add("Text", "x16 yp+23 w90 h23 +0x200", translate("Password"))
		passwordEdit := loginGui.Add("Edit", "x110 yp+1 w160 h21 Password", password)

		loginGui.Add("Button", "x60 yp+35 w80 h23 Default", translate("Ok")).OnEvent("Click", loginDialog.Bind(kOk))
		loginGui.Add("Button", "x146 yp w80 h23", translate("&Cancel")).OnEvent("Click", loginDialog.Bind(kCancel))

		loginGui.Opt("+Owner" . owner.Hwnd)

		loginGui.Show("AutoSize Center")

		while !result
			Sleep(100)

		try {
			if (result == kCancel)
				return false
			else if (result == kOk) {
				name := loginGui["nameEdit"]
				password := loginGui["passwordEdit"]

				try {
					connectorOrCommand.Initialize(teamServerURL)

					connectorOrCommand.Login(name, password)

					return connectorOrCommand.GetSessionToken()
				}
				catch Any as exception {
					OnMessage(0x44, translateOkButton)
					MsgBox((translate("Cannot connect to the Team Server.") . "`n`n" . translate("Error: ") . exception.Message), translate("Error"), 262160)
					OnMessage(0x44, translateOkButton, 0)

					return false
				}
			}
		}
		finally {
			loginGui.Destroy()
		}
	}
}

lapTimeDisplayValue(lapTime) {
	return RaceReportViewer.lapTimeDisplayValue(lapTime)
}

displayNullValue(value, null := "-") {
	return (isNull(value) ? null : value)
}

chartValue(value) {
	return (isNull(value) ? kNull : value)
}

null(value) {
	return (((value == 0) || (value == "-") || (value = "n/a")) ? kNull : valueOrNull(value))
}

parseObject(properties) {
	local result := Object()
	local property

	properties := StrReplace(properties, "`r", "")

	loop Parse, properties, "`n" {
		property := string2Values("=", A_LoopField)

		result.%property[1]% := property[2]
	}

	return result
}

loadTeams(connector) {
	local teams := CaseInsenseMap()
	local ignore, identifier, team

	try {
		for ignore, identifier in string2Values(";", connector.GetAllTeams()) {
			team := parseObject(connector.GetTeam(identifier))

			teams[team.Name] := team.Identifier
		}
	}
	catch Any as exception {
		logError(exception)
	}

	return teams
}

loadSessions(connector, team) {
	local sessions := CaseInsenseMap()
	local ignore, identifier, session

	if team
		for ignore, identifier in string2Values(";", connector.GetTeamSessions(team)) {
			try {
				session := parseObject(connector.GetSession(identifier))

				sessions[session.Name] := session.Identifier
			}
			catch Any as exception {
				logError(exception)
			}
		}

	return sessions
}

loadDrivers(connector, team) {
	local drivers := CaseInsenseMap()
	local ignore, identifier, driver

	if team
		for ignore, identifier in string2Values(";", connector.GetTeamDrivers(team)) {
			try {
				driver := parseObject(connector.GetDriver(identifier))

				drivers[computeDriverName(driver.ForName, driver.SurName, driver.NickName)] := driver.Identifier
			}
			catch Any as exception {
				logError(exception)
			}
		}

	return drivers
}

startupRaceCenter() {
	local icon := kIconsDirectory . "Console.ico"
	local rCenter

	TraySetIcon(icon, "1")
	A_IconTip := "Race Center"

	rCenter := RaceCenter(kSimulatorConfiguration, readMultiMap(kUserConfigDirectory . "Race.settings"))

	rCenter.createGui(rCenter.Configuration)

	rCenter.show()

	rCenter.connect(true)

	registerMessageHandler("Setup", functionMessageHandler)
}


;;;-------------------------------------------------------------------------;;;
;;;                         Message Handler Section                         ;;;
;;;-------------------------------------------------------------------------;;;

setTyrePressures(tyreCompound, tyreCompoundColor, flPressure, frPressure, rlPressure, rrPressure) {
	local rCenter := RaceCenter.Instance

	if (rCenter.iPressuresRequest = "Pitstop")
		rCenter.withExceptionhandler(ObjBindMethod(rCenter, "initializePitstopTyreSetup", &tyreCompound, &tyreCompoundColor, &flPressure, &frPressure, &rlPressure, &rrPressure))
	else
		if (rCenter.SetupsListView.GetNext(0) = rCenter.iPressuresRequest)
			rCenter.withExceptionhandler(ObjBindMethod(rCenter, "initializeSetup", tyreCompound, tyreCompoundColor, flPressure, frPressure, rlPressure, rrPressure))

	return false
}


;;;-------------------------------------------------------------------------;;;
;;;                          Initialization Section                         ;;;
;;;-------------------------------------------------------------------------;;;

startupRaceCenter()