# NYC Flights 2023 PostgreSQL Project

## Project Overview

This project involves working with the `nycflights23` dataset in R and PostgreSQL. The goal is to:

-    Create a PostgreSQL database named `nycflights23`

-    Create a schema `flights`

-    Define five tables: `flights`, `airlines`, `airports`, `planes`, `weather`

-    Populate the tables with data from the `nycflights23` R package

-    Set up foreign key relationships between the tables

-   All operations are done using R and the following libraries: `DBI`, `RPostgres`, `yaml`, and `nycflights23`.

## Requirements

Make sure the following packages are installed:

`install.packages("DBI")`

`install.packages("RPostgres")`

`install.packages("yaml")`

`install.packages("nycflights23")`

## Setup & Configuration

Create a `config.yaml` file for your PostgreSQL connection parameters:

postgres:

host: "localhost"

port: 5432

user: "your_username"

password: "your_password"

### Load your libraries:

library(DBI)

library(RPostgres)

library(yaml)

library(nycflights23)

## Database Creation & Schema Definition

Establish a connection using the `config.yaml`, then:

-    Create the database `nycflights23.`

-    Connect to it.

-    Create schema `flights.`

-    Define the five tables using `CREATE TABLE` statements.

-    Set up primary keys and foreign key constraints.

Each step is wrapped in `tryCatch` to handle errors gracefully and display custom messages.

## Data Insertion

Data from `nycflights23` is loaded into PostgreSQL using `dbWriteTable`:

```{r}
insert_data <- function(conn, table_name, data) {
  tryCatch({
    dbWriteTable(conn, table_name, data, append = TRUE)
    cat(paste("Data inserted into", table_name, "\n"))
  }, error = function(e) {
    cat(paste("Error while inserting data into", table_name, ":\n"))
    print(e)
  })
}
```

Then inserted like this:

```{r}
insert_data(conn, "flights.flights", flights)
insert_data(conn, "flights.airlines", airlines)
insert_data(conn, "flights.airports", airports)
insert_data(conn, "flights.planes", planes)
insert_data(conn, "flights.weather", weather)
```

## Relationships

Foreign key relationships were added to ensure data integrity. Example:

```{r}
"ALTER TABLE flights.flights
ADD CONSTRAINT fk_carrier FOREIGN KEY (carrier) REFERENCES flights.airlines(carrier)"
```

All key constraints are defined during or after table creation.

## Error Handling

`tryCatch()` is used to:

-    Prevent the script from crashing on failure.

-    Provide readable error messages during database and table creation or data insertion.

## Summary

This notebook does the following:

-    Connects to PostgreSQL using credentials from a YAML file.

-    Creates a dedicated database and schema.

-    Defines tables and relationships.

-    Populates all five tables with real-world flight data.

-    Handles errors gracefully.
