#!/bin/bash

if [[ $EUID -ne 0 ]]; then 
   echo "Erreur : Ce programme doit être lancé en root"
   exit 1
fi

while true; do
  echo "Choisissez une option :"
  echo "1 - Installer et ouvrir l'environnement"
  echo "2 - Ouvrir l'environnement"
  echo "3 - Fermer l'environnement"
  echo "4 - Gestion clés gpg avec l'environnement"
  echo "5 - Quitter le script"
  read -p "Entrez une option : " choix

  case $choix in
    1)
      if [[ -f /var/setup/env.img ]]; then
        echo "Erreur : L'environnement existe déjà. Veuillez le fermer ou supprimer /var/setup/env.img avant de réinstaller."
        exit 1
      fi
      read -s -p "Entrez un mot de passe : " PASSWORD
      echo "> Installation de l'env et ouverture..."
      ./install.sh "$PASSWORD"
      ;;
    2)
      read -s -p "Entrez le mot de passe : " PASSWORD
      echo "> Ouverture de l'env..."
      ./open.sh "$PASSWORD"
      ;;
    3)
      echo "> Fermeture de l'env..."
      ./close.sh
      ;;
    4) 
      source ./gpg.sh
      ;;
    5) 
      exit 0
      ;;
    *)
      echo "Choix invalide. Veuillez entrer un nombre entre 1 et 3."
    ;;
  esac

  echo
done