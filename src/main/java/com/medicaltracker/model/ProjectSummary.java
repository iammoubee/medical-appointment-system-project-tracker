package com.medicaltracker.model;

public record ProjectSummary(
        int totalTasks,
        int completedTasks,
        int inProgressTasks,
        int pendingTasks,
        double completionPercentage,
        double remainingPercentage,
        double totalWeight) {
}
