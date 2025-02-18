﻿using SQLite;

namespace TeamServer.Model {
    public class ModelManager {
        public SQLiteAsyncConnection Connection { get; private set; }

        public ModelManager(SQLiteAsyncConnection connection) {
            Connection = connection;
        }

        public void CreateTables()
        {
            CreateAttributeTable();
            CreateTaskTable();

            CreateAccountTable();
            CreateAccessTables();
            CreateTeamTables();
            CreateSessionTables();

            CreateDataTables();
        }

        protected void CreateAttributeTable()
        {
            Connection.CreateTableAsync<Attribute>().Wait();
        }

        protected void CreateTaskTable()
        {
            Connection.CreateTableAsync<Model.Task.Task>().Wait();
        }

        protected void CreateAccountTable() {
            Connection.CreateTableAsync<Access.Account>().Wait();
        }

        protected void CreateAccessTables()
        {
            Connection.CreateTableAsync<Access.Token>().Wait();
            Connection.CreateTableAsync<Access.Connection>().Wait();
        }

        protected void CreateTeamTables() {
            Connection.CreateTableAsync<Team>().Wait();
            Connection.CreateTableAsync<Driver>().Wait();
        }

        protected void CreateSessionTables() {
            Connection.CreateTableAsync<Session>().Wait();
            Connection.CreateTableAsync<Stint>().Wait();
            Connection.CreateTableAsync<Lap>().Wait();
        }

        protected void CreateDataTables()
        {
            Connection.CreateTableAsync<Data.Document>().Wait();
            Connection.CreateTableAsync<Data.License>().Wait();
            Connection.CreateTableAsync<Data.Electronics>().Wait();
            Connection.CreateTableAsync<Data.Tyres>().Wait();
            Connection.CreateTableAsync<Data.Brakes>().Wait();
            Connection.CreateTableAsync<Data.TyresPressures>().Wait();
            Connection.CreateTableAsync<Data.TyresPressuresDistribution>().Wait();
        }
    }
}