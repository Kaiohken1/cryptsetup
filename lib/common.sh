#!/bin/bash

load_config() {
    local config_file="${1:-$CONFIG_DIR/defaults.conf}"
    
    if [[ -f "$config_file" ]]; then
        source "$config_file"
    fi
    
    if [[ -f "$CONFIG_DIR/user.conf" ]]; then
        source "$CONFIG_DIR/user.conf"
    fi
}

log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "[$timestamp] [$level] $message" | tee -a "${LOG_FILE:-/tmp/secure-env.log}"
}

info() { log "INFO" "$1"; }
warn() { log "WARN" "$1"; }
error() { log "ERROR" "$1"; }
debug() { [[ "${LOG_LEVEL:-INFO}" == "DEBUG" ]] && log "DEBUG" "$1"; }

check_dependencies() {
    local deps=("cryptsetup" "gpg" "ssh-keygen")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        error "Dépendances manquantes: ${missing[*]}"
        return 1
    fi
}

check_privileges() {
    if [[ $EUID -ne 0 ]]; then
        error "Ce script nécessite des privilèges root"
        return 1
    fi
}

cleanup() {
    local exit_code=$?
    
    [[ -n "${TEMP_FILES:-}" ]] && rm -f $TEMP_FILES
    
    if [[ $exit_code -ne 0 ]] && mountpoint -q "$MOUNT_POINT" 2>/dev/null; then
        warn "Nettoyage d'urgence: démontage de $MOUNT_POINT"
        umount "$MOUNT_POINT" 2>/dev/null || true
        cryptsetup close "$MAPPER_NAME" 2>/dev/null || true
    fi
    
    exit $exit_code
}

trap cleanup EXIT INT TERM

init() {
    load_config "$@"
    check_dependencies
    check_privileges
    
    mkdir -p "$(dirname "$ENV_PATH")" "$MOUNT_POINT" "${LOG_FILE%/*}"
}