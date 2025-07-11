#!/bin/bash

CONFIG_PATH="/mnt/secure_env/.ssh/ssh_config"
ALIAS_FILE="/mnt/secure_env/.ssh/ssh_alias"
SSH_CONFIG="$HOME/.ssh/config"
KEY_PATH="/mnt/secure_env/.ssh/id_rsa"
ALIAS_LINK="/home/$SUDO_USER/.evsh_aliases"

mkdir -p "/mnt/secure_env/.ssh"


while true; do
  echo "Choisissez une option :"
  echo "1 - Générer une configuration ssh"
  echo "2 - Importer les configurations ssh dans l'environnement sécurisé"
  echo "3 - Quitter"
  read -rp "Numéro : " choice

  case $choice in
    1)
      if [[ ! -f "$CONFIG_PATH" ]]; then
        cat > "$CONFIG_PATH" <<EOF
Host secure_env
    User utilisateur
    Port 22
    IdentityFile $KEY_PATH
EOF
        echo "Fichier de configuration SSH généré à : $CONFIG_PATH"
        chmod 600 "$CONFIG_PATH"
      else
        echo "Configuration déjà présente à : $CONFIG_PATH"
      fi

      if [[ ! -f "$KEY_PATH" ]]; then
        ssh-keygen -t rsa -b 4096 -f "$KEY_PATH"
        chmod 600 "$KEY_PATH"
        chmod 644 "$KEY_PATH.pub"
        echo "Clé SSH générée dans /mnt/secure_env/ssh/"
      else
        echo "Clé SSH déjà existante à : $KEY_PATH"
      fi

      if [[ ! -f "$ALIAS_FILE" ]]; then
        echo "alias evsh='ssh -F $CONFIG_PATH secure_env'" > "$ALIAS_FILE"
        chmod +x "$ALIAS_FILE"
        ln -sf "$ALIAS_FILE" "$ALIAS_LINK"
        echo "Alias créé : evsh (lien symbolique dans $ALIAS_LINK)"
      fi
      ;;
    2)

      ;;
    3)
      break
      return 0
      ;;
    *)
      echo "Choix non reconnu, veuillez réessayer."
      ;;
  esac
done

