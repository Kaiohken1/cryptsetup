#!/bin/bash

source "$LIB_DIR/common.sh"

install_environment() {
    init
    
    info "Installation de l'environnement sécurisé"
    
    if [[ -f "$ENV_PATH" ]]; then
        read -p "L'environnement existe déjà. Remplacer? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            info "Installation annulée"
            return 0
        fi
        
        if mountpoint -q "$MOUNT_POINT"; then
            umount "$MOUNT_POINT"
            cryptsetup close "$MAPPER_NAME"
        fi
        
        rm -f "$ENV_PATH"
    fi
    
    info "Création du fichier de $ENV_SIZE"
    local size_bytes
    case "$ENV_SIZE" in
        *G) size_bytes=$(( ${ENV_SIZE%G} * 1024 * 1024 * 1024 )) ;;
        *M) size_bytes=$(( ${ENV_SIZE%M} * 1024 * 1024 )) ;;
        *) size_bytes="$ENV_SIZE" ;;
    esac
    dd if=/dev/zero of="$ENV_PATH" bs=1 count=0 seek="$size_bytes" status=progress
    
    read -s -p "Passphrase pour le chiffrement: " passphrase
    echo
    
    info "Chiffrement du fichier avec LUKS"
    echo "$passphrase" | cryptsetup luksFormat "$ENV_PATH" --cipher="$CIPHER" --key-size="$KEY_SIZE" --hash="$HASH" -
    
    info "Ouverture du volume chiffré"
    if ! echo "$passphrase" | cryptsetup open "$ENV_PATH" "$MAPPER_NAME" -; then
        error "Échec de l'ouverture du volume chiffré"
        return 1
    fi

    info "Création du système de fichiers ext4"
    if ! mkfs.ext4 "/dev/mapper/$MAPPER_NAME"; then
        error "Échec de la création du système de fichiers"
        cryptsetup close "$MAPPER_NAME"
        return 1
    fi
    
    info "Montage de l'environnement"
    mount "/dev/mapper/$MAPPER_NAME" "$MOUNT_POINT"
    
    info "Configuration des permissions"
    chmod 700 "$MOUNT_POINT"
    chown "$SUDO_USER:$SUDO_USER" "$MOUNT_POINT"
    chmod 600 "$ENV_PATH"
    
    info "Installation terminée avec succès"
    info "Utilisez '$0 open' pour ouvrir l'environnement"
}