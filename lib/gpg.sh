#!/bin/bash

source "$LIB_DIR/common.sh"
source "$LIB_DIR/validation.sh"

handle_gpg_command() {
    local subcommand="${1:-}"
    
    case "$subcommand" in
        "setup")
            setup_gpg_environment
            ;;
        "generate")
            generate_gpg_key
            ;;
        "import-keys")
            import_gpg_keys
            ;;
        "export-keys")
            export_gpg_keys
            ;;
        "list-keys")
            list_gpg_keys
            ;;
        *)
            show_gpg_usage
            ;;
    esac
}

setup_gpg_environment() {
    validate_environment_open
    
    info "Configuration de l'environnement GPG"
    
    mkdir -p "$GPG_HOME"
    chmod 700 "$GPG_HOME"
    
    export GNUPGHOME="$GPG_HOME"
    
    info "Environnement GPG configuré"
}

generate_gpg_key() {
    validate_environment_open
    
    export GNUPGHOME="$GPG_HOME"
    
    local batch_file="/tmp/gpg_batch_$$"
    TEMP_FILES="$TEMP_FILES $batch_file"
    
    read -p "Nom complet: " full_name
    read -p "Email: " email
    read -s -p "Passphrase: " passphrase
    echo
    
    cat > "$batch_file" << EOF
%echo Génération de la clé GPG
Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096
Name-Real: $full_name
Name-Email: $email
Expire-Date: 2y
Passphrase: $passphrase
%commit
%echo Clé GPG générée
EOF
    
    gpg --batch --generate-key "$batch_file"
    
    local key_id=$(gpg --list-secret-keys --with-colons | awk -F: '/^sec:/ {print $5; exit}')
    
    if [[ -n "$key_id" ]]; then
        info "Clé GPG générée avec succès: $key_id"
        
        gpg --armor --export "$key_id" > "$GPG_HOME/public_key.asc"
        info "Clé publique exportée: $GPG_HOME/public_key.asc"
        
        read -p "Exporter la clé privée? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            gpg --armor --export-secret-keys "$key_id" > "$GPG_HOME/private_key.asc"
            chmod 600 "$GPG_HOME/private_key.asc"
            warn "Clé privée exportée: $GPG_HOME/private_key.asc"
            warn "ATTENTION: Protégez cette clé privée!"
        fi
    else
        error "Échec de la génération de la clé GPG"
        return 1
    fi
}

import_gpg_keys() {
    validate_environment_open
    
    export GNUPGHOME="$GPG_HOME"
    
    info "Import des clés GPG du système vers le coffre"
    
    local system_gpg_home="${GNUPGHOME:-$HOME/.gnupg}"
    
    if [[ ! -d "$system_gpg_home" ]]; then
        error "Répertoire GPG système introuvable: $system_gpg_home"
        return 1
    fi
    
    local temp_export="/tmp/gpg_export_$$"
    TEMP_FILES="$TEMP_FILES $temp_export"
    
    GNUPGHOME="$system_gpg_home" gpg --armor --export > "$temp_export"
    
    if [[ -s "$temp_export" ]]; then
        gpg --import "$temp_export"
        info "Clés publiques importées"
    fi
    
    read -p "Importer les clés privées? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        GNUPGHOME="$system_gpg_home" gpg --armor --export-secret-keys > "$temp_export"
        if [[ -s "$temp_export" ]]; then
            gpg --import "$temp_export"
            info "Clés privées importées"
        fi
    fi
}

export_gpg_keys() {
    validate_environment_open
    
    export GNUPGHOME="$GPG_HOME"
    
    info "Export des clés GPG du coffre vers le système"
    
    local system_gpg_home="${GNUPGHOME:-$HOME/.gnupg}"
    
    local temp_export="/tmp/gpg_export_$$"
    TEMP_FILES="$TEMP_FILES $temp_export"
    
    gpg --armor --export > "$temp_export"
    
    if [[ -s "$temp_export" ]]; then
        GNUPGHOME="$system_gpg_home" gpg --import "$temp_export"
        info "Clés publiques exportées vers le système"
    fi
    
    read -p "Exporter les clés privées? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        gpg --armor --export-secret-keys > "$temp_export"
        if [[ -s "$temp_export" ]]; then
            GNUPGHOME="$system_gpg_home" gpg --import "$temp_export"
            info "Clés privées exportées vers le système"
        fi
    fi
}

list_gpg_keys() {
    validate_environment_open
    
    export GNUPGHOME="$GPG_HOME"
    
    info "Clés publiques dans l'environnement sécurisé:"
    gpg --list-keys
    
    echo
    info "Clés privées dans l'environnement sécurisé:"
    gpg --list-secret-keys
}

show_gpg_usage() {
    cat << EOF
Usage GPG:
    gpg setup          Configurer l'environnement GPG
    gpg generate       Générer une nouvelle paire de clés
    gpg import-keys    Importer les clés du système vers le coffre
    gpg export-keys    Exporter les clés du coffre vers le système
    gpg list-keys      Lister les clés du coffre
EOF
}