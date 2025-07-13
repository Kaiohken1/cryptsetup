#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"
COMMANDS_DIR="$SCRIPT_DIR/commands"
CONFIG_DIR="$SCRIPT_DIR"

source "$LIB_DIR/common.sh"
source "$LIB_DIR/validation.sh"

show_usage() {
    cat << EOF
Usage: $0 [COMMAND] [OPTIONS]

Commands:
    install     Installer l'environnement sécurisé
    open        Ouvrir l'environnement
    close       Fermer l'environnement
    status      Afficher le statut
    ssh         Gestion SSH
    gpg         Gestion GPG
    uninstall   Désinstaller l'environnement
    
Options:
    -h, --help      Afficher cette aide
    -v, --verbose   Mode verbeux
    -c, --config    Fichier de configuration personnalisé

Examples:
    $0 install
    $0 open
    $0 ssh import-host myserver
    $0 gpg export-keys
EOF
}

main() {
    local command="${1:-}"
    
    case "$command" in
        "install")
            source "$COMMANDS_DIR/install.sh"
            install_environment "${@:2}"
            ;;
        "open")
            source "$COMMANDS_DIR/open.sh"
            open_environment "${@:2}"
            ;;
        "close")
            source "$COMMANDS_DIR/close.sh"
            close_environment "${@:2}"
            ;;
        "status")
            source "$COMMANDS_DIR/status.sh"
            show_status "${@:2}"
            ;;
        "ssh")
            source "$LIB_DIR/ssh.sh"
            handle_ssh_command "${@:2}"
            ;;
        "gpg")
            source "$LIB_DIR/gpg.sh"
            handle_gpg_command "${@:2}"
            ;;
        "uninstall")
            source "$COMMANDS_DIR/uninstall.sh"
            uninstall_environment "${@:2}"
            ;;
        "-h"|"--help"|"help"|"")
            show_usage
            ;;
        *)
            error "Commande inconnue: $command"
            show_usage
            exit 1
            ;;
    esac
}

main "$@"