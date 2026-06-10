const searchForm = document.getElementById("search-form");
const searchInput = document.getElementById("search-input");
const clearSearchBtn = document.getElementById("clear-search");
const recordsBody = document.getElementById("records-body");
const recordCount = document.getElementById("record-count");
const submitForm = document.getElementById("submit-form");
const submitBtn = document.getElementById("submit-btn");
const formAlert = document.getElementById("form-alert");
const backendStatus = document.getElementById("backend-status");
const toastContainer = document.getElementById("toast-container");
const submissionsBody = document.getElementById("submissions-body");
const refreshSubmissionsBtn = document.getElementById("refresh-submissions");

let backendUrl = "http://localhost:5000";

async function loadConfig() {
  const response = await fetch("/config");
  const config = await response.json();
  backendUrl = config.backendUrl.replace(/\/$/, "");
}

function showToast(message, type = "success") {
  const toast = document.createElement("div");
  toast.className = `toast ${type}`;
  toast.textContent = message;
  toastContainer.appendChild(toast);
  setTimeout(() => toast.remove(), 4200);
}

function setBackendStatus(online, message) {
  backendStatus.classList.remove("online", "offline");
  backendStatus.classList.add(online ? "online" : "offline");
  backendStatus.querySelector(".status-text").textContent = message;
}

function renderRecords(records) {
  recordCount.textContent = String(records.length);

  if (!records.length) {
    recordsBody.innerHTML =
      '<tr><td colspan="3" class="empty-cell">No records found.</td></tr>';
    return;
  }

  recordsBody.innerHTML = records
    .map(
      (record) => `
        <tr>
          <td>${escapeHtml(String(record.id ?? "—"))}</td>
          <td>${escapeHtml(String(record.name ?? "—"))}</td>
          <td>${escapeHtml(String(record.role ?? "—"))}</td>
        </tr>
      `
    )
    .join("");
}

function escapeHtml(value) {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}

function showFormAlert(message, type) {
  formAlert.hidden = false;
  formAlert.textContent = message;
  formAlert.className = `alert ${type}`;
}

function hideFormAlert() {
  formAlert.hidden = true;
  formAlert.textContent = "";
}

function setSubmitLoading(isLoading) {
  submitBtn.disabled = isLoading;
  submitBtn.querySelector(".btn-label").hidden = isLoading;
  submitBtn.querySelector(".btn-spinner").hidden = !isLoading;
}

async function checkBackendHealth() {
  const endpoints = [`${backendUrl}/health`, `${backendUrl}/api/records`];

  for (const url of endpoints) {
    try {
      const response = await fetch(url);
      if (!response.ok) continue;
      setBackendStatus(true, "Backend online");
      return true;
    } catch {
      // Try the next endpoint (CORS or network may block one path only).
    }
  }

  setBackendStatus(false, "Backend offline");
  return false;
}

function markBackendOnline() {
  setBackendStatus(true, "Backend online");
}

function renderSubmissions(submissions) {
  if (!submissions.length) {
    submissionsBody.innerHTML =
      '<tr><td colspan="3" class="empty-cell">No submissions yet. Submit the form above.</td></tr>';
    return;
  }

  submissionsBody.innerHTML = submissions
    .map(
      (item) => `
        <tr>
          <td>${escapeHtml(String(item.name ?? "—"))}</td>
          <td>${escapeHtml(String(item.email ?? "—"))}</td>
          <td title="${escapeHtml(String(item.message ?? ""))}">${escapeHtml(String(item.message ?? "—"))}</td>
        </tr>
      `
    )
    .join("");
}

async function fetchSubmissions() {
  submissionsBody.innerHTML =
    '<tr><td colspan="3" class="table-placeholder">Loading submissions…</td></tr>';

  const response = await fetch(`${backendUrl}/api/submissions`);
  if (!response.ok) {
    const payload = await response.json().catch(() => ({}));
    throw new Error(payload.error || "Failed to load submissions.");
  }

  const payload = await response.json();
  renderSubmissions(payload.submissions || []);
  markBackendOnline();
}

async function fetchRecords(query = "") {
  recordsBody.innerHTML =
    '<tr><td colspan="3" class="table-placeholder">Loading records…</td></tr>';

  const params = new URLSearchParams();
  if (query.trim()) params.set("q", query.trim());

  const url = `${backendUrl}/api/records${params.toString() ? `?${params}` : ""}`;
  const response = await fetch(url);

  if (!response.ok) {
    const payload = await response.json().catch(() => ({}));
    throw new Error(payload.error || "Failed to load records.");
  }

  const payload = await response.json();
  renderRecords(payload.records || []);
  markBackendOnline();
}

searchForm.addEventListener("submit", async (event) => {
  event.preventDefault();
  try {
    await fetchRecords(searchInput.value);
  } catch (error) {
    showToast(error.message, "error");
    recordsBody.innerHTML =
      '<tr><td colspan="3" class="empty-cell">Could not load records.</td></tr>';
  }
});

clearSearchBtn.addEventListener("click", async () => {
  searchInput.value = "";
  try {
    await fetchRecords();
  } catch (error) {
    showToast(error.message, "error");
  }
});

submitForm.addEventListener("submit", async (event) => {
  event.preventDefault();
  hideFormAlert();

  const formData = {
    name: submitForm.name.value.trim(),
    email: submitForm.email.value.trim(),
    message: submitForm.message.value.trim(),
  };

  if (!formData.name || !formData.email || !formData.message) {
    showFormAlert("All fields are required.", "error");
    return;
  }

  setSubmitLoading(true);

  try {
    const response = await fetch(`${backendUrl}/api/submit`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(formData),
    });

    const payload = await response.json();

    if (!response.ok || !payload.success) {
      throw new Error(payload.error || "Submission failed.");
    }

    showFormAlert(payload.message, "success");
    showToast("Submission saved to MongoDB Atlas.", "success");
    markBackendOnline();
    submitForm.reset();
    await fetchSubmissions();
  } catch (error) {
    showFormAlert(error.message, "error");
    showToast(error.message, "error");
  } finally {
    setSubmitLoading(false);
  }
});

refreshSubmissionsBtn.addEventListener("click", async () => {
  try {
    await fetchSubmissions();
    showToast("Submissions refreshed.", "success");
  } catch (error) {
    showToast(error.message, "error");
    submissionsBody.innerHTML =
      '<tr><td colspan="3" class="empty-cell">Could not load submissions.</td></tr>';
  }
});

async function init() {
  try {
    await loadConfig();
    const online = await checkBackendHealth();
    if (online) {
      await Promise.all([fetchRecords(), fetchSubmissions()]);
    } else {
      recordCount.textContent = "0";
      recordsBody.innerHTML =
        '<tr><td colspan="3" class="empty-cell">Backend is not reachable.</td></tr>';
      submissionsBody.innerHTML =
        '<tr><td colspan="3" class="empty-cell">Backend is not reachable.</td></tr>';
    }
  } catch (error) {
    setBackendStatus(false, "Setup error");
    showToast(error.message, "error");
  }
}

init();
