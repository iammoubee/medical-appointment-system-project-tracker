CREATE DATABASE IF NOT EXISTS medical_project_tracker
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_0900_ai_ci;
USE medical_project_tracker;

CREATE TABLE IF NOT EXISTS projects (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    project_name VARCHAR(160) NOT NULL,
    description TEXT NOT NULL,
    start_date DATE NOT NULL,
    expected_deadline DATE NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    CONSTRAINT chk_project_dates CHECK (expected_deadline >= start_date)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS tasks (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    project_id BIGINT UNSIGNED NOT NULL,
    task_name VARCHAR(200) NOT NULL,
    description TEXT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    weight DECIMAL(7,2) NOT NULL DEFAULT 0,
    status ENUM('Pending', 'In Progress', 'Completed') NOT NULL DEFAULT 'Pending',
    completion_percentage TINYINT UNSIGNED NOT NULL DEFAULT 0,
    dependency_id BIGINT UNSIGNED NULL,
    is_milestone BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    INDEX idx_tasks_project_schedule (project_id, start_date, end_date),
    INDEX idx_tasks_dependency (dependency_id),
    CONSTRAINT fk_tasks_project FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
    CONSTRAINT fk_tasks_dependency FOREIGN KEY (dependency_id) REFERENCES tasks(id) ON DELETE SET NULL,
    CONSTRAINT chk_task_weight CHECK (weight >= 0),
    CONSTRAINT chk_task_completion CHECK (completion_percentage <= 100),
    CONSTRAINT chk_task_dates CHECK (end_date >= start_date)
) ENGINE=InnoDB;

INSERT INTO projects (id, project_name, description, start_date, expected_deadline)
SELECT 1, 'Medical Appointment System',
       'Planning, design, implementation, testing, and deployment of a medical appointment booking system.',
       '2026-09-01', '2027-02-28'
WHERE NOT EXISTS (SELECT 1 FROM projects WHERE id = 1);

INSERT INTO tasks
    (id, project_id, task_name, description, start_date, end_date, weight, status,
     completion_percentage, dependency_id, is_milestone)
SELECT seed.id, 1, seed.task_name, seed.description, seed.start_date, seed.end_date,
       seed.weight, seed.status, seed.completion_percentage, seed.dependency_id, seed.is_milestone
FROM (
    SELECT 1 AS id, 'Project Proposal and Requirement Analysis' AS task_name,
           'Define scope, stakeholders, goals, and high-level requirements.' AS description,
           '2026-09-01' AS start_date, '2026-09-10' AS end_date,
           8.00 AS weight, 'Completed' AS status, 100 AS completion_percentage,
           NULL AS dependency_id, TRUE AS is_milestone
    UNION ALL SELECT 2, 'System Requirement Specification (SRS)', 'Document functional and non-functional requirements.',
           '2026-09-08', '2026-09-18', 6.00, 'Completed', 100, 1, FALSE
    UNION ALL SELECT 3, 'Database Design', 'Design normalized data model and relationships.',
           '2026-09-16', '2026-09-26', 5.00, 'Completed', 100, 2, TRUE
    UNION ALL SELECT 4, 'UI/UX Design', 'Create responsive application flows and visual prototypes.',
           '2026-09-16', '2026-10-02', 5.00, 'Completed', 100, 2, FALSE
    UNION ALL SELECT 5, 'Frontend Development', 'Build responsive pages, navigation, and reusable UI components.',
           '2026-10-01', '2026-11-05', 8.00, 'In Progress', 55, 4, FALSE
    UNION ALL SELECT 6, 'User Registration and Login', 'Implement secure registration, login, and role-aware access.',
           '2026-10-20', '2026-11-12', 7.00, 'In Progress', 30, 5, FALSE
    UNION ALL SELECT 7, 'Doctor Management Module', 'Manage doctor profiles, specialties, and availability.',
           '2026-10-27', '2026-11-18', 6.00, 'Pending', 0, 3, FALSE
    UNION ALL SELECT 8, 'Patient Management Module', 'Manage patient profiles and appointment history.',
           '2026-11-03', '2026-11-24', 6.00, 'Pending', 0, 6, FALSE
    UNION ALL SELECT 9, 'Appointment Booking Module', 'Allow patients to find and book available appointments.',
           '2026-11-12', '2026-12-10', 8.00, 'Pending', 0, 7, TRUE
    UNION ALL SELECT 10, 'Appointment Scheduling', 'Coordinate doctor availability and prevent booking conflicts.',
           '2026-11-18', '2026-12-12', 6.00, 'Pending', 0, 9, FALSE
    UNION ALL SELECT 11, 'Admin Dashboard', 'Provide administrators with operational and appointment summaries.',
           '2026-11-26', '2026-12-17', 5.00, 'Pending', 0, 7, FALSE
    UNION ALL SELECT 12, 'Backend Development', 'Implement server-side business rules and REST-style operations.',
           '2026-10-13', '2026-12-19', 8.00, 'In Progress', 20, 2, FALSE
    UNION ALL SELECT 13, 'Database Integration', 'Connect application modules to the MySQL schema using JDBC.',
           '2026-12-08', '2026-12-29', 6.00, 'Pending', 0, 12, FALSE
    UNION ALL SELECT 14, 'Testing and Debugging', 'Run functional, integration, and regression tests; fix defects.',
           '2026-12-22', '2027-01-23', 7.00, 'Pending', 0, 13, FALSE
    UNION ALL SELECT 15, 'Documentation', 'Prepare user guide, technical notes, and project report.',
           '2027-01-05', '2027-01-26', 5.00, 'Pending', 0, 14, FALSE
    UNION ALL SELECT 16, 'Final Deployment', 'Deploy the tested application and verify production readiness.',
           '2027-01-27', '2027-02-05', 4.00, 'Pending', 0, 14, TRUE
) AS seed
WHERE NOT EXISTS (SELECT 1 FROM tasks WHERE tasks.id = seed.id);
