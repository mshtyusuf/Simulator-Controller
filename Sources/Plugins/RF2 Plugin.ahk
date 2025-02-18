﻿;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   Modular Simulator Controller System - RF2 Plugin                      ;;;
;;;                                                                         ;;;
;;;   Author:     Oliver Juwig (TheBigO)                                    ;;;
;;;   License:    (2023) Creative Commons - BY-NC-SA                        ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;-------------------------------------------------------------------------;;;
;;;                         Local Include Section                           ;;;
;;;-------------------------------------------------------------------------;;;

#Include "Libraries\SimulatorPlugin.ahk"
#Include "..\Database\Libraries\SessionDatabase.ahk"


;;;-------------------------------------------------------------------------;;;
;;;                         Public Constant Section                         ;;;
;;;-------------------------------------------------------------------------;;;

global kRF2Application := "rFactor 2"

global kRF2Plugin := "RF2"


;;;-------------------------------------------------------------------------;;;
;;;                          Public Classes Section                         ;;;
;;;-------------------------------------------------------------------------;;;

class RF2Plugin extends RaceAssistantSimulatorPlugin {
	iOpenPitstopMFDHotkey := false
	iClosePitstopMFDHotkey := false

	iSelectedDriver := false

	OpenPitstopMFDHotkey {
		Get {
			return this.iOpenPitstopMFDHotkey
		}
	}

	ClosePitstopMFDHotkey {
		Get {
			return this.iClosePitstopMFDHotkey
		}
	}

	__New(controller, name, simulator, configuration := false) {
		super.__New(controller, name, simulator, configuration)

		if (this.Active || isDebug()) {
			this.iOpenPitstopMFDHotkey := this.getArgumentValue("openPitstopMFD", false)
			this.iClosePitstopMFDHotkey := this.getArgumentValue("closePitstopMFD", false)
		}
	}

	getPitstopActions(&allActions, &selectActions) {
		allActions := CaseInsenseMap("NoRefuel", "No Refuel", "Refuel", "Refuel", "TyreCompound", "Tyre Compound", "TyreAllAround", "All Around"
								   , "TyreFrontLeft", "Front Left", "TyreFrontRight", "Front Right", "TyreRearLeft", "Rear Left", "TyreRearRight", "Rear Right"
								   , "DriverSelect", "Driver", "RepairRequest", "Repair")

		selectActions := []
	}

	activateWindow() {
	}

	sendPitstopCommand(command, operation := false, message := false, arguments*) {
		local simulator, exePath

		if (this.OpenPitstopMFDHotkey != "Off") {
			simulator := this.Code
			arguments := values2String(";", arguments*)
			exePath := kBinariesDirectory . simulator . " SHM Provider.exe"

			try {
				if operation
					RunWait(A_ComSpec . " /c `"`"" . exePath . "`" -" . command . " `"" . operation . ":" . message . ":" . arguments . "`"`"", , "Hide")
				else
					RunWait(A_ComSpec . " /c `"`"" . exePath . "`" -" . command . "`"", , "Hide")
			}
			catch Any as exception {
				logMessage(kLogCritical, substituteVariables(translate("Cannot start %simulator% %protocol% Provider ("), {simulator: simulator, protocol: "SHM"})
									   . exePath . translate(") - please rebuild the applications in the binaries folder (")
									   . kBinariesDirectory . translate(")"))

				showMessage(substituteVariables(translate("Cannot start %simulator% %protocol% Provider (%exePath%) - please check the configuration...")
											  , {exePath: exePath, simulator: simulator, protocol: "SHM"})
						  , translate("Modular Simulator Controller System"), "Alert.png", 5000, "Center", "Bottom", 800)
			}
		}
	}

	openPitstopMFD(descriptor := false) {
		static reported := false

		if this.OpenPitstopMFDHotkey {
			if (this.OpenPitstopMFDHotkey != "Off") {
				this.activateWindow()

				this.sendCommand(this.OpenPitstopMFDHotkey)

				return true
			}
			else
				return false
		}
		else if !reported {
			reported := true

			logMessage(kLogCritical, translate("The hotkeys for opening and closing the Pitstop MFD are undefined - please check the configuration"))

			showMessage(translate("The hotkeys for opening and closing the Pitstop MFD are undefined - please check the configuration...")
					  , translate("Modular Simulator Controller System"), "Alert.png", 5000, "Center", "Bottom", 800)

			return false
		}
	}

	closePitstopMFD() {
		static reported := false

		if this.ClosePitstopMFDHotkey {
			if (this.OpenPitstopMFDHotkey != "Off") {
				this.activateWindow()

				this.sendCommand(this.ClosePitstopMFDHotkey)
			}
		}
		else if !reported {
			reported := true

			logMessage(kLogCritical, translate("The hotkeys for opening and closing the Pitstop MFD are undefined - please check the configuration"))

			showMessage(translate("The hotkeys for opening and closing the Pitstop MFD are undefined - please check the configuration...")
					  , translate("Modular Simulator Controller System"), "Alert.png", 5000, "Center", "Bottom", 800)
		}
	}

	requirePitstopMFD() {
		return true
	}

	selectPitstopOption(option) {
		local actions := false
		local ignore := false
		local candidate

		this.getPitstopActions(&actions, &ignore)

		for ignore, candidate in actions
			if (candidate = option)
				return true

		return false
	}

	changePitstopOption(option, action, steps := 1) {
		if (this.OpenPitstopMFDHotkey != "Off") {
			switch option, false {
				case "Refuel":
					this.sendPitstopCommand("Pitstop", action, "Refuel", Round(steps))
				case "No Refuel":
					this.sendPitstopCommand("Pitstop", "Decrease", "Refuel", 250)
				case "Tyre Compound":
					this.sendPitstopCommand("Pitstop", action, "Tyre Compound", Round(steps))
				case "All Around":
					this.sendPitstopCommand("Pitstop", action, "Tyre Pressure", Round(steps * 0.1, 1), Round(steps * 0.1, 1), Round(steps * 0.1, 1), Round(steps * 0.1, 1))
				case "Front Left":
					this.sendPitstopCommand("Pitstop", action, "Tyre Pressure", Round(steps * 0.1, 1), 0.0, 0.0, 0.0)
				case "Front Right":
					this.sendPitstopCommand("Pitstop", action, "Tyre Pressure", 0.0, Round(steps * 0.1, 1), 0.0, 0.0)
				case "Rear Left":
					this.sendPitstopCommand("Pitstop", action, "Tyre Pressure", 0.0, 0.0, Round(steps * 0.1, 1), 0.0)
				case "Rear Right":
					this.sendPitstopCommand("Pitstop", action, "Tyre Pressure", 0.0, 0.0, 0.0, Round(steps * 0.1, 1))
				case "Driver", "Repair":
					this.sendPitstopCommand("Pitstop", action, option, Round(steps))
			}
		}
	}

	supportsPitstop() {
		return true
	}

	supportsTrackMap() {
		return true
	}

	supportsSetupImport() {
		return true
	}

	getPitstopOptionValues(option) {
		local data, compound, compoundColor

		if (this.OpenPitstopMFDHotkey != "Off") {
			switch option, false {
				case "Refuel":
					data := readSimulatorData(this.Code, "-Setup")

					return [getMultiMapValue(data, "Setup Data", "FuelAmount", 0)]
				case "Tyre Pressures":
					data := readSimulatorData(this.Code, "-Setup")

					return [getMultiMapValue(data, "Setup Data", "TyrePressureFL", 26.1), getMultiMapValue(data, "Setup Data", "TyrePressureFR", 26.1)
						  , getMultiMapValue(data, "Setup Data", "TyrePressureRL", 26.1), getMultiMapValue(data, "Setup Data", "TyrePressureRR", 26.1)]
				case "Tyre Compound":
					data := readSimulatorData(this.Code, "-Setup")

					compound := getMultiMapValue(data, "Setup Data", "TyreCompoundRaw")
					compound := SessionDatabase.getTyreCompoundName(this.Simulator[true], this.Car, this.Track, compound, kUndefined)

					if (compound = kUndefined)
						compound := normalizeCompound("Dry")

					compoundColor := false

					if compound
						splitCompound(compound, &compound, &compoundColor)

					return [compound, compoundColor]
				case "Repair Suspension":
					data := readSimulatorData(this.Code, "-Setup")

					return [getMultiMapValue(data, "Setup Data", "RepairSuspension", false)]
				case "Repair Bodywork":
					data := readSimulatorData(this.Code, "-Setup")

					return [getMultiMapValue(data, "Setup Data", "RepairBodywork", false)]
				default:
					return super.getPitstopOptionValues(option)
			}
		}
		else
			return false
	}

	performPitstop(lap, options) {
		super.performPitstop(lap, options)

		this.iSelectedDriver := false
	}

	setPitstopRefuelAmount(pitstopNumber, liters) {
		super.setPitstopRefuelAmount(pitstopNumber, liters)

		this.sendPitstopCommand("Pitstop", "Set", "Refuel", Round(liters))
	}

	setPitstopTyreSet(pitstopNumber, compound, compoundColor := false, set := false) {
		super.setPitstopTyreSet(pitstopNumber, compound, compoundColor, set)

		if compound {
			compound := this.tyreCompoundCode(compound, compoundColor)

			if compound {
				this.sendPitstopCommand("Pitstop", "Set", "Tyre Compound", compound)

				if set
					this.sendPitstopCommand("Pitstop", "Set", "Tyre Set", Round(set))
			}
		}
		else
			this.sendPitstopCommand("Pitstop", "Set", "Tyre Compound", "None")
	}

	setPitstopTyrePressures(pitstopNumber, pressureFL, pressureFR, pressureRL, pressureRR) {
		super.setPitstopTyrePressures(pitstopNumber, pressureFL, pressureFR, pressureRL, pressureRR)

		this.sendPitstopCommand("Pitstop", "Set", "Tyre Pressure"
							  , Round(pressureFL, 1), Round(pressureFR, 1), Round(pressureRL, 1), Round(pressureRR, 1))
	}

	requestPitstopRepairs(pitstopNumber, repairSuspension, repairBodywork, repairEngine := false) {
		super.requestPitstopRepairs(pitstopNumber, repairSuspension, repairBodywork, repairEngine)

		if (repairBodywork && repairSuspension)
			this.sendPitstopCommand("Pitstop", "Set", "Repair", "Both")
		else if repairSuspension
			this.sendPitstopCommand("Pitstop", "Set", "Repair", "Suspension")
		else if repairBodywork
			this.sendPitstopCommand("Pitstop", "Set", "Repair", "Bodywork")
		else
			this.sendPitstopCommand("Pitstop", "Set", "Repair", "Nothing")
	}

	requestPitstopDriver(pitstopNumber, driver) {
		local delta, currentDriver, nextDriver

		super.requestPitstopDriver(pitstopNumber, driver)

		if driver {
			driver := string2Values("|", driver)

			nextDriver := string2Values(":", driver[2])
			currentDriver := string2Values(":", driver[1])

			if !this.iSelectedDriver
				this.iSelectedDriver := currentDriver[2]

			delta := (nextDriver[2] - this.iSelectedDriver)

			loop Abs(delta)
				this.changePitstopOption("Driver", (delta < 0) ? "Decrease" : "Increase")

			this.iSelectedDriver := nextDriver[2]
		}
	}

	updateTelemetryData(data) {
		super.updateTelemetryData(data)

		if !getMultiMapValue(data, "Stint Data", "InPit", false)
			if (getMultiMapValue(data, "Car Data", "FuelRemaining", 0) = 0)
				setMultiMapValue(data, "Session Data", "Paused", true)
	}
}


;;;-------------------------------------------------------------------------;;;
;;;                     Function Hook Declaration Section                   ;;;
;;;-------------------------------------------------------------------------;;;

startRF2() {
	return SimulatorController.Instance.startSimulator(SimulatorController.Instance.findPlugin(kRF2Plugin).Simulator
													 , "Simulator Splash Images\RF2 Splash.jpg")
}


;;;-------------------------------------------------------------------------;;;
;;;                   Private Function Declaration Section                  ;;;
;;;-------------------------------------------------------------------------;;;

initializeRF2Plugin() {
	local controller := SimulatorController.Instance

	RF2Plugin(controller, kRF2Plugin, kRF2Application, controller.Configuration)
}


;;;-------------------------------------------------------------------------;;;
;;;                         Initialization Section                          ;;;
;;;-------------------------------------------------------------------------;;;

initializeRF2Plugin()
