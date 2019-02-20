#! /bin/bash

#-----------------------------------------------------------------
# Script pour monter un lecteur reseau coté client pour server NAS
#-----------------------------------------------------------------

#installation du paquet cifs-utils si non installé
sudo apt-get install cifs-utils

#ajout de ligne dans le fichier /etc/fstab pour ajouter le lecteur réseau
echo "//RASPBERRYPI/public /media/documents cifs username=pi,password=1234,iocharset=utf8,file_mode=0777,dir_mode=0777,noperm, 0 0 " >> /etc/fstab

#monter le lecteur réseau 
sudo mount -a 