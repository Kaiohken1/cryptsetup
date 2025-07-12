#!/bin/bash

validate_environment_exists() {
    if [[ ! -f "$ENV_PATH" ]]; then
        error "Environnement non installé: $ENV_PATH"
        return 1
    fi
}

validate_environment_open() {
    if ! mountpoint -q "$MOUNT_POINT"; then
        error "Environnement fermé"
        return 1
    fi
}

validate_environment_closed() {
    if mountpoint -q "$MOUNT_POINT"; then
        error "Environnement déjà ouvert"
        return 1
    fi
}

validate_host_pattern() {
    local pattern="$1"
    
    if [[ -z "$pattern" ]]; then
        error "Pattern d'host requis"
        return 1
    fi
    
    if [[ ! "$pattern" =~ ^[a-zA-Z0-9._-]+$ ]]; then
        error "Pattern d'host invalide: $pattern"
        return 1
    fi
}

validate_key_name() {
    local name="$1"
    
    if [[ -z "$name" ]]; then
        error "Nom de clé requis"
        return 1
    fi
    
    if [[ ! "$name" =~ ^[a-zA-Z0-9._-]+$ ]]; then
        error "Nom de clé invalide: $name"
        return 1
    fi
}