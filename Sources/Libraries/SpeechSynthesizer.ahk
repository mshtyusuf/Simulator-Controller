﻿;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   Modular Simulator Controller System - Speech Synthesizer              ;;;
;;;                                                                         ;;;
;;;   Part of this code is based on work of evilC and Learning one.         ;;;
;;;   See www.autohotkey.com/forum/topic57773.html and                      ;;;
;;;   https://www.autohotkey.com/boards/viewtopic.php?t=71363 and also      ;;;
;;;   http://msdn.microsoft.com/en-us/library/ms717077(v=vs.85).aspx        ;;;
;;;   for more information about the technical details.                     ;;;
;;;                                                                         ;;;
;;;   Author:     Oliver Juwig (TheBigO)                                    ;;;
;;;   License:    (2023) Creative Commons - BY-NC-SA                        ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;-------------------------------------------------------------------------;;;
;;;                         Global Include Section                          ;;;
;;;-------------------------------------------------------------------------;;;

#Include "..\Framework\Framework.ahk"


;;;-------------------------------------------------------------------------;;;
;;;                         Local Include Section                           ;;;
;;;-------------------------------------------------------------------------;;;

#Include "..\Libraries\Task.ahk"
#Include "..\Libraries\CLR.ahk"


;;;-------------------------------------------------------------------------;;;
;;;                        Private Constant Section                         ;;;
;;;-------------------------------------------------------------------------;;;

global kAzureVoices := Map("de", [["de-AT", "de-AT-IngridNeural"], ["de-AT", "de-AT-JonasNeural"]
								, ["de-DE", "de-DE-KatjaNeural"], ["de-DE", "de-DE-ConradNeural"]
								, ["de-CH", "de-CH-LeniNeural"], ["de-CH", "de-CH-JanNeural"]]
						 , "en", [["en-AU", "en-AU-NatashaNeural"], ["en-AU", "en-AU-WilliamNeural"]
								, ["en-CA", "en-CA-ClaraNeural"], ["en-CA", "en-CA-LiamNeural"]
								, ["en-HK", "en-HK-YanNeural Neu"], ["en-HK", "en-HK-SamNeural Neu"]
								, ["en-IN", "en-IN-NeerjaNeural"], ["en-IN", "en-IN-PrabhatNeural"]
								, ["en-GB", "en-GB-LibbyNeural"], ["en-GB", "en-GB-MiaNeural"], ["en-GB", "en-GB-RyanNeural"]
								, ["en-US", "en-US-AriaNeural"], ["en-US", "en-US-JennyNeural"], ["en-US", "en-US-GuyNeural"]])


;;;-------------------------------------------------------------------------;;;
;;;                          Public Class Section                           ;;;
;;;-------------------------------------------------------------------------;;;

class SpeechSynthesizer {
	iSynthesizer := "Windows"
	iVoices := []

	iLanguage := ""
	iLocale := ""
	iVoice := ""

	iRate := 0
	iPitch := 0
	iVolume := 100

	iCache := CaseInsenseMap()
	iCacheDirectory := false

	static sAudioRoutingInitialized := false

	static sAudioDriver := false
	static sAudioDevice := false

	iSoundPlayer := false
	iSoundPlayerLevel := 1.0
	iPlaysCacheFile := false

	iSpeechStatusCallback := false

	Synthesizer {
		Get {
			return this.iSynthesizer
		}
	}

	Routing {
		Get {
			return "Standard"
		}
	}

	Voices[language := false] {
		Get {
			local voices, voice, lcid, ignore, candidate, name

			if !language
				return this.iVoices
			else {
				voices := []

				if (this.Synthesizer = "Windows") {
					loop this.iSpeechSynthesizer.GetVoices.Count {
						voice := this.iSpeechSynthesizer.GetVoices.Item(A_Index - 1)
						lcid := voice.GetAttribute("Language")

						if (getLanguageFromLCID(lcid) = language)
							voices.Push(voice.GetAttribute("Name"))
					}
				}
				else if ((this.Synthesizer = "dotNET") || (this.Synthesizer = "Azure")) {
					for ignore, candidate in this.iVoices {
						name := string2Values("(", candidate)

						if (InStr(name[2], language) == 1)
							voices.Push(candidate)
					}
				}

				return voices
			}
		}
	}

	Language {
		Get {
			return this.iLanguage
		}
	}

	Awaitable {
		Get {
			return (kSox != false)
		}
	}

	Stoppable {
		Get {
			return true
		}
	}

	Locale {
		Get {
			return this.iLocale
		}
	}

	Voice {
		Get {
			return this.iVoice
		}
	}

	Speaking {
		Get {
			return this.isSpeaking()
		}
	}

	SpeechStatusCallback {
		Get {
			return this.iSpeechStatusCallback
		}

		Set {
			return (this.iSpeechStatusCallback := value)
		}
	}

	__New(synthesizer, voice := false, language := false) {
		local dllName, dllFile, voices, languageCode, voiceInfos, ignore, voiceInfo, dirName
		local player, copied, configuration

		dirName := ("PhraseCache." . StrSplit(A_ScriptName, ".")[1] . "." . kVersion)

		DirCreate(kTempDirectory . dirName)

		this.iCacheDirectory := (kTempDirectory . dirName . "\")

		this.clearCache()

		OnExit(ObjBindMethod(this, "clearCache"))

		if (synthesizer = "Windows") {
			this.iSynthesizer := "Windows"
			this.iSpeechSynthesizer := ComObject("SAPI.SpVoice")

			loop this.iSpeechSynthesizer.GetVoices.Count
				this.Voices.Push(this.iSpeechSynthesizer.GetVoices.Item(A_Index - 1).GetAttribute("Name"))

			this.setVoice(language, this.computeVoice(voice, language))
		}
		else if (synthesizer = "dotNET") {
			this.iSynthesizer := "dotNET"

			dllName := "Speech.Synthesizer.dll"
			dllFile := kBinariesDirectory . dllName

			try {
				if (!FileExist(dllFile)) {
					logMessage(kLogCritical, translate("Speech.Synthesizer.dll not found in ") . kBinariesDirectory)

					throw "Unable to find Speech.Synthesizer.dll in " . kBinariesDirectory . "..."
				}

				this.iSpeechSynthesizer := CLR_LoadLibrary(dllFile).CreateInstance("Speech.SpeechSynthesizer")

				voices := this.iSpeechSynthesizer.GetVoices()
			}
			catch Any as exception {
				logMessage(kLogCritical, translate("Error while initializing speech synthesizer module - please install the speech synthesizer software"))

				showMessage(translate("Error while initializing speech synthesizer module - please install the speech synthesizer software") . translate("...")
									, translate("Modular Simulator Controller System"), "Alert.png", 5000, "Center", "Bottom", 800)

				voices := ""
			}

			this.iVoices := string2Values("|", voices)

			this.setVoice(language, this.computeVoice(voice, language))
		}
		else if (InStr(synthesizer, "Azure|") == 1) {
			this.iSynthesizer := "Azure"

			dllName := "Speech.Synthesizer.dll"
			dllFile := kBinariesDirectory . dllName

			try {
				if (!FileExist(dllFile)) {
					logMessage(kLogCritical, translate("Speech.Synthesizer.dll not found in ") . kBinariesDirectory)

					throw "Unable to find Speech.Synthesizer.dll in " . kBinariesDirectory . "..."
				}

				this.iSpeechSynthesizer := CLR_LoadLibrary(dllFile).CreateInstance("Speech.SpeechSynthesizer")

				synthesizer := string2Values("|", synthesizer)

				if !this.iSpeechSynthesizer.Connect(synthesizer[2], synthesizer[3]) {
					logMessage(kLogCritical, translate("Could not communicate with speech synthesizer library (") . dllName . translate(")"))
					logMessage(kLogCritical, translate("Try running the Powershell command `"Get-ChildItem -Path '.' -Recurse | Unblock-File`" in the Binaries folder"))

					throw "Could not communicate with speech synthesizer library (" . dllName . ")..."
				}

				voices := this.iSpeechSynthesizer.GetVoices()
			}
			catch Any as exception {
				logMessage(kLogCritical, translate("Error while initializing speech synthesizer module - please install the speech synthesizer software"))

				showMessage(translate("Error while initializing speech synthesizer module - please install the speech synthesizer software") . translate("...")
									, translate("Modular Simulator Controller System"), "Alert.png", 5000, "Center", "Bottom", 800)

				voices := ""
			}

			if (voices = "") {
				for languageCode, voiceInfos in kAzureVoices
					for ignore, voiceInfo in voiceInfos
						this.Voices.Push(voiceInfo[2] . " (" . voiceInfo[1] . ")")
			}
			else {
				this.iVoices := string2Values("|", voices)
			}

			this.setVoice(language, this.computeVoice(voice, language))
		}
		else
			throw "Unsupported speech synthesizer service detected in SpeechSynthesizer.__New..."

		if kSox {
			if !SpeechSynthesizer.sAudioRoutingInitialized {
				SpeechSynthesizer.sAudioRoutingInitialized := true

				configuration := readMultiMap(kUserConfigDirectory . "Audio Settings.ini")

				SpeechSynthesizer.sAudioDriver := getMultiMapValue(configuration, "Output", this.Routing . ".AudioDriver", false)
				SpeechSynthesizer.sAudioDevice := getMultiMapValue(configuration, "Output", this.Routing . ".AudioDevice", false)
			}

			if FileExist(kSox)
				for ignore, player in ["SoundPlayerSync.exe", "SoundPlayerAsync.exe"]
					if !FileExist(kTempDirectory . player) {
						copied := false

						while (!copied)
							try {
								FileCopy(kSox, kTempDirectory . player, true)

								copied := true
							}
							catch Any as exception {
								logError(exception)
							}
					}
		}
	}

	setPlayerLevel(level) {
		local pid := this.iSoundPlayer

		this.iSoundPlayerLevel := level

		if (pid && kNirCmd) {
			if ProcessExist(pid) {
				try {
					Run("`"" . kNirCmd . "`" setappvolume /" . pid . A_Space . level)
				}
				catch Any as exception {
					showMessage(substituteVariables(translate("Cannot start NirCmd (%kNirCmd%) - please check the configuration..."))
							  , translate("Modular Simulator Controller System"), "Alert.png", 5000, "Center", "Bottom", 800)
				}
			}
		}
	}

	mute() {
		this.setPlayerLevel(0.4)
	}

	unmute() {
		this.setPlayerLevel(1.0)
	}

	updateSpeechStatus(pid) {
		local callback

		if ProcessExist(pid) {
			Task.CurrentTask.Sleep := 50

			return Task.CurrentTask
		}
		else {
			this.iSoundPlayer := false
			this.iPlaysCacheFile := false

			callback := this.SpeechStatusCallback

			callback.Call("Stop")

			return false
		}
	}

	playSound(soundFile, wait := true) {
		local callback, player, pid, workingDirectory, level, option

		callback := this.SpeechStatusCallback

		if kSox {
			player := (wait ? "SoundPlayerSync.exe" : "SoundPlayerAsync.exe")

			SplitPath(kSox, , &workingDirectory)

			option := (SpeechSynthesizer.sAudioDevice ? ("`"" . SpeechSynthesizer.sAudioDevice . "`"") : "")

			Run("`"" . kTempDirectory . player . "`" `"" . soundFile . "`" -t waveaudio " . option, workingDirectory, "HIDE", &pid)

			if callback
				callback.Call("Start")

			Sleep(500)

			this.iSoundPlayer := pid

			if kNirCmd
				try {
					level := this.iSoundPlayerLevel

					Run("`"" . kNirCmd . "`" setappvolume /" . pid . A_Space . level)
				}
				catch Any as exception {
					showMessage(substituteVariables(translate("Cannot start NirCmd (%kNirCmd%) - please check the configuration..."))
												  , translate("Modular Simulator Controller System"), "Alert.png", 5000, "Center", "Bottom", 800)
				}

			if wait {
				loop {
					if ProcessExist(pid)
						Sleep(50)
					else
						break
				}

				this.iSoundPlayer := false

				if callback
					callback.Call("Stop")
			}
			else if callback
				Task.startTask(ObjBindMethod(this, "updateSpeechStatus", pid), 500, kHighPriority)
		}
		else {
			if wait {
				if callback
					callback.Call("Start")

				SoundPlay(soundFile, "Wait")

				if callback
					callback.Call("Stop")
			}
			else {
				if callback
					callback.Call("Play")

				SoundPlay(soundFile)
			}
		}
	}

	clearCache(*) {
		local directory := this.iCacheDirectory

		if directory
			deleteFile(directory . "Unnamed*.*")

		return false
	}

	cacheFileName(cacheKey, fileName := false) {
		if this.iCache.Has(cacheKey)
			return this.iCache[cacheKey]
		else {
			fileName := (this.iCacheDirectory . (fileName ? fileName : cacheKey) . ".wav")

			this.iCache[cacheKey] := fileName

			return fileName
		}
	}

	speak(text, wait := true, cache := false) {
		local cacheFileName, tempName, temp1Name, temp2Name, callback, volume
		local overdriveGain, overdriveColor, filterHighpass, filterLowpass, noiseVolume, clickVolume

		static counter := 1

		this.wait()

		if (cache && (cache == true))
			cache := text

		if cache {
			if (cache == true)
				cacheFileName := this.cacheFileName(text, "Unnamed_" . counter++)
			else
				cacheFileName := this.cacheFileName(cache)

			if FileExist(cacheFileName) {
				if (wait || !cache)
					this.playSound(cacheFileName, true)
				else {
					this.playSound(cacheFileName, false)

					this.iPlaysCacheFile := true
				}

				return
			}
		}
		else
			cacheFileName := false

		if kSoX {
			temp1Name := temporaryFileName("temp1", "wav")

			if cacheFileName
				temp2Name := cacheFileName
			else
				temp2Name := temporaryFileName("temp2", "wav")

			this.speakToFile(temp1Name, text)

			if !FileExist(temp1Name) {
				callback := this.SpeechStatusCallback

				if (this.Synthesizer = "Windows") {
					if callback
						callback.Call(wait ? "Start" : "Play")

					this.iSpeechSynthesizer.Speak(text, (wait ? 0x0 : 0x1))

					if (callback && wait)
						callback.Call("Stop")
				}

				return
			}

			overdriveGain := getMultiMapValue(kSimulatorConfiguration, "Voice Control", "Speaker.Overdrive", 20)
			overdriveColor := getMultiMapValue(kSimulatorConfiguration, "Voice Control", "Speaker.Color", 20)
			filterHighpass := getMultiMapValue(kSimulatorConfiguration, "Voice Control", "Speaker.HighPass", 800)
			filterLowpass := getMultiMapValue(kSimulatorConfiguration, "Voice Control", "Speaker.LowPass", 1800)

			try {
				noiseVolume := Round(0.3 * getMultiMapValue(kSimulatorConfiguration, "Voice Control", "Speaker.NoiseVolume", 66) / 100, 2)
			}
			catch Any as exception {
				logError(exception, true)

				noiseVolume := Round(0.3 * 66 / 100, 2)
			}

			try {
				clickVolume := Round(0.6 * getMultiMapValue(kSimulatorConfiguration, "Voice Control", "Speaker.ClickVolume", 80) / 100, 2)
			}
			catch Any as exception {
				logError(exception, true)

				clickVolume := Round(0.6 * 66 / 100, 2)
			}

			if !isInteger(overDriveGain)
				overDriveGain := 20

			if !isInteger(overDriveColor)
				overDriveColor := 20

			if !isInteger(filterHighpass)
				filterHighpass := 800

			if !isInteger(filterLowpass)
				filterLowpass := 1800

			try {
				try {
					RunWait("`"" . kSoX . "`" `"" . temp1Name . "`" `"" . temp2Name . "`" rate 16k channels 1 overdrive " . overdriveGain . A_Space . overdriveColor
																					. " highpass " . filterHighpass . " lowpass " . filterLowpass . " Norm", , "Hide")

					if (noiseVolume > 0)
						RunWait("`"" . kSoX . "`" -m -v " . noiseVolume . " `"" . kResourcesDirectory . "Sounds\Noise.wav`" `""
														  . temp2Name . "`" `"" . temp1Name . "`" channels 1 reverse vad -p 1 reverse", , "Hide")
					else
						RunWait("`"" . kSoX . "`" `"" . temp2Name . "`" `"" . temp1Name . "`" channels 1 reverse vad -p 1 reverse", , "Hide")

					volume := Round(this.iVolume / 100, 2)

					if (clickVolume > 0)
						RunWait("`"" . kSoX . "`" -v " . clickVolume . " `"" . kResourcesDirectory . "Sounds\Click.wav`" `"" . temp1Name . "`" `"" . temp2Name . "`" norm vol " . volume, , "Hide")
					else
						RunWait("`"" . kSoX . "`" `"" . temp1Name . "`" `"" . temp2Name . "`" norm vol " . volume, , "Hide")
				}
				catch Any as exception {
					showMessage(substituteVariables(translate("Cannot start SoX (%kSoX%) - please check the configuration..."))
							  , translate("Modular Simulator Controller System"), "Alert.png", 5000, "Center", "Bottom", 800)

					if (this.Synthesizer = "Windows")
						this.iSpeechSynthesizer.Speak(text, (wait ? 0x0 : 0x1))
				}

				if (wait || !cache)
					this.playSound(temp2Name, true)
				else {
					this.playSound(temp2Name, false)

					this.iPlaysCacheFile := true
				}
			}
			finally {
				try {
					if FileExist(temp1Name)
						deleteFile(temp1Name)

					if (!cache && FileExist(temp2Name))
						deleteFile(temp2Name)
				}
				catch Any as exception {
					logError(exception)
				}
			}
		}
		else {
			if (this.Synthesizer = "Windows")
				this.iSpeechSynthesizer.Speak(text, (wait ? 0x0 : 0x1))
			else if ((this.Synthesizer = "dotNET") || (this.Synthesizer = "Azure")) {
				tempName := (cache ? cacheFileName : temporaryFileName("temp", "wav"))

				this.SpeakToFile(tempName, text)

				if !FileExist(tempName)
					return

				this.playSound(tempName, wait || !cache)

				if !cache
					deleteFile(tempName)
			}
		}
	}

	speakToFile(fileName, text) {
		local oldStream, stream, ssml

		this.stop()

		if (this.Synthesizer = "Windows") {
			oldStream := this.iSpeechSynthesizer.AudioOutputStream

			stream := ComObject("Sapi.SpFileStream")

			try {
				stream.Open(fileName, 0x3, 0)

				this.iSpeechSynthesizer.AudioOutputStream := stream

				this.iSpeechSynthesizer.Speak(text, 0x0)
			}
			finally {
				stream.Close()

				this.iSpeechSynthesizer.AudioOutputStream := oldStream
			}
		}
		else if ((this.Synthesizer = "dotNET") || (this.Synthesizer = "Azure")) {
			ssml := "<speak version=`"1.0`" xmlns=`"http://www.w3.org/2001/10/synthesis`" xml:lang=`"%language%`">"
		    ssml .= " <voice name=`"%voice%`">"

			if (this.Synthesizer = "Azure") {
				ssml .= "  <prosody pitch=`"%pitch%`" rate=`"%rate%`""

				if !kSoX
					ssml .= " volume=`"%volume%`""

				ssml .= ">"
			}
			else
				ssml .= "  <prosody pitch=`"%pitch%`">"

			ssml .= "  %text%"
			ssml .= "  </prosody>"
			ssml .= " </voice>"
			ssml .= "</speak>"

			ssml := substituteVariables(ssml, {volume: this.iVolume, pitch: ((this.iPitch > 0) ? "+" : "-") . Abs(this.iPitch) . "st", rate: 1 + (0.05 * this.iRate)
											 , language: this.Locale, voice: this.Voice, text: text})

			try {
				if !this.iSpeechSynthesizer.SpeakSsmlToFile(fileName, ssml)
					throw "Error while speech synthesizing..."
			}
			catch Any as exception {
				if (this.Synthesizer = "Azure")
					SpeechSynthesizer("Windows", true, "EN").speak("Error while calling Azure Cognitive Services. Maybe your monthly contingent is exhausted.")
			}
		}
	}

	isSpeaking() {
		if this.iSoundPlayer {
			if ProcessExist(this.iSoundPlayer)
				return true
			else {
				this.iSoundPlayer := false
				this.iPlaysCacheFile := false

				return false
			}
		}
		else
			return false
	}

	pause() {
		local status

		if (this.Synthesizer = "Windows") {
			status := this.iSpeechSynthesizer.Status.RunningState

			if (status = 0)
				this.iSpeechSynthesizer.Resume
			else if (status = 2)
				this.iSpeechSynthesizer.Pause
		}
	}

	wait() {
		if this.iSoundPlayer {
			while this.isSpeaking()
				Sleep(1)
		}
		else
			this.stop()
	}

	stop() {
		local pid := this.iSoundPlayer
		local status

		if pid {
			if ProcessExist(pid) {
				ProcessClose(pid)

				this.iSoundPlayer := false
				this.iPlaysCacheFile := false
			}

			return true
		}
		else if (this.iPlaysCacheFile || (this.Synthesizer = "dotNET") || (this.Synthesizer = "Azure")) {
			try
				SoundPlay("NonExistent.avi")

			if this.iPlaysCacheFile {
				this.iPlaysCacheFile := false

				return true
			}
		}
		else if (this.Synthesizer = "Windows") {
			status := this.iSpeechSynthesizer.Status.RunningState

			if (status = 0)
				this.iSpeechSynthesizer.Resume

			this.iSpeechSynthesizer.Speak("", 0x1 | 0x2)
		}

		return false
	}

	setRate(rate) {
		this.iRate := rate

		if (this.Synthesizer = "Windows")
			this.iSpeechSynthesizer.Rate := rate
		else if (this.Synthesizer = "dotNET")
			this.iSpeechSynthesizer.SetProsody(rate, kSoX ? 100 : this.iVolume)
	}

	setVolume(volume) {
		this.iVolume := volume

		if (this.Synthesizer = "Windows")
			this.iSpeechSynthesizer.Volume := (kSoX ? 100 : this.iVolume)
		else if (this.Synthesizer = "dotNET")
			this.iSpeechSynthesizer.SetProsody(this.iRate, kSoX ? 100 : this.iVolume)
	}

	setPitch(pitch) {
		this.iPitch := pitch

		if (this.Synthesizer = "Windows")
			this.iSpeechSynthesizer.Speak("<pitch absmiddle = '" pitch "'/>", 0x20)
	}

	computeVoice(voice, language, randomize := true) {
		local voices := this.Voices
		local availableVoices, count, index, locale, ignore, candidate

		if (this.Synthesizer = "Windows") {
			if ((voice == true) && language) {
				availableVoices := this.Voices[language]

				count := availableVoices.Length

				if (count == 0)
					voice := false
				else if randomize {
					index := Random(1, count)

					voice := availableVoices[Round(index)]
				}
				else
					voice := availableVoices[1]
			}
			else
				voices := this.Voices
		}
		else if ((this.Synthesizer = "dotNET") || (this.Synthesizer = "Azure")) {
			if ((voice == true) && language) {
				availableVoices := []

				for ignore, candidate in voices {
					voice := string2Values("(", candidate)
					locale := StrReplace(voice[2], ")", "")

					if (InStr(locale, language) == 1)
						availableVoices.Push(candidate)
				}

				count := availableVoices.Length

				if (count == 0)
					voice := false
				else if randomize {
					index := Random(1, count)

					voice := availableVoices[Round(index)]
				}
				else
					voice := availableVoices[1]
			}
		}

		if (voice && (voice != true))
			voice := inList(voices, voice)

		if !voice
			voice := 1

		return voices[voice]
	}

	setVoice(language, name) {
		if (this.Synthesizer = "Windows") {
			if !inList(this.Voices, name)
				return false

			while !(this.iSpeechSynthesizer.Status.RunningState = 1)
				Sleep(200)

			this.iSpeechSynthesizer.Voice := this.iSpeechSynthesizer.GetVoices("Name=" . name).Item(0)
			this.iLanguage := language
			this.iVoice := name
		}
		else if ((this.Synthesizer = "dotNET") || (this.Synthesizer = "Azure")) {
			name := string2Values("(", name)

			this.iLanguage := language
			this.iVoice := name[1]
			this.iLocale := StrReplace(name[2], ")", "")
		}

		return true
	}
}