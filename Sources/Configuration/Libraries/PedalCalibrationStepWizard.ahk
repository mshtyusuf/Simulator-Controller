﻿;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   Modular Simulator Controller System - Pedal Calibtazion Step Wizard   ;;;
;;;                                                                         ;;;
;;;   Author:     Oliver Juwig (TheBigO)                                    ;;;
;;;   License:    (2021) Creative Commons - BY-NC-SA                        ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;-------------------------------------------------------------------------;;;
;;;                         Local Include Section                           ;;;
;;;-------------------------------------------------------------------------;;;

#Include Libraries\ButtonBoxStepWizard.ahk


;;;-------------------------------------------------------------------------;;;
;;;                          Public Classes Section                         ;;;
;;;-------------------------------------------------------------------------;;;

;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;
;;; PedalCalibrationStepWizard                                              ;;;
;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;

class PedalCalibrationStepWizard extends ActionsStepWizard {
	iCachedActions := false
	iPedalsCheck := {}
	
	Pages[] {
		Get {
			wizard := this.SetupWizard

			if (wizard.isModuleSelected("Button Box") && wizard.isModuleSelected("Pedal Calibration"))
				return 1
			else
				return 0
		}
	}
	
	saveToConfiguration(configuration) {
		local function
		local action
		
		base.saveToConfiguration(configuration)
		
		wizard := this.SetupWizard
	
		arguments := ""
		calibrations := []

		for ignore, action in this.getActions() {
			function := wizard.getModuleActionFunction("Pedal Calibration", "Pedal Calibration", action)
			
			if (function && (function != ""))
				calibrations.Push("""" . action . """ " . (IsObject(function) ? function[1] : function))
		}
		
		if (calibrations.Length() > 0) {
			if (arguments != "")
				arguments .= "; "

			arguments .= ("pedalCalibrations: " . values2String(", ", calibrations*))
		}
		
		new Plugin("Pedal Calibration", false, true, "", arguments).saveToConfiguration(configuration)
	}
	
	createGui(wizard, x, y, width, height) {
		local application
		
		static pedalCalibrationInfoText
		
		wizard := this.SetupWizard
		window := this.Window
		
		Gui %window%:Default
		
		pedalCalibrationIconHandle := false
		pedalCalibrationLabelHandle := false
		pedalCalibrationListViewHandle := false
		pedalCalibrationInfoTextHandle := false
		
		labelWidth := width - 30
		labelX := x + 35
		labelY := y + 8
		
		Gui %window%:Font, s10 Bold, Arial
		
		Gui %window%:Add, Picture, x%x% y%y% w30 h30 HWNDpedalCalibrationIconHandle Hidden, %kResourcesDirectory%Setup\Images\Brake.png
		Gui %window%:Add, Text, x%labelX% y%labelY% w%labelWidth% h26 HWNDpedalCalibrationLabelHandle Hidden, % translate("Pedal Calibration Configuration")
		
		colummLabel1Handle := false
		colummLine1Handle := false
		colummLabel2Handle := false
		colummLine2Handle := false
	
		secondX := x + 80
		secondWidth := 40
		
		col1Width := (secondX - x) + secondWidth
		
		listX := x + 150
		listWidth := width - 150
		
		Gui %window%:Font, s8 Bold, Arial
		
		Gui %window%:Add, Text, x%x% yp+30 w%col1Width% h23 +0x200 HWNDcolumnLabel1Handle Hidden Section, % translate("Pedals")
		Gui %window%:Add, Text, yp+20 x%x% w%col1Width% 0x10 HWNDcolumnLine1Handle Hidden

		Gui %window%:Font, s8 Norm, Arial
		
		throttleLabelHandle := false
		throttleCheckHandle := false
		brakeLabelHandle := false
		brakeCheckHandle := false
		clutchLabelHandle := false
		clutchCheckHandle := false
		
		allPedals := string2Values(",", getConfigurationValue(wizard.Definition, "Setup.Pedal Calibration", "Pedal Calibration.Pedals"))
		pedals := wizard.getModuleValue("Pedal Calibration", "Pedals", kUndefined)
		
		if (pedals == kUndefined)
			pedals := values2String("|", allPedals*)
		
		pedals := string2Values("|", pedals)
		
		for index, pedal in allPedals {
			if (index = 1)
				yOption := "yp+10"
			else
				yOption := "yp+24"

			checked := (inList(pedals, pedal) ? "Checked" : "")
			
			Gui %window%:Add, Text, x%x% %yOption% w105 h23 +0x200 HWND%pedal%LabelHandle Hidden, % translate(pedal)
			Gui %window%:Add, CheckBox, x%secondX% yp w24 h23 +0x200 HWND%pedal%CheckHandle %checked% gupdatePedals Hidden
			
			this.iPedalsCheck[pedal] := %pedal%CheckHandle
		}
		
		Gui %window%:Font, Bold, Arial
		
		Gui %window%:Add, Text, x%listX% ys w%listWidth% h23 +0x200 HWNDcolumnLabel2Handle Hidden, % translate("Actions")
		Gui %window%:Add, Text, yp+20 x%listX% w%listWidth% 0x10 HWNDcolumnLine2Handle Hidden

		Gui %window%:Font, s8 Norm, Arial
		
		Gui Add, ListView, x%listX% yp+10 w%listWidth% h260 AltSubmit -Multi -LV0x10 NoSort NoSortHdr HWNDpedalCalibrationListViewHandle gupdatePedalCalibrationActionFunction Hidden, % values2String("|", map(["Mode", "Pedal", "Action", "Label", "Function"], "translate")*)
		
		info := substituteVariables(getConfigurationValue(this.SetupWizard.Definition, "Setup.Pedal Calibration", "Pedal Calibration.Actions.Info." . getLanguage()))
		info := "<div style='font-family: Arial, Helvetica, sans-serif' style='font-size: 12px'><hr style='width: 90%'>" . info . "</div>"

		Sleep 200
		
		Gui %window%:Add, ActiveX, x%x% yp+265 w%width% h80 HWNDpedalCalibrationInfoTextHandle VpedalCalibrationInfoText Hidden, shell.explorer

		html := "<html><body style='background-color: #D0D0D0' style='overflow: auto' leftmargin='0' topmargin='0' rightmargin='0' bottommargin='0'>" . info . "</body></html>"

		pedalCalibrationInfoText.Navigate("about:blank")
		pedalCalibrationInfoText.Document.Write(html)
		
		this.setActionsListView(pedalCalibrationListViewHandle)
		
		this.registerWidgets(1, pedalCalibrationIconHandle, pedalCalibrationLabelHandle, pedalCalibrationListViewHandle, pedalCalibrationInfoTextHandle, columnLabel1Handle, columnLine1Handle, columnLabel2Handle, columnLine2Handle, throttleLabelHandle, throttleCheckHandle, brakeLabelHandle, brakeCheckHandle, clutchLabelHandle, clutchCheckHandle)
	}
	
	reset() {
		base.reset()
	
		this.iCachedActions := false
		this.iPedalsCheck := {}
	}
	
	hidePage(page) {
		wizard := this.SetupWizard
		
		if !wizard.isSoftwareInstalled("SmartControl") {
			OnMessage(0x44, Func("translateMsgBoxButtons").Bind(["Yes", "No"]))
			title := translate("Setup ")
			MsgBox 262436, %title%, % translate("Heusinkveld SmartControl cannot be found. Do you really want to proceed?")
			OnMessage(0x44, "")
			
			IfMsgBox No
				return false
		}
		
		return base.hidePage(page)
	}
	
	getModule() {
		return "Pedal Calibration"
	}
	
	getModes() {
		return ["Pedal Calibration"]
	}
	
	getActions() {
		if this.iCachedActions
			return this.iCachedActions
		else {
			wizard := this.SetupWizard
			
			actions := wizard.moduleAvailableActions("Pedal Calibration", "Pedal Calibration")
			
			if (actions.Length() == 0) {
				actions := []
		
				pedals := wizard.getModuleValue("Pedal Calibration", "Pedals", kUndefined)
				
				if (pedals == kUndefined)
					pedals := values2String("|", string2Values(",", getConfigurationValue(wizard.Definition, "Setup.Pedal Calibration", "Pedal Calibration.Pedals"))*)
				
				for ignore, pedal in string2Values("|", pedals)
					for ignore, curve in string2Values(",", getConfigurationValue(wizard.Definition, "Setup.Pedal Calibration", "Pedal Calibration.Curves"))
						actions.Push(pedal . "." . curve)
				
				wizard.setModuleAvailableActions("Pedal Calibration", "Pedal Calibration", actions)
			}
			
			this.iCachedActions := actions
			
			return actions
		}
	}
	
	loadActions(load := false) {
		local function
		local action
		local count
		
		window := this.Window
		wizard := this.SetupWizard
		
		if load {
			this.iCachedActions := false
			
			this.clearActionFunctions()
		}
		
		this.clearActions()
		
		Gui %window%:Default
		
		Gui ListView, % this.ActionsListView
		
		LV_Delete()
		
		count := 1
		lastPedal := false
		
		for ignore, action in this.getActions() {
			if wizard.moduleActionAvailable("Pedal Calibration", "Pedal Calibration", action) {
				if load {
					function := wizard.getModuleActionFunction("Pedal Calibration", "Pedal Calibration", action)
					
					if (function && (function != ""))
						this.setActionFunction("Pedal Calibration", action, (IsObject(function) ? function : Array(function)))
				}
				
				subAction := ConfigurationItem.splitDescriptor(action)
				
				label := (translate(subAction[1]) . " " . subAction[2])
				
				this.setAction(count, "Pedal Calibration", action, [false, "Activate"], label)
				
				function := this.getActionFunction("Pedal Calibration", action)
				
				if (function && (function != ""))
					function := (IsObject(function) ? function[1] : function)
				else
					function := ""
				
				action := ConfigurationItem.splitDescriptor(action)
				pedal := action[1]
				action := action[2]
				
				if (pedal != lastPedal) {
					lastPedal := pedal
					
					pedal := translate(pedal)
				}
				else
					pedal := ""
				
				LV_Add("", ((count = 1) ? translate("Pedal Calibration") : ""), pedal, action, label, function)
				
				count += 1
			}
		}
		
		this.loadButtonBoxLabels()
			
		LV_ModifyCol(1, "AutoHdr")
		LV_ModifyCol(2, "AutoHdr")
		LV_ModifyCol(3, "AutoHdr")
		LV_ModifyCol(4, "AutoHdr")
	}
	
	saveActions() {
		local function
		local action
		
		wizard := this.SetupWizard
		
		modeFunctions := {}
		
		for ignore, action in this.getActions() {
			if wizard.moduleActionAvailable("Pedal Calibration", "Pedal Calibration", action) {
				function := this.getActionFunction("Pedal Calibration", action)
				
				if (function && (function != ""))
					modeFunctions[action] := function
			}
		}
					
		wizard.setModuleActionFunctions("Pedal Calibration", "Pedal Calibration", modeFunctions)
	}
	
	updatePedals() {
		this.saveActions()
		
		wizard := this.SetupWizard
		pedals := []
		
		wizard.setModuleAvailableActions("Pedal Calibration", "Pedal Calibration", [])
		
		for ignore, pedal in string2Values(",", getConfigurationValue(wizard.Definition, "Setup.Pedal Calibration", "Pedal Calibration.Pedals")) {
			GuiControlGet checked, , % this.iPedalsCheck[pedal]
		
			if checked
				pedals.Push(pedal)
		}
		
		wizard.setModuleValue("Pedal Calibration", "Pedals", values2String("|", pedals*), false)
		
		this.loadActions(true)
	}
}


;;;-------------------------------------------------------------------------;;;
;;;                   Private Function Declaration Section                  ;;;
;;;-------------------------------------------------------------------------;;;

updatePedals() {
	SetupWizard.Instance.StepWizards["Pedal Calibration"].updatePedals()
}

updatePedalCalibrationActionFunction() {
	updateActionFunction(SetupWizard.Instance.StepWizards["Pedal Calibration"])
}

initializePedalCalibrationStepWizard() {
	SetupWizard.Instance.registerStepWizard(new PedalCalibrationStepWizard(SetupWizard.Instance, "Pedal Calibration", kSimulatorConfiguration))
}


;;;-------------------------------------------------------------------------;;;
;;;                         Initialization Section                          ;;;
;;;-------------------------------------------------------------------------;;;

initializePedalCalibrationStepWizard()