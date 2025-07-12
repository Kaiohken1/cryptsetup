# commands/close.sh
#!/bin/bash

source "$LIB_DIR/common.sh"
source "$LIB_DIR/validation.sh"

close_environment() {
    init
    
    validate_environment_open
    
    info "Fermeture de l'environnement sécurisé"
    
    info "Démontage de l'environnement"
    umount "$MOUNT_POINT"
    
    info "Fermeture du volume chiffré"
    cryptsetup close "$MAPPER_NAME"
    
    info "Environnement fermé"
}