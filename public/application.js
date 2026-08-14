document.addEventListener("DOMContentLoaded", () => {
  const container = document.querySelector("[data-downstream]")
  if (!container) return

  const downloadUrl = container.dataset.downstreamUrl
  const statusUrl = container.dataset.downstreamStatusUrl
  const statusEl = document.getElementById("downstream-status")
  const messageEl = document.getElementById("downstream-status-message") || statusEl
  const spinner = statusEl && statusEl.querySelector(".spinner-border")
  const progressEl = document.getElementById("downstream-progress")
  const progressBar = document.getElementById("downstream-progress-bar")
  const progressFill = document.getElementById("downstream-progress-fill")
  const csrfToken = () => document.querySelector('meta[name="csrf-token"]').content

  const POLL_INTERVAL = 45000
  const handledStates = ["working", "waiting"]
  let timer = null

  const setMessage = (message) => {
    if (messageEl) messageEl.textContent = message
  }

  const setSpinner = (show) => {
    if (spinner) spinner.classList.toggle("d-none", !show)
  }

  const formatBytes = (bytes) => {
    if (!Number.isFinite(bytes) || bytes < 0) return "0 B"
    const units = ["B", "KiB", "MiB", "GiB", "TiB"]
    let value = bytes
    let i = 0
    while (value >= 1024 && i < units.length - 1) { value /= 1024; i++ }
    return `${value.toFixed(i === 0 ? 0 : 1)} ${units[i]}`
  }

  const formatEta = (seconds) => {
    if (!Number.isFinite(seconds) || seconds < 0) return null
    const h = Math.floor(seconds / 3600)
    const m = Math.floor((seconds % 3600) / 60)
    if (h > 0) return m > 0 ? `~${h}h ${m}m` : `~${h}h`
    if (m > 0) return `~${m}m`
    return `~${Math.max(1, Math.round(seconds))}s`
  }

  const formatRate = (bytesPerSec) => {
    if (!Number.isFinite(bytesPerSec) || bytesPerSec < 0) return null
    const units = ["B", "KiB", "MiB", "GiB", "TiB"]
    let value = bytesPerSec
    let i = 0
    while (value >= 1024 && i < units.length - 1) { value /= 1024; i++ }
    return `${value.toFixed(value >= 100 ? 0 : 1)} ${units[i]}/s`
  }

  const showProgress = (status) => {
    if (!progressEl || !progressBar || !progressFill) return
    const hasProgress = status.downloaded != null && status.total > 0
    if (!hasProgress) {
      progressEl.classList.add("d-none")
      progressBar.classList.add("d-none")
      return
    }
    const percent = status.percent != null
      ? status.percent
      : Math.min(100, Math.round((status.downloaded / status.total) * 100))
    let text = `${formatBytes(status.downloaded)} of ${formatBytes(status.total)} (${percent}%)`
    const eta = formatEta(status.eta_seconds)
    if (eta) text += ` — ${eta} left`
    const rate = formatRate(status.dl_bytes_per_sec)
    if (rate) text += ` @ ${rate}`
    progressEl.textContent = text
    progressEl.classList.remove("d-none")
    progressBar.classList.remove("d-none")
    progressFill.style.width = `${percent}%`
  }

  const schedulePoll = (delay) => {
    clearTimeout(timer)
    timer = setTimeout(poll, delay)
  }

  // Strictly ordered flow: status first. Only POST the download when this
  // movie isn't already being handled, so we never fire a pointless 409
  // against a download that is already running.
  const poll = () => {
    fetch(statusUrl)
      .then(response => response.json())
      .then(status => {
        if (status.message) setMessage(status.message)
        showProgress(status)
        setSpinner(handledStates.includes(status.state))
        if (status.state === "done" && status.redirect) {
          window.location = status.redirect
          return
        }
        if (status.state === "failed") return
        if (handledStates.includes(status.state)) {
          schedulePoll(POLL_INTERVAL)
        } else {
          trigger()
        }
      })
      .catch(() => schedulePoll(POLL_INTERVAL))
  }

  const trigger = () => {
    fetch(downloadUrl, {
      method: "POST",
      credentials: "same-origin",
      headers: { "X-CSRF-Token": csrfToken() }
    }).then(response => {
      if (response.status === 200) {
        schedulePoll(0)
      } else if (response.status === 409) {
        // The global lock is held by another download; this movie is queued.
        setMessage("Waiting for the current download to finish...")
        setSpinner(true)
        schedulePoll(POLL_INTERVAL)
      }
    }).catch(() => schedulePoll(POLL_INTERVAL))
  }

  poll()
})