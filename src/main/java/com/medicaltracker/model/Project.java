package com.medicaltracker.model;

import java.time.LocalDate;

public record Project(long id, String name, String description, LocalDate startDate, LocalDate deadline) {
}
