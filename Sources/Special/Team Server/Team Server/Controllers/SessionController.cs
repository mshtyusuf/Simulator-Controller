﻿using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using TeamServer.Model;
using TeamServer.Model.Access;
using TeamServer.Server;

namespace TeamServer.Controllers {
    [ApiController]
    [Route("api/[controller]")]
    public class SessionController : ControllerBase {
        private readonly ILogger<SessionController> _logger;

        public SessionController(ILogger<SessionController> logger) {
            _logger = logger;
        }

        [HttpGet("allsessions")]
        public String GetSessions([FromQuery(Name = "token")] string token) {
            try {
                SessionManager sessionManager = new SessionManager(Server.TeamServer.ObjectManager, Server.TeamServer.TokenIssuer.ValidateToken(token));

                return String.Join(";", sessionManager.GetAllSessions().Select(a => a.Identifier));
            }
            catch (AggregateException exception) {
                return "Error: " + exception.InnerException.Message;
            }
            catch (Exception exception) {
                return "Error: " + exception.Message;
            }
        }

        [HttpGet("{identifier}")]
        public string Get([FromQuery(Name = "token")] string token, string identifier) {
            try {
                SessionManager sessionManager = new SessionManager(Server.TeamServer.ObjectManager, Server.TeamServer.TokenIssuer.ValidateToken(token));
                Session session = sessionManager.LookupSession(identifier);

                return ControllerUtils.SerializeObject(session, new List<string>(new string[] { "Identifier", "Name", "Duration", "Started", "Finished", "Car", "Track", "RaceNr" }));
            }
            catch (Exception exception) {
                return "Error: " + exception.Message;
            }
        }

        [HttpGet("{identifier}/team")]
        public string GetTeam([FromQuery(Name = "token")] string token, string identifier) {
            try {
                SessionManager sessionManager = new SessionManager(Server.TeamServer.ObjectManager, Server.TeamServer.TokenIssuer.ValidateToken(token));
                
                return sessionManager.LookupSession(identifier).Team.Identifier.ToString();
            }
            catch (Exception exception) {
                return "Error: " + exception.Message;
            }
        }

        [HttpGet("{identifier}/stint")]
        public string GetStint([FromQuery(Name = "token")] string token, string identifier) {
            try {
                SessionManager sessionManager = new SessionManager(Server.TeamServer.ObjectManager, Server.TeamServer.TokenIssuer.ValidateToken(token));
                Session session = sessionManager.LookupSession(identifier);
                Stint stint = session.GetCurrentStint();

                return (stint != null) ? stint.Identifier.ToString() : "Null";
            }
            catch (Exception exception) {
                return "Error: " + exception.Message;
            }
        }

        [HttpGet("{identifier}/stints")]
        public string GetStints([FromQuery(Name = "token")] string token, string identifier) {
            try {
                SessionManager sessionManager = new SessionManager(Server.TeamServer.ObjectManager, Server.TeamServer.TokenIssuer.ValidateToken(token));

                return String.Join(";", sessionManager.LookupSession(identifier).Stints.OrderBy(s => s.Nr).Select(s => s.Identifier));
            }
            catch (Exception exception) {
                return "Error: " + exception.Message;
            }
        }

        [HttpPut("{identifier}")]
        public string Put([FromQuery(Name = "token")] string token, string identifier, [FromBody] string keyValues) {
            try {
                SessionManager sessionManager = new SessionManager(Server.TeamServer.ObjectManager, Server.TeamServer.TokenIssuer.ValidateToken(token));
                Session session = sessionManager.LookupSession(identifier);

                ControllerUtils.DeserializeObject(session, keyValues);

                session.Save();

                return "Ok";
            }
            catch (Exception exception) {
                return "Error: " + exception.Message;
            }
        }

        [HttpPut("{identifier}/start")]
        public string StartSession([FromQuery(Name = "token")] string token, string identifier) {
            try {
                SessionManager sessionManager = new SessionManager(Server.TeamServer.ObjectManager, Server.TeamServer.TokenIssuer.ValidateToken(token));

                sessionManager.StartSession(identifier);

                return "Ok";
            }
            catch (Exception exception) {
                return "Error: " + exception.Message;
            }
        }

        [HttpPut("{identifier}/finish")]
        public string FinishSession([FromQuery(Name = "token")] string token, string identifier) {
            try {
                SessionManager sessionManager = new SessionManager(Server.TeamServer.ObjectManager, Server.TeamServer.TokenIssuer.ValidateToken(token));

                sessionManager.FinishSession(identifier);

                return "Ok";
            }
            catch (Exception exception) {
                return "Error: " + exception.Message;
            }
        }

        [HttpPost]
        public string Post([FromQuery(Name = "token")] string token, [FromQuery(Name = "team")] string team, [FromBody] string keyValues) {
            try {
                Token theToken = Server.TeamServer.TokenIssuer.ValidateToken(token);
                Team theTeam = new TeamManager(Server.TeamServer.ObjectManager, theToken).LookupTeam(team);
                SessionManager sessionManager = new SessionManager(Server.TeamServer.ObjectManager, theToken);

                Dictionary<string, string> properties = ControllerUtils.ParseKeyValues(keyValues);

                return sessionManager.CreateSession(theTeam,
                                                    name: properties.GetValueOrDefault<string, string>("Name", "Unknown"),
                                                    duration: Int32.Parse(properties["Duration"]),
                                                    car: properties.GetValueOrDefault<string, string>("Car", "Unknown"),
                                                    track: properties.GetValueOrDefault<string, string>("Track", "Unknown"),
                                                    raceNr: properties.GetValueOrDefault<string, string>("RaceNr", "Unknown")).Identifier.ToString();
            }
            catch (Exception exception) {
                return "Error: " + exception.Message;
            }
        }

        [HttpDelete("{identifier}")]
        public String Delete([FromQuery(Name = "token")] string token, string identifier) {
            try {
                SessionManager sessionManager = new SessionManager(Server.TeamServer.ObjectManager, Server.TeamServer.TokenIssuer.ValidateToken(token));

                sessionManager.DeleteSession(identifier);

                return "Ok";
            }
            catch (Exception exception) {
                return "Error: " + exception.Message;
            }
        }
    }

    [ApiController]
    [Route("api/[controller]")]
    public class StintController : ControllerBase {
        private readonly ILogger<StintController> _logger;

        public StintController(ILogger<StintController> logger) {
            _logger = logger;
        }

        [HttpGet("{identifier}")]
        public string Get([FromQuery(Name = "token")] string token, string identifier) {
            try {
                SessionManager sessionManager = new SessionManager(Server.TeamServer.ObjectManager, Server.TeamServer.TokenIssuer.ValidateToken(token));
                Stint stint = sessionManager.LookupStint(identifier);

                return ControllerUtils.SerializeObject(stint, new List<string>(new string[] { "Identifier", "Nr", "Lap" }));
            }
            catch (Exception exception) {
                return "Error: " + exception.Message;
            }
        }

        [HttpGet("{identifier}/pitstopdata")]
        public string GetPitstopData([FromQuery(Name = "token")] string token, string identifier) {
            try {
                SessionManager sessionManager = new SessionManager(Server.TeamServer.ObjectManager, Server.TeamServer.TokenIssuer.ValidateToken(token));
                Stint stint = sessionManager.LookupStint(identifier);

                return stint.PitstopData;
            }
            catch (Exception exception) {
                return "Error: " + exception.Message;
            }
        }

        [HttpGet("{identifier}/driver")]
        public string GetDriver([FromQuery(Name = "token")] string token, string identifier) {
            try {
                SessionManager sessionManager = new SessionManager(Server.TeamServer.ObjectManager, Server.TeamServer.TokenIssuer.ValidateToken(token));

                return sessionManager.LookupStint(identifier).Driver.Identifier.ToString();
            }
            catch (Exception exception) {
                return "Error: " + exception.Message;
            }
        }

        [HttpGet("{identifier}/lap")]
        public string GetLap([FromQuery(Name = "token")] string token, string identifier) {
            try {
                SessionManager sessionManager = new SessionManager(Server.TeamServer.ObjectManager, Server.TeamServer.TokenIssuer.ValidateToken(token));
                Stint stint = sessionManager.LookupStint(identifier);
                Lap lap = stint.GetCurrentLap();

                return (lap != null) ? lap.Identifier.ToString() : "Null";
            }
            catch (Exception exception) {
                return "Error: " + exception.Message;
            }
        }

        [HttpGet("{identifier}/laps")]
        public string GetLaps([FromQuery(Name = "token")] string token, string identifier) {
            try {
                SessionManager sessionManager = new SessionManager(Server.TeamServer.ObjectManager, Server.TeamServer.TokenIssuer.ValidateToken(token));

                return String.Join(";", sessionManager.LookupStint(identifier).Laps.OrderBy(l => l.Nr).Select(l => l.Identifier));
            }
            catch (Exception exception) {
                return "Error: " + exception.Message;
            }
        }

        [HttpPut("{identifier}/pitstopdata")]
        public string SetPitstopData([FromQuery(Name = "token")] string token, string identifier, [FromBody] string keyValues) {
            try {
                SessionManager sessionManager = new SessionManager(Server.TeamServer.ObjectManager, Server.TeamServer.TokenIssuer.ValidateToken(token));

                sessionManager.UpdatePitstopData(identifier, keyValues);

                return "Ok";
            }
            catch (Exception exception) {
                return "Error: " + exception.Message;
            }
        }

        [HttpPost]
        public string Post([FromQuery(Name = "token")] string token,
                           [FromQuery(Name = "session")] string session, [FromQuery(Name = "driver")] string driver,
                           [FromBody] string keyValues) {
            try {
                Token theToken = Server.TeamServer.TokenIssuer.ValidateToken(token);
                SessionManager sessionManager = new SessionManager(Server.TeamServer.ObjectManager, theToken);
                Session theSession = sessionManager.LookupSession(session);
                Driver theDriver = new TeamManager(Server.TeamServer.ObjectManager, theToken).LookupDriver(driver);

                Dictionary<string, string> properties = ControllerUtils.ParseKeyValues(keyValues);

                return sessionManager.CreateStint(theSession, theDriver, lap: Int32.Parse(properties["Lap"])).Identifier.ToString();
            }
            catch (Exception exception) {
                return "Error: " + exception.Message;
            }
        }

        [HttpDelete("{identifier}")]
        public String Delete([FromQuery(Name = "token")] string token, string identifier) {
            try {
                SessionManager sessionManager = new SessionManager(Server.TeamServer.ObjectManager, Server.TeamServer.TokenIssuer.ValidateToken(token));

                sessionManager.DeleteStint(identifier);

                return "Ok";
            }
            catch (Exception exception) {
                return "Error: " + exception.Message;
            }
        }
    }


    [ApiController]
    [Route("api/[controller]")]
    public class LapController : ControllerBase {
        private readonly ILogger<LapController> _logger;

        public LapController(ILogger<LapController> logger) {
            _logger = logger;
        }

        [HttpGet("{identifier}")]
        public string Get([FromQuery(Name = "token")] string token, string identifier) {
            try {
                SessionManager sessionManager = new SessionManager(Server.TeamServer.ObjectManager, Server.TeamServer.TokenIssuer.ValidateToken(token));
                Lap lap = sessionManager.LookupLap(identifier);

                return ControllerUtils.SerializeObject(lap, new List<string>(new string[] { "Identifier", "Nr" }));
            }
            catch (Exception exception) {
                return "Error: " + exception.Message;
            }
        }

        [HttpGet("{identifier}/telemetrydata")]
        public string GetTelemetryData([FromQuery(Name = "token")] string token, string identifier) {
            try {
                SessionManager sessionManager = new SessionManager(Server.TeamServer.ObjectManager, Server.TeamServer.TokenIssuer.ValidateToken(token));
                Lap lap = sessionManager.LookupLap(identifier);

                return lap.TelemetryData;
            }
            catch (Exception exception) {
                return "Error: " + exception.Message;
            }
        }

        [HttpGet("{identifier}/positiondata")]
        public string GetPositionData([FromQuery(Name = "token")] string token, string identifier) {
            try {
                SessionManager sessionManager = new SessionManager(Server.TeamServer.ObjectManager, Server.TeamServer.TokenIssuer.ValidateToken(token));
                Lap lap = sessionManager.LookupLap(identifier);

                return lap.PositionData;
            }
            catch (Exception exception) {
                return "Error: " + exception.Message;
            }
        }

        [HttpPut("{identifier}/telemetrydata")]
        public string SetTelemetryData([FromQuery(Name = "token")] string token, string identifier, [FromBody] string keyValues) {
            try {
                SessionManager sessionManager = new SessionManager(Server.TeamServer.ObjectManager, Server.TeamServer.TokenIssuer.ValidateToken(token));

                sessionManager.UpdateTelemetryData(identifier, keyValues);

                return "Ok";
            }
            catch (Exception exception) {
                return "Error: " + exception.Message;
            }
        }

        [HttpPut("{identifier}/positiondata")]
        public string SetPositionData([FromQuery(Name = "token")] string token, string identifier, [FromBody] string keyValues) {
            try {
                SessionManager sessionManager = new SessionManager(Server.TeamServer.ObjectManager, Server.TeamServer.TokenIssuer.ValidateToken(token));

                sessionManager.UpdatePositionData(identifier, keyValues);

                return "Ok";
            }
            catch (Exception exception) {
                return "Error: " + exception.Message;
            }
        }

        [HttpPost]
        public string Post([FromQuery(Name = "token")] string token, [FromQuery(Name = "stint")] string stint, [FromBody] string keyValues) {
            try {
                Token theToken = Server.TeamServer.TokenIssuer.ValidateToken(token);
                SessionManager sessionManager = new SessionManager(Server.TeamServer.ObjectManager, theToken);
                Stint theStint = sessionManager.LookupStint(stint);
                
                Dictionary<string, string> properties = ControllerUtils.ParseKeyValues(keyValues);

                return sessionManager.CreateLap(theStint, lap: Int32.Parse(properties["Nr"])).Identifier.ToString();
            }
            catch (Exception exception) {
                return "Error: " + exception.Message;
            }
        }

        [HttpDelete("{identifier}")]
        public String Delete([FromQuery(Name = "token")] string token, string identifier) {
            try {
                SessionManager sessionManager = new SessionManager(Server.TeamServer.ObjectManager, Server.TeamServer.TokenIssuer.ValidateToken(token));

                sessionManager.DeleteLap(identifier);

                return "Ok";
            }
            catch (Exception exception) {
                return "Error: " + exception.Message;
            }
        }
    }
}