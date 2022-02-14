﻿/*
RF2 SHM Spotter main class.

Small parts original by: The Iron Wolf (vleonavicius@hotmail.com; thecrewchief.org)
*/
using RF2SHMSpotter.rFactor2Data;
using System;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;
using static RF2SHMSpotter.rFactor2Constants;
using static RF2SHMSpotter.rFactor2Constants.rF2GamePhase;
using static RF2SHMSpotter.rFactor2Constants.rF2PitState;

namespace RF2SHMSpotter {
	public class SHMSpotter {
		bool connected = false;

		// Read buffers:
		MappedBuffer<rF2Telemetry> telemetryBuffer = new MappedBuffer<rF2Telemetry>(rFactor2Constants.MM_TELEMETRY_FILE_NAME, true /*partial*/, true /*skipUnchanged*/);
		MappedBuffer<rF2Scoring> scoringBuffer = new MappedBuffer<rF2Scoring>(rFactor2Constants.MM_SCORING_FILE_NAME, true /*partial*/, true /*skipUnchanged*/);
		MappedBuffer<rF2Rules> rulesBuffer = new MappedBuffer<rF2Rules>(rFactor2Constants.MM_RULES_FILE_NAME, true /*partial*/, true /*skipUnchanged*/);
		MappedBuffer<rF2ForceFeedback> forceFeedbackBuffer = new MappedBuffer<rF2ForceFeedback>(rFactor2Constants.MM_FORCE_FEEDBACK_FILE_NAME, false /*partial*/, false /*skipUnchanged*/);
		MappedBuffer<rF2Graphics> graphicsBuffer = new MappedBuffer<rF2Graphics>(rFactor2Constants.MM_GRAPHICS_FILE_NAME, false /*partial*/, false /*skipUnchanged*/);
		MappedBuffer<rF2PitInfo> pitInfoBuffer = new MappedBuffer<rF2PitInfo>(rFactor2Constants.MM_PITINFO_FILE_NAME, false /*partial*/, true /*skipUnchanged*/);
		MappedBuffer<rF2Weather> weatherBuffer = new MappedBuffer<rF2Weather>(rFactor2Constants.MM_WEATHER_FILE_NAME, false /*partial*/, true /*skipUnchanged*/);
		MappedBuffer<rF2Extended> extendedBuffer = new MappedBuffer<rF2Extended>(rFactor2Constants.MM_EXTENDED_FILE_NAME, false /*partial*/, true /*skipUnchanged*/);

		// Write buffers:
		MappedBuffer<rF2HWControl> hwControlBuffer = new MappedBuffer<rF2HWControl>(rFactor2Constants.MM_HWCONTROL_FILE_NAME);
		MappedBuffer<rF2WeatherControl> weatherControlBuffer = new MappedBuffer<rF2WeatherControl>(rFactor2Constants.MM_WEATHER_CONTROL_FILE_NAME);
		MappedBuffer<rF2RulesControl> rulesControlBuffer = new MappedBuffer<rF2RulesControl>(rFactor2Constants.MM_RULES_CONTROL_FILE_NAME);
		MappedBuffer<rF2PluginControl> pluginControlBuffer = new MappedBuffer<rF2PluginControl>(rFactor2Constants.MM_PLUGIN_CONTROL_FILE_NAME);

		// Marshalled views:
		rF2Telemetry telemetry;
		rF2Scoring scoring;
		rF2Rules rules;
		rF2ForceFeedback forceFeedback;
		rF2Graphics graphics;
		rF2PitInfo pitInfo;
		rF2Weather weather;
		rF2Extended extended;

		// Marashalled output views:
		rF2HWControl hwControl;
		rF2WeatherControl weatherControl;
		rF2RulesControl rulesControl;
		rF2PluginControl pluginControl;

		public SHMSpotter() {
			if (!this.connected)
				this.Connect();
		}

		private static string GetStringFromBytes(byte[] bytes) {
			if (bytes == null)
				return "";

			var nullIdx = Array.IndexOf(bytes, (byte)0);

			return nullIdx >= 0 ? Encoding.Default.GetString(bytes, 0, nullIdx) : Encoding.Default.GetString(bytes);
		}

		public static rF2VehicleTelemetry GetPlayerTelemetry(int id, ref rF2Telemetry telemetry) {
			var playerVehTelemetry = new rF2VehicleTelemetry();

			for (int i = 0; i < telemetry.mNumVehicles; ++i) {
				var vehicle = telemetry.mVehicles[i];

				if (vehicle.mID == id) {
					playerVehTelemetry = vehicle;

					break;
				}
			}

			return playerVehTelemetry;
		}

		private void Connect() {
			if (!this.connected) {
				try {
					// Extended buffer is the last one constructed, so it is an indicator RF2SM is ready.
					this.extendedBuffer.Connect();

					this.telemetryBuffer.Connect();
					this.scoringBuffer.Connect();
					this.rulesBuffer.Connect();
					this.forceFeedbackBuffer.Connect();
					this.graphicsBuffer.Connect();
					this.pitInfoBuffer.Connect();
					this.weatherBuffer.Connect();

					this.hwControlBuffer.Connect();
					this.hwControlBuffer.GetMappedData(ref this.hwControl);
					this.hwControl.mLayoutVersion = rFactor2Constants.MM_HWCONTROL_LAYOUT_VERSION;

					this.weatherControlBuffer.Connect();
					this.weatherControlBuffer.GetMappedData(ref this.weatherControl);
					this.weatherControl.mLayoutVersion = rFactor2Constants.MM_WEATHER_CONTROL_LAYOUT_VERSION;

					this.rulesControlBuffer.Connect();
					this.rulesControlBuffer.GetMappedData(ref this.rulesControl);
					this.rulesControl.mLayoutVersion = rFactor2Constants.MM_RULES_CONTROL_LAYOUT_VERSION;

					this.pluginControlBuffer.Connect();
					this.pluginControlBuffer.GetMappedData(ref this.pluginControl);
					this.pluginControl.mLayoutVersion = rFactor2Constants.MM_PLUGIN_CONTROL_LAYOUT_VERSION;

					// Scoring cannot be enabled on demand.
					this.pluginControl.mRequestEnableBuffersMask = /*(int)SubscribedBuffer.Scoring | */(int)SubscribedBuffer.Telemetry | (int)SubscribedBuffer.Rules
					| (int)SubscribedBuffer.ForceFeedback | (int)SubscribedBuffer.Graphics | (int)SubscribedBuffer.Weather | (int)SubscribedBuffer.PitInfo;
					this.pluginControl.mRequestHWControlInput = 1;
					this.pluginControl.mRequestRulesControlInput = 1;
					this.pluginControl.mRequestWeatherControlInput = 1;
					this.pluginControl.mVersionUpdateBegin = this.pluginControl.mVersionUpdateEnd = this.pluginControl.mVersionUpdateBegin + 1;
					this.pluginControlBuffer.PutMappedData(ref this.pluginControl);

					this.connected = true;
				}
				catch (Exception) {
					this.Disconnect();
				}
			}
		}

		private void Disconnect() {
			this.extendedBuffer.Disconnect();
			this.scoringBuffer.Disconnect();
			this.rulesBuffer.Disconnect();
			this.telemetryBuffer.Disconnect();
			this.forceFeedbackBuffer.Disconnect();
			this.pitInfoBuffer.Disconnect();
			this.weatherBuffer.Disconnect();
			this.graphicsBuffer.Disconnect();

			this.hwControlBuffer.Disconnect();
			this.weatherControlBuffer.Disconnect();
			this.rulesControlBuffer.Disconnect();
			this.pluginControlBuffer.Disconnect();

			this.connected = false;
		}
		public static rF2VehicleScoring GetPlayerScoring(ref rF2Scoring scoring)
		{
			var playerVehScoring = new rF2VehicleScoring();

			for (int i = 0; i < scoring.mScoringInfo.mNumVehicles; ++i)
			{
				var vehicle = scoring.mVehicles[i];

				switch ((rFactor2Constants.rF2Control)vehicle.mControl)
				{
					case rFactor2Constants.rF2Control.AI:
					case rFactor2Constants.rF2Control.Player:
					case rFactor2Constants.rF2Control.Remote:
						if (vehicle.mIsPlayer == 1)
							playerVehScoring = vehicle;

						break;

					default:
						continue;
				}

				if (playerVehScoring.mIsPlayer == 1)
					break;
			}

			return playerVehScoring;
		}

		const int WM_COPYDATA = 0x004A;

		public struct COPYDATASTRUCT
		{
			public IntPtr dwData;
			public int cbData;
			[MarshalAs(UnmanagedType.LPStr)]
			public string lpData;
		}

		[DllImport("user32.dll")]
		public static extern int FindWindowEx(int hwndParent, int hwndChildAfter, string lpszClass, string lpszWindow);

		[DllImport("user32.dll")]
		public static extern int SendMessage(int hWnd, int uMsg, int wParam, ref COPYDATASTRUCT lParam);

		public int SendStringMessage(int hWnd, int wParam, string msg)
		{
			int result = 0;

			if (hWnd > 0)
			{
				byte[] sarr = System.Text.Encoding.Default.GetBytes(msg);
				int len = sarr.Length;
				COPYDATASTRUCT cds;

				cds.dwData = (IntPtr)(256 * 'R' + 'S');
				cds.lpData = msg;
				cds.cbData = len + 1;

				result = SendMessage(hWnd, WM_COPYDATA, wParam, ref cds);
			}

			return result;
		}

		void SendMessage(string message)
		{
			int winHandle = FindWindowEx(0, 0, null, "Race Spotter.exe");

			if (winHandle == 0)
				FindWindowEx(0, 0, null, "Race Spotter.ahk");

			if (winHandle != 0)
				SendStringMessage(winHandle, 0, "Race Spotter:" + message);
		}

		const double PI = 3.14159265;

		const double nearByDistance = 8;
		const double longitudinalDistance = 4;
		const double lateralDistance = 6;
		const double verticalDistance = 2;

		const int CLEAR = 0;
		const int LEFT = 1;
		const int RIGHT = 2;
		const int THREE = 3;

		const int situationRepeat = 5;

		const string noAlert = "NoAlert";

		int lastSituation = CLEAR;
		int situationCount = 0;

		bool carBehind = false;
		bool carBehindReported = false;

		const int YELLOW_SECTOR_1 = 1;
		const int YELLOW_SECTOR_2 = 2;
		const int YELLOW_SECTOR_3 = 4;

		const int YELLOW_FULL = (YELLOW_SECTOR_1 + YELLOW_SECTOR_2 + YELLOW_SECTOR_3);

		const int BLUE = 16;

		int blueCount = 0;

		int lastFlagState = 0;

		string computeAlert(int newSituation) {
			string alert = noAlert;

			if (lastSituation == newSituation)
			{
				if (lastSituation > CLEAR)
				{
					if (situationCount++ > situationRepeat)
					{
						situationCount = 0;

						alert = "Hold";
					}
				}
				else
					situationCount = 0;
			}
			else
			{
				situationCount = 0;

				if (lastSituation == CLEAR)
				{
					switch (newSituation)
					{
						case LEFT:
							alert = "Left";
							break;
						case RIGHT:
							alert = "Right";
							break;
						case THREE:
							alert = "Three";
							break;
					}
				}
				else
				{
					switch (newSituation)
					{
						case CLEAR:
							if (lastSituation == THREE)
								alert = "ClearAll";
							else
								alert = (lastSituation == RIGHT) ? "ClearRight" : "ClearLeft";
							break;
						case LEFT:
							if (lastSituation == THREE)
								alert = "ClearRight";
							else
								alert = "Three";
							break;
						case RIGHT:
							if (lastSituation == THREE)
								alert = "ClearLeft";
							else
								alert = "Three";
							break;
						case THREE:
							alert = "Three";
							break;
					}
				}
			}

			lastSituation = newSituation;

			return alert;
		}

		double vectorAngle(double x, double y)
		{
			double scalar = (x * 0) + (y * 1);
			double length = Math.Sqrt((x * x) + (y * y));

			double angle = (length > 0) ? Math.Acos(scalar / length) * 180 / PI : 0;

			if (x < 0)
				angle = 360 - angle;

			return angle;
		}

		bool nearBy(double car1X, double car1Y, double car1Z,
					double car2X, double car2Y, double car2Z)
		{
			return (Math.Abs(car1X - car2X) < nearByDistance) &&
				   (Math.Abs(car1Y - car2Y) < nearByDistance) &&
				   (Math.Abs(car1Z - car2Z) < nearByDistance);
		}

		void rotateBy(ref double x, ref double y, double angle)
		{
			double sinus = Math.Sin(angle * PI / 180);
			double cosinus = Math.Cos(angle * PI / 180);

			double newX = (x * cosinus) - (y * sinus);
			double newY = (x * sinus) + (y * cosinus);

			x = newX;
			y = newY;
		}

		int checkCarPosition(double carX, double carY, double carZ, double angle,
							 double otherX, double otherY, double otherZ)
		{
			if (nearBy(carX, carY, carZ, otherX, otherY, otherZ))
			{
				double transX = (otherX - carX);
				double transY = (otherY - carY);

				rotateBy(ref transX, ref transY, angle);

				if ((Math.Abs(transY) < longitudinalDistance) && (Math.Abs(transX) < lateralDistance) && (Math.Abs(otherZ - carZ) < verticalDistance))
					return (transX < 0) ? RIGHT : LEFT;
				else
				{
					if (transY < 0)
						carBehind = true;

					return CLEAR;
				}
			}
			else
				return CLEAR;
		}

		bool checkPositions(ref rF2VehicleScoring playerScoring)
		{
			double lVelocityX = playerScoring.mLocalVel.x;
			double lVelocityY = playerScoring.mLocalVel.z;
			double lVelocityZ = playerScoring.mLocalVel.y;

			var ori = playerScoring.mOri;

			double velocityX = ori[RowX].x * lVelocityX + ori[RowX].y * lVelocityY + ori[RowX].z * lVelocityZ;
			double velocityY = ori[RowZ].x * lVelocityX + ori[RowZ].y * lVelocityY + ori[RowZ].z * lVelocityZ;
			double velocityZ = ori[RowY].x * lVelocityX + ori[RowY].y * lVelocityY + ori[RowY].z * lVelocityZ;

			if ((velocityX != 0) || (velocityY != 0) || (velocityZ != 0))
			{
				double angle = vectorAngle(velocityX, velocityY);

				Console.WriteLine(angle);

				double coordinateX = playerScoring.mPos.x;
				double coordinateY = playerScoring.mPos.z;
				double coordinateZ = playerScoring.mPos.y;

				int newSituation = CLEAR;

				carBehind = false;

				for (int i = 0; i < scoring.mScoringInfo.mNumVehicles; ++i)
				{
					var vehicle = scoring.mVehicles[i];

					Console.Write(i); Console.Write(" "); Console.Write(vehicle.mPos.x); Console.Write(" ");
					Console.Write(vehicle.mPos.z); Console.Write(" "); Console.WriteLine(vehicle.mPos.y);

					if (vehicle.mIsPlayer != 0)
						newSituation |= checkCarPosition(coordinateX, coordinateY, coordinateZ, angle,
														 vehicle.mPos.x, vehicle.mPos.y, vehicle.mPos.z);

					if ((newSituation == THREE) && carBehind)
						break;
				}

				string alert = computeAlert(newSituation);

				if (alert != noAlert)
				{
					carBehindReported = false;

					SendMessage("proximityAlert:" + alert);

					return true;
				}
				else if (carBehind)
				{
					if (!carBehindReported)
					{
						carBehindReported = true;

						SendMessage("proximityAlert:Behind");

						return true;
					}
				}
				else
					carBehindReported = false;
			}
			else
			{
				lastSituation = CLEAR;
				carBehind = false;
				carBehindReported = false;
			}

			return false;
		}

		bool checkFlagState(ref rF2VehicleScoring playerScoring)
		{
			if (playerScoring.mFlag == (byte)rF2PrimaryFlag.Blue)
			{
				if ((lastFlagState & BLUE) == 0)
				{
					SendMessage("blueFlag");

					lastFlagState |= BLUE;

					return true;
				}
				else if (blueCount++ > 100)
				{
					lastFlagState &= ~BLUE;

					blueCount = 0;
				}
			}
			else
			{
				lastFlagState &= ~BLUE;

				blueCount = 0;
			}

			if (scoring.mScoringInfo.mGamePhase == (byte)rF2GamePhase.FullCourseYellow)
			{
				if ((lastFlagState & YELLOW_FULL) == 0)
				{
					SendMessage("yellowFlag:Full");

					lastFlagState |= YELLOW_FULL;

					return true;
				}
			}
			else
			{
				if ((lastFlagState & YELLOW_FULL) != 0)
				{
					SendMessage("yellowFlag:Clear");

					lastFlagState &= ~YELLOW_FULL;

					return true;
				}
			}
			/*
			else if (scoring.mScoringInfo.mSectorFlag[(int)rF2Sector.Sector1] > 0)
			{
				if ((lastFlagState & YELLOW_SECTOR_1) == 0)
				{
					SendMessage("yellowFlag:Sector;1");

					lastFlagState |= YELLOW_SECTOR_1;

					return true;
				}
			}
			else if (scoring.mScoringInfo.mSectorFlag[(int)rF2Sector.Sector2] > 0)
			{
				if ((lastFlagState & YELLOW_SECTOR_2) == 0)
				{
					SendMessage("yellowFlag:Sector;2");

					lastFlagState |= YELLOW_SECTOR_2;

					return true;
				}
			}
			else if (scoring.mScoringInfo.mSectorFlag[(int)rF2Sector.Sector3] > 0)
			{
				if ((lastFlagState & YELLOW_SECTOR_3) == 0)
				{
					SendMessage("yellowFlag:Sector;3");

					lastFlagState |= YELLOW_SECTOR_3;

					return true;
				}
			}
			else
			{
				if ((lastFlagState & YELLOW_SECTOR_1) != 0 || (lastFlagState & YELLOW_SECTOR_2) != 0 ||
					(lastFlagState & YELLOW_SECTOR_3) != 0)
				{
					SendMessage("yellowFlag:Clear");

					lastFlagState &= ~YELLOW_FULL;

					return true;
				}
			}
			*/

			return false;
		}

		void checkPitWindow(ref rF2VehicleScoring playerScoring)
		{
			// No support by rFactor 2
		}

		public void Run() {
			while (true) {
				if (!connected)
					Connect();

				if (connected)
				{
					try
					{
						extendedBuffer.GetMappedData(ref extended);
						scoringBuffer.GetMappedData(ref scoring);
					}
					catch (Exception)
					{
						this.Disconnect();
					}

					if (connected) {
						rF2VehicleScoring playerScoring = GetPlayerScoring(ref scoring);

						if (extended.mSessionStarted != 0 && scoring.mScoringInfo.mGamePhase != (byte)PausedOrHeartbeat &&
							playerScoring.mPitState < (byte)Entering) {
							if (!checkFlagState(ref playerScoring) && !checkPositions(ref playerScoring))
								checkPitWindow(ref playerScoring);
						}
						else
						{
							lastSituation = CLEAR;
							carBehind = false;
							carBehindReported = false;

							lastFlagState = 0;
						}

						Thread.Sleep(50);
					}
					else
						Thread.Sleep(1000);
				}
				else
					Thread.Sleep(1000);
            }
		}
    }
}