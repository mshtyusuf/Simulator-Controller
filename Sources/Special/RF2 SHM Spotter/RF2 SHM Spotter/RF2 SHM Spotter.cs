﻿/*
RF2 SHM Spotter main class.

Small parts original by: The Iron Wolf (vleonavicius@hotmail.com; thecrewchief.org)
*/
using RF2SHMSpotter.rFactor2Data;
using System;
using System.Collections.Generic;
using System.Drawing;
using System.IO;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;
using static RF2SHMSpotter.rFactor2Constants;
using static RF2SHMSpotter.rFactor2Constants.rF2GamePhase;
using static RF2SHMSpotter.rFactor2Constants.rF2PitState;
using static System.Net.WebRequestMethods;
using static System.Windows.Forms.VisualStyles.VisualStyleElement.TextBox;

namespace RF2SHMSpotter {
	public class SHMSpotter {
		bool connected = false;

		// Read buffers:
		MappedBuffer<rF2Scoring> scoringBuffer = new MappedBuffer<rF2Scoring>(rFactor2Constants.MM_SCORING_FILE_NAME, true /*partial*/, true /*skipUnchanged*/);
        MappedBuffer<rF2Extended> extendedBuffer = new MappedBuffer<rF2Extended>(rFactor2Constants.MM_EXTENDED_FILE_NAME, false /*partial*/, true /*skipUnchanged*/);
        MappedBuffer<rF2Telemetry> telemetryBuffer = new MappedBuffer<rF2Telemetry>(rFactor2Constants.MM_TELEMETRY_FILE_NAME, true /*partial*/, true /*skipUnchanged*/);

        // Marshalled views:
        rF2Scoring scoring;
        rF2Extended extended;
        rF2Telemetry telemetry;

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
                    this.scoringBuffer.Connect();
                    this.telemetryBuffer.Connect();

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
            this.telemetryBuffer.Disconnect();

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

		void SendSpotterMessage(string message)
		{
			int winHandle = FindWindowEx(0, 0, null, "Race Spotter.exe");

			if (winHandle == 0)
				FindWindowEx(0, 0, null, "Race Spotter.ahk");

			if (winHandle != 0)
				SendStringMessage(winHandle, 0, "Race Spotter:" + message);
		}

		void SendAutomationMessage(string message)
		{
			int winHandle = FindWindowEx(0, 0, null, "Simulator Controller.exe");

			if (winHandle == 0)
				winHandle = FindWindowEx(0, 0, null, "Simulator Controller.ahk");

			if (winHandle != 0)
				SendStringMessage(winHandle, 0, "Race Spotter:" + message);
		}

		const double PI = 3.14159265;

		long cycle = 0;

		const double nearByXYDistance = 10.0;
		const double nearByZDistance = 6.0;
		double longitudinalFrontDistance = 4;
		double longitudinalRearDistance = 5;
		const double lateralDistance = 6;
		const double verticalDistance = 2;

		const int CLEAR = 0;
		const int LEFT = 1;
		const int RIGHT = 2;
		const int THREE = 3;

		const int situationRepeat = 50;

		const string noAlert = "NoAlert";

		int lastSituation = CLEAR;
		int situationCount = 0;

		bool carBehind = false;
		bool carBehindLeft = false;
		bool carBehindRight = false;
		bool carBehindReported = false;
		int carBehindCount = 0;
		long nextCarBehind = 0;

		const int YELLOW_SECTOR_1 = 1;
		const int YELLOW_SECTOR_2 = 2;
		const int YELLOW_SECTOR_3 = 4;

		const int YELLOW_ALL = (YELLOW_SECTOR_1 + YELLOW_SECTOR_2 + YELLOW_SECTOR_3);

		const int BLUE = 16;

		int blueCount = 0;
		int yellowCount = 0;
		long nextBlueFlag = 0;

		int lastFlagState = 0;
		int waitYellowFlagState = 0;

		string computeAlert(int newSituation) {
			string alert = noAlert;

			if (lastSituation == newSituation)
			{
				if (lastSituation > CLEAR)
				{
					if (situationCount > situationRepeat)
					{
						situationCount = 0;

						alert = "Hold";
					}
					else
						situationCount += 1;
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

							carBehindReported = true;
							carBehindCount = 21;

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

		double vectorLength(double x, double y)
		{
			return Math.Sqrt((x * x) + (y * y));
		}

		double vectorAngle(double x, double y)
		{
			double scalar = (x * 0) + (y * 1);
			double length = vectorLength(x, y);

			double angle = (length > 0) ? Math.Acos(scalar / length) * 180 / PI : 0;

			if (x < 0)
				angle = 360 - angle;

			return angle;
		}

		bool nearBy(double car1X, double car1Y, double car1Z,
					double car2X, double car2Y, double car2Z)
		{
			return (Math.Abs(car1X - car2X) < nearByXYDistance) &&
				   (Math.Abs(car1Y - car2Y) < nearByXYDistance) &&
				   (Math.Abs(car1Z - car2Z) < nearByZDistance);
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

		int checkCarPosition(double carX, double carY, double carZ, double angle, bool faster,
							 double otherX, double otherY, double otherZ)
		{
			if (nearBy(carX, carY, carZ, otherX, otherY, otherZ))
			{
				double transX = (otherX - carX);
				double transY = (otherY - carY);

				rotateBy(ref transX, ref transY, angle);

				if ((Math.Abs(transY) < ((transY > 0) ? longitudinalFrontDistance : longitudinalRearDistance)) &&
					(Math.Abs(transX) < lateralDistance) && (Math.Abs(otherZ - carZ) < verticalDistance))
					return (transX < 0) ? RIGHT : LEFT;
				else
				{
					if (transY < 0)
					{
						carBehind = true;

						if ((faster && Math.Abs(transY) < longitudinalFrontDistance * 1.5) ||
							(Math.Abs(transY) < longitudinalFrontDistance * 2 && Math.Abs(transX) > lateralDistance / 2))
							if (transX < 0)
								carBehindRight = true;
							else
								carBehindLeft = true;
					}

					return CLEAR;
				}
			}
			else
				return CLEAR;
		}

		double[,] lastCoordinates;
		bool hasLastCoordinates = false;

		bool checkPositions(ref rF2VehicleScoring playerScoring)
		{
			if (!hasLastCoordinates)
				lastCoordinates = new double[scoring.mScoringInfo.mNumVehicles, 3];

			double lVelocityX = playerScoring.mLocalVel.x;
			double lVelocityY = playerScoring.mLocalVel.y;
			double lVelocityZ = playerScoring.mLocalVel.z;

			int carID = 0;

			for (int i = 0; i < scoring.mScoringInfo.mNumVehicles; ++i)
				if (scoring.mVehicles[i].mIsPlayer != 0)
				{
					carID = i;

					break;
				}

			var ori = playerScoring.mOri;

			double velocityX = ori[RowX].x * lVelocityX + ori[RowX].y * lVelocityY + ori[RowX].z * lVelocityZ;
			double velocityY = ori[RowY].x * lVelocityX + ori[RowY].y * lVelocityY + ori[RowY].z * lVelocityZ;
			double velocityZ = (ori[RowZ].x * lVelocityX + ori[RowZ].y * lVelocityY + ori[RowZ].z * lVelocityZ) * -1;

			if ((velocityX != 0) || (velocityY != 0) || (velocityZ != 0))
			{
				double angle = vectorAngle(velocityX, velocityZ);

				// Console.WriteLine(vectorAngle(lVelocityX, lVelocityY));
				// Console.WriteLine(angle);
				// Console.WriteLine();

				double coordinateX = playerScoring.mPos.x;
				double coordinateY = playerScoring.mPos.y;
				double coordinateZ = (- playerScoring.mPos.z);
				double speed = 0.0;

				if (hasLastCoordinates)
					speed = vectorLength(lastCoordinates[carID, 0] - coordinateX, lastCoordinates[carID, 2] - coordinateZ);

				int newSituation = CLEAR;

				carBehind = false;
				carBehindLeft = false;
				carBehindRight = false;

				for (int i = 0; i < scoring.mScoringInfo.mNumVehicles; ++i)
				{
					var vehicle = scoring.mVehicles[i];

					if ((vehicle.mIsPlayer == 0) && (vehicle.mInPits == 0))
					{
						// Console.Write(i); Console.Write(" "); Console.Write(vehicle.mPos.x); Console.Write(" ");
						// Console.Write(vehicle.mPos.z); Console.Write(" "); Console.WriteLine(vehicle.mPos.y);

						double otherSpeed = vectorLength(lastCoordinates[i, 0] - vehicle.mPos.x,
														 lastCoordinates[i, 2] - (-vehicle.mPos.z));

						if (Math.Abs(speed - otherSpeed) / speed < 0.5)
						{

							bool faster = false;

							if (hasLastCoordinates)
								faster = otherSpeed > speed * 1.05;

							newSituation |= checkCarPosition(coordinateX, coordinateZ, coordinateY, angle, faster,
															 vehicle.mPos.x, (-vehicle.mPos.z), vehicle.mPos.y);

							if ((newSituation == THREE) && carBehind)
								break;
						}
					}
				}

				for (int i = 0; i < scoring.mScoringInfo.mNumVehicles; ++i)
				{
					var position = scoring.mVehicles[i].mPos;

					lastCoordinates[i, 0] = position.x;
					lastCoordinates[i, 1] = position.y;
					lastCoordinates[i, 2] = (- position.z);
				}

				hasLastCoordinates = true;

				if (newSituation != CLEAR)
				{
					carBehind = false;
					carBehindLeft = false;
					carBehindRight = false;
					carBehindReported = false;
				}

				if (carBehindCount++ > 200)
					carBehindCount = 0;

				string alert = computeAlert(newSituation);

				if (alert != noAlert)
				{
					longitudinalRearDistance = 4;

					SendSpotterMessage("proximityAlert:" + alert);

					return true;
				}
				else {
					longitudinalRearDistance = 5;

					if (carBehind)
					{
						if (!carBehindReported)
						{
							if (carBehindLeft || carBehindRight || ((carBehindCount < 20) && (cycle > nextCarBehind)))
                            {
                                nextCarBehind = cycle + 200;
                                carBehindReported = true;

								SendSpotterMessage(carBehindLeft ? "proximityAlert:BehindLeft" :
															(carBehindRight ? "proximityAlert:BehindRight" : "proximityAlert:Behind"));

								return true;
							}
						}
					}
					else
						carBehindReported = false;
				}
			}
			else
			{
				longitudinalRearDistance = 5;
				
				lastSituation = CLEAR;
				carBehind = false;
				carBehindReported = false;
			}

			return false;
		}

		bool checkFlagState(ref rF2VehicleScoring playerScoring)
		{
			if ((waitYellowFlagState & YELLOW_SECTOR_1) != 0 || (waitYellowFlagState & YELLOW_SECTOR_2) != 0 || (waitYellowFlagState & YELLOW_SECTOR_3) != 0)
			{
				yellowCount += 1;

				if (yellowCount > 50)
				{
					if (scoring.mScoringInfo.mSectorFlag[0] == 0)
						waitYellowFlagState &= ~YELLOW_SECTOR_1;

					if (scoring.mScoringInfo.mSectorFlag[1] == 0)
						waitYellowFlagState &= ~YELLOW_SECTOR_2;

					if (scoring.mScoringInfo.mSectorFlag[1] == 0)
						waitYellowFlagState &= ~YELLOW_SECTOR_3;

					yellowCount = 0;

					if ((waitYellowFlagState & YELLOW_SECTOR_1) != 0)
					{
						SendSpotterMessage("yellowFlag:Sector;1");

						waitYellowFlagState &= ~YELLOW_SECTOR_1;

						return true;
					}

					if ((waitYellowFlagState & YELLOW_SECTOR_2) != 0)
					{
						SendSpotterMessage("yellowFlag:Sector;2");

						waitYellowFlagState &= ~YELLOW_SECTOR_2;

						return true;
					}

					if ((waitYellowFlagState & YELLOW_SECTOR_3) != 0)
					{
						SendSpotterMessage("yellowFlag:Sector;3");

						waitYellowFlagState &= ~YELLOW_SECTOR_3;

						return true;
					}
				}
			}
			else
				yellowCount = 0;

			if (playerScoring.mFlag == (byte)rF2PrimaryFlag.Blue)
			{
				if ((lastFlagState & BLUE) == 0 && cycle > nextBlueFlag)
                {
                    nextBlueFlag = cycle + 400;

                    SendSpotterMessage("blueFlag");

					lastFlagState |= BLUE;

					return true;
				}
				else if (blueCount > 1000)
				{
					lastFlagState &= ~BLUE;

					blueCount = 0;
				}
				else
					blueCount += 1;
			}
			else
			{
				lastFlagState &= ~BLUE;

				blueCount = 0;
			}

			/*
			if (scoring.mScoringInfo.mGamePhase == (byte)rF2GamePhase.FullCourseYellow)
			{
				if ((lastFlagState & YELLOW_FULL) == 0)
				{
					SendSpotterMessage("yellowFlag:Full");

					lastFlagState |= YELLOW_FULL;

					return true;
				}
			}
			*/
			if ((scoring.mScoringInfo.mSectorFlag[0] == 1) && (scoring.mScoringInfo.mSectorFlag[1] == 1) && (scoring.mScoringInfo.mSectorFlag[2] == 1))
			{
				if ((lastFlagState & YELLOW_ALL) == 0)
				{
					SendSpotterMessage("yellowFlag:All");

					lastFlagState |= YELLOW_ALL;

					return true;
				}
			}
			else if (scoring.mScoringInfo.mSectorFlag[0] == 1)
			{
				if ((lastFlagState & YELLOW_SECTOR_1) == 0)
				{
					/*
					SendSpotterMessage("yellowFlag:Sector;1");

					lastFlagState |= YELLOW_SECTOR_1;

					return true;
					*/

					lastFlagState |= YELLOW_SECTOR_1;
					waitYellowFlagState |= YELLOW_SECTOR_1;
					yellowCount = 0;
				}
			}
			else if (scoring.mScoringInfo.mSectorFlag[1] == 1)
			{
				if ((lastFlagState & YELLOW_SECTOR_2) == 0)
				{
					/*
					SendSpotterMessage("yellowFlag:Sector;2");

					lastFlagState |= YELLOW_SECTOR_2;

					return true;
					*/

					lastFlagState |= YELLOW_SECTOR_2;
					waitYellowFlagState |= YELLOW_SECTOR_2;
					yellowCount = 0;
				}
			}
			else if (scoring.mScoringInfo.mSectorFlag[2] == 1)
			{
				if ((lastFlagState & YELLOW_SECTOR_3) == 0)
				{
					/*
					SendSpotterMessage("yellowFlag:Sector;3");

					lastFlagState |= YELLOW_SECTOR_3;

					return true;
					*/

					lastFlagState |= YELLOW_SECTOR_2;
					waitYellowFlagState |= YELLOW_SECTOR_2;
					yellowCount = 0;
				}
			}
			else
			{
				if ((lastFlagState & YELLOW_SECTOR_1) != 0 || (lastFlagState & YELLOW_SECTOR_2) != 0 ||
					(lastFlagState & YELLOW_SECTOR_3) != 0)
				{
					if (waitYellowFlagState != lastFlagState)
						SendSpotterMessage("yellowFlag:Clear");

					lastFlagState &= ~YELLOW_ALL;
					waitYellowFlagState &= ~YELLOW_ALL;
					yellowCount = 0;

					return true;
				}
			}

			return false;
		}

		bool checkPitWindow(ref rF2VehicleScoring playerScoring)
		{
			// No support by rFactor 2

			return false;
		}

		bool greenFlagReported = false;

		bool greenFlag() {
			if (!greenFlagReported && (scoring.mScoringInfo.mGamePhase == (byte)rF2GamePhase.GreenFlag)) {
				greenFlagReported = true;
				
				SendSpotterMessage("greenFlag");
				
				Thread.Sleep(2000);
				
				return true;
			}
			else
				return false;
		}

        class CornerDynamics
        {
            public double Speed;
            public double Usos;
            public int CompletedLaps;
            public int Phase;

            public CornerDynamics(double speed, double usos, int completedLaps, int phase)
            {
                Speed = speed;
                Usos = usos;
                CompletedLaps = completedLaps;
                Phase = phase;
            }
        }

        const int MAXVALUES = 6;

        List<float> recentSteerAngles = new List<float>();
        List<float> recentGLongs = new List<float>();
        List<float> recentIdealAngVels = new List<float>();
        List<float> recentRealAngVels = new List<float>();

        void pushValue(List<float> values, float value)
        {
            values.Add(value);

            if ((int)values.Count > MAXVALUES)
                values.RemoveAt(0);
        }

        float averageValue(List<float> values, ref int num)
        {
            float sum = 0.0f;

            foreach (float value in values)
                sum += value;

            num = values.Count;

            return (num > 0) ? sum / num : 0.0f;
        }

        float smoothValue(List<float> values, float value)
        {
            int ignore = 0;

            pushValue(values, value);

            return averageValue(values, ref ignore);
        }

        List<CornerDynamics> cornerDynamicsList = new List<CornerDynamics>();

        string dataFile = "";
        int understeerLightThreshold = 12;
        int understeerMediumThreshold = 20;
        int understeerHeavyThreshold = 35;
        int oversteerLightThreshold = 2;
        int oversteerMediumThreshold = -6;
        int oversteerHeavyThreshold = -10;
        int lowspeedThreshold = 100;
        int steerLock = 900;
        int steerRatio = 14;
        int wheelbase = 270;
        int trackWidth = 150;

        int lastCompletedLaps = 0;
        float lastSpeed = 0.0f;
		
		bool calibrate = false;

		bool collectTelemetry()
		{
            int carID = 0;

            for (int i = 0; i < scoring.mScoringInfo.mNumVehicles; ++i)
                if (scoring.mVehicles[i].mIsPlayer != 0)
                {
                    carID = i;

                    break;
                }

            rF2VehicleScoring playerScoring = GetPlayerScoring(ref scoring);

            if (extended.mSessionStarted == 0 || scoring.mScoringInfo.mGamePhase >= (byte)SessionStopped && playerScoring.mPitState >= (byte)Entering)
                return true;

			float steerAngle = smoothValue(recentSteerAngles, (float)telemetry.mVehicles[carID].mFilteredSteering);

            rF2Vec3 localVel = telemetry.mVehicles[carID].mLocalVel;
            float speed = (float)Math.Sqrt(localVel.x * localVel.x + localVel.y * localVel.y + localVel.z * localVel.z) * 3.6f;
			float acceleration = (float)speed - lastSpeed;

			lastSpeed = speed;

            pushValue(recentGLongs, acceleration);

            double angularVelocity = smoothValue(recentRealAngVels, (float)telemetry.mVehicles[carID].mLocalRot.z);
            double steeredAngleDegs = steerAngle * steerLock / 2.0f / steerRatio;
            double steerAngleRadians = -steeredAngleDegs / 57.2958;
            double wheelBaseMeter = (float)wheelbase / 10;
            double radius = wheelBaseMeter / steerAngleRadians;
            double perimeter = radius * PI * 2;
            double perimeterSpeed = lastSpeed / 3.6;
            double idealAngularVelocity = smoothValue(recentIdealAngVels, (float)(perimeterSpeed / perimeter * 2 * PI));
            
			if (Math.Abs(steerAngle) > 0.1 && lastSpeed > 60)
			{
                // Get the average recent GLong
                int numGLong = 0;
                float glongAverage = averageValue(recentGLongs, ref numGLong);

                int phase = 0;
                if (numGLong > 0)
                    if (glongAverage < -0.2)
                    {
                        // Braking
                        phase = -1;
                    }
                    else if (glongAverage > 0.1)
                    {
                        // Accelerating
                        phase = 1;
                    }

                CornerDynamics cd = new CornerDynamics(speed, 0, playerScoring.mTotalLaps, phase);

				if (Math.Abs(angularVelocity * 57.2958) > 0.1)
				{
					double slip = Math.Abs(idealAngularVelocity) - Math.Abs(angularVelocity);

					if (false)
						if (steerAngle > 0)
						{
							if (angularVelocity < idealAngularVelocity)
								slip *= -1;
						}
						else
						{
							if (angularVelocity > idealAngularVelocity)
								slip *= -1;
						}

                    cd.Usos = slip * 57.2989 * 10;

                    if (true)
                    {
                        StreamWriter output = new StreamWriter(dataFile + ".trace", true);

						output.Write(steerAngle + "  ");
						output.Write(steeredAngleDegs + "  ");
						output.Write(steerAngleRadians + "  ");
						output.Write(lastSpeed + "  ");
						output.Write(idealAngularVelocity + "  ");
						output.Write(angularVelocity + "  ");
						output.Write(slip + "  ");
                        output.WriteLine(cd.Usos);

                        output.Close();
                    }
                }

				cornerDynamicsList.Add(cd);

				int completedLaps = playerScoring.mTotalLaps;

				if (lastCompletedLaps != completedLaps)
					while (true)
						if (cornerDynamicsList[0].CompletedLaps < completedLaps - 2)
							cornerDynamicsList.RemoveAt(0);
						else
							break;
			}

            return true;
        }

        void writeTelemetry()
        {
            StreamWriter output = new StreamWriter(dataFile + ".tmp", false);

            try
            {
                int[] slowLightUSNum = { 0, 0, 0 };
                int[] slowMediumUSNum = { 0, 0, 0 };
                int[] slowHeavyUSNum = { 0, 0, 0 };
                int[] slowLightOSNum = { 0, 0, 0 };
                int[] slowMediumOSNum = { 0, 0, 0 };
                int[] slowHeavyOSNum = { 0, 0, 0 };
                int slowTotalNum = 0;
                int[] fastLightUSNum = { 0, 0, 0 };
                int[] fastMediumUSNum = { 0, 0, 0 };
                int[] fastHeavyUSNum = { 0, 0, 0 };
                int[] fastLightOSNum = { 0, 0, 0 };
                int[] fastMediumOSNum = { 0, 0, 0 };
                int[] fastHeavyOSNum = { 0, 0, 0 };
                int fastTotalNum = 0;
		
				int[] slowOSMin = { 0, 0, 0 };
				int[] fastOSMin = { 0, 0, 0 };
				int[] slowUSMax = { 0, 0, 0 };
				int[] fastUSMax = { 0, 0, 0 };

                foreach (CornerDynamics corner in cornerDynamicsList)
                {
                    int phase = corner.Phase + 1;

                    if (calibrate) {
						if (corner.Speed < lowspeedThreshold) {
							slowOSMin[phase] = Math.Min(slowOSMin[phase], (int)corner.Usos);
							slowUSMax[phase] = Math.Max(slowUSMax[phase], (int)corner.Usos);
						}
						else {
							fastOSMin[phase] = Math.Min(fastOSMin[phase], (int)corner.Usos);
							fastUSMax[phase] = Math.Max(fastUSMax[phase], (int)corner.Usos);
						}
					}
					else {
						if (corner.Speed < lowspeedThreshold)
						{
							slowTotalNum++;
							if (corner.Usos < oversteerHeavyThreshold)
							{
								slowHeavyOSNum[phase]++;
							}
							else if (corner.Usos < oversteerMediumThreshold)
							{
								slowMediumOSNum[phase]++;
							}
							else if (corner.Usos < oversteerLightThreshold)
							{
								slowLightOSNum[phase]++;
							}
							else if (corner.Usos > understeerHeavyThreshold)
							{
								slowHeavyUSNum[phase]++;
							}
							else if (corner.Usos > understeerMediumThreshold)
							{
								slowMediumUSNum[phase]++;
							}
							else if (corner.Usos > understeerLightThreshold)
							{
								slowLightUSNum[phase]++;
							}
						}
						else
						{
							fastTotalNum++;
							if (corner.Usos < oversteerHeavyThreshold)
							{
								fastHeavyOSNum[phase]++;
							}
							else if (corner.Usos < oversteerMediumThreshold)
							{
								fastMediumOSNum[phase]++;
							}
							else if (corner.Usos < oversteerLightThreshold)
							{
								fastLightOSNum[phase]++;
							}
							else if (corner.Usos > understeerHeavyThreshold)
							{
								fastHeavyUSNum[phase]++;
							}
							else if (corner.Usos > understeerMediumThreshold)
							{
								fastMediumUSNum[phase]++;
							}
							else if (corner.Usos > understeerLightThreshold)
							{
								fastLightUSNum[phase]++;
							}
						}
					}
                }

                if (calibrate) {
					output.WriteLine("[Understeer.Slow]");

					output.WriteLine("Entry=" + slowUSMax[0]);
					output.WriteLine("Apex=" + slowUSMax[1]);
					output.WriteLine("Exit=" + slowUSMax[2]);
					
					output.WriteLine("[Understeer.Fast]");

					output.WriteLine("Entry=" + fastUSMax[0]);
					output.WriteLine("Apex=" + fastUSMax[1]);
					output.WriteLine("Exit=" + fastUSMax[2]);
					
					output.WriteLine("[Oversteer.Slow]");

					output.WriteLine("Entry=" + slowOSMin[0]);
					output.WriteLine("Apex=" + slowOSMin[1]);
					output.WriteLine("Exit=" + slowOSMin[2]);
					
					output.WriteLine("[Oversteer.Fast]");

					output.WriteLine("Entry=" + fastOSMin[0]);
					output.WriteLine("Apex=" + fastOSMin[1]);
					output.WriteLine("Exit=" + fastOSMin[2]);
				}
				else {
					output.WriteLine("[Understeer.Slow.Light]");

					if (slowTotalNum > 0)
					{
						output.WriteLine("Entry=" + (int)(100.0f * slowLightUSNum[0] / slowTotalNum));
						output.WriteLine("Apex=" + (int)(100.0f * slowLightUSNum[1] / slowTotalNum));
						output.WriteLine("Exit=" + (int)(100.0f * slowLightUSNum[2] / slowTotalNum));
					}

					output.WriteLine("[Understeer.Slow.Medium]");

					if (slowTotalNum > 0)
					{
						output.WriteLine("Entry=" + (int)(100.0f * slowMediumUSNum[0] / slowTotalNum));
						output.WriteLine("Apex=" + (int)(100.0f * slowMediumUSNum[1] / slowTotalNum));
						output.WriteLine("Exit=" + (int)(100.0f * slowMediumUSNum[2] / slowTotalNum));
					}

					output.WriteLine("[Understeer.Slow.Heavy]");

					if (slowTotalNum > 0)
					{
						output.WriteLine("Entry=" + (int)(100.0f * slowHeavyUSNum[0] / slowTotalNum));
						output.WriteLine("Apex=" + (int)(100.0f * slowHeavyUSNum[1] / slowTotalNum));
						output.WriteLine("Exit=" + (int)(100.0f * slowHeavyUSNum[2] / slowTotalNum));
					}

					output.WriteLine("[Understeer.Fast.Light]");

					if (fastTotalNum > 0)
					{
						output.WriteLine("Entry=" + (int)(100.0f * fastLightUSNum[0] / fastTotalNum));
						output.WriteLine("Apex=" + (int)(100.0f * fastLightUSNum[1] / fastTotalNum));
						output.WriteLine("Exit=" + (int)(100.0f * fastLightUSNum[2] / fastTotalNum));
					}

					output.WriteLine("[Understeer.Fast.Medium]");

					if (fastTotalNum > 0)
					{
						output.WriteLine("Entry=" + (int)(100.0f * fastMediumUSNum[0] / fastTotalNum));
						output.WriteLine("Apex=" + (int)(100.0f * fastMediumUSNum[1] / fastTotalNum));
						output.WriteLine("Exit=" + (int)(100.0f * fastMediumUSNum[2] / fastTotalNum));
					}

					output.WriteLine("[Understeer.Fast.Heavy]");

					if (fastTotalNum > 0)
					{
						output.WriteLine("Entry=" + (int)(100.0f * fastHeavyUSNum[0] / fastTotalNum));
						output.WriteLine("Apex=" + (int)(100.0f * fastHeavyUSNum[1] / fastTotalNum));
						output.WriteLine("Exit=" + (int)(100.0f * fastHeavyUSNum[2] / fastTotalNum));
					}

					output.WriteLine("[Oversteer.Slow.Light]");

					if (slowTotalNum > 0)
					{
						output.WriteLine("Entry=" + (int)(100.0f * slowLightOSNum[0] / slowTotalNum));
						output.WriteLine("Apex=" + (int)(100.0f * slowLightOSNum[1] / slowTotalNum));
						output.WriteLine("Exit=" + (int)(100.0f * slowLightOSNum[2] / slowTotalNum));
					}

					output.WriteLine("[Oversteer.Slow.Medium]");

					if (slowTotalNum > 0)
					{
						output.WriteLine("Entry=" + (int)(100.0f * slowMediumOSNum[0] / slowTotalNum));
						output.WriteLine("Apex=" + (int)(100.0f * slowMediumOSNum[1] / slowTotalNum));
						output.WriteLine("Exit=" + (int)(100.0f * slowMediumOSNum[2] / slowTotalNum));
					}

					output.WriteLine("[Oversteer.Slow.Heavy]");

					if (slowTotalNum > 0)
					{
						output.WriteLine("Entry=" + (int)(100.0f * slowHeavyOSNum[0] / slowTotalNum));
						output.WriteLine("Apex=" + (int)(100.0f * slowHeavyOSNum[1] / slowTotalNum));
						output.WriteLine("Exit=" + (int)(100.0f * slowHeavyOSNum[2] / slowTotalNum));
					}

					output.WriteLine("[Oversteer.Fast.Light]");

					if (fastTotalNum > 0)
					{
						output.WriteLine("Entry=" + (int)(100.0f * fastLightOSNum[0] / fastTotalNum));
						output.WriteLine("Apex=" + (int)(100.0f * fastLightOSNum[1] / fastTotalNum));
						output.WriteLine("Exit=" + (int)(100.0f * fastLightOSNum[2] / fastTotalNum));
					}

					output.WriteLine("[Oversteer.Fast.Medium]");

					if (fastTotalNum > 0)
					{
						output.WriteLine("Entry=" + (int)(100.0f * fastMediumOSNum[0] / fastTotalNum));
						output.WriteLine("Apex=" + (int)(100.0f * fastMediumOSNum[1] / fastTotalNum));
						output.WriteLine("Exit=" + (int)(100.0f * fastMediumOSNum[2] / fastTotalNum));
					}

					output.WriteLine("[Oversteer.Fast.Heavy]");

					if (fastTotalNum > 0)
					{
						output.WriteLine("Entry=" + (int)(100.0f * fastHeavyOSNum[0] / fastTotalNum));
						output.WriteLine("Apex=" + (int)(100.0f * fastHeavyOSNum[1] / fastTotalNum));
						output.WriteLine("Exit=" + (int)(100.0f * fastHeavyOSNum[2] / fastTotalNum));
					}
				}

                output.Close();

                FileInfo info = new FileInfo(dataFile);

                info.Delete();

                info = new FileInfo(dataFile + ".tmp");

                info.MoveTo(dataFile);
            }
            catch (Exception)
            {
                try
                {
                    output.Close();
                }
                catch (Exception)
                {
                }

                // retry next round...
            }
        }

        double initialX = 0.0d;
		double initialY = 0.0d;
		int coordCount = 0;

		bool writeCoordinates(ref rF2VehicleScoring playerScoring)
		{
			double lVelocityX = playerScoring.mLocalVel.x;
			double lVelocityY = playerScoring.mLocalVel.y;
			double lVelocityZ = playerScoring.mLocalVel.z;

			int carID = 0;

			for (int i = 0; i < scoring.mScoringInfo.mNumVehicles; ++i)
				if (scoring.mVehicles[i].mIsPlayer != 0)
				{
					carID = i;

					break;
				}

			var ori = playerScoring.mOri;

			double velocityX = ori[RowX].x * lVelocityX + ori[RowX].y * lVelocityY + ori[RowX].z * lVelocityZ;
			double velocityY = ori[RowY].x * lVelocityX + ori[RowY].y * lVelocityY + ori[RowY].z * lVelocityZ;
			double velocityZ = (ori[RowZ].x * lVelocityX + ori[RowZ].y * lVelocityY + ori[RowZ].z * lVelocityZ) * -1;

			if ((velocityX != 0) || (velocityY != 0) || (velocityZ != 0))
			{
				double coordinateX = playerScoring.mPos.x;
				double coordinateY = (- playerScoring.mPos.z);
				
				Console.WriteLine(coordinateX + "," + coordinateY);

				if (coordCount == 0)
				{
					initialX = coordinateX;
					initialY = coordinateY;
				}
				else if (coordCount > 100 && Math.Abs(coordinateX - initialX) < 10.0 && Math.Abs(coordinateY - initialY) < 10.0)
					return false;

				coordCount += 1;
			}

			return true;
		}

		float[] xCoordinates = new float[60];
		float[] yCoordinates = new float[60];
		int numCoordinates = 0;
		long lastUpdate = 0;

		void checkCoordinates(ref rF2VehicleScoring playerScoring)
		{
			if (DateTimeOffset.Now.ToUnixTimeMilliseconds() > (lastUpdate + 2000))
			{
				double lVelocityX = playerScoring.mLocalVel.x;
				double lVelocityY = playerScoring.mLocalVel.y;
				double lVelocityZ = playerScoring.mLocalVel.z;

				int carID = 0;

				for (int i = 0; i < scoring.mScoringInfo.mNumVehicles; ++i)
					if (scoring.mVehicles[i].mIsPlayer != 0)
					{
						carID = i;

						break;
					}

				var ori = playerScoring.mOri;

				double velocityX = ori[RowX].x * lVelocityX + ori[RowX].y * lVelocityY + ori[RowX].z * lVelocityZ;
				double velocityY = ori[RowY].x * lVelocityX + ori[RowY].y * lVelocityY + ori[RowY].z * lVelocityZ;
				double velocityZ = (ori[RowZ].x * lVelocityX + ori[RowZ].y * lVelocityY + ori[RowZ].z * lVelocityZ) * -1;

				if ((velocityX != 0) || (velocityY != 0) || (velocityZ != 0))
				{
					double coordinateX = playerScoring.mPos.x;
					double coordinateY = (- playerScoring.mPos.z);

					for (int i = 0; i < numCoordinates; i += 1)
					{
						if (Math.Abs(xCoordinates[i] - coordinateX) < 20 && Math.Abs(yCoordinates[i] - coordinateY) < 20)
						{
							SendAutomationMessage("positionTrigger:" + (i + 1) + ";" + xCoordinates[i] + ";" + yCoordinates[i]);

							lastUpdate = DateTimeOffset.Now.ToUnixTimeMilliseconds();

							break;
						}
					}
				}
			}
		}

		public void initializeTrigger(string[] args)
        {
			for (int i = 1; i < (args.Length - 1); i += 2)
			{
				xCoordinates[numCoordinates] = float.Parse(args[i]);
				yCoordinates[numCoordinates] = float.Parse(args[i + 1]);

				numCoordinates += 1;
			}
        }

        public void initializeAnalyzer(bool calibrateTelemetry, string[] args)
        {
            dataFile = args[1];
			
			calibrate = calibrateTelemetry;
			
			if (calibrate) {
				lowspeedThreshold = int.Parse(args[2]);
				steerLock = int.Parse(args[3]);
				steerRatio = int.Parse(args[4]);
				wheelbase = int.Parse(args[5]);
				trackWidth = int.Parse(args[6]);
			}
			else {
				understeerLightThreshold = int.Parse(args[2]);
				understeerMediumThreshold = int.Parse(args[3]);
				understeerHeavyThreshold = int.Parse(args[4]);
				oversteerLightThreshold = int.Parse(args[5]);
				oversteerMediumThreshold = int.Parse(args[6]);
				oversteerHeavyThreshold = int.Parse(args[7]);
				lowspeedThreshold = int.Parse(args[8]);
				steerLock = int.Parse(args[9]);
				steerRatio = int.Parse(args[10]);
				wheelbase = int.Parse(args[11]);
				trackWidth = int.Parse(args[12]);
			}
        }

        public void Run(bool mapTrack, bool positionTrigger, bool analyzeTelemetry) {
            bool running = false;
			int countdown = 4000;
			long counter = 0;

			while (true) {
				counter++;

				if (!connected)
					Connect();

				if (connected)
				{
					try
					{
						extendedBuffer.GetMappedData(ref extended);
                        scoringBuffer.GetMappedData(ref scoring);
                        telemetryBuffer.GetMappedData(ref telemetry);
                    }
					catch (Exception)
					{
						this.Disconnect();
					}

					if (connected) {
						bool wait = true;

						rF2VehicleScoring playerScoring = GetPlayerScoring(ref scoring);

                        if (analyzeTelemetry)
                        {
                            if (collectTelemetry())
							{
                                if (counter % 20 == 0)
                                    writeTelemetry();
                            }
                            else
                                break;
                        }
                        else if (mapTrack)
						{
							if (!writeCoordinates(ref playerScoring))
								break;
						}
						else if (positionTrigger)
							checkCoordinates(ref playerScoring);
						else
						{
							bool startGo = (scoring.mScoringInfo.mGamePhase == (byte)rF2GamePhase.GreenFlag);

							if (!running)
							{
								countdown -= 1;

								if (!greenFlagReported && (countdown <= 0))
									greenFlagReported = true;

								if (startGo || (countdown <= 0))
									running = true;
							}

							if (running)
							{
								if (extended.mSessionStarted != 0 && scoring.mScoringInfo.mGamePhase < (byte)SessionStopped &&
									playerScoring.mPitState < (byte)Entering)
								{
									cycle += 1;

									if (!startGo || !greenFlag())
										if (!checkFlagState(ref playerScoring) && !checkPositions(ref playerScoring))
											wait = !checkPitWindow(ref playerScoring);
										else
											wait = false;
								}
								else
								{
									longitudinalRearDistance = 5;
									
									lastSituation = CLEAR;
									carBehind = false;
									carBehindReported = false;

									lastFlagState = 0;
								}
							}
						}

                        if (analyzeTelemetry)
                            Thread.Sleep(10);
                        else if (positionTrigger)
                            Thread.Sleep(10);
                        else if (wait)
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
