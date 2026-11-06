package com.medicaltracker.service;

import com.medicaltracker.model.ProjectSummary;
import com.medicaltracker.model.Task;
import org.junit.jupiter.api.Test;

import java.time.LocalDate;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;

class ProjectServiceTest {
    private final ProjectService service = new ProjectService();

    @Test
    void calculatesProgressUsingTaskWeightsAndPartialCompletion() {
        List<Task> tasks = List.of(
                task(1, 20, "Completed", 100),
                task(2, 25, "Completed", 100),
                task(3, 15, "In Progress", 50),
                task(4, 20, "Pending", 0),
                task(5, 20, "Pending", 0));

        ProjectSummary summary = service.summarize(tasks);

        assertEquals(52.5, summary.completionPercentage());
        assertEquals(47.5, summary.remainingPercentage());
        assertEquals(5, summary.totalTasks());
        assertEquals(2, summary.completedTasks());
        assertEquals(1, summary.inProgressTasks());
        assertEquals(2, summary.pendingTasks());
        assertEquals(100, summary.totalWeight());
    }

    @Test
    void returnsZeroProgressWhenThereIsNoTaskWeight() {
        ProjectSummary summary = service.summarize(List.of(task(1, 0, "Pending", 0)));

        assertEquals(0, summary.completionPercentage());
        assertEquals(100, summary.remainingPercentage());
    }

    private Task task(long id, double weight, String status, int completion) {
        return new Task(id, 1, "Task " + id, "", LocalDate.parse("2026-01-01"),
                LocalDate.parse("2026-01-02"), weight, status, completion, null, false);
    }
}
