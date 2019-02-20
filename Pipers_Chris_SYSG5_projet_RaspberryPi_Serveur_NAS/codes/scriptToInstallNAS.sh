#! /bin/bash

# mettre a jour le Raspberry Pi
sudo apt update
sudo apt upgrade 

#creation des dossiers accessible sur le NAS
sudo mkdir /home/files
sudo mkdir /home/files/public

# attribution du groupe au fichier public
sudo chown -R root:users /home/files/public

#attribution des droit selon les groupes au fichier public
sudo chmod -R ug=rwx,o=rx /home/files/public

#installation du logiciel Samba
sudo apt install samba samba-common-bin 

#configurer pour l'acces a la partie public du nass on ajoute ca au fichier /etc/samba/smb.conf
echo "[public]
comment = Public Storage 
path = /home/files/public 
valid users = @users 
force group = users 
create mask 0771 
read only = no " >> /etc/samba/smb.conf

#restart Samba pour modifier la configuration
sudo /etc/init.d/samba restart

#ajout d'un utilidateur a Samba
echo "Attention retené le mot de passe qui vous sera demandé"
read -p "Appuyer sur une touche pour continuer ... " 
sudo smbpasswd -a pi
