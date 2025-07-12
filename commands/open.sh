#!/bin/bash

source "$LIB_DIR/common.sh"
source "$LIB_DIR/validation.sh"

open_environment() {
    init
    
    validate_environment_exists
    validate_environment_closed
    
    info "Ouverture de l'environnement sécurisé"
    
    read -s -p "Passphrase: " passphrase
    echo
    
    info "Ouverture du volume chiffré"
    echo "$passphrase" | cryptsetup open "$ENV_PATH" "$MAPPER_NAME" -
    
    info "Montage de l'environnement"
    mount "/dev/mapper/$MAPPER_NAME" "$MOUNT_POINT"
    
    chown "$SUDO_USER:$SUDO_USER" "$MOUNT_POINT"
    
    info "Environnement ouvert: $MOUNT_POINT"
}