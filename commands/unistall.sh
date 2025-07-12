#!/bin/bash

source "$LIB_DIR/common.sh"
source "$LIB_DIR/validation.sh"

uninstall_environment() {
    init
    
    if [[ ! -f "$ENV_PATH" ]]; then
        error "Aucun environnement à désinstaller"
        return 1
    fi
    
    read -p "Êtes-vous sûr de vouloir supprimer l'environnement? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        info "Désinstallation annulée"
        return 0
    fi
    
    if mountpoint -q "$MOUNT_POINT"; then
        umount "$MOUNT_POINT"
        cryptsetup close "$MAPPER_NAME"
    fi
    
    rm -f "$ENV_PATH"
    
    if [[ -L "$ALIAS_LINK" ]]; then
        rm -f "$ALIAS_LINK"
    fi
    
    info "Environnement désinstallé"
}