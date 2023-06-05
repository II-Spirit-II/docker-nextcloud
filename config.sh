#!/bin/bash

if [ $EUID -ne 0 ]; then
  echo -e "\e[31mVous devez être root pour exécuter ce script.\e[0m"
  exit 1
fi

while true; do
  # Afficher le menu
  echo -e "\e[33mQue voulez-vous faire ?\n\e[0m"
  echo -e "\e[34m1. Générer un certificat SSL autosigné"
  echo -e "2. Initialiser l'environement"
  echo -e "3. Supprimer tout pour recommencer du début\e[0m"
  echo -e "\e[31m\nQ. Quitter\n\e[0m"

  # Lire le choix de l'utilisateur
  read -p $'\e[33mVotre choix : \e[0m' CHOICE

  # Exécuter l'action correspondant au choix de l'utilisateur
  case "$CHOICE" in
    1)
      # Créer le répertoire "ssl" s'il n'existe pas déjà
      if [ ! -d "ssl" ]; then
        mkdir ssl
      fi

      # Se placer dans le répertoire "ssl"
      cd ssl

      # Générer une clé privée RSA de 2048 bits et la stocker dans le répertoire "ssl"
      openssl genrsa -out server.key 2048

      # Créer une demande de signature de certificat (CSR) pour la clé privée
      openssl req -new -key server.key -out server.csr

      # Générer un certificat SSL autosigné valide pour 365 jours
      openssl x509 -req -days 365 -in server.csr -signkey server.key -out server.crt

      # Afficher le contenu du certificat pour vérifier qu'il a été correctement généré
      openssl x509 -in server.crt -text -noout

      # Afficher un message de fin en vert
      echo -e "\e[32mToutes les générations ont été exécutées avec succès !\e[0m"
      ;;
    2)
      # Demander les informations d'environnement à l'utilisateur
      read -p $'\e[33mVeuillez entrer l\'URL de votre serveur Nextcloud (ex: https://nextcloud.example.com) : \e[0m' NEXTCLOUD_SERVER
      read -p $'\e[33mVeuillez entrer votre nom d\'utilisateur Nextcloud : \e[0m' NEXTCLOUD_USERNAME
      read -sp $'\e[33mVeuillez entrer votre mot de passe Nextcloud : \e[0m' NEXTCLOUD_PASSWORD

      # Enregistrer ces informations dans le fichier d'environnement
      echo "NEXTCLOUD_SERVER=$NEXTCLOUD_SERVER" > nextcloud-exporter.env
      echo "NEXTCLOUD_USERNAME=$NEXTCLOUD_USERNAME" >> nextcloud-exporter.env
      echo "NEXTCLOUD_PASSWORD=$NEXTCLOUD_PASSWORD" >> nextcloud-exporter.env
      echo "NEXTCLOUD_TLS_SKIP_VERIFY=true" >> nextcloud-exporter.env

      echo -e "\e[32mLes informations d'environnement ont été enregistrées avec succès !\e[0m"
      ;;
    3)
      # Supprimer tout pour recommencer du début
      rm -rf ssl
      rm -rf /var/lib/docker/volumes/*
      docker network prune

      # Afficher un message de fin en vert
      echo -e "\e[32mTout a été supprimé avec succès !\e[0m"
      ;;
    q|Q)
      echo -e "\e[31mBye !\e[0m"
      exit 0
      ;;
    *)
      # Afficher un message d'erreur en rouge si le choix est invalide
      echo -e "\e[31mChoix invalide !\e[0m"
      ;;
  esac

  # Demander à l'utilisateur s'il veut revenir au menu principal ou quitter le script
  read -p $'\e[33mAppuyez sur Entrée pour revenir au menu principal ou tapez "q" pour quitter : \e[0m' REPLY

  # Sortir du script si l'utilisateur tape "q" ou "Q"
  if [[ "$REPLY" =~ ^[qQ]$ ]]; then
    echo -e "\e[31mBye !\e[0m"
    exit 0
  fi

done

