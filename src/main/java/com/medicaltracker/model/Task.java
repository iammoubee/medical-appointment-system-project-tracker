package com.medicaltracker.model;

import java.time.LocalDate;

public record Task(
        long id,
        long projectId,
        String name,
        String description,
        LocalDate startDate,
        LocalDate endDate,
        double weight,
        String status,
        int completionPercentage,
        Long dependencyId,
        boolean milestone) {
}
