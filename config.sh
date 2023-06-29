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
  echo -e "3. Initialiser le système de sauvegarde automatique"
  echo -e "4. Restauration de la sauvegarde\n"
  echo -e "5. Supprimer tout pour recommencer du début\e[0m"
  echo -e "\e[31m\nQ. Quitter\n\e[0m"

  # Lire le choix de l'utilisateur
  read -p $'\e[33mVotre choix : \e[0m ' CHOICE

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
      read -p $'\e[33mVeuillez entrer l\'URL de votre serveur Nextcloud (ex: https://nextcloud.exemple.com) : \e[0m' NEXTCLOUD_SERVER
      read -p $'\e[33mVeuillez entrer votre nom d\'utilisateur Nextcloud : \e[0m' NEXTCLOUD_USERNAME
      read -sp $'\e[33mVeuillez entrer votre mot de passe Nextcloud : \e[0m' NEXTCLOUD_PASSWORD

      # Enregistrer ces informations dans le fichier d'environnement
      echo "NEXTCLOUD_SERVER=$NEXTCLOUD_SERVER" > nextcloud-exporter.env
      echo "NEXTCLOUD_USERNAME=$NEXTCLOUD_USERNAME" >> nextcloud-exporter.env
      echo "NEXTCLOUD_PASSWORD=$NEXTCLOUD_PASSWORD" >> nextcloud-exporter.env
      echo "NEXTCLOUD_TLS_SKIP_VERIFY=true" >> nextcloud-exporter.env
      ip=$(ip addr show enp0s8 | awk '/inet / {print $2}' | cut -d '/' -f 1)
      NEXTCLOUD_SERVER=https://nextcloud.lan
      domaine=$(echo "$NEXTCLOUD_SERVER" | awk -F/ '{print $3}')
      sed -i "/0 => 'localhost',/a\    1 => '$domaine'," nextcloud/config/config.php
      sed -i "/1 => '$domaine',/a\    2 => '$ip'," nextcloud/config/config.php
      sed -i "/);/i\  'trashbin_retention_obligation' => 'auto, 30'," nextcloud/config/config.php
      sed -i "/);/i\  'default_phone_region' => 'FR'," nextcloud/config/config.php
      sed -i "/127.0.1.1/a\\$ip    $domaine" /etc/hosts

      echo -e "\e[32mLes informations d'environnement ont été enregistrées avec succès !\e[0m"
      ;;

   3)
      # Demander les informations de sauvegarde à l'utilisateur
      read -p $'\e[33mVeuillez entrer le chemin du répertoire que vous voulez sauvegarder : \e[0m' BACKUP_DIR
      read -p $'\e[33mVeuillez entrer l\'endroit où vous voulez que le script de sauvegarde synchronisé soit créé : \e[0m' BACKUP_SYNCRO
      read -p $'\e[33mVeuillez entrer l\'endroit où vous voulez que le script de sauvegarde incrementielle soit créé : \e[0m' BACKUP_INCRE

      read -p $'\e[33mVeuillez entrer le nom d\'utilisateur distant : \e[0m' REMOTE_USER
      read -p $'\e[33mVeuillez entrer l\'IP de l\'hôte distant : \e[0m' REMOTE_HOST
      read -p $'\e[33mVeuillez entrer le répertoire distant où vous voulez que les sauvegardes soient stockées : \e[0m' REMOTE_DIR

      # Créer le script de sauvegarde
	echo -e "#!/bin/bash\n\nrsync -avz --backup --backup-dir=data-backup  $BACKUP_DIR $REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/backup_syncro" > $BACKUP_SYNCRO

	echo "# Activer le mode maintenance dans Nextcloud" > $BACKUP_INCRE
	echo "docker exec -u 33 -it docker-nextcloud_nextcloud_1 php occ maintenance:mode --on" >> $BACKUP_INCRE
	echo "# Pause de 2 minutes pour assurer la mise en place du mode maintenance" >> $BACKUP_INCRE
        echo "sleep 2m" >> $BACKUP_INCRE
	echo "# Sauvegarde incrémentielle sur le serveur distant" >> $BACKUP_INCRE
        echo "rsync -a --delete --link-dest=$REMOTE_DIR/\$(date -d '1 day ago' +\%d-\%m-\%Y) --rsync-path='mkdir -p $BACKUP_DIR/\$(date +\%d-\%m-\%Y) && rsync' $BACKUP_DIR $REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/\$(date +\%d-\%m-\%Y)" >> $BACKUP_INCRE
	echo "# Désactiver le mode maintenance dans Nextcloud" >> $BACKUP_INCRE
	echo "docker exec -u 33 -it docker-nextcloud_nextcloud_1 php occ maintenance:mode --off" >> $BACKUP_INCRE

      # Rendre le script exécutable
      chmod +x $BACKUP_SYNCRO
      chmod +x $BACKUP_INCRE

      # Installer cron si ce n'est pas déjà fait
      apt install cron -y

      # Ajouter une entrée dans le fichier crontab pour exécuter le script de sauvegarde toutes les heures
      (crontab -l ; echo "00 * * * * docker_incre.sh") | crontab -
      (crontab -l ; echo "00 * * * * docker_syncro.sh") | crontab -

      echo -e "\e[32mLe système de sauvegarde automatique a été initialisé avec succès !\e[0m"
      ;;

      # Restauration
    4) echo "exemple de la commande : rsync -a --delete NOM_UTILISATEUR_DISTANT@ADRESSE_IP_DISTANTE:/RÉPERTOIRE_A_RESTAURER /CHEMIN_DE_DESTINATION/"
      read -p $'\e[33mVeuillez entrer le chemin du répertoire que vous voulez restaurer distant : \e[0m' RESTOR_DIR
      read -p $'\e[33mVeuillez entrer le chemin du répertoire que vous voulez restaurer : \e[0m' RESTOR_DIRE
      read -p $'\e[33mVeuillez entrer le nom d\'utilisateur distant : \e[0m' RESTOR_USER
      read -p $'\e[33mVeuillez entrer l\'IP de l\'hôte distant : \e[0m' RESTOR_HOST

      echo "#!/bin/bash" > restauration.sh
      echo "docker exec -u 33 -it docker-nextcloud_nextcloud_1 php occ maintenance:mode --on" >> restauration.sh
      echo "sleep 2m" >> restauration.sh
      echo "rsync -a --delete $RESTOR_USER@$RESTOR_HOST:$RESTOR_DIR $RESTOR_DIRE" >> restauration.sh
      echo "docker exec -u 33 -it docker-nextcloud_nextcloud_1 php occ maintenance:mode --off" >> restauration.sh
      echo "# Commande qui permet de vérifier l'intégrité des données après la restauration" >> restauration.sh
      echo "docker exec -u 33 -it docker-nextcloud_nextcloud_1 php occ files:scan --all" >> restauration.sh
      chmod +x restauration.sh
       # read -p $'\e[33mVoulez vous vraiment restaurer le dossier "'$RESTOR_DIR'" dans le dossier "'$RESTOR_DIRE'" ? \e[0m ' yes

        # Exécuter l'action correspondant au choix de l'utilisateur
       # case "$yes" in
       # y|yes)



        echo "FROM ubuntu:latest" > dockerfile_restauration
        # Installation de Docker" >> dockerfile_restauration
        echo "RUN apt-get update && apt-get install -y rsync ssh docker.io docker docker-compose" >> dockerfile_restauration
        # Copie du script de sauvegarde
        echo "COPY restauration.sh /restauration.sh" >> dockerfile_restauration
        # Copie des chemins vers les clés ssh
        echo "COPY id_ed25519 /root/.ssh/id_ed25519" >> dockerfile_restauration
        echo "COPY known_hosts /root/.ssh/known_hosts" >> dockerfile_restauration
        # Définition de l'exécution du script au démarrage du conteneur
        echo "CMD [\"/restauration.sh\"]" >> dockerfile_restauration

        docker build -f dockerfile_restauration -t ubuntu_restau:latest .

        docker run --rm -it -v /var/run/docker.sock:/var/run/docker.sock -v /root/docker-nextcloud:/root/docker-nextcloud ubuntu_restau:latest
      ;;

      5)
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

