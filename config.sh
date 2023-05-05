#!/bin/bash

if [ $EUID -ne 0 ]; then
  echo -e "\e[31mVous devez être root pour exécuter ce script.\e[0m"
  exit 1
fi

while true; do
  # Afficher le menu
  echo -e "\e[33mQue voulez-vous faire ?\n\e[0m"
  echo -e "\e[34m1. Générer un certificat SSL autosigné"
  echo -e "2. Initialiser un cluster Swarm"
  echo -e "3. Créer les secrets Docker"
  echo -e "4. Supprimer tout pour recommencer du début\e[0m"
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
      # Montrer à l'utilisateur ses interfaces
      ip -c -br a

      # Demander à l'utilisateur de saisir l'adresse IP du nœud de gestionnaire de Swarm
      read -p $'\e[33mVeuillez saisir l adresse IP du nœud de gestionnaire de Swarm : \e[0m' SWARM_MANAGER_IP
 
      # Initialiser le cluster Swarm avec l'adresse IP spécifiée
      docker swarm init --advertise-addr $SWARM_MANAGER_IP

      # Afficher les informations sur le cluster Swarm
      docker node ls

      # Afficher un message de fin en vert
      echo -e "\e[32mInitialisation du cluster Swarm réussie !\e[0m"
      ;;
    3)
      # Créer les secrets Docker
      echo "root_password" | docker secret create root_password -
      echo "password" | docker secret create db_password -
      echo "nextcloud_db" | docker secret create db_name -
      echo "nextcloud_user" | docker secret create db_user -

      # Afficher un message de fin en vert
      echo -e "\e[32mTous les secrets Docker ont été créés avec succès !\e[0m"
      ;;
    4)
      # Supprimer tout pour recommencer du début
      rm -rf ssl
      docker stack rm nextcloud_stack
      docker secret rm db_password db_name db_user 2> /dev/null
      docker swarm leave --force.
      rm -rf /var/lib/docker/swarm
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
      echo -e "\e[31mChoix invalide ! Veuillez choisir entre 1 et 4.\e[0m"
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

