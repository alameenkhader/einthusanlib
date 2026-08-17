// Live download progress: poll /status.json every 30s while a download runs
// and refresh the page when it finishes (success or error).
(function () {
  'use strict';

  function currentState() {
    return document.getElementById('status-panel') &&
      document.querySelector('[data-download-state]');
  }

  var panel = document.querySelector('#status-panel[data-download-state="downloading"]');
  if (!panel) return;

  var bar = document.getElementById('progress-bar');
  var text = document.getElementById('progress-text');

  setInterval(function () {
    fetch('/status.json')
      .then(function (response) { return response.json(); })
      .then(function (status) {
        if (status.state === 'done' || status.state === 'error') {
          location.reload();
          return;
        }
        if (status.state !== 'downloading') return;
        if (status.progress) {
          bar.style.width = status.progress.percent + '%';
          text.textContent = status.progress.percent + '% - ' +
            formatBytes(status.progress.downloaded) + ' of ' +
            formatBytes(status.progress.total) +
            (status.progress.dl_bytes_per_sec ? ' @ ' + formatRate(status.progress.dl_bytes_per_sec) : '');
        }
      })
      .catch(function () { /* transient; next poll retries */ });
  }, 10000);

  function formatBytes(bytes) {
    if (!bytes && bytes !== 0) return '?';
    var units = ['B', 'KiB', 'MiB', 'GiB', 'TiB'];
    var value = bytes;
    var i = 0;
    while (value >= 1024 && i < units.length - 1) { value /= 1024; i += 1; }
    return (i === 0 ? value.toFixed(0) : value.toFixed(1)) + ' ' + units[i];
  }

  function formatRate(bytesPerSec) {
    return formatBytes(bytesPerSec) + '/s';
  }
}());