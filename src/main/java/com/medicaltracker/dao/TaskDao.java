package com.medicaltracker.dao;

import com.medicaltracker.model.Task;
import com.medicaltracker.util.Database;

import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

public class TaskDao {
    public boolean wouldCreateDependencyCycle(long projectId, long taskId, Long dependencyId) throws SQLException {
        if (dependencyId == null) {
            return false;
        }
        Map<Long, Long> dependencies = new HashMap<>();
        for (Task task : findByProject(projectId)) {
            if (task.dependencyId() != null) {
                dependencies.put(task.id(), task.dependencyId());
            }
        }
        Set<Long> visited = new HashSet<>();
        Long current = dependencyId;
        while (current != null && visited.add(current)) {
            if (current == taskId) {
                return true;
            }
            current = dependencies.get(current);
        }
        return false;
    }

    public boolean existsInProject(long projectId, long taskId) throws SQLException {
        String sql = "SELECT 1 FROM tasks WHERE project_id = ? AND id = ?";
        try (Connection connection = Database.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setLong(1, projectId);
            statement.setLong(2, taskId);
            try (ResultSet result = statement.executeQuery()) {
                return result.next();
            }
        }
    }

    public List<Task> findByProject(long projectId) throws SQLException {
        String sql = """
                SELECT id, project_id, task_name, description, start_date, end_date, weight,
                       status, completion_percentage, dependency_id, is_milestone
                FROM tasks WHERE project_id = ? ORDER BY start_date, id
                """;
        List<Task> tasks = new ArrayList<>();
        try (Connection connection = Database.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setLong(1, projectId);
            try (ResultSet result = statement.executeQuery()) {
                while (result.next()) {
                    long dependency = result.getLong("dependency_id");
                    Long dependencyId = result.wasNull() ? null : dependency;
                    tasks.add(new Task(
                            result.getLong("id"),
                            result.getLong("project_id"),
                            result.getString("task_name"),
                            result.getString("description"),
                            result.getDate("start_date").toLocalDate(),
                            result.getDate("end_date").toLocalDate(),
                            result.getDouble("weight"),
                            result.getString("status"),
                            result.getInt("completion_percentage"),
                            dependencyId,
                            result.getBoolean("is_milestone")));
                }
            }
        }
        return tasks;
    }

    public Task save(Task task) throws SQLException {
        String sql = """
                INSERT INTO tasks
                    (project_id, task_name, description, start_date, end_date, weight, status,
                     completion_percentage, dependency_id, is_milestone)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """;
        try (Connection connection = Database.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            bind(statement, task, false);
            statement.executeUpdate();
            try (ResultSet keys = statement.getGeneratedKeys()) {
                if (!keys.next()) {
                    throw new SQLException("Creating task did not return an ID.");
                }
                return findById(connection, keys.getLong(1));
            }
        }
    }

    public boolean update(Task task) throws SQLException {
        String sql = """
                UPDATE tasks SET task_name = ?, description = ?, start_date = ?, end_date = ?,
                    weight = ?, status = ?, completion_percentage = ?, dependency_id = ?, is_milestone = ?
                WHERE id = ? AND project_id = ?
                """;
        try (Connection connection = Database.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            bind(statement, task, true);
            return statement.executeUpdate() == 1;
        }
    }

    public boolean delete(long projectId, long id) throws SQLException {
        String sql = "DELETE FROM tasks WHERE project_id = ? AND id = ?";
        try (Connection connection = Database.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setLong(1, projectId);
            statement.setLong(2, id);
            return statement.executeUpdate() == 1;
        }
    }

    private Task findById(Connection connection, long id) throws SQLException {
        String sql = """
                SELECT id, project_id, task_name, description, start_date, end_date, weight,
                       status, completion_percentage, dependency_id, is_milestone
                FROM tasks WHERE id = ?
                """;
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setLong(1, id);
            try (ResultSet result = statement.executeQuery()) {
                if (!result.next()) {
                    throw new SQLException("Created task could not be reloaded.");
                }
                long dependency = result.getLong("dependency_id");
                Long dependencyId = result.wasNull() ? null : dependency;
                return new Task(result.getLong("id"), result.getLong("project_id"),
                        result.getString("task_name"), result.getString("description"),
                        result.getDate("start_date").toLocalDate(), result.getDate("end_date").toLocalDate(),
                        result.getDouble("weight"), result.getString("status"),
                        result.getInt("completion_percentage"), dependencyId, result.getBoolean("is_milestone"));
            }
        }
    }

    private void bind(PreparedStatement statement, Task task, boolean update) throws SQLException {
        int index = 1;
        if (!update) {
            statement.setLong(index++, task.projectId());
        }
        statement.setString(index++, task.name());
        statement.setString(index++, task.description());
        statement.setDate(index++, Date.valueOf(task.startDate()));
        statement.setDate(index++, Date.valueOf(task.endDate()));
        statement.setDouble(index++, task.weight());
        statement.setString(index++, task.status());
        statement.setInt(index++, task.completionPercentage());
        if (task.dependencyId() == null) {
            statement.setNull(index++, java.sql.Types.BIGINT);
        } else {
            statement.setLong(index++, task.dependencyId());
        }
        statement.setBoolean(index++, task.milestone());
        if (update) {
            statement.setLong(index++, task.id());
            statement.setLong(index, task.projectId());
        }
    }
}
