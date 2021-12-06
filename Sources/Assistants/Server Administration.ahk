﻿;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   Modular Simulator Controller System - Server Administration Tool      ;;;
;;;                                                                         ;;;
;;;   Author:     Oliver Juwig (TheBigO)                                    ;;;
;;;   License:    (2021) Creative Commons - BY-NC-SA                        ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;-------------------------------------------------------------------------;;;
;;;                       Global Declaration Section                        ;;;
;;;-------------------------------------------------------------------------;;;

#SingleInstance Force			; Ony one instance allowed
#NoEnv							; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn							; Enable warnings to assist with detecting common errors.
#Warn LocalSameAsGlobal, Off

SendMode Input					; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%		; Ensures a consistent starting directory.

SetBatchLines -1				; Maximize CPU utilization
ListLines Off					; Disable execution history

;@Ahk2Exe-SetMainIcon ..\..\Resources\Icons\Server Administration.ico
;@Ahk2Exe-ExeName Server Administration.exe


;;;-------------------------------------------------------------------------;;;
;;;                         Global Include Section                          ;;;
;;;-------------------------------------------------------------------------;;;

#Include ..\Includes\Includes.ahk


;;;-------------------------------------------------------------------------;;;
;;;                         Local Include Section                           ;;;
;;;-------------------------------------------------------------------------;;;

#Include ..\Libraries\CLR.ahk


;;;-------------------------------------------------------------------------;;;
;;;                   Private Constant Declaration Section                  ;;;
;;;-------------------------------------------------------------------------;;;

global kClose = "Close"
global kConnect = "Connect"
global kEvent = "Event"


;;;-------------------------------------------------------------------------;;;
;;;                        Private Variable Section                         ;;;
;;;-------------------------------------------------------------------------;;;

global vToken := false

	
;;;-------------------------------------------------------------------------;;;
;;;                   Private Function Declaration Section                  ;;;
;;;-------------------------------------------------------------------------;;;

setButtonIcon(buttonHandle, file, index := 1, options := "") {
;   Parameters:
;   1) {Handle} 	HWND handle of Gui button
;   2) {File} 		File containing icon image
;   3) {Index} 		Index of icon in file
;						Optional: Default = 1
;   4) {Options}	Single letter flag followed by a number with multiple options delimited by a space
;						W = Width of Icon (default = 16)
;						H = Height of Icon (default = 16)
;						S = Size of Icon, Makes Width and Height both equal to Size
;						L = Left Margin
;						T = Top Margin
;						R = Right Margin
;						B = Botton Margin
;						A = Alignment (0 = left, 1 = right, 2 = top, 3 = bottom, 4 = center; default = 4)

	RegExMatch(options, "i)w\K\d+", W), (W="") ? W := 16 :
	RegExMatch(options, "i)h\K\d+", H), (H="") ? H := 16 :
	RegExMatch(options, "i)s\K\d+", S), S ? W := H := S :
	RegExMatch(options, "i)l\K\d+", L), (L="") ? L := 0 :
	RegExMatch(options, "i)t\K\d+", T), (T="") ? T := 0 :
	RegExMatch(options, "i)r\K\d+", R), (R="") ? R := 0 :
	RegExMatch(options, "i)b\K\d+", B), (B="") ? B := 0 :
	RegExMatch(options, "i)a\K\d+", A), (A="") ? A := 4 :

	ptrSize := A_PtrSize = "" ? 4 : A_PtrSize, DW := "UInt", Ptr := A_PtrSize = "" ? DW : "Ptr"

	VarSetCapacity(button_il, 20 + ptrSize, 0)

	NumPut(normal_il := DllCall("ImageList_Create", DW, W, DW, H, DW, 0x21, DW, 1, DW, 1), button_il, 0, Ptr)	; Width & Height
	NumPut(L, button_il, 0 + ptrSize, DW)		; Left Margin
	NumPut(T, button_il, 4 + ptrSize, DW)		; Top Margin
	NumPut(R, button_il, 8 + ptrSize, DW)		; Right Margin
	NumPut(B, button_il, 12 + ptrSize, DW)		; Bottom Margin	
	NumPut(A, button_il, 16 + ptrSize, DW)		; Alignment

	SendMessage, BCM_SETIMAGELIST := 5634, 0, &button_il,, AHK_ID %buttonHandle%

	return IL_Add(normal_il, file, index)
}

generatePassword(length) {
	valid = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"
	result := ""
	
	while (0 < length--) {
		Random index, 1, % StrLen(valid)
	
		result .= SubStr(valid, Round(index), 1)
	}
            
	return result
}

parseObject(properties) {
	result := {}
	
	properties := StrReplace(properties, "`r", "")
	
	Loop Parse, properties, `n
	{
		property := string2Values("=", A_LoopField)
		
		result[property[1]] := property[2]
	}
	
	return result
}

loadAccounts(connector, listView) {
	accounts := {}
	
	Gui ListView, % listView
	
	LV_Delete()
	
	if vToken {
		for ignore, identifier in string2Values(";", connector.GetAllAccounts()) {
			account := parseObject(connector.GetAccount(identifier))
		
			accounts[A_Index] := account
			accounts[account.Name] := account
			
			index := inList(["Expired", "OneTime", "FixedMinutes", "AdditionalMinutes"], account.Contract)
			
			LV_Add("", account.Name, account.EMail, translate(["Expired", "One-Time", "Fixed", "Additional"][index]) . translate(" (") . account.ContractMinutes . translate(")"), account.AvailableMinutes)
		}
	}
	
	LV_ModifyCol()
	LV_ModifyCol(1, "AutoHdr")
	LV_ModifyCol(2, "AutoHdr")
	LV_ModifyCol(3, "AutoHdr")
	LV_ModifyCol(4, "AutoHdr")
	LV_ModifyCol(5, "AutoHdr")
	
	return accounts
}

updateTask(connector, tasks, task, which, operation, frequency) {
	if operation is integer
		operation := ["Delete", "Cleanup", "Reset", "Renew"][operation],
	
	if frequency is integer
		frequency := ["Never", "Daily", "Weekly", "Monthly"][frequency]
	
	if (frequency = "Never") {
		if task {
			connector.DeleteTask(task)
			
			tasks.Delete(which)
		}
	}
	else if task
		connector.UpdateTask(task, operation, frequency, true)
	else
		tasks[which] := connector.CreateTask(which, operation, frequency)
	
	return tasks
}

global teamServerNameEdit = ""
global teamServerPasswordEdit = ""
	
administrationEditor(configurationOrCommand, arguments*) {
	static connector := false
	static done := false
	static accounts := {}
	static tasks := {}
	static account := false
	
	static teamServerURLEdit = "https://localhost:5001"
	static changePasswordButton
	static teamServerTokenEdit = ""
	static accountsListView

	static accountNameEdit
	static accountEMailEdit
	static accountPasswordEdit
	static accountContractDropDown
	static accountMinutesEdit
	
	static createPasswordButton
	static copyPasswordButton
	static availableMinutesButton
	
	static taskTokenOperationDropDown
	static taskTokenFrequencyDropDown
	static taskSessionOperationDropDown
	static taskSessionFrequencyDropDown
	static taskAccountOperationDropDown
	static taskAccountFrequencyDropDown
	
	static addAccountButton
	static deleteAccountButton
	static saveAccountButton
	
	if (configurationOrCommand == kClose)
		done := true
	else if (configurationOrCommand == kConnect) {
		GuiControlGet teamServerURLEdit
		GuiControlGet teamServerNameEdit
		GuiControlGet teamServerPasswordEdit
		
		try {
			connector.Connect(teamServerURLEdit)
			vToken := connector.Login(teamServerNameEdit, teamServerPasswordEdit)
		
			if (vToken = "")
				vToken := false
			
			if vToken {
				accounts := loadAccounts(connector, accountsListView)
				
				administrationEditor(kEvent, "TasksLoad")
				administrationEditor(kEvent, "AccountClear")
			
				GuiControl, , teamServerTokenEdit, % vToken
			
				showMessage(translate("Successfully connected to the Team Server."))
			}
		}
		catch exception {
			vToken := false
			
			GuiControl, , teamServerTokenEdit, % ""
			
			accounts := loadAccounts(connector, accountsListView)
			account := false
		
			administrationEditor(kEvent, "TasksReset")
			administrationEditor(kEvent, "AccountClear")
			
			title := translate("Error")
		
			OnMessage(0x44, Func("translateMsgBoxButtons").Bind(["Ok"]))
			MsgBox 262160, %title%, % (translate("Cannot connect to the Team Server.") . "`n`n" . translate("Error: ") . exception.Message)
			OnMessage(0x44, "")
		}
	}
	else if (configurationOrCommand == kEvent) {
		try {
			if (arguments[1] = "TasksReset") {
				 GuiControl Choose, taskTokenOperationDropDown, 1
				 GuiControl Choose, taskTokenFrequencyDropDown, 1
				 GuiControl Choose, taskSessionOperationDropDown, 3
				 GuiControl Choose, taskSessionFrequencyDropDown, 1
				 GuiControl Choose, taskAccountOperationDropDown, 1
				 GuiControl Choose, taskAccountFrequencyDropDown, 1
			}
			else if (arguments[1] = "TasksLoad") {
				administrationEditor(kEvent, "TasksReset")
			
				tasks := {}
				
				for ignore, identifier in string2Values(";", connector.GetAllTasks()) {
					task := parseObject(connector.GetTask(identifier))

					tasks[task.Which] := task.Identifier
					
					if (task.Which = "Token") {
						GuiControl Choose, taskTokenOperationDropDown, % inList(["Delete", "Cleanup", "Reset", "Renew"], task.What)
						GuiControl Choose, taskTokenFrequencyDropDown, % inList(["Never", "Daily", "Weekly", "Monthly"], task.When)
					}
					else if (task.Which = "Session") {
						GuiControl Choose, taskSessionOperationDropDown, % inList(["Delete", "Cleanup", "Reset", "Renew"], task.What)
						GuiControl Choose, taskSessionFrequencyDropDown, % inList(["Never", "Daily", "Weekly", "Monthly"], task.When)
					}
					else if (task.Which = "Account") {
						GuiControl Choose, taskAccountOperationDropDown, % inList(["Delete", "Cleanup", "Reset", "Renew"], task.What) - 3
						GuiControl Choose, taskAccountFrequencyDropDown, % inList(["Never", "Daily", "Weekly", "Monthly"], task.When)
					}
				}
			}
			else if (arguments[1] = "TaskUpdate") {
				which := arguments[2]
			
				task := (tasks.HasKey(which) ? tasks[which] : false)
				
				switch which {
					case "Token":
						GuiControlGet taskTokenOperationDropDown
						GuiControlGet taskTokenFrequencyDropDown
				
						tasks := updateTask(connector, tasks, task, which, taskTokenOperationDropDown, taskTokenFrequencyDropDown)
					case "Session":
						GuiControlGet taskSessionOperationDropDown
						GuiControlGet taskSessionFrequencyDropDown
				
						tasks := updateTask(connector, tasks, task, which, taskSessionOperationDropDown, taskSessionFrequencyDropDown)
					case "Account":
						GuiControlGet taskAccountOperationDropDown
						GuiControlGet taskAccountFrequencyDropDown
				
						tasks := updateTask(connector, tasks, task, which, taskAccountOperationDropDown + 3, taskAccountFrequencyDropDown)
				}
			}
			else if (arguments[1] = "PasswordChange") {
				connector.ChangePassword(arguments[2])
				
				GuiControl, , teamServerPasswordEdit, % arguments[2]
			}
			else if (arguments[1] = "AccountLoad") {
				account := accounts[arguments[2]]
			
				GuiControl, , accountNameEdit, % account.Name
				GuiControl, , accountEMailEdit, % account.EMail
				GuiControl, , accountPasswordEdit, % ""
				GuiControl Choose, accountContractDropDown, % inList(["Expired", "OneTime", "FixedMinutes", "AdditionalMinutes"], account.Contract)
				GuiControl, , accountMinutesEdit, % account.ContractMinutes
				
				administrationEditor(kEvent, "UpdateState")
			}
			else if (arguments[1] = "AccountNew") {
				administrationEditor(kEvent, "AccountClear")
			
				GuiControl Choose, accountContractDropDown, 2
				GuiControl, , accountMinutesEdit, 120
				
				account := true
				
				administrationEditor(kEvent, "UpdateState")
			}
			else if (arguments[1] = "AccountSave") {
				GuiControlGet accountNameEdit
				GuiControlGet accountEMailEdit
				GuiControlGet accountPasswordEdit
				GuiControlGet accountContractDropDown
				GuiControlGet accountMinutesEdit
				
				contract := ["Expired", "OneTime", "FixedMinutes", "AdditionalMinutes"][accountContractDropDown]
					
				if (account == true) {
					connector.CreateAccount(accountNameEdit, accountEMailEdit, accountPasswordEdit
										  , accountMinutesEdit, contract, accountMinutesEdit)
				}
				else {
					if (accountPasswordEdit != "")
						connector.ChangeAccountPassword(account.Identifier, accountPasswordEdit)
					
					if ((account.Contract != contract) || (account.ContractMinutes != accountMinutesEdit))
						connector.ChangeAccountContract(account.Identifier, contract, accountMinutesEdit)
					
					if (accountEMailEdit != account.EMail)
						connector.ChangeAccountEMail(account.Identifier, accountEMailEdit)
				}
				
				accounts := loadAccounts(connector, accountsListView)
				
				administrationEditor(kEvent, "AccountClear")
			}
			else if (arguments[1] = "AccountClear") {
				account := false
			
				GuiControl, , accountNameEdit, % ""
				GuiControl, , accountEMailEdit, % ""
				GuiControl, , accountPasswordEdit, % ""
				GuiControl Choose, accountContractDropDown, 0
				GuiControl, , accountMinutesEdit, % ""
				
				administrationEditor(kEvent, "UpdateState")
			}
			else if (arguments[1] = "UpdateAvailableMinutes") {
				title := translate("Team Server")
				prompt := translate("Please enter the amount of available minutes:")
				
				locale := ((getLanguage() = "en") ? "" : "Locale")
				minutes := account.AvailableMinutes
				
				InputBox minutes, %title%, %prompt%, , 200, 150, , , %locale%, , %minutes%
				
				if !ErrorLevel
				{
					connector.SetAccountMinutes(account.Identifier, minutes)
					
					accounts := loadAccounts(connector, accountsListView)
				
					administrationEditor(kEvent, "AccountClear")
				}
			}
			else if (arguments[1] = "UpdateState") {
				GuiControl Disable, copyPasswordButton
			
				if vToken {
					GuiControl Enable, changePasswordButton
					GuiControl Enable, addAccountButton
					
					GuiControl Enable, taskTokenOperationDropDown
					GuiControl Enable, taskTokenFrequencyDropDown
					GuiControl Enable, taskSessionOperationDropDown
					GuiControl Enable, taskSessionFrequencyDropDown
					GuiControl Enable, taskAccountOperationDropDown
					GuiControl Enable, taskAccountFrequencyDropDown
				}
				else {
					GuiControl Disable, changePasswordButton
					GuiControl Disable, addAccountButton
					
					GuiControl Disable, taskTokenOperationDropDown
					GuiControl Disable, taskTokenFrequencyDropDown
					GuiControl Disable, taskSessionOperationDropDown
					GuiControl Disable, taskSessionFrequencyDropDown
					GuiControl Disable, taskAccountOperationDropDown
					GuiControl Disable, taskAccountFrequencyDropDown
				}
				
				if account {
					GuiControlGet accountContractDropDown
					
					if (account == true)
						GuiControl Enable, accountNameEdit
					else
						GuiControl Disable, accountNameEdit
					
					GuiControl Enable, accountEMailEdit
					GuiControl Enable, accountPasswordEdit
					GuiControl Enable, accountContractDropDown
					
					if (accountContractDropDown > 1) {
						GuiControl Enable, availableMinutesButton
						GuiControl Enable, accountMinutesEdit
					}
					else {
						GuiControl Disable, availableMinutesButton
						GuiControl Disable, accountMinutesEdit
					}
					
					GuiControl Enable, createPasswordButton
					
					GuiControl Enable, deleteAccountButton
					GuiControl Enable, saveAccountButton
				}
				else {
					GuiControl Disable, accountNameEdit
					GuiControl Disable, accountEMailEdit
					GuiControl Disable, accountPasswordEdit
					GuiControl Disable, accountContractDropDown
					GuiControl Disable, accountMinutesEdit
					
					GuiControl Disable, createPasswordButton
					GuiControl Disable, availableMinutesButton
						
					GuiControl Disable, deleteAccountButton
					GuiControl Disable, saveAccountButton
				}
			}
			else if (arguments[1] = "PasswordCreate") {
				GuiControl Enable, copyPasswordButton
			
				GuiControl Text, accountPasswordEdit, % generatePassword(20)
			}
			else if (arguments[1] = "PasswordCopy") {
				GuiControlGet accountPasswordEdit
		
				if (accountPasswordEdit && (accountPasswordEdit != "")) {
					Clipboard := accountPasswordEdit
					
					showMessage(translate("Password copied to the clipboard."))
				}
			}
		}
		catch exception {
			title := translate("Error")
		
			OnMessage(0x44, Func("translateMsgBoxButtons").Bind(["Ok"]))
			MsgBox 262160, %title%, % (translate("Error while executing command.") . "`n`n" . translate("Error: ") . exception.Message)
			OnMessage(0x44, "")
		}
	}
	else {
		dllName := "Team Server Connector.dll"
		dllFile := kBinariesDirectory . dllName
		
		try {
			if (!FileExist(dllFile)) {
				logMessage(kLogCritical, translate("Team Server Connector.dll not found in ") . kBinariesDirectory)
				
				Throw "Unable to find Team Server Connector.dll in " . kBinariesDirectory . "..."
			}

			connector := CLR_LoadLibrary(dllFile).CreateInstance("TeamServer.TeamServerConnector")
		}
		catch exception {
			logMessage(kLogCritical, translate("Error while initializing Team Server Connector - please rebuild the applications"))
			
			showMessage(translate("Error while initializing Team Server Connector - please rebuild the applications") . translate("...")
					  , translate("Modular Simulator Controller System"), "Alert.png", 5000, "Center", "Bottom", 800)
		}
	
		Gui ADM:Default
			
		Gui ADM:-Border ; -Caption
		Gui ADM:Color, D0D0D0, D8D8D8

		Gui ADM:Font, Bold, Arial

		Gui ADM:Add, Text, w388 Center gmoveAdministrationEditor, % translate("Modular Simulator Controller System") 

		Gui ADM:Font, Norm, Arial
		Gui ADM:Font, Italic Underline, Arial

		Gui ADM:Add, Text, YP+20 w388 cBlue Center gopenAdministrationDocumentation, % translate("Server Administration")
		
		Gui ADM:Add, Text, x24 yp+30 w356 0x10

		Gui ADM:Font, Norm, Arial
				
		Gui ADM:Add, Button, x164 y450 w80 h23 gcloseAdministrationEditor, % translate("Close")
		
		x := 8
		y := 68
		width := 388
		
		x0 := x + 8
		x1 := x + 132
		
		w1 := width - (x1 - x + 8)
		
		w2 := w1 - 70
		
		x2 := x + 172
		
		x2 := x1 - 25
		
		w4 := w1 - 25
		x4 := x1 + w4 + 2
		
		w3 := Round((w4 / 2) - 3)
		x3 := x1 + w3 + 6
		
		x4 := x3 + 64
		
		x5 := x3 + w3 + 2
		w5 := w3 - 25
		
		Gui ADM:Add, Text, x%x0% y%y% w90 h23 +0x200, % translate("Server URL")
		Gui ADM:Add, Edit, x%x1% yp+1 w%w4% h21 VteamServerURLEdit, %teamServerURLEdit%
		
		Gui ADM:Add, Text, x%x0% yp+23 w90 h23 +0x200, % translate("Login Credentials")
		Gui ADM:Add, Edit, x%x1% yp+1 w%w3% h21 HWNDloginHandle VteamServerNameEdit, %teamServerNameEdit%
		Gui ADM:Add, Edit, x%x3% yp w%w3% h21 Password VteamServerPasswordEdit, %teamServerPasswordEdit%
		Gui ADM:Add, Button, x%x5% yp-1 w23 h23 Center +0x200 HWNDchangePasswordButtonHandle vchangePasswordButton gchangePassword
		setButtonIcon(changePasswordButtonHandle, kIconsDirectory . "Pencil.ico", 1, "L4 T4 R4 B4")
		
		Gui ADM:Add, Text, x%x0% yp+26 w90 h23 +0x200, % translate("Access Token")
		Gui ADM:Add, Edit, x%x1% yp-1 w%w4% h21 ReadOnly VteamServerTokenEdit, %teamServerTokenEdit%
		Gui ADM:Add, Button, x%x2% yp-1 w23 h23 Default Center +0x200 HWNDconnectButton grenewToken
		setButtonIcon(connectButton, kIconsDirectory . "Authorize.ico", 1, "L4 T4 R4 B4")

		Gui ADM:Add, Tab3, x8 y148 w388 h293 -Wrap, % values2String("|", map(["Accounts", "Jobs"], "translate")*)
		
		x0 := 16
		y := 178
		
		Gui Tab, 1
		
		Gui ADM:Add, ListView, x%x0% y%y% w372 h120 -Multi -LV0x10 AltSubmit NoSort NoSortHdr HWNDaccountsListView gaccountsListEvent, % values2String("|", map(["Account", "eMail", "Kontingent", "Available"], "translate")*)
		
		Gui ADM:Add, Text, x%x0% yp+124 w90 h23 +0x200, % translate("Name")
		Gui ADM:Add, Edit, x%x1% yp+1 w%w3% vaccountNameEdit
		
		Gui ADM:Add, Text, x%x0% yp+24 w90 h23 +0x200, % translate("Password")
		Gui ADM:Add, Edit, x%x1% yp+1 w%w4% ReadOnly Password vaccountPasswordEdit
		Gui ADM:Add, Button, x%x2% yp-1 w23 h23 Center +0x200 HWNDcreatePasswordButtonHandle vcreatePasswordButton gcreatePassword
		setButtonIcon(createPasswordButtonHandle, kIconsDirectory . "Authorize.ico", 1, "L4 T4 R4 B4")
		Gui ADM:Add, Button, x%x5% yp w23 h23 Center +0x200 HWNDcopyPasswordButtonHandle vcopyPasswordButton
		setButtonIcon(copyPasswordButtonHandle, kIconsDirectory . "Copy.ico", 1, "L4 T4 R4 B4")
		
		Gui ADM:Add, Text, x%x0% yp+24 w90 h23 +0x200, % translate("E-Mail")
		Gui ADM:Add, Edit, x%x1% yp+1 w%w4%  vaccountEMailEdit
		
		Gui ADM:Add, Text, x%x0% yp+24 w90 h23 +0x200, % translate("Contingent")
		Gui ADM:Add, DropDownList, x%x1% yp+1 w%w3% AltSubmit Choose2 vaccountContractDropDown gupdateContract, % values2String("|", map(["Expired", "One-Time", "Monthly Fixed", "Monthly Additional"], "translate")*)
		Gui ADM:Add, Edit, x%x3% yp w60 h21  vaccountMinutesEdit
		Gui ADM:Add, Text, x%x4% yp w90 h23 +0x200, % translate("Minutes")
		Gui ADM:Add, Button, x%x2% yp-1 w23 h23 Center +0x200 HWNDavailableMinutesButtonHandle vavailableMinutesButton gupdateAvailableMinutes
		setButtonIcon(availableMinutesButtonHandle, kIconsDirectory . "Watch.ico", 1, "L4 T4 R4 B4")
		
		x5 := x4 - 1
		x6 := x5 + 24
		x7 := x6 + 24
		
		Gui ADM:Add, Button, x%x5% yp+30 w23 h23 Center +0x200 gnewAccount HWNDaddAccountButtonHandle vaddAccountButton
		setButtonIcon(addAccountButtonHandle, kIconsDirectory . "Plus.ico", 1, "L4 T4 R4 B4")
		Gui ADM:Add, Button, x%x6% yp w23 h23 Center +0x200 gdeleteAccount HWNDdeleteAccountButtonHandle vdeleteAccountButton
		setButtonIcon(deleteAccountButtonHandle, kIconsDirectory . "Minus.ico", 1, "L4 T4 R4 B4")
		Gui ADM:Add, Button, x%x7% yp w23 h23 Center +0x200 gsaveAccount HWNDsaveAccountButtonHandle vsaveAccountButton
		setButtonIcon(saveAccountButtonHandle, kIconsDirectory . "Save.ico", 1, "L5 T5 R5 B5")
		
		Gui Tab, 2
		
		Gui ADM:Add, Text, x%x0% y%y% w120 h23 +0x200, % translate("Expired Tokens")
		Gui ADM:Add, DropDownList, x%x1% yp+1 w%w3% AltSubmit Choose1 vtaskTokenOperationDropDown gupdateTokenTask, % values2String("|", map(["Delete"], "translate")*)
		Gui ADM:Add, DropDownList, x%x3% yp+1 w%w3% AltSubmit Choose1 vtaskTokenFrequencyDropDown gupdateTokenTask, % values2String("|", map(["Never", "Daily", "Weekly"], "translate")*)
		
		Gui ADM:Add, Text, x%x0% yp+23 w120 h23 +0x200, % translate("Finished Sessions")
		Gui ADM:Add, DropDownList, x%x1% yp+1 w%w3% AltSubmit Choose3 vtaskSessionOperationDropDown gupdateSessionTask, % values2String("|", map(["Delete", "Cleanup", "Reset"], "translate")*)
		Gui ADM:Add, DropDownList, x%x3% yp+1 w%w3% AltSubmit Choose1 vtaskSessionFrequencyDropDown gupdateSessionTask, % values2String("|", map(["Never", "Daily", "Weekly"], "translate")*)
		
		Gui ADM:Add, Text, x%x0% yp+23 w120 h23 +0x200, % translate("Account Contingents")
		Gui ADM:Add, DropDownList, x%x1% yp+1 w%w3% AltSubmit Choose1 vtaskAccountOperationDropDown gupdateAccountTask, % values2String("|", map(["Renew"], "translate")*)
		Gui ADM:Add, DropDownList, x%x3% yp+1 w%w3% AltSubmit Choose1 vtaskAccountFrequencyDropDown gupdateAccountTask, % values2String("|", map(["Never", "Daily", "Weekly", "1st of Month"], "translate")*)
		
		Gui ADM:Show, AutoSize Center
		
		ControlFocus, , ahk_id %loginHandle%
		
		administrationEditor(kEvent, "AccountClear")
		
		Loop {
			Sleep 1000
		} until done
	}
}

moveAdministrationEditor() {
	moveByMouse("ADM")
}

closeAdministrationEditor() {
	administrationEditor(kClose)
}

openAdministrationDocumentation() {
	Run https://github.com/SeriousOldMan/Simulator-Controller/wiki/Team-Server#server-administration
}

renewToken() {
	administrationEditor(kConnect)
}

changePassword() {
	errorTitle := translate("Error")
	
	if vToken {
		title := translate("Team Server")
		prompt := translate("Please enter your current password:")
		
		Gui ADM:Default
		
		GuiControlGet teamServerNameEdit
		GuiControlGet teamServerPasswordEdit
		
		locale := ((getLanguage() = "en") ? "" : "Locale")
		
		InputBox password, %title%, %prompt%, Hide, 200, 150, , , %locale%
		
		if ErrorLevel
			return

		if (teamServerPasswordEdit != password) {
			OnMessage(0x44, Func("translateMsgBoxButtons").Bind(["Ok"]))
			MsgBox 262160, %errorTitle%, % translate("Invalid password.")
			OnMessage(0x44, "")
			
			return
		}
		
		prompt := translate("Please enter your new password:")
		
		InputBox firstPassword, %title%, %prompt%, Hide, 200, 150, , , %locale%
		
		if ErrorLevel
			return
		
		prompt := translate("Please re-enter your new password:")
		
		InputBox secondPassword, %title%, %prompt%, Hide, 200, 150, , , %locale%
		
		if ErrorLevel
			return
		
		if (firstPassword != secondPassword) {
			OnMessage(0x44, Func("translateMsgBoxButtons").Bind(["Ok"]))
			MsgBox 262160, %errorTitle%, % translate("The passwords do not match.")
			OnMessage(0x44, "")
			
			return
		}
		
		administrationEditor(kEvent, "PasswordChange", firstPassword)
	}
	else {
		OnMessage(0x44, Func("translateMsgBoxButtons").Bind(["Ok"]))
		MsgBox 262160, %errorTitle%, % translate("You must be connected to the Team Server to change your password.")
		OnMessage(0x44, "")
	}
}

updateAvailableMinutes() {
	administrationEditor(kEvent, "UpdateAvailableMinutes")
}

accountsListEvent() {
	if ((A_GuiEvent == "DoubleClick") || (A_GuiEvent == "Normal"))
		administrationEditor(kEvent, "AccountLoad", A_EventInfo)
}

createPassword() {
	administrationEditor(kEvent, "PasswordCreate")
}

copyPassword() {
	administrationEditor(kEvent, "PasswordCopy")
}

updateContract() {
	administrationEditor(kEvent, "UpdateState")
}

newAccount() {
	administrationEditor(kEvent, "AccountNew")
}

deleteAccount() {
}

saveAccount() {
	administrationEditor(kEvent, "AccountSave")
}

updateTokenTask() {
	administrationEditor(kEvent, "TaskUpdate", "Token")
}

updateSessionTask() {
	administrationEditor(kEvent, "TaskUpdate", "Session")
}

updateAccountTask() {
	administrationEditor(kEvent, "TaskUpdate", "Account")
}

startupServerAdministration() {
	icon := kIconsDirectory . "Server Administration.ico"
	
	Menu Tray, Icon, %icon%, , 1
	Menu Tray, Tip, Server Administration
	
	administrationEditor(kSimulatorConfiguration)
	
	ExitApp 0
}


;;;-------------------------------------------------------------------------;;;
;;;                          Initialization Section                         ;;;
;;;-------------------------------------------------------------------------;;;

startupServerAdministration()