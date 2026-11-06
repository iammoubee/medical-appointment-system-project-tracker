package com.medicaltracker.dao;

import com.medicaltracker.model.Project;
import com.medicaltracker.util.Database;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

public class ProjectDao {
    public Project findDefault() throws SQLException {
        String sql = """
                SELECT id, project_name, description, start_date, expected_deadline
                FROM projects ORDER BY id LIMIT 1
                """;
        try (Connection connection = Database.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql);
             ResultSet result = statement.executeQuery()) {
            if (!result.next()) {
                throw new SQLException("No project is configured. Run database/schema.sql first.");
            }
            return new Project(
                    result.getLong("id"),
                    result.getString("project_name"),
                    result.getString("description"),
                    result.getDate("start_date").toLocalDate(),
                    result.getDate("expected_deadline").toLocalDate());
        }
    }
}
