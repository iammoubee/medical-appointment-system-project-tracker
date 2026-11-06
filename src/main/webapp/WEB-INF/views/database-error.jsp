<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Database setup required | Medical Project Tracker</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.8/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body class="bg-body-tertiary">
<main class="container py-5">
    <section class="mx-auto rounded-4 bg-white p-4 p-md-5 shadow-sm" style="max-width: 760px">
        <p class="text-primary fw-semibold text-uppercase small">Setup required</p>
        <h1 class="h2">Project database is unavailable</h1>
        <p class="text-secondary"><%= request.getAttribute("databaseError") %></p>
        <h2 class="h5 mt-4">Connect MySQL 8</h2>
        <ol class="text-secondary">
            <li>Start MySQL and run <code>database\schema.sql</code>.</li>
            <li>Set <code>MEDICAL_TRACKER_DB_URL</code>, <code>MEDICAL_TRACKER_DB_USER</code>, and <code>MEDICAL_TRACKER_DB_PASSWORD</code>.</li>
            <li>Restart Tomcat and reload this page.</li>
        </ol>
        <p class="small text-secondary mb-0">Default URL: <code>jdbc:mysql://localhost:3306/medical_project_tracker</code></p>
    </section>
</main>
</body>
</html>
