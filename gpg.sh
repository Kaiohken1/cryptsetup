#!/bin/bash

KEY_NAME="Username"
KEY_EMAIL="user@mail.com"
KEY_IDENTITY="$KEY_NAME <$KEY_EMAIL>"
KEY_TYPE="rsa2048"
KEY_USAGE="sign"
KEY_EXPIRATION="0"
KEY_PASSPHRASE="azerty"
ENV_GPG="/mnt/secure_env/.gnupg"
USER_GNUPG="/home/$SUDO_USER/.gnupg"
ENV_PUB_KEY="/mnt/secure_env/public_key.txt"
ENV_PRIV_KEY="/mnt/secure_env/private_key.txt"

echo $USER_GNUPG

mkdir -p "$ENV_GPG"
chmod 700 "$ENV_GPG"

while true; do
  echo "Choisissez une option :"
  echo "1 - Générer une nouvelle clé dans l'environnement sécurisé"
  echo "2 - Exporter une clé publique existante vers l'environnement sécurisé"
  echo "3 - Exporter une clé privée existante vers l'environnement sécurisé"
  echo "4 - Importer une clé publique de l'environnement sécurisé"
  echo "5 - Importer une clé privée de l'environnement sécurisé"
  echo "6 - Quitter"
  read -rp "Numéro : " choice

  case $choice in
    1)
      if ! gpg --homedir "$ENV_GPG" --list-keys "$KEY_EMAIL" > /dev/null 2>&1; then
        echo "Génération d'une clé GPG pour $KEY_IDENTITY"
        gpg --homedir "$ENV_GPG" \
            --batch --pinentry-mode loopback \
            --passphrase "$KEY_PASSPHRASE" \
            --quick-gen-key "$KEY_IDENTITY" "$KEY_TYPE" "$KEY_USAGE" "$KEY_EXPIRATION"
      else
        echo "Clé GPG déjà présente pour $KEY_EMAIL"
      fi
      ;;
    2)
      read -rp "Nom de la clé : " KEY_ID
      if gpg --homedir "$USER_GNUPG" --list-keys "$KEY_ID" > /dev/null 2>&1; then
        gpg --homedir "$USER_GNUPG" --armor --output /mnt/secure_env/public_key.txt --export "$KEY_ID"
        echo "Clé exportée dans /mnt/secure_env/public_key.txt"
      else
        echo "Clé introuvable : $KEY_ID"
      fi
      ;;
    3)
      read -rp "Nom de la clé : " KEY_ID
      if gpg --homedir "$USER_GNUPG" --list-keys "$KEY_ID" > /dev/null 2>&1; then
        gpg --homedir "$USER_GNUPG" --armor --output /mnt/secure_env/private_key.txt --export-secret-key "$KEY_ID"
        chown $SUDO_USER:$SUDO_USER /mnt/secure_env/private_key.txt
        chmod 600 /mnt/secure_env/private_key.txt
        echo "Clé exportée dans /mnt/secure_env/private_key.txt"
      else
        echo "Clé introuvable : $KEY_ID"
      fi
      ;;
    4)
      if test -f "$ENV_PUB_KEY"; then
        gpg --homedir "$USER_GNUPG" --import "$ENV_PUB_KEY"
        echo "Clé importée depuis l'environnement sécurisé"
      else
        echo "Aucune clé présente dans l'environnement sécurisé"
      fi
      ;;
    5)
      if test -f "$ENV_PRIV_KEY"; then
        gpg --homedir "$USER_GNUPG" --import "$ENV_PRIV_KEY"
        echo "Clé importée depuis l'environnement sécurisé"
      else
        echo "Aucune clé présente dans l'environnement sécurisé"
      fi
      ;;
    6)
      break
      return 0
      ;;
    *)
      echo "Choix non reconnu, veuillez réessayer."
      ;;
  esac
done

