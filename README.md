# Medical Appointment System Project Tracker

A Java Servlet MVC application for tracking the planned Medical Appointment System delivery.
Task changes are persisted in MySQL; project completion is calculated from task weights and
partial completion, and the Gantt chart reads the same tasks from the JSON endpoint.

## Architecture

- **Views:** JSP pages, responsive Bootstrap layout, CSS, and browser-side JavaScript.
- **Controllers:** `DashboardServlet` builds the dashboard; `TaskServlet` provides JSON CRUD at
  `/api/tasks` and `/api/tasks/{id}`.
- **Service:** `ProjectService` computes weighted overall and remaining progress.
- **DAO:** `ProjectDao` and `TaskDao` use JDBC prepared statements for MySQL persistence.
- **Models:** immutable project, task, and project summary records.
- **Database configuration:** `Database` reads the `MEDICAL_TRACKER_DB_*` environment variables.
- **Visualization:** Frappe Gantt supports weekly/monthly views, dependency links, progress,
  milestones, date dragging, and a today marker.

## Project structure

```text
medical-project-tracker/
├── database/schema.sql
├── pom.xml
└── src/
    ├── main/java/com/medicaltracker/
    │   ├── controller/
    │   ├── dao/
    │   ├── model/
    │   ├── service/
    │   └── util/
    ├── main/webapp/
    │   ├── assets/css/dashboard.css
    │   ├── assets/js/dashboard.js
    │   ├── WEB-INF/views/
    │   └── index.jsp
    └── test/java/com/medicaltracker/service/
```

## Requirements

- JDK 17 or newer (required by Tomcat 11)
- Apache Maven
- Apache Tomcat 11
- MySQL 8

## Database setup

The included idempotent script creates the database, project, and 16 weighted sample tasks.
From the project root, run it with a MySQL account allowed to create the database:

```powershell
$mysqlHome = "C:\Program Files\MySQL\MySQL Server 8.4"
cmd.exe /c "`"$mysqlHome\bin\mysql.exe`" --protocol=TCP --host=127.0.0.1 --port=3306 --user=root < database\schema.sql"
```

For a new local MySQL installation that does not already have a configured service, initialize
its data directory once, then start `mysqld` in a separate PowerShell window and leave that
window open while developing:

```powershell
$mysqlHome = "C:\Program Files\MySQL\MySQL Server 8.4"
$dataDir = Join-Path $env:LOCALAPPDATA "MedicalTrackerMySQL\data"
New-Item -ItemType Directory -Force -Path $dataDir
& "$mysqlHome\bin\mysqld.exe" "--basedir=$mysqlHome" "--datadir=$dataDir" --initialize-insecure --console
```

Start the initialized server in a separate terminal (skip initialization if you already have
a data directory):

```powershell
$mysqlHome = "C:\Program Files\MySQL\MySQL Server 8.4"
$dataDir = Join-Path $env:LOCALAPPDATA "MedicalTrackerMySQL\data"
& "$mysqlHome\bin\mysqld.exe" "--basedir=$mysqlHome" "--datadir=$dataDir" --bind-address=127.0.0.1 --port=3306 --console
```

`--initialize-insecure` creates a root account without a password for local development.
Keep this server bound to localhost; use a password-protected database account outside local
development and provide its credentials with the environment variables below.

By default the application connects to:

```text
jdbc:mysql://localhost:3306/medical_project_tracker
```

Set credentials in the environment before launching Tomcat. Example for the current
PowerShell window:

```powershell
$env:MEDICAL_TRACKER_DB_URL = "jdbc:mysql://localhost:3306/medical_project_tracker?serverTimezone=UTC"
$env:MEDICAL_TRACKER_DB_USER = "root"
$env:MEDICAL_TRACKER_DB_PASSWORD = "your-local-password"
```

Do not put real database credentials in source control. The schema seeds the project and its
16 weighted tasks; weights sum to 100 for the initial plan, but can be changed independently.

## Build and test

From the project root:

```powershell
mvn clean test package
```

## Run on Tomcat 11

Copy the WAR to Tomcat and start the server:

```powershell
Copy-Item target\medical-project-tracker.war "$env:CATALINA_HOME\webapps\"
& "$env:CATALINA_HOME\bin\startup.bat"
```

Open `http://localhost:8080/medical-project-tracker/`. In VS Code, install the Java Extension
Pack and Community Server Connectors, add your Tomcat 11 installation, then deploy
`target\medical-project-tracker.war` from the Servers view. The app expects the schema and
MySQL service to be available when its dashboard loads.

## Weighted calculation

`overall = sum(weight × completion / 100) / sum(weight) × 100`

For weights `20, 25, 15, 20, 20` and completion `100, 100, 50, 0, 0`, overall completion is
`52.5%`, and remaining work is `47.5%`. A zero total weight is treated as 0% complete.
