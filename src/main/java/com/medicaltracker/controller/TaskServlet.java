package com.medicaltracker.controller;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.JsonParseException;
import com.medicaltracker.dao.ProjectDao;
import com.medicaltracker.dao.TaskDao;
import com.medicaltracker.model.Project;
import com.medicaltracker.model.Task;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.logging.Level;
import java.util.logging.Logger;

@WebServlet("/api/tasks/*")
public class TaskServlet extends HttpServlet {
    private static final Logger LOGGER = Logger.getLogger(TaskServlet.class.getName());
    private static final Set<String> STATUSES = Set.of("Pending", "In Progress", "Completed");
    private static final Gson GSON = new GsonBuilder()
            .registerTypeAdapter(LocalDate.class,
                    (com.google.gson.JsonSerializer<LocalDate>) (date, type, context) ->
                            new com.google.gson.JsonPrimitive(date.toString()))
            .create();
    private final ProjectDao projectDao = new ProjectDao();
    private final TaskDao taskDao = new TaskDao();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws IOException {
        try {
            Project project = projectDao.findDefault();
            writeJson(response, HttpServletResponse.SC_OK, taskDao.findByProject(project.id()));
        } catch (SQLException exception) {
            databaseFailure(response, exception);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException {
        handleSave(request, response, false);
    }

    @Override
    protected void doPut(HttpServletRequest request, HttpServletResponse response) throws IOException {
        handleSave(request, response, true);
    }

    @Override
    protected void doDelete(HttpServletRequest request, HttpServletResponse response) throws IOException {
        try {
            long id = parseId(request);
            Project project = projectDao.findDefault();
            if (!taskDao.delete(project.id(), id)) {
                writeJson(response, HttpServletResponse.SC_NOT_FOUND, Map.of("error", "Task not found."));
                return;
            }
            writeJson(response, HttpServletResponse.SC_OK, Map.of("deleted", true));
        } catch (IllegalArgumentException exception) {
            writeJson(response, HttpServletResponse.SC_BAD_REQUEST, Map.of("error", exception.getMessage()));
        } catch (SQLException exception) {
            databaseFailure(response, exception);
        }
    }

    private void handleSave(HttpServletRequest request, HttpServletResponse response, boolean update)
            throws IOException {
        try {
            TaskInput input = GSON.fromJson(request.getReader(), TaskInput.class);
            if (input == null) {
                throw new IllegalArgumentException("A task payload is required.");
            }
            Project project = projectDao.findDefault();
            Task task = validate(input, project.id(), update ? parseId(request) : 0);
            if (task.dependencyId() != null
                    && !taskDao.existsInProject(project.id(), task.dependencyId())) {
                throw new IllegalArgumentException("Dependency must be another task in this project.");
            }
            if (update && taskDao.wouldCreateDependencyCycle(project.id(), task.id(), task.dependencyId())) {
                throw new IllegalArgumentException("Task dependencies cannot create a cycle.");
            }
            if (update) {
                if (!taskDao.update(task)) {
                    writeJson(response, HttpServletResponse.SC_NOT_FOUND, Map.of("error", "Task not found."));
                    return;
                }
            } else {
                task = taskDao.save(task);
            }
            writeJson(response, update ? HttpServletResponse.SC_OK : HttpServletResponse.SC_CREATED, task);
        } catch (IllegalArgumentException | JsonParseException | DateTimeParseException exception) {
            writeJson(response, HttpServletResponse.SC_BAD_REQUEST, Map.of("error", exception.getMessage()));
        } catch (SQLException exception) {
            databaseFailure(response, exception);
        }
    }

    private Task validate(TaskInput input, long projectId, long id) {
        String name = required(input.name, "Task name");
        String status = required(input.status, "Status");
        if (name.length() > 200) {
            throw new IllegalArgumentException("Task name must be 200 characters or fewer.");
        }
        if (!STATUSES.contains(status)) {
            throw new IllegalArgumentException("Status must be Pending, In Progress, or Completed.");
        }
        if (input.weight < 0 || input.weight > 99999.99 || !Double.isFinite(input.weight)) {
            throw new IllegalArgumentException("Weight must be between 0 and 99999.99.");
        }
        if (input.completionPercentage < 0 || input.completionPercentage > 100) {
            throw new IllegalArgumentException("Completion must be between 0 and 100.");
        }
        if (status.equals("Completed")) {
            input.completionPercentage = 100;
        } else if (status.equals("Pending")) {
            input.completionPercentage = 0;
        }
        LocalDate start = LocalDate.parse(required(input.startDate, "Start date"));
        LocalDate end = LocalDate.parse(required(input.endDate, "End date"));
        if (end.isBefore(start)) {
            throw new IllegalArgumentException("End date must be on or after the start date.");
        }
        Long dependencyId = input.dependencyId;
        if (dependencyId != null && (dependencyId <= 0 || dependencyId == id)) {
            throw new IllegalArgumentException("Choose a valid task dependency.");
        }
        return new Task(id, projectId, name, input.description == null ? "" : input.description.trim(),
                start, end, input.weight, status, input.completionPercentage, dependencyId, input.milestone);
    }

    private String required(String value, String label) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException(label + " is required.");
        }
        return value.trim();
    }

    private long parseId(HttpServletRequest request) {
        String path = request.getPathInfo();
        if (path == null || !path.matches("/\\d+")) {
            throw new IllegalArgumentException("A valid task ID is required in the URL.");
        }
        return Long.parseLong(path.substring(1));
    }

    private void databaseFailure(HttpServletResponse response, SQLException exception) throws IOException {
        LOGGER.log(Level.SEVERE, "Task API database operation failed", exception);
        writeJson(response, HttpServletResponse.SC_SERVICE_UNAVAILABLE,
                Map.of("error", "Database unavailable. Check the MySQL service, schema, and connection settings."));
    }

    private void writeJson(HttpServletResponse response, int status, Object body) throws IOException {
        response.setStatus(status);
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        GSON.toJson(body, response.getWriter());
    }

    private static final class TaskInput {
        private String name;
        private String description;
        private String startDate;
        private String endDate;
        private double weight;
        private String status;
        private int completionPercentage;
        private Long dependencyId;
        private boolean milestone;
    }
}
