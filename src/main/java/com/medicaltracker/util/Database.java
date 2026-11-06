package com.medicaltracker.util;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public final class Database {
    private static final String DEFAULT_URL =
            "jdbc:mysql://localhost:3306/medical_project_tracker?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC";

    private Database() {
    }

    public static Connection getConnection() throws SQLException {
        String url = setting("MEDICAL_TRACKER_DB_URL", DEFAULT_URL);
        String user = setting("MEDICAL_TRACKER_DB_USER", "root");
        String password = setting("MEDICAL_TRACKER_DB_PASSWORD", "");
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException exception) {
            throw new SQLException("MySQL Connector/J is missing from the deployed application.", exception);
        }
        return DriverManager.getConnection(url, user, password);
    }

    private static String setting(String name, String fallback) {
        String value = System.getenv(name);
        return value == null || value.isBlank() ? fallback : value;
    }
}
