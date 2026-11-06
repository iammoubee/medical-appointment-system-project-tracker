(() => {
    "use strict";

    const apiUrl = `${window.projectTrackerContext}/api/tasks`;
    const tasksBody = document.getElementById("task-rows");
    const taskModal = new bootstrap.Modal(document.getElementById("task-modal"));
    const toast = new bootstrap.Toast(document.getElementById("app-toast"), { delay: 3200 });
    const form = document.getElementById("task-form");
    let tasks = [];
    let gantt = null;
    let viewMode = "Month";

    const byId = (id) => document.getElementById(id);
    const safeText = (value) => String(value ?? "");
    const escapeHtml = (value) => safeText(value).replace(/[&<>"']/g, (character) => ({
        "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;"
    })[character]);
    const statusClass = (status) => status.toLowerCase().replaceAll(" ", "-");

    function showMessage(message) {
        byId("app-toast").querySelector(".toast-body").textContent = message;
        toast.show();
    }

    async function request(url, options = {}) {
        const response = await fetch(url, {
            ...options,
            headers: { "Content-Type": "application/json", ...(options.headers || {}) }
        });
        const result = await response.json().catch(() => ({}));
        if (!response.ok) {
            throw new Error(result.error || `Request failed (${response.status}).`);
        }
        return result;
    }

    function summarize() {
        const weight = tasks.reduce((sum, task) => sum + Number(task.weight), 0);
        const earned = tasks.reduce((sum, task) => sum + Number(task.weight) * task.completionPercentage / 100, 0);
        const completion = weight === 0 ? 0 : Math.round(earned / weight * 1000) / 10;
        const remaining = Math.round((100 - completion) * 10) / 10;
        const count = (status) => tasks.filter((task) => task.status === status).length;

        byId("total-tasks").textContent = tasks.length;
        byId("completed-tasks").textContent = count("Completed");
        byId("in-progress-tasks").textContent = count("In Progress");
        byId("pending-tasks").textContent = count("Pending");
        byId("completion-value").textContent = completion.toFixed(1);
        byId("remaining-value").textContent = `${remaining.toFixed(1)}% remaining`;
        byId("overall-progress").style.width = `${Math.min(100, completion)}%`;
        byId("report-completion").textContent = `${completion.toFixed(1)}%`;
        byId("report-remaining").textContent = `${remaining.toFixed(1)}%`;
        byId("total-weight").textContent = weight.toFixed(2).replace(/\.?0+$/, "");
        const today = new Date();
        const todayString = new Date(today.getTime() - today.getTimezoneOffset() * 60000).toISOString().slice(0, 10);
        const delayed = tasks.filter((task) => task.status !== "Completed" && task.endDate < todayString).length;
        byId("delayed-tasks").textContent = delayed;
        byId("schedule-note").textContent = delayed ? `${delayed} task${delayed === 1 ? "" : "s"} past planned end date` : "Based on planned task dates";
    }

    function renderTasks() {
        tasksBody.replaceChildren();
        byId("empty-tasks").classList.toggle("d-none", tasks.length > 0);
        for (const task of tasks) {
            const row = document.createElement("tr");
            const taskCell = document.createElement("td");
            const title = document.createElement("div");
            title.className = "task-name";
            if (task.milestone) {
                const marker = document.createElement("span");
                marker.className = "milestone-badge";
                marker.textContent = "◆";
                marker.title = "Milestone";
                title.append(marker);
            }
            const name = document.createElement("span");
            name.textContent = task.name;
            title.append(name);
            const description = document.createElement("div");
            description.className = "task-subtitle";
            description.textContent = task.description || "No description";
            taskCell.append(title, description);

            const schedule = document.createElement("td");
            schedule.textContent = `${task.startDate} – ${task.endDate}`;
            const weight = document.createElement("td");
            weight.textContent = Number(task.weight).toFixed(2).replace(/\.?0+$/, "");
            const statusCell = document.createElement("td");
            const status = document.createElement("select");
            status.className = `task-status-select status-${statusClass(task.status)}`;
            status.setAttribute("aria-label", `Status for ${task.name}`);
            for (const choice of ["Pending", "In Progress", "Completed"]) {
                const option = document.createElement("option");
                option.value = choice;
                option.textContent = choice;
                option.selected = choice === task.status;
                status.append(option);
            }
            statusCell.append(status);

            const completionCell = document.createElement("td");
            const completion = document.createElement("div");
            completion.className = "completion-control";
            const percentage = document.createElement("input");
            percentage.type = "number";
            percentage.min = "0";
            percentage.max = "100";
            percentage.step = "1";
            percentage.value = task.completionPercentage;
            percentage.setAttribute("aria-label", `Completion percentage for ${task.name}`);
            const percentLabel = document.createElement("span");
            percentLabel.textContent = "%";
            const track = document.createElement("div");
            track.className = "mini-progress";
            const fill = document.createElement("span");
            fill.style.width = `${task.completionPercentage}%`;
            track.append(fill);
            completion.append(percentage, percentLabel, track);
            completionCell.append(completion);

            const actions = document.createElement("td");
            const edit = document.createElement("button");
            edit.className = "task-action";
            edit.type = "button";
            edit.textContent = "Edit";
            edit.addEventListener("click", () => openTaskModal(task));
            const remove = document.createElement("button");
            remove.className = "task-action delete";
            remove.type = "button";
            remove.textContent = "Delete";
            remove.addEventListener("click", () => deleteTask(task));
            actions.append(edit, remove);
            row.append(taskCell, schedule, weight, statusCell, completionCell, actions);

            status.addEventListener("change", async () => {
                const previous = task.status;
                task.status = status.value;
                if (task.status === "Completed") task.completionPercentage = 100;
                if (task.status === "Pending") task.completionPercentage = 0;
                percentage.value = task.completionPercentage;
                fill.style.width = `${task.completionPercentage}%`;
                status.className = `task-status-select status-${statusClass(task.status)}`;
                summarize();
                await saveInline(task, previous);
            });
            percentage.addEventListener("change", async () => {
                const value = Number(percentage.value);
                if (!Number.isInteger(value) || value < 0 || value > 100) {
                    showMessage("Completion must be a whole number between 0 and 100.");
                    percentage.value = task.completionPercentage;
                    return;
                }
                const previous = task.completionPercentage;
                task.completionPercentage = value;
                task.status = value === 100 ? "Completed" : value === 0 ? "Pending" : "In Progress";
                summarize();
                renderTasks();
                await saveInline(task, previous);
            });
            tasksBody.append(row);
        }
        summarize();
    }

    async function saveInline(task, previousValue) {
        try {
            await request(`${apiUrl}/${task.id}`, {
                method: "PUT",
                body: JSON.stringify(taskPayload(task))
            });
            await loadTasks(false);
            showMessage("Task progress saved.");
        } catch (error) {
            if (typeof previousValue === "string") task.status = previousValue;
            else task.completionPercentage = previousValue;
            await loadTasks(false);
            showMessage(error.message);
        }
    }

    function taskPayload(task) {
        return {
            name: task.name,
            description: task.description,
            startDate: task.startDate,
            endDate: task.endDate,
            weight: Number(task.weight),
            status: task.status,
            completionPercentage: Number(task.completionPercentage),
            dependencyId: task.dependencyId || null,
            milestone: Boolean(task.milestone)
        };
    }

    function drawGantt() {
        const empty = byId("empty-chart");
        if (!tasks.length || typeof window.Gantt !== "function") {
            byId("gantt-chart").replaceChildren();
            empty.classList.remove("d-none");
            empty.textContent = tasks.length ? "The Gantt chart library could not be loaded. Check the browser network connection." : "Add tasks with start and end dates to build the schedule.";
            return;
        }
        empty.classList.add("d-none");
        const knownIds = new Set(tasks.map((task) => String(task.id)));
        const ganttTasks = tasks.map((task) => ({
            id: String(task.id),
            name: escapeHtml(`${task.milestone ? "◆ " : ""}${task.name}`),
            start: task.startDate,
            end: task.endDate,
            progress: Number(task.completionPercentage),
            dependencies: task.dependencyId && knownIds.has(String(task.dependencyId)) ? String(task.dependencyId) : "",
            custom_class: `${statusClass(task.status)}${task.milestone ? " milestone" : ""}`
        }));
        try {
            gantt = new window.Gantt("#gantt-chart", ganttTasks, {
                view_mode: viewMode,
                date_format: "YYYY-MM-DD",
                on_click: (item) => {
                    const selected = tasks.find((task) => String(task.id) === item.id);
                    if (selected) openTaskModal(selected);
                },
                on_date_change: async (item, start, end) => {
                    const selected = tasks.find((task) => String(task.id) === item.id);
                    if (!selected) return;
                    selected.startDate = formatDate(start);
                    selected.endDate = formatDate(end);
                    try {
                        await request(`${apiUrl}/${selected.id}`, { method: "PUT", body: JSON.stringify(taskPayload(selected)) });
                        await loadTasks(false);
                        showMessage("Task schedule saved.");
                    } catch (error) {
                        showMessage(error.message);
                        await loadTasks(false);
                    }
                },
                on_progress_change: async (item, progress) => {
                    const selected = tasks.find((task) => String(task.id) === item.id);
                    if (!selected) return;
                    selected.completionPercentage = Math.round(progress);
                    selected.status = selected.completionPercentage === 100 ? "Completed" : selected.completionPercentage === 0 ? "Pending" : "In Progress";
                    try {
                        await request(`${apiUrl}/${selected.id}`, { method: "PUT", body: JSON.stringify(taskPayload(selected)) });
                        await loadTasks(false);
                        showMessage("Task progress saved.");
                    } catch (error) {
                        showMessage(error.message);
                        await loadTasks(false);
                    }
                }
            });
            addTodayIndicator();
        } catch (error) {
            console.error("Could not draw the Gantt chart.", error);
            empty.classList.remove("d-none");
            empty.textContent = "The schedule chart could not be rendered. Check task dates and reload.";
        }
    }

    function addTodayIndicator() {
        const svg = byId("gantt-chart");
        const tasksLayer = svg.querySelector("g.bar");
        const firstTask = tasks.find((task) => svg.querySelector(`.bar-wrapper[data-id="${task.id}"] .bar`));
        if (!tasksLayer || !firstTask) return;

        const bar = svg.querySelector(`.bar-wrapper[data-id="${firstTask.id}"] .bar`);
        const taskStart = new Date(`${firstTask.startDate}T00:00:00Z`);
        const taskEnd = new Date(`${firstTask.endDate}T00:00:00Z`);
        const duration = Math.max(1, (taskEnd - taskStart) / 86400000 + 1);
        const scale = Number(bar.getAttribute("width")) / duration;
        const today = new Date();
        const todayUtc = new Date(Date.UTC(today.getFullYear(), today.getMonth(), today.getDate()));
        const x = Number(bar.getAttribute("x")) + (todayUtc - taskStart) / 86400000 * scale;
        const chartWidth = Number(svg.querySelector(".grid-header")?.getAttribute("width"));
        if (!Number.isFinite(x) || !Number.isFinite(chartWidth) || x < 0 || x > chartWidth) return;

        const height = Number(svg.getAttribute("height")) || svg.viewBox.baseVal.height;
        const line = document.createElementNS("http://www.w3.org/2000/svg", "line");
        line.setAttribute("class", "today-line-marker");
        line.setAttribute("x1", String(x));
        line.setAttribute("x2", String(x));
        line.setAttribute("y1", "58");
        line.setAttribute("y2", String(height));
        line.setAttribute("aria-label", "Today");
        svg.insertBefore(line, tasksLayer);

        const label = document.createElementNS("http://www.w3.org/2000/svg", "text");
        label.setAttribute("class", "today-label");
        label.setAttribute("x", String(x + 4));
        label.setAttribute("y", "16");
        label.textContent = "Today";
        svg.insertBefore(label, tasksLayer);
    }

    function formatDate(date) {
        return new Date(date.getTime() - date.getTimezoneOffset() * 60000).toISOString().slice(0, 10);
    }

    function openTaskModal(task = null) {
        byId("task-form").reset();
        byId("form-error").classList.add("d-none");
        byId("task-id").value = task ? task.id : "";
        byId("task-modal-title").textContent = task ? "Edit task" : "Add task";
        byId("task-name").value = task?.name || "";
        byId("task-description").value = task?.description || "";
        byId("task-start").value = task?.startDate || new Date().toISOString().slice(0, 10);
        byId("task-end").value = task?.endDate || new Date().toISOString().slice(0, 10);
        byId("task-weight").value = task?.weight ?? 5;
        byId("task-status").value = task?.status || "Pending";
        byId("task-completion").value = task?.completionPercentage ?? 0;
        byId("task-milestone").checked = Boolean(task?.milestone);
        const dependency = byId("task-dependency");
        dependency.replaceChildren(new Option("No dependency", ""));
        for (const item of tasks) {
            if (item.id === task?.id) continue;
            dependency.add(new Option(item.name, item.id));
        }
        dependency.value = task?.dependencyId || "";
        taskModal.show();
    }

    async function deleteTask(task) {
        if (!window.confirm(`Delete "${task.name}"? This cannot be undone.`)) return;
        try {
            await request(`${apiUrl}/${task.id}`, { method: "DELETE" });
            await loadTasks(false);
            showMessage("Task deleted.");
        } catch (error) {
            showMessage(error.message);
        }
    }

    async function loadTasks(showErrors = true) {
        try {
            tasks = await request(apiUrl);
            renderTasks();
            drawGantt();
        } catch (error) {
            tasks = [];
            renderTasks();
            drawGantt();
            if (showErrors) showMessage(error.message);
        }
    }

    form.addEventListener("submit", async (event) => {
        event.preventDefault();
        const errorBox = byId("form-error");
        const startDate = byId("task-start").value;
        const endDate = byId("task-end").value;
        const weight = Number(byId("task-weight").value);
        const completionPercentage = Number(byId("task-completion").value);
        if (endDate < startDate) {
            errorBox.textContent = "End date must be on or after the start date.";
            errorBox.classList.remove("d-none");
            return;
        }
        if (!Number.isFinite(weight) || weight < 0 || !Number.isInteger(completionPercentage) || completionPercentage < 0 || completionPercentage > 100) {
            errorBox.textContent = "Weight must be non-negative and completion must be a whole number from 0 to 100.";
            errorBox.classList.remove("d-none");
            return;
        }
        const id = byId("task-id").value;
        const payload = {
            name: byId("task-name").value.trim(),
            description: byId("task-description").value.trim(),
            startDate,
            endDate,
            weight,
            status: byId("task-status").value,
            completionPercentage,
            dependencyId: byId("task-dependency").value || null,
            milestone: byId("task-milestone").checked
        };
        const saveButton = byId("save-task");
        saveButton.disabled = true;
        try {
            await request(id ? `${apiUrl}/${id}` : apiUrl, {
                method: id ? "PUT" : "POST",
                body: JSON.stringify(payload)
            });
            taskModal.hide();
            await loadTasks(false);
            showMessage(id ? "Task updated." : "Task added.");
        } catch (error) {
            errorBox.textContent = error.message;
            errorBox.classList.remove("d-none");
        } finally {
            saveButton.disabled = false;
        }
    });

    byId("task-status").addEventListener("change", (event) => {
        const completion = byId("task-completion");
        if (event.target.value === "Completed") completion.value = 100;
        if (event.target.value === "Pending") completion.value = 0;
    });
    byId("task-completion").addEventListener("input", (event) => {
        const value = Number(event.target.value);
        if (value > 0 && value < 100) byId("task-status").value = "In Progress";
        if (value === 0) byId("task-status").value = "Pending";
        if (value === 100) byId("task-status").value = "Completed";
    });
    byId("add-task-button").addEventListener("click", () => openTaskModal());
    byId("add-task-top").addEventListener("click", () => openTaskModal());
    byId("print-report").addEventListener("click", () => window.print());
    document.querySelectorAll(".view-button").forEach((button) => {
        button.addEventListener("click", () => {
            viewMode = button.dataset.view;
            document.querySelectorAll(".view-button").forEach((entry) => entry.classList.toggle("active", entry === button));
            if (gantt) {
                gantt.change_view_mode(viewMode);
                addTodayIndicator();
            }
            else drawGantt();
        });
    });
    document.querySelectorAll(".side-nav .nav-link").forEach((link) => {
        link.addEventListener("click", () => {
            document.querySelectorAll(".side-nav .nav-link").forEach((entry) => entry.classList.toggle("active", entry === link));
        });
    });

    loadTasks();
})();
