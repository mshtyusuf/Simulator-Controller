;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   Modular Simulator Controller System - Setup Database                  ;;;
;;;                                                                         ;;;
;;;   Author:     Oliver Juwig (TheBigO)                                    ;;;
;;;   License:    (2021) Creative Commons - BY-NC-SA                        ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;-------------------------------------------------------------------------;;;
;;;                         Public Constant Section                         ;;;
;;;-------------------------------------------------------------------------;;;

global kWeatherOptions = ["Dry", "Drizzle", "LightRain", "MediumRain", "HeavyRain", "Thunderstorm"]

global kTyreCompounds = ["Dry", "Wet"]
global kTyreCompoundColors = ["Red", "White", "Blue"]

global kQualifiedTyreCompounds = ["Wet", "Dry", "Dry (Red)", "Dry (White)", "Dry (Blue)"]


;;;-------------------------------------------------------------------------;;;
;;;                          Public Classes Section                         ;;;
;;;-------------------------------------------------------------------------;;;

class SetupDatabase {
	iControllerConfiguration := false
	
	iUseGlobalDatabase := false
	
	iLastSimulator := false
	iLastCar := false
	iLastTrack := false
	iLastCompound := false
	iLastCompoundColor := false
	iLastWeather := false
	
	iDatabase := false
	iDatabaseName := false
		
	ControllerConfiguration[] {
		Get {
			return this.iControllerConfiguration
		}
	}
	
	UseGlobalDatabase[] {
		Get {
			return this.iUseGlobalDatabase
		}
	}
	
	__New(controllerConfiguration := false) {
		this.iControllerConfiguration := (controllerConfiguration ? controllerConfiguration : getControllerConfiguration())
	}

	getEntries(filter := "*.*", option := "D") {
		result := []
		
		Loop Files, %kSetupDatabaseDirectory%local\%filter%, %option%
			result.Push(A_LoopFileName)
		
		if this.UseGlobalDatabase
			Loop Files, %kSetupDatabaseDirectory%Global\%filter%, %option%
				if !inList(result, A_LoopFileName)
					result.Push(A_LoopFileName)
		
		return result
	}

	getPressureDistributions(fileName, airTemperature, trackTemperature, ByRef distributions) {
		tyreSetup := getConfigurationValue(readConfiguration(fileName), "Pressures", ConfigurationItem.descriptor(airTemperature, trackTemperature), false)
		
		if tyreSetup {
			tyreSetup := string2Values(";", tyreSetup)
			
			for index, key in ["FL", "FR", "RL", "RR"]
				for ignore, pressure in string2Values(",", tyreSetup[index]) {
					pressure := string2Values(":", pressure)
				
					if distributions[key].HasKey(pressure[1])
						distributions[key][pressure[1]] := distributions[key][pressure[1]] + pressure[2]
					else
						distributions[key][pressure[1]] := pressure[2]
				}
		}		
	}
	
	setUseGlobalDatabase(useGlobalDatabase) {
		this.iUseGlobalDatabase := useGlobalDatabase
	}

	getSimulatorName(simulatorCode) {
		for name, description in getConfigurationSectionValues(this.ControllerConfiguration, "Simulators", Object())
			if (simulatorCode = string2Values("|", description)[1])
				return name
			
		return false
	}

	getSimulatorCode(simulatorName) {
		return string2Values("|", getConfigurationValue(this.ControllerConfiguration, "Simulators", simulatorName))[1]
	}

	getSimulators() {
		simulators := []
		
		for simulator, ignore in getConfigurationSectionValues(this.ControllerConfiguration, "Simulators", Object())
			simulators.Push(simulator)
				
		return simulators
	}

	getCars(simulator) {
		code := this.getSimulatorCode(simulator)
		
		if code {
			return this.getEntries(code . "\*.*")
		}
		else
			return []
	}

	getTracks(simulator, car) {
		code := this.getSimulatorCode(simulator)
		
		if code {
			return this.getEntries(code . "\" . car . "\*.*")
		}
		else
			return []
	}

	getConditions(simulator, car, track) {
		local condition
		local compound
		
		path := (this.getSimulatorCode(simulator) . "\" . car . "\" . track . "\")
		conditions := []
		
		for ignore, fileName in this.getEntries(path . "Tyre Setup*.data", "F") {
			condition := string2Values(A_Space, StrReplace(StrReplace(fileName, "Tyre Setup ", ""), ".data", ""))
		
			if (condition.Length() == 2) {
				compound := condition[1]
				weather := condition[2]
			}
			else {
				compound := condition[1] . " " . condition[2]
				weather := condition[3]
			}
			
			pressures := readConfiguration(kSetupDatabaseDirectory . "local\" . path . fileName)
			
			if (pressures.Count() == 0)
				pressures := readConfiguration(kSetupDatabaseDirectory . "global\" . path . fileName)
			
			for descriptor, ignore in getConfigurationSectionValues(pressures, "Pressures") {
				descriptor := ConfigurationItem.splitDescriptor(descriptor)
			
				if descriptor[1] {
					; weather, airTemperature, trackTemperature, compound
					conditions.Push(weather, descriptor[1], descriptor[2], compound)
				
					break
				}
			}
		}
		
		return conditions
	}

	getTyreSetup(simulator, car, track, weather, airTemperature, trackTemperature, ByRef compound, ByRef compoundColor, ByRef pressures, ByRef certainty) {
		local condition
		
		if !compound {
			visited := []
			compounds := []
			
			for ignore, condition in this.getConditions(simulator, car, track) {
				theCompound := condition[4]
			
				if ((weather = condition[1]) && !inList(visited, theCompound)) {
					visited.Push(theCompound)
					
					theCompound := string2Values(A_Space, theCompound)
					
					if (theCompound.Length() == 1)
						theCompoundColor := "Black"
					else
						theCompoundColor := SubStr(theCompound[2], 2, StrLen(theCompound[2]) - 2)
				
					compounds.Push(Array(theCompound, theCompoundColor))
				}
			}
		}
		else
			compounds := [Array(compound, compoundColor)]
		
		thePressures := []
		theCertainty := 1.0
		
		for ignore, compoundInfo in compounds {
			theCompound := compoundInfo[1]
			theCompoundColor := compoundInfo[2]
			
			for ignore, pressureInfo in this.getPressures(simulator, car, track, weather, airTemperature, trackTemperature, theCompound, theCompoundColor) {
				deltaAir := pressureInfo["Delta Air"]
				deltaTrack := pressureInfo["Delta Track"]
				
				correction := (deltaAir + Round(deltaTrack * 0.49))
				
				thePressures.Push(pressureInfo["Pressure"] + (correction * 0.1))
				
				theCertainty := Min(theCertainty, 1.0 - ((deltaAir + deltaTrack) / 4))
			}
			
			if (thePressures.Length() > 0) {
				compound := theCompound
				compoundColor := theCompoundColor
				certainty := theCertainty
					
				pressures := thePressures
				
				return true
			}
		}
		
		return false
	}

	getPressures(simulator, car, track, weather, airTemperature, trackTemperature, compound, compoundColor) {
		if (compoundColor = "Black")
			path := (this.getSimulatorCode(simulator) . "\" . car . "\" . track . "\Tyre Setup " . compound . " " . weather . ".data")
		else
			path := (this.getSimulatorCode(simulator) . "\" . car . "\" . track . "\Tyre Setup " . compound . " (" . compoundColor . ") " . weather . ".data")
		
		for ignore, airDelta in [0, 1, -1, 2, -2] {
			for ignore, trackDelta in [0, 1, -1, 2, -2] {
				distributions := {FL: {}, FR: {}, RL: {}, RR: {}}
		
				this.getPressureDistributions(kSetupDatabaseDirectory . "local\" . path, airTemperature + airDelta, trackTemperature + trackDelta, distributions)
				
				if this.UseGlobalDatabase
					this.getPressureDistributions(kSetupDatabaseDirectory . "global\" . path, airTemperature + airDelta, trackTemperature + trackDelta, distributions)
				
				if (distributions["FL"].Count() != 0) {
					thePressures := {}
					
					for index, tyre in ["FL", "FR", "RL", "RR"] {
						thePressures[tyre] := {}
						tyrePressures := distributions[tyre]
					
						bestPressure := false
						bestCount := 0
						
						for pressure, pressureCount in tyrePressures {
							if (pressureCount > bestCount) {
								bestCount := pressureCount
								bestPressure := pressure
							}
						}
							
						thePressures[tyre]["Pressure"] := bestPressure
						thePressures[tyre]["Delta Air"] := airDelta
						thePressures[tyre]["Delta Track"] := trackDelta
					}
					
					return thePressures
				}
			}
		}
			
		return {}
	}
	
	updatePressures(simulator, car, track, weather, airTemperature, trackTemperature, compound, compoundColor, targetPressures) {
		if getConfigurationValue(this.ControllerConfiguration, "Simulators", simulator, false)
			simulatorCode := this.getSimulatorCode(simulator)
		else
			simulatorCode := simulator
		
		simulator := this.getSimulatorName(simulatorCode)
		
		FileCreateDir %kSetupDatabaseDirectory%Local\%simulatorCode%\%car%\%track%
		
		if ((this.iLastSimulator != simulator) || (this.iLastCar != car) || (this.iLastTrack != track)
		 || (this.iLastCompound != compound) || (this.iLastCompoundColor != compoundColor) || (this.iLastWeather != weather)) {
			this.iDatabase := false
		
			this.iLastSimulator := simulator
			this.iLastCar := car
			this.iLastTrack := track
			this.iLastCompound := compound
			this.iLastCompoundColor := compoundColor
			this.iLastWeather := weather
		}
		
		key := ConfigurationItem.descriptor(airTemperature, trackTemperature)
		
		if !this.iDatabase {
			if (compoundColor = "Black")
				this.iDatabaseName := (kSetupDatabaseDirectory . "Local\" . simulatorCode . "\" . car . "\" . track . "\Tyre Setup " . compound . " " . weather . ".data")
			else
				this.iDatabaseName := (kSetupDatabaseDirectory . "Local\" . simulatorCode . "\" . car . "\" . track . "\Tyre Setup " . compound . " (" . compoundColor . ") " . weather . ".data")
		
			this.iDatabase := readConfiguration(this.iDatabaseName)
		}
		
		pressureData := getConfigurationValue(database, "Pressures", key, false)
		pressures := {FL: {}, FR: {}, RL: {}, RR: {}}
		
		if pressureData {
			pressureData := string2Values(";", pressureData)
			
			for index, tyre in ["FL", "FR", "RL", "RR"]
				for index, pressure in string2Values(",", pressureData[index]) {
					pressure := string2Values(":", pressure)
				
					pressures[tyre][pressure[1]] := pressure[2]
				}
		}
		
		for tyrePressure, count in targetPressures {
			tyrePressure := string2Values(":", tyrePressure)
			pressure := tyrePressure[2]
			
			tyrePressures := pressures[tyrePressure[1]]
			
			tyrePressures[pressure] := (tyrePressures.HasKey(pressure) ? (tyrePressures[pressure] + count) : count)
		}
			
		pressureData := []
		
		for ignore, tyrePressures in pressures {
			data := []
		
			for pressure, count in tyrePressures
				data.Push(pressure . ":" . count)
			
			pressureData.Push(values2String(",", data*))
		}
		
		setConfigurationValue(this.iDatabase, "Pressures", key, values2String("; ", pressureData*))
		
		writeConfiguration(this.iDatabaseName, this.iDatabase)
	}
}