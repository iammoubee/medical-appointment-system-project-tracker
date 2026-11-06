package com.medicaltracker.controller;

import com.medicaltracker.dao.ProjectDao;
import com.medicaltracker.dao.TaskDao;
import com.medicaltracker.model.Project;
import com.medicaltracker.model.ProjectSummary;
import com.medicaltracker.model.Task;
import com.medicaltracker.service.ProjectService;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.sql.SQLException;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

@WebServlet("/dashboard")
public class DashboardServlet extends HttpServlet {
    private static final Logger LOGGER = Logger.getLogger(DashboardServlet.class.getName());
    private final ProjectDao projectDao = new ProjectDao();
    private final TaskDao taskDao = new TaskDao();
    private final ProjectService projectService = new ProjectService();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        try {
            Project project = projectDao.findDefault();
            List<Task> tasks = taskDao.findByProject(project.id());
            ProjectSummary summary = projectService.summarize(tasks);
            request.setAttribute("project", project);
            request.setAttribute("summary", summary);
            request.setAttribute("tasks", tasks);
            request.getRequestDispatcher("/WEB-INF/views/dashboard.jsp").forward(request, response);
        } catch (SQLException exception) {
            LOGGER.log(Level.SEVERE, "Unable to load project dashboard", exception);
            response.setStatus(HttpServletResponse.SC_SERVICE_UNAVAILABLE);
            request.setAttribute("databaseError",
                    "The project database is not ready. Apply database/schema.sql and verify the database connection settings.");
            request.getRequestDispatcher("/WEB-INF/views/database-error.jsp").forward(request, response);
        }
    }
}
