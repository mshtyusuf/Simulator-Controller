// Used for memory-mapped functionality
#include <windows.h>
#include <math.h>
#include "sharedmemory.h"

// Used for this example
#include <stdio.h>
#include <conio.h>

// Name of the pCars memory mapped file
#define MAP_OBJECT_NAME "$pcars2$"

inline double normalize(double value) {
	return (value < 0) ? 0.0 : value;
}

void substring(char s[], char sub[], int p, int l) {
	int c = 0;

	while (c < l) {
		sub[c] = s[p + c];

		c++;
	}
	sub[c] = '\0';
}

int sendStringMessage(HWND hWnd, int wParam, char* msg) {
	int result = 0;

	if (hWnd > 0) {
		COPYDATASTRUCT cds;
		cds.dwData = (256 * 'R' + 'S');
		cds.cbData = sizeof(char) * (strlen(msg) + 1);
		cds.lpData = msg;

		result = SendMessage(hWnd, WM_COPYDATA, wParam, (LPARAM)(LPVOID)&cds);
	}

	return result;
}

void sendMessage(char* message) {
	HWND winHandle = FindWindowExA(0, 0, 0, "Race Spotter.exe");

	if (winHandle == 0)
		FindWindowExA(0, 0, 0, "Race Spotter.ahk");

	if (winHandle != 0) {
		char buffer[128];

		strcpy_s(buffer, 128, "Race Spotter:");
		strcpy_s(buffer + strlen("Race Spotter:"), 128 - strlen("Race Spotter:"), message);

		sendStringMessage(winHandle, 0, buffer);
	}
}

#define PI 3.14159265

const float nearByDistance = 8.0;
const float longitudinalDistance = 4;
const float lateralDistance = 6;
const float verticalDistance = 2;

const int CLEAR = 0;
const int LEFT = 1;
const int RIGHT = 2;
const int THREE = 3;

const int situationRepeat = 5;

const char* noAlert = "NoAlert";

int lastSituation = CLEAR;
int situationCount = 0;

bool carBehind = false;
bool carBehindReported = false;

const int YELLOW = 1;

const int BLUE = 16;

int blueCount = 0;

int lastFlagState = 0;

bool pitWindowOpenReported = false;
bool pitWindowClosedReported = true;

const char* computeAlert(int newSituation) {
	const char* alert = noAlert;

	if (lastSituation == newSituation) {
		if (lastSituation > CLEAR) {
			if (situationCount++ > situationRepeat) {
				situationCount = 0;

				alert = "Hold";
			}
		}
		else
			situationCount = 0;
	}
	else {
		situationCount = 0;

		if (lastSituation == CLEAR) {
			switch (newSituation) {
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
		else {
			switch (newSituation) {
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

float vectorAngle(float x, float y) {
	float scalar = (x * 0) + (y * 1);
	float length = sqrt((x * x) + (y * y));

	float angle = (length > 0) ? acos(scalar / length) * 180 / PI : 0;

	if (x < 0)
		angle = 360 - angle;

	return angle;
}

bool nearBy(float car1X, float car1Y, float car1Z,
	float car2X, float car2Y, float car2Z) {
	return (fabs(car1X - car2X) < nearByDistance) &&
		(fabs(car1Y - car2Y) < nearByDistance) &&
		(fabs(car1Z - car2Z) < nearByDistance);
}

void rotateBy(float* x, float* y, float angle) {
	float sinus = sin(angle * PI / 180);
	float cosinus = cos(angle * PI / 180);

	float newX = (*x * cosinus) - (*y * sinus);
	float newY = (*x * sinus) + (*y * cosinus);

	*x = newX;
	*y = newY;
}

int checkCarPosition(float carX, float carY, float carZ, float angle,
					 float otherX, float otherY, float otherZ) {
	if (nearBy(carX, carY, carZ, otherX, otherY, otherZ)) {
		float transX = (otherX - carX);
		float transY = (otherY - carY);

		rotateBy(&transX, &transY, angle);

		if ((fabs(transY) < longitudinalDistance) && (fabs(transX) < lateralDistance) && (fabs(otherZ - carZ) < verticalDistance))
			return (transX > 0) ? RIGHT : LEFT;
		else {
			if (transY < 0)
				carBehind = true;

			return CLEAR;
		}
	}
	else
		return CLEAR;
}

bool checkPositions(const SharedMemory* sharedData) {
	float velocityX = sharedData->mWorldVelocity[VEC_X];
	float velocityY = sharedData->mWorldVelocity[VEC_Z];
	float velocityZ = sharedData->mWorldVelocity[VEC_Y];

	if ((velocityX != 0) || (velocityY != 0) || (velocityZ != 0)) {
		float angle = vectorAngle(velocityX, velocityY);

		int carID = sharedData->mViewedParticipantIndex;

		float coordinateX = sharedData->mParticipantInfo[carID].mWorldPosition[VEC_X];
		float coordinateY = sharedData->mParticipantInfo[carID].mWorldPosition[VEC_Z];
		float coordinateZ = sharedData->mParticipantInfo[carID].mWorldPosition[VEC_Y];

		int newSituation = CLEAR;

		carBehind = false;

		for (int id = 0; id < sharedData->mNumParticipants; id++) {
			if (id != carID)
				newSituation |= checkCarPosition(coordinateX, coordinateY, coordinateZ, angle,
												 sharedData->mParticipantInfo[id].mWorldPosition[VEC_X],
												 sharedData->mParticipantInfo[id].mWorldPosition[VEC_Z],
												 sharedData->mParticipantInfo[id].mWorldPosition[VEC_Y]);

			if ((newSituation == THREE) && carBehind)
				break;
		}

		const char* alert = computeAlert(newSituation);

		if (alert != noAlert) {
			carBehindReported = false;

			char buffer[128];

			strcpy_s(buffer, 128, "proximityAlert:");
			strcpy_s(buffer + strlen("proximityAlert:"), 128 - strlen("proximityAlert:"), alert);

			sendMessage(buffer);

			return true;
		}
		else if (carBehind) {
			if (!carBehindReported) {
				carBehindReported = true;

				sendMessage("proximityAlert:Behind");

				return true;
			}
		}
		else
			carBehindReported = false;
	}
	else {
		lastSituation = CLEAR;
		carBehind = false;
		carBehindReported = false;
	}

	return false;
}

bool checkFlagState(const SharedMemory* sharedData) {
	if (sharedData->mHighestFlagColour == FLAG_COLOUR_BLUE) {
		if ((lastFlagState & BLUE) == 0) {
			sendMessage("blueFlag");

			lastFlagState |= BLUE;

			return true;
		}
		else if (blueCount++ > 100) {
			lastFlagState &= ~BLUE;

			blueCount = 0;
		}
	}
	else {
		lastFlagState &= ~BLUE;

		blueCount = 0;
	}

	if (sharedData->mHighestFlagColour == FLAG_COLOUR_YELLOW || sharedData->mHighestFlagColour == FLAG_COLOUR_DOUBLE_YELLOW) {
		if ((lastFlagState & YELLOW) == 0) {
			sendMessage("yellowFlag:Ahead");

			lastFlagState |= YELLOW;

			return true;
		}
	}
	else if ((lastFlagState & YELLOW) != 0) {
		sendMessage("yellowFlag:Clear");

		lastFlagState &= ~YELLOW;

		return true;
	}

	return false;
}

void checkPitWindow(const SharedMemory* sharedData) {
	if (sharedData->mEnforcedPitStopLap > 0)
		if ((sharedData->mEnforcedPitStopLap == sharedData->mParticipantInfo[sharedData->mViewedParticipantIndex].mLapsCompleted) &&
			!pitWindowOpenReported) {
			pitWindowOpenReported = true;
			pitWindowClosedReported = false;

			sendMessage("pitWindow:Open");
		}
		else if ((sharedData->mEnforcedPitStopLap < sharedData->mParticipantInfo[sharedData->mViewedParticipantIndex].mLapsCompleted) &&
			!pitWindowClosedReported) {
			pitWindowClosedReported = true;
			pitWindowOpenReported = false;

			sendMessage("pitWindow:Closed");
		}
}

int main(int argc, char* argv[]) {
	// Open the memory-mapped file
	HANDLE fileHandle = OpenFileMappingA(PAGE_READONLY, FALSE, MAP_OBJECT_NAME);

	const SharedMemory* sharedData = NULL;
	SharedMemory* localCopy = NULL;

	if (fileHandle != NULL) {
		sharedData = (SharedMemory*)MapViewOfFile(fileHandle, PAGE_READONLY, 0, 0, sizeof(SharedMemory));
		localCopy = new SharedMemory;
	
		if (sharedData == NULL) {
			CloseHandle(fileHandle);

			fileHandle = NULL;
		}
		/*
		else if (sharedData->mVersion != SHARED_MEMORY_VERSION) {
			CloseHandle(fileHandle);

			fileHandle = NULL;
		}
		*/

		//------------------------------------------------------------------------------
		// TEST DISPLAY CODE
		//------------------------------------------------------------------------------
		unsigned int updateIndex(0);
		unsigned int indexChange(0);

		while (true)
		{
			if (sharedData->mSequenceNumber % 2)
			{
				// Odd sequence number indicates, that write into the shared memory is just happening
				continue;
			}

			indexChange = sharedData->mSequenceNumber - updateIndex;
			updateIndex = sharedData->mSequenceNumber;

			//Copy the whole structure before processing it, otherwise the risk of the game writing into it during processing is too high.
			memcpy(localCopy, sharedData, sizeof(SharedMemory));

			if (localCopy->mSequenceNumber != updateIndex)
			{
				// More writes had happened during the read. Should be rare, but can happen.
				continue;
			}

			if (localCopy->mGameState != GAME_INGAME_PAUSED && localCopy->mPitMode == PIT_MODE_NONE) {
				if (!checkFlagState(localCopy) && !checkPositions(localCopy))
					checkPitWindow(localCopy);
			}
			else {
				lastSituation = CLEAR;
				carBehind = false;
				carBehindReported = false;

				lastFlagState = 0;
			}

			Sleep(50);
		}
	}

	//------------------------------------------------------------------------------

	// Cleanup
	UnmapViewOfFile(sharedData);
	CloseHandle(fileHandle);
	delete localCopy;

	return 0;
}