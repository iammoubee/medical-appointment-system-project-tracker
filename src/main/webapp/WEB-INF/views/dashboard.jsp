<%@ page import="com.medicaltracker.model.Project" %>
<%@ page import="com.medicaltracker.model.ProjectSummary" %>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%
    Project project = (Project) request.getAttribute("project");
    ProjectSummary summary = (ProjectSummary) request.getAttribute("summary");
    String safeProjectName = project.name().replace("&", "&amp;").replace("<", "&lt;")
            .replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title><%= safeProjectName %> | Project Tracker</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.8/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/frappe-gantt@0.6.1/dist/frappe-gantt.css" rel="stylesheet">
    <link href="<%= request.getContextPath() %>/assets/css/dashboard.css?v=2" rel="stylesheet">
</head>
<body>
<div class="app-shell">
    <aside class="sidebar">
        <a class="brand" href="#dashboard">
            <span class="brand-mark">M</span>
            <span>MedTrack <small>PROJECT WORKSPACE</small></span>
        </a>
        <div class="sidebar-label">WORKSPACE</div>
        <nav class="side-nav" aria-label="Main navigation">
            <a class="nav-link active" href="#dashboard"><span>▦</span> Dashboard</a>
            <a class="nav-link" href="#overview"><span>◷</span> Project Overview</a>
            <a class="nav-link" href="#tasks"><span>☷</span> Task Management</a>
            <a class="nav-link" href="#calculator"><span>∑</span> Work Calculator</a>
            <a class="nav-link" href="#gantt-section"><span>▤</span> Gantt Chart</a>
            <a class="nav-link" href="#reports"><span>▧</span> Reports</a>
            <a class="nav-link" href="#settings"><span>⚙</span> Settings</a>
        </nav>
        <div class="sidebar-project">
            <span class="project-dot"></span>
            <div><small>ACTIVE PROJECT</small><strong><%= safeProjectName %></strong></div>
        </div>
        <div class="sidebar-footer">Project planning &amp; delivery</div>
    </aside>

    <main class="main-content" id="dashboard">
        <header class="topbar">
            <div>
                <div class="breadcrumb-line">Workspace <span>/</span> Projects <span>/</span> Overview</div>
                <div class="topbar-title">Project dashboard</div>
            </div>
            <div class="topbar-actions">
                <span class="live-status"><i></i> Live project data</span>
                <button class="btn btn-primary btn-sm px-3" id="add-task-top">＋ New task</button>
            </div>
        </header>

        <div class="page-content">
            <section class="project-heading" id="overview">
                <div>
                    <div class="eyebrow">PROJECT OVERVIEW</div>
                    <h1><%= safeProjectName %></h1>
                    <p>Track delivery, work completion, and upcoming milestones.</p>
                </div>
                <div class="project-dates">
                    <div><span>START DATE</span><strong><%= project.startDate() %></strong></div>
                    <div class="date-divider"></div>
                    <div><span>EXPECTED DEADLINE</span><strong><%= project.deadline() %></strong></div>
                </div>
            </section>

            <section class="summary-grid" aria-label="Project summary">
                <article class="summary-card">
                    <div class="summary-icon icon-blue">☷</div>
                    <div class="summary-label">Total tasks</div>
                    <div class="summary-value" id="total-tasks"><%= summary.totalTasks() %></div>
                    <div class="summary-foot">Across the project plan</div>
                </article>
                <article class="summary-card">
                    <div class="summary-icon icon-green">✓</div>
                    <div class="summary-label">Completed</div>
                    <div class="summary-value" id="completed-tasks"><%= summary.completedTasks() %></div>
                    <div class="summary-foot">Tasks fully delivered</div>
                </article>
                <article class="summary-card">
                    <div class="summary-icon icon-amber">◷</div>
                    <div class="summary-label">In progress</div>
                    <div class="summary-value" id="in-progress-tasks"><%= summary.inProgressTasks() %></div>
                    <div class="summary-foot">Currently being worked on</div>
                </article>
                <article class="summary-card">
                    <div class="summary-icon icon-slate">○</div>
                    <div class="summary-label">Pending</div>
                    <div class="summary-value" id="pending-tasks"><%= summary.pendingTasks() %></div>
                    <div class="summary-foot">Not started yet</div>
                </article>
            </section>

            <section class="progress-layout" id="calculator">
                <article class="panel overall-panel">
                    <div class="panel-heading">
                        <div><div class="eyebrow">WEIGHTED PROGRESS</div><h2>Work completion</h2></div>
                        <span class="pill pill-blue">Auto-calculated</span>
                    </div>
                    <div class="completion-number"><span id="completion-value"><%= summary.completionPercentage() %></span><small>%</small></div>
                    <div class="progress-track"><div class="progress-fill" id="overall-progress" style="width:<%= summary.completionPercentage() %>%"></div></div>
                    <div class="progress-caption"><span>Project completion</span><strong id="remaining-value"><%= summary.remainingPercentage() %>% remaining</strong></div>
                </article>
                <article class="panel schedule-panel">
                    <div class="panel-heading">
                        <div><div class="eyebrow">PROJECT SCHEDULE</div><h2>Delivery timeline</h2></div>
                        <span class="schedule-icon">◷</span>
                    </div>
                    <div class="schedule-dates">
                        <div><span>Project start</span><strong><%= project.startDate() %></strong></div>
                        <div><span>Expected deadline</span><strong><%= project.deadline() %></strong></div>
                    </div>
                    <div class="schedule-note"><span class="project-dot"></span><span id="schedule-note">Based on planned task dates</span></div>
                </article>
            </section>

            <section class="panel chart-panel" id="gantt-section">
                <div class="panel-heading chart-heading">
                    <div><div class="eyebrow">PROJECT SCHEDULE</div><h2>Gantt chart</h2><p>Task durations, dependencies, and completion at a glance.</p></div>
                    <div class="view-switch" role="group" aria-label="Gantt timeline view">
                        <button class="view-button" data-view="Week" type="button">Weekly</button>
                        <button class="view-button active" data-view="Month" type="button">Monthly</button>
                    </div>
                </div>
                <div class="chart-legend">
                    <span><i class="legend-dot completed"></i>Completed</span>
                    <span><i class="legend-dot in-progress"></i>In progress</span>
                    <span><i class="legend-dot pending"></i>Pending</span>
                    <span><i class="legend-diamond"></i>Milestone</span>
                    <span><i class="today-line"></i>Today</span>
                </div>
                <div class="gantt-wrap"><svg id="gantt-chart" aria-label="Project Gantt chart"></svg></div>
                <div class="empty-chart d-none" id="empty-chart">Add tasks with start and end dates to build the schedule.</div>
            </section>

            <section class="panel task-panel" id="tasks">
                <div class="panel-heading task-heading">
                    <div><div class="eyebrow">DELIVERY PLAN</div><h2>Task management</h2><p>Update status and completion inline, or edit the full task details.</p></div>
                    <button class="btn btn-primary px-3" id="add-task-button">＋ Add task</button>
                </div>
                <div class="table-responsive">
                    <table class="table task-table align-middle mb-0">
                        <thead><tr>
                            <th>Task</th><th>Schedule</th><th>Weight</th><th>Status</th><th>Completion</th><th>Actions</th>
                        </tr></thead>
                        <tbody id="task-rows"></tbody>
                    </table>
                </div>
                <div class="empty-tasks d-none" id="empty-tasks">No tasks yet. Add your first project task to begin.</div>
            </section>

            <section class="panel report-panel" id="reports">
                <div class="panel-heading">
                    <div><div class="eyebrow">PROJECT REPORT</div><h2>Progress report</h2><p>Current delivery summary and schedule health.</p></div>
                    <button class="btn btn-outline-secondary" id="print-report">Print report</button>
                </div>
                <div class="report-grid">
                    <div class="report-stat"><span>Total work weight</span><strong id="total-weight">0</strong></div>
                    <div class="report-stat"><span>Overall completion</span><strong id="report-completion">0%</strong></div>
                    <div class="report-stat"><span>Remaining work</span><strong id="report-remaining">100%</strong></div>
                    <div class="report-stat"><span>Delayed tasks</span><strong id="delayed-tasks">0</strong></div>
                </div>
                <div class="report-schedule">
                    <span>Project schedule</span>
                    <strong><%= project.startDate() %> <span>to</span> <%= project.deadline() %></strong>
                </div>
            </section>

            <section class="settings-note" id="settings">
                <strong>Database configuration</strong>
                <span>Set MEDICAL_TRACKER_DB_URL, MEDICAL_TRACKER_DB_USER, and MEDICAL_TRACKER_DB_PASSWORD for your MySQL 8 instance.</span>
            </section>
            <footer class="page-footer">Medical Appointment System · Project progress workspace</footer>
        </div>
    </main>
</div>

<div class="modal fade" id="task-modal" tabindex="-1" aria-labelledby="task-modal-title" aria-hidden="true">
    <div class="modal-dialog modal-lg modal-dialog-centered">
        <div class="modal-content">
            <form id="task-form">
                <div class="modal-header">
                    <div><div class="eyebrow">PROJECT TASK</div><h2 class="modal-title fs-5" id="task-modal-title">Add task</h2></div>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body">
                    <input type="hidden" id="task-id">
                    <div class="row g-3">
                        <div class="col-12"><label class="form-label" for="task-name">Task name</label><input class="form-control" id="task-name" maxlength="200" required></div>
                        <div class="col-12"><label class="form-label" for="task-description">Description</label><textarea class="form-control" id="task-description" rows="2"></textarea></div>
                        <div class="col-md-6"><label class="form-label" for="task-start">Start date</label><input class="form-control" id="task-start" type="date" required></div>
                        <div class="col-md-6"><label class="form-label" for="task-end">End date</label><input class="form-control" id="task-end" type="date" required></div>
                        <div class="col-md-4"><label class="form-label" for="task-weight">Assigned weight</label><input class="form-control" id="task-weight" type="number" min="0" max="99999.99" step="0.01" required></div>
                        <div class="col-md-4"><label class="form-label" for="task-status">Status</label><select class="form-select" id="task-status"><option>Pending</option><option>In Progress</option><option>Completed</option></select></div>
                        <div class="col-md-4"><label class="form-label" for="task-completion">Completion %</label><input class="form-control" id="task-completion" type="number" min="0" max="100" step="1" value="0" required></div>
                        <div class="col-md-8"><label class="form-label" for="task-dependency">Depends on</label><select class="form-select" id="task-dependency"><option value="">No dependency</option></select></div>
                        <div class="col-md-4 d-flex align-items-end"><div class="form-check mb-2"><input class="form-check-input" id="task-milestone" type="checkbox"><label class="form-check-label" for="task-milestone">Mark as milestone</label></div></div>
                    </div>
                    <div class="alert alert-danger mt-3 d-none mb-0" id="form-error" role="alert"></div>
                </div>
                <div class="modal-footer"><button type="button" class="btn btn-light" data-bs-dismiss="modal">Cancel</button><button type="submit" class="btn btn-primary" id="save-task">Save task</button></div>
            </form>
        </div>
    </div>
</div>
<div class="toast-container position-fixed bottom-0 end-0 p-3"><div class="toast" id="app-toast" role="status"><div class="toast-body"></div></div></div>
<script>window.projectTrackerContext = "<%= request.getContextPath() %>";</script>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.8/dist/js/bootstrap.bundle.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/frappe-gantt@0.6.1/dist/frappe-gantt.min.js"></script>
<script src="<%= request.getContextPath() %>/assets/js/dashboard.js?v=2"></script>
</body>
</html>
