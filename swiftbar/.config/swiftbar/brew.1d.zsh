#!/usr/bin/env zsh

# <xbar.title>Homebrew Updates</xbar.title>
# <xbar.version>v1.0.0</xbar.version>
# <xbar.author>trivk</xbar.author>
# <xbar.desc>Checks Homebrew daily and offers manual or automatic upgrades.</xbar.desc>
# <xbar.dependencies>zsh,brew</xbar.dependencies>
# <swiftbar.hideAbout>true</swiftbar.hideAbout>
# <swiftbar.hideLastUpdated>true</swiftbar.hideLastUpdated>

set -u
zmodload zsh/datetime

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
SF_SIZE=15

mkdir -p "${CACHE_DIR}" "${STATE_DIR}"

escape_swiftbar() {
  local value="$1"
  printf '%s' "${value//\|/\\|}"
}

escape_attribute() {
  local value="$1"
  local backslash='\'
  local quote='"'
  local pipe='|'

  value="${value//${backslash}/${backslash}${backslash}}"
  value="${value//${quote}/${backslash}${quote}}"
  printf '%s' "${value//${pipe}/${backslash}${pipe}}"
}

is_auto_enabled() {
  [[ -f "${AUTO_FILE}" ]]
}

is_manual_check_running() {
  [[ -f "${MANUAL_CHECK_FILE}" ]]
}

is_upgrade_running() {
  [[ -d "${UPGRADE_LOCK_DIR}" ]] || return 1

  local upgrade_pid
  upgrade_pid="$(<"${UPGRADE_PID_FILE}" 2>/dev/null || true)"
  case "${upgrade_pid}" in
    *[!0-9]*|'') return 0 ;;
  esac

  if kill -0 "${upgrade_pid}" 2>/dev/null; then
    return 0
  fi

  rm -f -- "${UPGRADE_PID_FILE:?}" # noka: ZC1059
  rmdir "${UPGRADE_LOCK_DIR}" 2>/dev/null || true
  return 1
}

is_brew_busy() {
  is_manual_check_running || is_upgrade_running
}

acquire_upgrade_lock() {
  local allow_during_check="${1:-false}"

  if [[ "${allow_during_check}" != "true" ]] && { is_manual_check_running || [[ -d "${LOCK_DIR}" ]]; }; then
    return 1
  fi

  if ! mkdir "${UPGRADE_LOCK_DIR}" 2>/dev/null; then # noka: ZC1147
    is_upgrade_running && return 1
    mkdir "${UPGRADE_LOCK_DIR}" 2>/dev/null || return 1 # noka: ZC1147
  fi

  printf '%s\n' "$$" > "${UPGRADE_PID_FILE}"
}

release_upgrade_lock() {
  local upgrade_pid
  upgrade_pid="$(<"${UPGRADE_PID_FILE}" 2>/dev/null || true)"
  [[ "${upgrade_pid}" = "$$" ]] || return 0

  rm -f -- "${UPGRADE_PID_FILE:?}" # noka: ZC1059
  rmdir "${UPGRADE_LOCK_DIR}" 2>/dev/null || true
}

log_busy_upgrade() {
  printf '\n[%s] Skipped %s: another Homebrew operation is already running\n' \
    "$(date '+%Y-%m-%d %H:%M:%S')" "$1" >> "${LOG_FILE}"
}

refresh_plugin() {
  local plugin_name="${PLUGIN_PATH:t}"
  /usr/bin/open -g "swiftbar://refreshplugin?name=${plugin_name}" >/dev/null 2>&1 || true
}

start_manual_check() {
  is_manual_check_running && return 0

  : >| "${MANUAL_CHECK_FILE}"
  "${PLUGIN_PATH}" --check-now-worker >/dev/null 2>&1 &!
}

run_manual_check_worker() {
  rm -f -- "${CHECKED_AT_FILE:?}" # noka: ZC1059
  perform_daily_check
  local check_status=$?
  rm -f -- "${MANUAL_CHECK_FILE:?}" # noka: ZC1059
  refresh_plugin
  return "${check_status}"
}

write_error() {
  printf '%s\n' "$1" > "${ERROR_FILE}"
}

clear_error() {
  rm -f -- "${ERROR_FILE:?}" # noka: ZC1059
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

  mv "${FORMULAE_FILE}.tmp" "${FORMULAE_FILE}" # noka: ZC1244
  mv "${CASKS_FILE}.tmp" "${CASKS_FILE}" # noka: ZC1244
  rm -f "${ERROR_FILE}.tmp"
  clear_error
}

run_upgrade_all() {
  local upgrade_mode="${1:-manual}"
  local allow_during_check

  if [[ "${upgrade_mode}" = "auto" ]]; then
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
    if [[ "${upgrade_mode}" = "auto" ]]; then
      "${BREW_BIN}" upgrade --yes
    else
      "${BREW_BIN}" update && "${BREW_BIN}" upgrade --yes
    fi
  } >> "${LOG_FILE}" 2>&1
  local upgrade_status=$?

  collect_outdated || true
  record_check_time
  release_upgrade_lock
  refresh_plugin
  return "${upgrade_status}"
}

run_upgrade_one() {
  local package_name="$1"
  local package_type="$2"
  local type_flag

  case "${package_name}" in
    *[!A-Za-z0-9@+._/-]*|'')
      printf 'Invalid Homebrew package name: %s\n' "${package_name}" >&2
      return 2
      ;;
  esac

  case "${package_type}" in
    formula) type_flag="--formula" ;;
    cask) type_flag="--cask" ;;
    *)
      printf 'Invalid package type: %s\n' "${package_type}" >&2
      return 2
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
  local upgrade_status=$?

  collect_outdated || true
  record_check_time
  release_upgrade_lock
  refresh_plugin
  return "${upgrade_status}"
}

perform_daily_check() {
  if ! mkdir "${LOCK_DIR}" 2>/dev/null; then # noka: ZC1147
    return 0
  fi
  trap 'rmdir "${LOCK_DIR}" 2>/dev/null || true' EXIT

  local update_output update_status
  update_output="$("${BREW_BIN}" update 2>&1)"
  update_status=$?
  if (( update_status != 0 )); then
    write_error "$(printf '%s\n' "${update_output}" | tail -n 1)"
    record_check_time
    return 1
  fi

  collect_outdated || {
    record_check_time
    return 1
  }
  record_check_time

  if is_auto_enabled && (( $(outdated_count) > 0 )); then
    run_upgrade_all auto
  fi
}

check_is_due() {
  [[ ! -f "${CHECKED_AT_FILE}" ]] && return 0

  local checked_at
  checked_at="$(<"${CHECKED_AT_FILE}" 2>/dev/null || printf '0')"
  case "${checked_at}" in
    *[!0-9]*|'') return 0 ;;
  esac

  local now
  now="$(date +%s)"
  (( now - checked_at >= CHECK_INTERVAL_SECONDS ))
}

file_line_count() {
  if [[ -s "$1" ]]; then
    local count
    count="$(wc -l < "$1")"
    printf '%s' "${count// /}"
  else
    printf '0'
  fi
}

outdated_count() {
  local formula_count cask_count
  formula_count="$(file_line_count "${FORMULAE_FILE}")"
  cask_count="$(file_line_count "${CASKS_FILE}")"
  printf '%s' $((formula_count + cask_count))
}

format_checked_at() {
  if [[ ! -f "${CHECKED_AT_FILE}" ]]; then
    printf 'Never'
    return
  fi

  local checked_at
  checked_at="$(<"${CHECKED_AT_FILE}")"
  strftime '%Y-%m-%d %H:%M' "${checked_at}" 2>/dev/null || printf 'Unknown'
}

render_package_menu() {
  local package_file="$1"
  local package_type="$2"
  local heading="$3"

  [[ -s "${package_file}" ]] || return 0

  local script_path
  script_path="$(escape_attribute "${PLUGIN_PATH}")"
  if [[ "${package_type}" = "formula" ]]; then
    local heading_symbol="shippingbox"
    local package_symbol="cube.box"
  else
    local heading_symbol="macwindow"
    local package_symbol="app"
  fi

  printf ':%s: %s | sfsize=%s\n' "${heading_symbol}" "${heading}" "${SF_SIZE}"
  local package_name safe_name
  while IFS= read -r package_name; do
    [[ -n "${package_name}" ]] || continue
    safe_name="$(escape_swiftbar "${package_name}")"
    if is_brew_busy; then
      printf -- '--:%s: %s | sfsize=%s disabled=true\n' "${package_symbol}" "${safe_name}" "${SF_SIZE}"
    else
      printf -- '--:%s: %s | sfsize=%s bash="%s" param1=--upgrade-one param2=%s param3=%s terminal=false refresh=true\n' \
        "${package_symbol}" "${safe_name}" "${SF_SIZE}" "${script_path}" "${safe_name}" "${package_type}"
    fi
  done < "${package_file}"
}

render_menu() {
  local count checked_at script_path
  count="$(outdated_count)"
  checked_at="$(format_checked_at)"
  script_path="$(escape_attribute "${PLUGIN_PATH}")"

  if is_brew_busy; then
    printf ':arrow.triangle.2.circlepath: … | sfsize=%s tooltip="Homebrew operation in progress…"\n' "${SF_SIZE}"
  elif (( count == 0 )); then
    printf ':shippingbox.fill: 0 | sfsize=%s tooltip="Homebrew is up to date"\n' "${SF_SIZE}"
  else
    printf ':shippingbox.fill: %s | sfsize=%s tooltip="%s Homebrew package(s) outdated"\n' "${count}" "${SF_SIZE}" "${count}"
  fi

  printf -- '---\n'
  printf ':shippingbox.fill: Homebrew Updates | sfsize=%s size=14\n' "${SF_SIZE}"
  printf -- '--:number.circle: Outdated: %s | sfsize=%s\n' "${count}" "${SF_SIZE}"
  printf -- '--:clock: Last check: %s | sfsize=%s\n' "${checked_at}" "${SF_SIZE}"

  if [[ -s "${ERROR_FILE}" ]]; then
    local error_message
    error_message="$(escape_swiftbar "$(tail -n 1 "${ERROR_FILE}")")"
    printf -- '--:exclamationmark.triangle.fill: Last check failed: %s | sfsize=%s color=#FF3B30\n' "${error_message}" "${SF_SIZE}"
  fi

  printf -- '---\n'
  if is_auto_enabled; then
    printf ':checkmark.circle.fill: Auto upgrade | sfsize=%s bash="%s" param1=--disable-auto terminal=false refresh=true\n' "${SF_SIZE}" "${script_path}"
  else
    printf ':circle: Auto upgrade | sfsize=%s bash="%s" param1=--enable-auto terminal=false refresh=true\n' "${SF_SIZE}" "${script_path}"
  fi

  if is_brew_busy; then
    printf ':arrow.clockwise: Check for updates now | sfsize=%s disabled=true\n' "${SF_SIZE}"
  else
    printf ':arrow.clockwise: Check for updates now | sfsize=%s bash="%s" param1=--check-now terminal=false refresh=true\n' "${SF_SIZE}" "${script_path}"
  fi

  if (( count > 0 )); then
    if is_brew_busy; then
      printf ':arrow.up: Upgrade all in background | sfsize=%s disabled=true\n' "${SF_SIZE}"
    else
      printf ':arrow.up: Upgrade all in background | sfsize=%s bash="%s" param1=--upgrade-all terminal=false refresh=true\n' "${SF_SIZE}" "${script_path}"
    fi
    printf -- '---\n'
    render_package_menu "${FORMULAE_FILE}" formula 'Formulae'
    render_package_menu "${CASKS_FILE}" cask 'Casks'
  fi

  if [[ -f "${LOG_FILE}" ]]; then
    local log_path
    log_path="$(escape_attribute "${LOG_FILE}")"
    printf -- '---\n'
    printf ':doc.text: Open upgrade log | sfsize=%s bash=/usr/bin/open param1="%s" terminal=false\n' "${SF_SIZE}" "${log_path}"
  fi
}

if [[ -z "${BREW_BIN}" ]]; then
  printf ':exclamationmark.triangle.fill: ! | sfsize=%s color=#FF3B30\n' "${SF_SIZE}"
  printf -- '---\nHomebrew was not found in /opt/homebrew or /usr/local.\n'
  exit 0
fi

case "${1:-}" in
  --enable-auto)
    : >| "${AUTO_FILE}"
    exit 0
    ;;
  --disable-auto)
    rm -f -- "${AUTO_FILE:?}" # noka: ZC1059
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
