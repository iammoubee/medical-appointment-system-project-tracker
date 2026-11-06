# Medical Appointment System Project Tracker

A Java Servlet MVC-based web application designed to track the development progress of a Medical Appointment System using a Work Completion Calculator and an interactive Gantt Chart.

## Features

- **Project Dashboard:** Overview of total, completed, pending, and ongoing tasks.
- **Work Completion Calculator:** Calculates overall project progress and remaining work using weighted task completion.
- **Gantt Chart:** Visualizes task schedules, durations, deadlines, dependencies, and progress.
- **Task Management:** Add, update, view, and delete project tasks.
- **MySQL Integration:** Stores project and task information using JDBC.
- **Progress Reports:** Displays project statistics and delayed tasks.

## Screenshots

### 1. Project Dashboard
<img width="1482" height="847" alt="Screenshot 2026-11-06 213235" src="https://github.com/user-attachments/assets/fcf7948d-57d5-43eb-9d3d-1fa59b724a08" />

### 2. Gantt Chart

<img width="1475" height="845" alt="Screenshot 2026-11-06 213302" src="https://github.com/user-attachments/assets/2fc96941-5d04-48f8-b29e-781aa6110591" />

### 3. Task Management
<img width="1472" height="827" alt="Screenshot 2026-11-06 213320" src="https://github.com/user-attachments/assets/d3e7c26e-96c9-42b3-acc4-c022bd7639a8" />


## Technologies Used

- Java (JDK 17+)
- Java Servlet & JSP
- MySQL 8
- JDBC
- HTML, CSS, JavaScript
- Bootstrap 5
- Frappe Gantt
- Apache Maven
- Apache Tomcat 11

## Project Structure

```text
medical-project-tracker/
├── database/
├── src/
│   ├── main/java/
│   └── main/webapp/
├── pom.xml
└── README.md
```

## Progress Calculation

```text
Overall Progress =
(Sum of Weight × Completion Percentage / 100)
÷ Total Task Weight × 100

Remaining Work = 100 - Overall Progress
```

## Setup & Run

1. Clone or download the repository.
2. Create the MySQL database using `database/schema.sql`.
3. Configure database credentials using environment variables.
4. Build the project:

```bash
mvn clean test package
```

5. Deploy the generated WAR file to Apache Tomcat 11.
6. Open:

```text
http://localhost:8080/medical-project-tracker/
```

## Project Purpose

This project demonstrates practical Software Engineering Project Management concepts by monitoring project completion, managing tasks, and visualizing development schedules through an interactive Gantt Chart.

---

**Developed as an academic project for Software Engineering Project Management (SEPM).**
