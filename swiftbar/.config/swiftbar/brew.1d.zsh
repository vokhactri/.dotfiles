#!/usr/bin/env zsh

# <xbar.title>Homebrew Updates</xbar.title>
# <xbar.version>v1.0.0</xbar.version>
# <xbar.author>trivk</xbar.author>
# <xbar.desc>Checks Homebrew daily and offers manual or automatic upgrades.</xbar.desc>
# <xbar.dependencies>zsh,brew</xbar.dependencies>

set -u

PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export HOMEBREW_NO_UPGRADE_AUTO_UPDATES_CASKS=1
PLUGIN_PATH="${0:A}"

BREW_BIN="${BREW_BIN:-$(command -v brew 2>/dev/null || true)}"
CACHE_DIR="${HOME}/Library/Caches/SwiftBarBrewUpdates"
STATE_DIR="${HOME}/Library/Application Support/SwiftBarBrewUpdates"
FORMULAE_FILE="${CACHE_DIR}/outdated-formulae"
CASKS_FILE="${CACHE_DIR}/outdated-casks"
CHECKED_AT_FILE="${CACHE_DIR}/checked-at"
ERROR_FILE="${CACHE_DIR}/last-error"
MANUAL_CHECK_FILE="${CACHE_DIR}/manual-check-running"
AUTO_FILE="${STATE_DIR}/auto-upgrade-enabled"
LOG_FILE="${STATE_DIR}/upgrade.log"
LOCK_DIR="${CACHE_DIR}/check.lock"
UPGRADE_LOCK_DIR="${CACHE_DIR}/upgrade.lock"
UPGRADE_PID_FILE="${UPGRADE_LOCK_DIR}/pid"
CHECK_INTERVAL_SECONDS=86400

mkdir -p "${CACHE_DIR}" "${STATE_DIR}"

escape_swiftbar() {
  printf '%s' "$1" | sed 's/|/\\|/g'
}

escape_attribute() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/|/\\|/g'
}

is_auto_enabled() {
  [ -f "${AUTO_FILE}" ]
}

is_manual_check_running() {
  [ -f "${MANUAL_CHECK_FILE}" ]
}

is_upgrade_running() {
  [ -d "${UPGRADE_LOCK_DIR}" ] || return 1

  upgrade_pid="$(cat "${UPGRADE_PID_FILE}" 2>/dev/null || true)"
  case "${upgrade_pid}" in
    *[!0-9]*|'') return 0 ;;
  esac

  if kill -0 "${upgrade_pid}" 2>/dev/null; then
    return 0
  fi

  rm -f "${UPGRADE_PID_FILE}"
  rmdir "${UPGRADE_LOCK_DIR}" 2>/dev/null || true
  return 1
}

is_brew_busy() {
  is_manual_check_running || is_upgrade_running
}

acquire_upgrade_lock() {
  allow_during_check="${1:-false}"

  if [ "${allow_during_check}" != "true" ] && { is_manual_check_running || [ -d "${LOCK_DIR}" ]; }; then
    return 1
  fi

  if ! mkdir "${UPGRADE_LOCK_DIR}" 2>/dev/null; then
    is_upgrade_running && return 1
    mkdir "${UPGRADE_LOCK_DIR}" 2>/dev/null || return 1
  fi

  printf '%s\n' "$$" > "${UPGRADE_PID_FILE}"
}

release_upgrade_lock() {
  upgrade_pid="$(cat "${UPGRADE_PID_FILE}" 2>/dev/null || true)"
  [ "${upgrade_pid}" = "$$" ] || return 0

  rm -f "${UPGRADE_PID_FILE}"
  rmdir "${UPGRADE_LOCK_DIR}" 2>/dev/null || true
}

log_busy_upgrade() {
  printf '\n[%s] Skipped %s: another Homebrew operation is already running\n' \
    "$(date '+%Y-%m-%d %H:%M:%S')" "$1" >> "${LOG_FILE}"
}

refresh_plugin() {
  plugin_name="${PLUGIN_PATH:t}"
  /usr/bin/open -g "swiftbar://refreshplugin?name=${plugin_name}" >/dev/null 2>&1 || true
}

start_manual_check() {
  is_manual_check_running && return 0

  touch "${MANUAL_CHECK_FILE}"
  nohup "${PLUGIN_PATH}" --check-now-worker >/dev/null 2>&1 &
}

run_manual_check_worker() {
  rm -f "${CHECKED_AT_FILE}"
  perform_daily_check
  check_status=$?
  rm -f "${MANUAL_CHECK_FILE}"
  refresh_plugin
  return "${check_status}"
}

write_error() {
  printf '%s\n' "$1" > "${ERROR_FILE}"
}

clear_error() {
  rm -f "${ERROR_FILE}"
}

record_check_time() {
  date +%s > "${CHECKED_AT_FILE}"
}

collect_outdated() {
  if ! "${BREW_BIN}" outdated --formula --quiet > "${FORMULAE_FILE}.tmp" 2> "${ERROR_FILE}.tmp"; then
    write_error "$(tail -n 1 "${ERROR_FILE}.tmp")"
    rm -f "${FORMULAE_FILE}.tmp" "${ERROR_FILE}.tmp"
    return 1
  fi

  if ! "${BREW_BIN}" outdated --cask --quiet > "${CASKS_FILE}.tmp" 2> "${ERROR_FILE}.tmp"; then
    write_error "$(tail -n 1 "${ERROR_FILE}.tmp")"
    rm -f "${FORMULAE_FILE}.tmp" "${CASKS_FILE}.tmp" "${ERROR_FILE}.tmp"
    return 1
  fi

  mv "${FORMULAE_FILE}.tmp" "${FORMULAE_FILE}"
  mv "${CASKS_FILE}.tmp" "${CASKS_FILE}"
  rm -f "${ERROR_FILE}.tmp"
  clear_error
}

run_upgrade_all() {
  upgrade_mode="${1:-manual}"

  if [ "${upgrade_mode}" = "auto" ]; then
    allow_during_check=true
  else
    allow_during_check=false
  fi

  if ! acquire_upgrade_lock "${allow_during_check}"; then
    log_busy_upgrade "Homebrew upgrade"
    return 75
  fi
  refresh_plugin

  {
    printf '\n[%s] Starting Homebrew upgrade\n' "$(date '+%Y-%m-%d %H:%M:%S')"
    if [ "${upgrade_mode}" = "auto" ]; then
      "${BREW_BIN}" upgrade --yes
    else
      "${BREW_BIN}" update && "${BREW_BIN}" upgrade --yes
    fi
  } >> "${LOG_FILE}" 2>&1
  upgrade_status=$?

  collect_outdated || true
  record_check_time
  release_upgrade_lock
  refresh_plugin
  return "${upgrade_status}"
}

run_upgrade_one() {
  package_name="$1"
  package_type="$2"

  case "${package_name}" in
    *[!A-Za-z0-9@+._/-]*|'')
      printf 'Invalid Homebrew package name: %s\n' "${package_name}" >&2
      exit 2
      ;;
  esac

  case "${package_type}" in
    formula) type_flag="--formula" ;;
    cask) type_flag="--cask" ;;
    *)
      printf 'Invalid package type: %s\n' "${package_type}" >&2
      exit 2
      ;;
  esac

  if ! acquire_upgrade_lock; then
    log_busy_upgrade "upgrade of ${package_name}"
    return 75
  fi
  refresh_plugin

  {
    printf '\n[%s] Upgrading %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "${package_name}"
    "${BREW_BIN}" upgrade --yes "${type_flag}" "${package_name}"
  } >> "${LOG_FILE}" 2>&1
  upgrade_status=$?

  collect_outdated || true
  record_check_time
  release_upgrade_lock
  refresh_plugin
  return "${upgrade_status}"
}

perform_daily_check() {
  if ! mkdir "${LOCK_DIR}" 2>/dev/null; then
    return 0
  fi
  trap 'rmdir "${LOCK_DIR}" 2>/dev/null || true' EXIT

  update_output="$("${BREW_BIN}" update 2>&1)"
  update_status=$?
  if [ "${update_status}" -ne 0 ]; then
    write_error "$(printf '%s\n' "${update_output}" | tail -n 1)"
    record_check_time
    return 1
  fi

  collect_outdated || {
    record_check_time
    return 1
  }
  record_check_time

  if is_auto_enabled && [ "$(outdated_count)" -gt 0 ]; then
    run_upgrade_all auto
  fi
}

check_is_due() {
  [ ! -f "${CHECKED_AT_FILE}" ] && return 0

  checked_at="$(cat "${CHECKED_AT_FILE}" 2>/dev/null || printf '0')"
  case "${checked_at}" in
    *[!0-9]*|'') return 0 ;;
  esac

  now="$(date +%s)"
  [ $((now - checked_at)) -ge "${CHECK_INTERVAL_SECONDS}" ]
}

file_line_count() {
  if [ -s "$1" ]; then
    wc -l < "$1" | tr -d ' '
  else
    printf '0'
  fi
}

outdated_count() {
  formula_count="$(file_line_count "${FORMULAE_FILE}")"
  cask_count="$(file_line_count "${CASKS_FILE}")"
  printf '%s' $((formula_count + cask_count))
}

format_checked_at() {
  if [ ! -f "${CHECKED_AT_FILE}" ]; then
    printf 'Never'
    return
  fi

  checked_at="$(cat "${CHECKED_AT_FILE}")"
  date -r "${checked_at}" '+%Y-%m-%d %H:%M' 2>/dev/null || printf 'Unknown'
}

render_package_menu() {
  package_file="$1"
  package_type="$2"
  heading="$3"

  [ -s "${package_file}" ] || return 0

  script_path="$(escape_attribute "${PLUGIN_PATH}")"
  if [ "${package_type}" = "formula" ]; then
    heading_symbol="shippingbox"
    package_symbol="cube.box"
  else
    heading_symbol="macwindow"
    package_symbol="app"
  fi

  printf '%s | sfimage=%s\n' "${heading}" "${heading_symbol}"
  while IFS= read -r package_name; do
    [ -n "${package_name}" ] || continue
    safe_name="$(escape_swiftbar "${package_name}")"
    if is_brew_busy; then
      printf -- '--%s | sfimage=%s disabled=true\n' "${safe_name}" "${package_symbol}"
    else
      printf -- '--%s | sfimage=%s bash="%s" param1=--upgrade-one param2=%s param3=%s terminal=false refresh=true\n' \
        "${safe_name}" "${package_symbol}" "${script_path}" "${safe_name}" "${package_type}"
    fi
  done < "${package_file}"
}

render_menu() {
  count="$(outdated_count)"
  checked_at="$(format_checked_at)"
  script_path="$(escape_attribute "${PLUGIN_PATH}")"

  if is_brew_busy; then
    printf '… | sfimage=arrow.triangle.2.circlepath sfcolor=#007AFF sfsize=14 tooltip="Homebrew operation in progress…"\n'
  elif [ "${count}" -eq 0 ]; then
    printf '0 | sfimage=shippingbox.fill sfcolor=#34C759 sfsize=14 tooltip="Homebrew is up to date"\n'
  else
    printf '%s | sfimage=shippingbox.fill sfcolor=#FF9500 sfsize=14 tooltip="%s Homebrew package(s) outdated"\n' "${count}" "${count}"
  fi

  printf -- '---\n'
  printf 'Homebrew Updates | sfimage=shippingbox.fill sfcolor=#007AFF size=14\n'
  printf -- '--Outdated: %s | sfimage=number.circle\n' "${count}"
  printf -- '--Last check: %s | sfimage=clock\n' "${checked_at}"

  if [ -s "${ERROR_FILE}" ]; then
    error_message="$(escape_swiftbar "$(tail -n 1 "${ERROR_FILE}")")"
    printf -- '--Last check failed: %s | sfimage=exclamationmark.triangle.fill sfcolor=#FF3B30 color=#FF3B30\n' "${error_message}"
  fi

  printf -- '---\n'
  if is_auto_enabled; then
    printf 'Auto upgrade | checked=true sfimage=arrow.triangle.2.circlepath sfcolor=#34C759 bash="%s" param1=--disable-auto terminal=false refresh=true\n' "${script_path}"
  else
    printf 'Auto upgrade | checked=false sfimage=arrow.triangle.2.circlepath sfcolor=#8E8E93 bash="%s" param1=--enable-auto terminal=false refresh=true\n' "${script_path}"
  fi

  if is_brew_busy; then
    printf 'Check for updates now | sfimage=arrow.clockwise disabled=true\n'
  else
    printf 'Check for updates now | sfimage=arrow.clockwise bash="%s" param1=--check-now terminal=false refresh=true\n' "${script_path}"
  fi

  if [ "${count}" -gt 0 ]; then
    if is_brew_busy; then
      printf 'Upgrade all in background | sfimage=arrow.up sfcolor=#007AFF disabled=true\n'
    else
      printf 'Upgrade all in background | sfimage=arrow.up sfcolor=#007AFF bash="%s" param1=--upgrade-all terminal=false refresh=true\n' "${script_path}"
    fi
    printf -- '---\n'
    render_package_menu "${FORMULAE_FILE}" formula 'Formulae'
    render_package_menu "${CASKS_FILE}" cask 'Casks'
  fi

  if [ -f "${LOG_FILE}" ]; then
    log_path="$(escape_attribute "${LOG_FILE}")"
    printf -- '---\n'
    printf 'Open upgrade log | sfimage=doc.text bash=/usr/bin/open param1="%s" terminal=false\n' "${log_path}"
  fi
}

if [ -z "${BREW_BIN}" ]; then
  printf '! | sfimage=exclamationmark.triangle.fill sfcolor=#FF3B30 color=#FF3B30\n'
  printf -- '---\nHomebrew was not found in /opt/homebrew or /usr/local.\n'
  exit 0
fi

case "${1:-}" in
  --enable-auto)
    touch "${AUTO_FILE}"
    exit 0
    ;;
  --disable-auto)
    rm -f "${AUTO_FILE}"
    exit 0
    ;;
  --check-now)
    start_manual_check
    exit $?
    ;;
  --check-now-worker)
    run_manual_check_worker
    exit $?
    ;;
  --upgrade-all)
    run_upgrade_all
    exit $?
    ;;
  --upgrade-one)
    run_upgrade_one "${2:-}" "${3:-}"
    exit $?
    ;;
esac

if check_is_due; then
  perform_daily_check || true
fi

render_menu
