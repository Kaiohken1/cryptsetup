# commands/status.sh
#!/bin/bash

source "$LIB_DIR/common.sh"

show_status() {
    init
    
    echo "=== Statut de l'environnement sécurisé ==="
    echo
    
    if [[ -f "$ENV_PATH" ]]; then
        echo "✓ Fichier environnement: $ENV_PATH"
        echo "  Taille: $(du -h "$ENV_PATH" | cut -f1)"
    else
        echo "✗ Fichier environnement: Non installé"
    fi
    
    if cryptsetup status "$MAPPER_NAME" &>/dev/null; then
        echo "✓ Volume chiffré: Ouvert"
    else
        echo "✗ Volume chiffré: Fermé"
    fi
    
    if mountpoint -q "$MOUNT_POINT"; then
        echo "✓ Point de montage: $MOUNT_POINT"
        echo "  Utilisation: $(df -h "$MOUNT_POINT" | tail -1 | awk '{print $3 "/" $2 " (" $5 ")"}')"
    else
        echo "✗ Point de montage: Non monté"
    fi
    
    echo
    
    if mountpoint -q "$MOUNT_POINT"; then
        if [[ -d "$SSH_DIR" ]]; then
            echo "✓ Configuration SSH disponible"
            local host_count=$(grep "^Host " "$SSH_CONFIG" 2>/dev/null | wc -l || echo 0)
            echo "  Hosts configurés: $host_count"
        else
            echo "✗ Configuration SSH: Non configurée"
        fi
        
        if [[ -d "$GPG_HOME" ]]; then
            echo "✓ Configuration GPG disponible"
            local key_count=$(GNUPGHOME="$GPG_HOME" gpg --list-keys 2>/dev/null | grep "^pub" | wc -l || echo 0)
            echo "  Clés publiques: $key_count"
        else
            echo "✗ Configuration GPG: Non configurée"
        fi
    fi
}