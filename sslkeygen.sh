#!/bin/bash

# Afficher un message d'attente en vert et attendre une entrée utilisateur
echo -e "\e[32mAppuyez sur une touche pour lancer la génération\e[0m"
read -n 1 -s

# Créer un répertoire "ssl" s'il n'existe pas déjà
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
echo -e "\e[32mToutes les générations ont été exécuter avec succès !\e[0m"

