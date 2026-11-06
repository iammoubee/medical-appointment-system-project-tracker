package com.medicaltracker.service;

import com.medicaltracker.model.ProjectSummary;
import com.medicaltracker.model.Task;

import java.util.List;

public class ProjectService {
    public ProjectSummary summarize(List<Task> tasks) {
        int completed = 0;
        int inProgress = 0;
        int pending = 0;
        double totalWeight = 0;
        double earnedWeight = 0;

        for (Task task : tasks) {
            totalWeight += task.weight();
            earnedWeight += task.weight() * task.completionPercentage() / 100.0;
            switch (task.status()) {
                case "Completed" -> completed++;
                case "In Progress" -> inProgress++;
                default -> pending++;
            }
        }

        double progress = totalWeight == 0 ? 0 : earnedWeight / totalWeight * 100;
        progress = Math.round(progress * 10.0) / 10.0;
        return new ProjectSummary(tasks.size(), completed, inProgress, pending, progress,
                Math.round((100 - progress) * 10.0) / 10.0, totalWeight);
    }
}
