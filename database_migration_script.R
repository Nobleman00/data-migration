#Loading libraries
library(nycflights23)
library(DBI)
library(RPostgres)
library(yaml)

# Database Connection
# Database connection function
db_connection <- function(config){
   # Load Yaml file
   cnf <- yaml.load_file(config)
   pg_cnf <- cnf[['postgres']]
   
   # Create connection to PostgreSQL server (not a specific database yet) so the Rscript can execute the code to create the flights database
   conn <- dbConnect(
      Postgres(),
      dbname = "postgres",  # Connecting to the default 'postgres' database
      host = pg_cnf[["host"]],  # Access host key
      port = as.integer(pg_cnf[["port"]]),  # Access port key
      user = pg_cnf[["user"]],  # Access user key
      password = pg_cnf[["password"]]  # Access password key
   )
   
   # Create the 'nycflights23' database
   dbExecute(conn, "CREATE DATABASE nycflights23")
   
   # To close the connection
   dbDisconnect(conn)
   
   # Connecting to the new database
   conn <- dbConnect(
      Postgres(),
      dbname = "nycflights23",  #To Connect to the newly created database
      host = pg_cnf[["host"]],
      port = as.integer(pg_cnf[["port"]]),
      user = pg_cnf[["user"]],
      password = pg_cnf[["password"]]
   )
   
   return(conn)
}

# Check if connection is established before proceeding
conn <- db_connection(config = "database_connect\\config.yaml")

# If the connection is successful, proceed to create schema
if (!is.null(conn)) {
   # Create schema if it doesn’t exist
   tryCatch({
      dbExecute(conn, "CREATE SCHEMA IF NOT EXISTS flights")
      cat("Schema created or already exists.\n")
   }, error = function(e) {
      cat("Error while creating schema:\n")
      print(e)
   })
   
   # Creating tables in PostgreSQL with names, data type and all
   tryCatch({
      dbExecute(conn, "
  CREATE TABLE IF NOT EXISTS flights.flights (
    year INT,
    month INT,
    day INT,
    dep_time INT,
    sched_dep_time INT,
    dep_delay DOUBLE PRECISION,
    arr_time INT,
    sched_arr_time INT,
    arr_delay DOUBLE PRECISION,
    carrier TEXT,
    flight INT,
    tailnum TEXT,
    origin TEXT,
    dest TEXT,
    air_time DOUBLE PRECISION,
    distance DOUBLE PRECISION,
    hour INT,
    minute INT,
    time_hour TIMESTAMP
  )
")
     
       # Alter flights table to add foreign keys
      dbExecute(conn, "
  ALTER TABLE flights.flights
  ADD CONSTRAINT unique_flight_date_time UNIQUE (year, month, day, hour, time_hour),
  ADD CONSTRAINT fk_carrier FOREIGN KEY (carrier) REFERENCES flights.airlines(carrier),
  ADD CONSTRAINT fk_origin FOREIGN KEY (origin) REFERENCES flights.airports(faa),
  ADD CONSTRAINT fk_dest FOREIGN KEY (dest) REFERENCES flights.airports(faa),
  ADD CONSTRAINT fk_tailnum FOREIGN KEY (tailnum) REFERENCES flights.planes(tailnum)
   ")
      cat("Table 'flights' created or already exists.\n")
   }, error = function(e) {
      cat("Error while creating 'flights' table:\n")
      print(e)
   })
   
   tryCatch({
      dbExecute(conn, "
      CREATE TABLE IF NOT EXISTS flights.airlines (
        carrier TEXT PRIMARY KEY,
        name TEXT
      )
    ")
      cat("Table 'airlines' created or already exists.\n")
   }, error = function(e) {
      cat("Error while creating 'airlines' table:\n")
      print(e)
   })
   
   tryCatch({
      dbExecute(conn, "
      CREATE TABLE IF NOT EXISTS flights.airports (
        faa TEXT PRIMARY KEY,
        name TEXT,
        lat DOUBLE PRECISION,
        lon DOUBLE PRECISION,
        alt INT,
        tz INT,
        dst TEXT,
        tzone TEXT
      )
    ")
      cat("Table 'airports' created or already exists.\n")
   }, error = function(e) {
      cat("Error while creating 'airports' table:\n")
      print(e)
   })
   
   tryCatch({
      dbExecute(conn, "
      CREATE TABLE IF NOT EXISTS flights.planes (
        tailnum TEXT PRIMARY KEY,
        year INT,
        type TEXT,
        manufacturer TEXT,
        model TEXT,
        engines INT,
        seats INT,
        speed INT,
        engine TEXT
      )
    ")
      cat("Table 'planes' created or already exists.\n")
   }, error = function(e) {
      cat("Error while creating 'planes' table:\n")
      print(e)
   })
   
   tryCatch({
      dbExecute(conn, "
  CREATE TABLE IF NOT EXISTS flights.weather (
    origin TEXT,
    year INT,
    month INT,
    day INT,
    hour INT,
    temp DOUBLE PRECISION,
    dewp DOUBLE PRECISION,
    humid DOUBLE PRECISION,
    wind_dir DOUBLE PRECISION,
    wind_speed DOUBLE PRECISION,
    wind_gust DOUBLE PRECISION,
    precip DOUBLE PRECISION,
    pressure DOUBLE PRECISION,
    visib DOUBLE PRECISION,
    time_hour TIMESTAMP,
    CONSTRAINT fk_weather_date FOREIGN KEY (year, month, day, hour, time_hour) 
      REFERENCES flights.flights(year, month, day, hour, time_hour)
  )
")
      
      # Alter weather table to add foreign keys
      dbExecute(conn, "
  ALTER TABLE flights.weather
  ADD CONSTRAINT fk_weather_origin FOREIGN KEY (origin) REFERENCES flights.airports(faa)
   ")
      cat("Table 'weather' created or already exists.\n")
   }, error = function(e) {
      cat("Error while creating 'weather' table:\n")
      print(e)
   })
   
   # Function to insert data into tables
   insert_data <- function(conn, table_name, data) {
      tryCatch({
         dbWriteTable(conn, table_name, data, append = TRUE)
         cat(paste("Data inserted into", table_name, "\n"))
      }, error = function(e) {
         cat(paste("Error while inserting data into", table_name, ":\n"))
         print(e)
      })
   }
   
   # Insert data into each table
   insert_data(conn, "flights.flights", flights)
   insert_data(conn, "flights.airlines", airlines)
   insert_data(conn, "flights.airports", airports)
   insert_data(conn, "flights.planes", planes)
   insert_data(conn, "flights.weather", weather)
   
   # Close connection
   dbDisconnect(conn)
} else {
   cat("Failed to connect to the database. Please check the connection parameters.\n")
}
