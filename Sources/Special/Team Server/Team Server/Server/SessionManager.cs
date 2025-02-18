﻿using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using TeamServer.Model;

namespace TeamServer.Server {
	public class SessionManager : ManagerBase
    {
        public SessionManager(ObjectManager objectManager, Model.Access.Token token) : base(objectManager, token)
        {
        }
        public SessionManager(ObjectManager objectManager, Guid token) : base(objectManager, token)
        {
        }
        public SessionManager(ObjectManager objectManager, string token) : base(objectManager, token)
        {
        }

        #region Validation
        public override Model.Access.Token ValidateToken(Model.Access.Token token)
		{
			token = base.ValidateToken(token);

			if (!token.HasAccess(Model.Access.Token.TokenType.Session))
				throw new Exception("Token does not support session access...");
			
			return token;
		}

		public void ValidateAccount(int duration) {
			if (!Token.Account.Administrator)
				if (Token.Account.Contract == Model.Access.Account.ContractType.Expired)
					throw new Exception("Account is no longer valid...");
				else if (!Token.Account.SessionAccess)
					throw new Exception("Account does not support team sessions...");
				else if (Token.Account.Contract != Model.Access.Account.ContractType.Unlimited &&
						 (Token.Account.AvailableMinutes < duration))
					throw new Exception("Not enough time available on account...");
		}

		public void ValidateSession(Session session) {
			if (session == null)
				throw new Exception("Not a valid or active session...");
		}

		public void ValidateDriver(Driver driver) {
			if (driver == null)
				throw new Exception("Not a known driver...");
		}

		public void ValidateDriver(Team team, Driver driver) {
			if (driver.Team.Identifier != team.Identifier)
				throw new Exception("Driver not part of the team...");
		}

		public void ValidateDriver(Session session, Driver driver) {
			ValidateDriver(session.Team, driver);
		}

		public void ValidateStint(Stint stint) {
			if (stint == null)
				throw new Exception("Not a valid stint...");
		}

		public void ValidateStint(Session session, Stint stint) {
			ValidateSession(session);

			if (stint == null)
				throw new Exception("Not a valid stint...");
		}

		public void ValidateLap(Lap lap) {
			if (lap == null)
				throw new Exception("Not a valid lap...");
		}

		public void ValidateLap(Stint stint, Lap lap) {
			ValidateStint(stint);

			if (lap == null)
				throw new Exception("Not a valid lap...");
		}
		#endregion

		#region Session
		#region Query
		public List<Session> GetAllSessions()
		{
			return ObjectManager.GetAllSessionsAsync().Result;
		}

		public List<Session> GetSessions()
		{
			return Token.Account.Sessions;
		}

		public Session LookupSession(Guid identifier) {
			Session session = FindSession(identifier);

			ValidateSession(session);

			return session;
		}

		public Session LookupSession(string identifier) {
			return LookupSession(new Guid(identifier));
		}

		public Session FindSession(Guid identifier) {
			return ObjectManager.GetSessionAsync(identifier).Result;
		}

		public Session FindSession(string identifier) {
			return FindSession(new Guid(identifier));
		}
		#endregion

		#region CRUD
		public Session CreateSession(Team team, string name) {
			Session session = new Session { TeamID = team.ID, Name = name };

			ValidateSession(session);

			session.Save();

			return session;
		}

		public string GetSessionValue(Session session, string name) {
			ValidateSession(session);

			return ObjectManager.GetAttribute(session, name);
		}

		public string GetSessionValue(Guid identifier, string name) {
			return GetSessionValue(LookupSession(identifier), name);
		}

		public string GetSessionValue(string identifier, string name) {
			return GetSessionValue(new Guid(identifier), name);
		}

		public void SetSessionValue(Session session, string name, string value)	{
			ValidateSession(session);

			ObjectManager.SetAttribute(session, name, value);
		}

		public void SetSessionValue(Guid identifier, string name, string value) {
			SetSessionValue(LookupSession(identifier), name, value);
		}

		public void SetSessionValue(string identifier, string name, string value) {
			SetSessionValue(new Guid(identifier), name, value);
		}

		public void DeleteSessionValue(Session session, string name) {
			ValidateSession(session);

			ObjectManager.DeleteAttribute(session, name);
		}

		public void DeleteSessionValue(Guid identifier, string name) {
			DeleteSessionValue(LookupSession(identifier), name);
		}

		public void DeleteSessionValue(string identifier, string name) {
			DeleteSessionValue(new Guid(identifier), name);
		}

		public void DeleteSession(Session session) {
			if (session != null)
				session.Delete();
		}

		public void DeleteSession(Guid identifier) {
			DeleteSession(ObjectManager.GetSessionAsync(identifier).Result);
		}

		public void DeleteSession(string identifier) {
			DeleteSession(new Guid(identifier));
		}
		#endregion

		#region Operations
		public Session StartSession(Session session, int duration, string car, string track) {
			ValidateSession(session);
			ValidateAccount(duration);

			ClearSession(session);
			
			session.Duration = duration;
			session.Car = car;
			session.Track = track;
			session.StartTime = DateTime.Now;
			session.FinishTime = DateTime.MinValue;
			session.Started = true;
			session.Finished = false;

			session.Save();
			
			return session;
		}

		public Session StartSession(Guid identifier, int duration, string car, string track) {
			return StartSession(ObjectManager.GetSessionAsync(identifier).Result, duration, car, track);
		}

		public Session StartSession(string identifier, int duration, string car, string track) {
			return StartSession(new Guid(identifier), duration, car, track);
		}

		public void FinishSession(Session session) {
			ValidateSession(session);

			if (session.Started && !session.Finished) {
				var account = Token.Account;

				account.AvailableMinutes -= (int)Math.Round((DateTime.Now - session.StartTime).TotalMinutes);

				session.Started = false;
				session.Finished = true;
				session.FinishTime = DateTime.Now;

				account.Save();
				session.Save();
			}
		}

		public void FinishSession(Guid identifier) {
			FinishSession(ObjectManager.GetSessionAsync(identifier).Result);
		}

		public void FinishSession(string identifier) {
			FinishSession(new Guid(identifier));
		}

		public void ClearSession(Session session) {
			ValidateSession(session);

			// foreach (Model.Attribute attribute in session.Attributes)
			//	attribute.Delete();

			foreach (Stint stint in session.Stints)
				stint.Delete();
		}

		public void ClearSession(Guid identifier) {
			ClearSession(ObjectManager.GetSessionAsync(identifier).Result);
		}

		public void ClearSession(string identifier) {
			ClearSession(new Guid(identifier));
		}

		public async void DeleteSessionsAsync() {
			TeamServer.TokenIssuer.ElevateToken(Token);

			await ObjectManager.Connection.QueryAsync<Session>(
				@"
                    Select * From Sessions Where Finished = ? And FinishTime < ?
                ", true, DateTime.Now.AddHours(1)).ContinueWith(t => t.Result.ForEach(s => {
					DeleteSession(s);
				}));
		}

		public async void CleanupSessionsAsync() {
			TeamServer.TokenIssuer.ElevateToken(Token);

			await ObjectManager.Connection.QueryAsync<Session>(
				@"
                    Select * From Sessions Where Finished = ? And FinishTime < ?
                ", true, DateTime.Now.AddHours(1)).ContinueWith(t => t.Result.ForEach(s => {
					foreach (Model.Attribute attribute in s.Attributes)
						attribute.Delete();

					foreach (Stint stint in s.Stints) {
						foreach (Model.Attribute attribute in stint.Attributes)
							attribute.Delete();

						foreach (Lap lap in stint.Laps)
							foreach (Model.Attribute attribute in lap.Attributes)
								attribute.Delete();
					}
				}));
		}

		public async void ResetSessionsAsync() {
			TeamServer.TokenIssuer.ElevateToken(Token);

			await ObjectManager.Connection.QueryAsync<Session>(
				@"
                    Select * From Sessions Where Finised = ? And FinishTime < ?
                ", true, DateTime.Now.AddHours(1)).ContinueWith(t => t.Result.ForEach(s => {
					foreach (Stint stint in s.Stints)
						stint.Delete();

					s.Started = false;
					s.Finished = false;
					s.StartTime = DateTime.MinValue;
					s.FinishTime = DateTime.MinValue;
				}));
		}
		#endregion
		#endregion

		#region Stint
		#region Query
		public Stint LookupStint(Guid identifier) {
			Stint stint = FindStint(identifier);

			ValidateStint(stint);

			return stint;
		}

		public Stint LookupStint(string identifier) {
			return LookupStint(new Guid(identifier));
		}
		
		public Stint LookupStint(Session session, int stintNr) {
			Stint stint = FindStint(session, stintNr);
			
			ValidateStint(stint);
			
			return stint;
		}

		public Stint FindStint(Guid identifier) {
			return ObjectManager.GetStintAsync(identifier).Result;
		}

		public Stint FindStint(string identifier) {
			return FindStint(new Guid(identifier));
		}
		
		public Stint FindStint(Session session, int stintNr) {
			Task<List<Stint>> task = ObjectManager.Connection.QueryAsync<Stint>(
				@"
                    Select * From Stints Where SessionID = ? And Nr = ?
                ", session.ID, stintNr);
			
			return (task.Result.Count == 0) ? null : task.Result[0];
		}
		#endregion

		#region CRUD
		public Stint CreateStint(Session session, Driver driver, int lap) {
			ValidateSession(session);
			ValidateDriver(driver);

			Task<List<Stint>> task = ObjectManager.Connection.QueryAsync<Stint>(
				@"
                    Select * From Stints Where SessionID = ? And DriverID = ? And Lap = ?
                ", session.ID, driver.ID, lap);

			if (task.Result.Count == 0) {
				Stint lastStint = session.GetCurrentStint();
				int stintNr = (lastStint != null) ? lastStint.Nr + 1 : 1;

				Stint stint = new Stint { SessionID = session.ID, DriverID = driver.ID, Nr = stintNr, Lap = lap };

				stint.Save();

				return stint;
			}
			else
				return task.Result[0];
		}

		public void DeleteStint(Stint stint) {
			if (stint != null)
				stint.Delete();
		}

		public void DeleteStint(Guid identifier) {
			DeleteStint(ObjectManager.GetStintAsync(identifier).Result);
		}

		public void DeleteStint(string identifier) {
			DeleteStint(new Guid(identifier));
		}
		#endregion

		#region Operations
		public string GetStintValue(Stint stint, string name) {
			ValidateStint(stint);

			return ObjectManager.GetAttribute(stint, name);
		}

		public string GetStintValue(Guid identifier, string name) {
			return GetStintValue(ObjectManager.GetStintAsync(identifier).Result, name);
		}

		public string GetStintValue(string identifier, string name) {
			return GetStintValue(new Guid(identifier), name);
		}

		public void SetStintValue(Stint stint, string name, string value) {
			ValidateStint(stint);

			ObjectManager.SetAttribute(stint, name, value);
		}

		public void SetStintValue(Guid identifier, string name, string value) {
			SetStintValue(ObjectManager.GetStintAsync(identifier).Result, name, value);
		}

		public void SetStintValue(string identifier, string name, string value) {
			SetStintValue(new Guid(identifier), name, value);
		}

		public void DeleteStintValue(Stint stint, string name) {
			ValidateStint(stint);

			ObjectManager.DeleteAttribute(stint, name);
		}

		public void DeleteStintValue(Guid identifier, string name) {
			DeleteStintValue(ObjectManager.GetStintAsync(identifier).Result, name);
		}

		public void DeleteStintValue(string identifier, string name) {
			DeleteStintValue(new Guid(identifier), name);
		}
		#endregion
		#endregion

		#region Lap
		#region Query
		public Lap LookupLap(Guid identifier) {
			Lap lap = FindLap(identifier);

			ValidateLap(lap);

			return lap;
		}

		public Lap LookupLap(string identifier) {
			return LookupLap(new Guid(identifier));
		}

		public Lap FindLap(Guid identifier) {
			return ObjectManager.GetLapAsync(identifier).Result;
		}

		public Lap FindLap(string identifier) {
			return FindLap(new Guid(identifier));
		}
		#endregion

		#region CRUD
		public Lap CreateLap(Stint stint, int lap) {
			ValidateStint(stint);

			Task<List<Lap>> task = ObjectManager.Connection.QueryAsync<Lap>(
				@"
                    Select * From Laps Where StintID = ? And Nr = ?
                ", stint.ID, lap);

			if (task.Result.Count == 0) {
				Lap theLap = new Lap { SessionID = stint.Session.ID, StintID = stint.ID, Nr = lap };

				theLap.Save();

				return theLap;
			}
			else
				return task.Result[0];
		}

		public void DeleteLap(Lap lap) {
			if (lap != null)
				lap.Delete();
		}

		public void DeleteLap(Guid identifier) {
			DeleteLap(ObjectManager.GetLapAsync(identifier).Result);
		}

		public void DeleteLap(string identifier) {
			DeleteLap(new Guid(identifier));
		}
		#endregion

		#region Operations
		public string GetLapValue(Lap lap, string name) {
			ValidateLap(lap);

			return ObjectManager.GetAttribute(lap, name);
		}

		public string GetLapValue(Guid identifier, string name) {
			return GetLapValue(ObjectManager.GetLapAsync(identifier).Result, name);
		}

		public string GetLapValue(string identifier, string name) {
			return GetLapValue(new Guid(identifier), name);
		}

		public void SetLapValue(Lap lap, string name, string value) {
			ValidateLap(lap);

			ObjectManager.SetAttribute(lap, name, value);
		}

		public void SetLapValue(Guid identifier, string name, string value) {
			SetLapValue(ObjectManager.GetLapAsync(identifier).Result, name, value);
		}

		public void SetLapValue(string identifier, string name, string value) {
			SetLapValue(new Guid(identifier), name, value);
		}

		public void DeleteLapValue(Lap lap, string name) {
			ValidateLap(lap);

			ObjectManager.DeleteAttribute(lap, name);
		}

		public void DeleteLapValue(Guid identifier, string name) {
			DeleteLapValue(ObjectManager.GetLapAsync(identifier).Result, name);
		}

		public void DeleteLapValue(string identifier, string name) {
			DeleteLapValue(new Guid(identifier), name);
		}
		#endregion
		#endregion
	}
}