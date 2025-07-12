#!/bin/bash

source "$LIB_DIR/common.sh"
source "$LIB_DIR/validation.sh"

handle_ssh_command() {
    local subcommand="${1:-}"
    
    case "$subcommand" in
        "setup")
            setup_ssh_environment
            ;;
        "import-host")
            import_ssh_host "${2:-}"
            ;;
        "list-hosts")
            list_available_hosts
            ;;
        "generate-key")
            generate_ssh_key "${2:-}" "${3:-}"
            ;;
        *)
            show_ssh_usage
            ;;
    esac
}

setup_ssh_environment() {
    validate_environment_open
    
    info "Configuration de l'environnement SSH"
    
    mkdir -p "$SSH_DIR"
    chmod 700 "$SSH_DIR"
    
    if [[ -f "$SCRIPT_DIR/templates/ssh_config.template" ]]; then
        cp "$SCRIPT_DIR/templates/ssh_config.template" "$SSH_CONFIG"
    else
        touch "$SSH_CONFIG"
    fi
    
    chmod 600 "$SSH_CONFIG"
    
    setup_ssh_aliases
    
    info "Environnement SSH configuré"
}

import_ssh_host() {
    local host_pattern="${1:-}"
    
    validate_environment_open
    validate_host_pattern "$host_pattern"
    
    local system_config="$HOME/.ssh/config"
    
    if [[ ! -f "$system_config" ]]; then
        error "Fichier de configuration SSH système introuvable: $system_config"
        return 1
    fi
    
    extract_host_config "$system_config" "$host_pattern"
}

extract_host_config() {
    local config_file="$1"
    local host_pattern="$2"
    
    info "Import de la configuration pour: $host_pattern"
    
    awk -v host="$host_pattern" -v ssh_dir="$SSH_DIR" '
    /^Host / {
        if (match($0, host)) {
            in_host = 1
            print $0
        } else {
            in_host = 0
        }
        next
    }
    /^Host / && in_host {
        in_host = 0
    }
    in_host {
        if (/IdentityFile/) {
            gsub(/IdentityFile.*/, "IdentityFile " ssh_dir "/" host "_key")
        }
        print $0
    }
    ' "$config_file" >> "$SSH_CONFIG"
    
    copy_ssh_keys "$config_file" "$host_pattern"
}

copy_ssh_keys() {
    local config_file="$1"
    local host_pattern="$2"
    
    local key_path=$(awk -v host="$host_pattern" '
    /^Host / && match($0, host) { in_host = 1; next }
    /^Host / && in_host { in_host = 0 }
    in_host && /IdentityFile/ { 
        gsub(/^[ \t]*IdentityFile[ \t]*/, "")
        gsub(/~/, ENVIRON["HOME"])
        print $0
        exit
    }
    ' "$config_file")
    
    if [[ -n "$key_path" && -f "$key_path" ]]; then
        info "Copie des clés SSH pour $host_pattern"
        
        cp "$key_path" "$SSH_DIR/${host_pattern}_key"
        chmod 600 "$SSH_DIR/${host_pattern}_key"
        
        if [[ -f "$key_path.pub" ]]; then
            cp "$key_path.pub" "$SSH_DIR/${host_pattern}_key.pub"
            chmod 644 "$SSH_DIR/${host_pattern}_key.pub"
        fi
        
        info "Clés copiées avec succès"
    else
        warn "Clé SSH introuvable pour $host_pattern: $key_path"
    fi
}

setup_ssh_aliases() {
    local bashrc_file="$MOUNT_POINT/.bashrc"
    
    cat > "$bashrc_file" << EOF
alias evsh='ssh -F $SSH_CONFIG'
alias evscp='scp -F $SSH_CONFIG'
alias evsftp='sftp -F $SSH_CONFIG'

evhost() {
    grep "^Host " "$SSH_CONFIG" | awk '{print \$2}' | grep -v "\*"
}

evkey() {
    local host="\$1"
    if [[ -n "\$host" ]]; then
        ssh-keygen -f "$SSH_DIR/\${host}_key" -y
    else
        echo "Usage: evkey <hostname>"
    fi
}
EOF
    
    if [[ ! -L "$HOME/.secure_env_aliases" ]]; then
        ln -sf "$bashrc_file" "$HOME/.secure_env_aliases"
        info "Lien symbolique créé: $HOME/.secure_env_aliases"
        info "Ajoutez 'source ~/.secure_env_aliases' à votre ~/.bashrc pour utiliser les alias"
    fi
}

generate_ssh_key() {
    local key_name="${1:-}"
    local key_type="${2:-rsa}"
    
    validate_environment_open
    validate_key_name "$key_name"
    
    local key_path="$SSH_DIR/${key_name}_key"
    
    if [[ -f "$key_path" ]]; then
        read -p "La clé $key_name existe déjà. Remplacer? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            info "Génération annulée"
            return 0
        fi
    fi
    
    ssh-keygen -t "$key_type" -f "$key_path" -N ""
    chmod 600 "$key_path"
    chmod 644 "$key_path.pub"
    
    info "Clé SSH générée: $key_path"
}

list_available_hosts() {
    validate_environment_open
    
    if [[ -f "$SSH_CONFIG" ]]; then
        info "Hosts configurés dans l'environnement sécurisé:"
        grep "^Host " "$SSH_CONFIG" | awk '{print "  " $2}' | grep -v "\*"
    else
        info "Aucun host configuré"
    fi
}

show_ssh_usage() {
    cat << EOF
Usage SSH:
    ssh setup              Configurer l'environnement SSH
    ssh import-host HOST   Importer la configuration d'un host
    ssh list-hosts         Lister les hosts disponibles
    ssh generate-key NAME [TYPE]  Générer une nouvelle clé SSH
EOF
}