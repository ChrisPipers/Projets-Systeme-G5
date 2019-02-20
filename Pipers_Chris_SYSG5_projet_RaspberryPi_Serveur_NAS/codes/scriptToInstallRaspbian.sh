#! /bin/bash

#-------------------------------
# script pou installer raspbian
#------------------------------

function download()
{
        echo -e "download func"
	echo téléchargement de la distribution Raspbian
        wget -O Raspbian.zip https://downloads.raspberrypi.org/raspbian_full_latest /home/mitch/Documents
}

function unz()
{
	echo -e "unzip func"
 	echo décompression du zip de la distribution Raspbian
	unzip /home/mitch/Documents/Raspbian.zip -d /home/mitch/Documents
}

#Récupérer le nom de l'utilisateur courant
user="$(whoami)"

#Télécharger la distribution Raspbian si existe pas 
(ls "/home/$user/Documents/Raspbian.zip" >> /dev/null && echo fichier ditrbution Raspbian.zip trouvé)  || ( download ) 
read -p "Appuyer sur une touche pour continuer ... "
echo ""
echo ""

#Décompresser l'image de Raspbian
file=$(ls *raspbian*.img)
(ls "/home/$user/Documents/$file" >> /dev/null && echo fichier distribution *Raspbian*.img trouvé)  || ( unz )
read -p "Appuyer sur une touche pour continuer ... "
echo ""
echo ""

#Selection de la devise par l'utilisateur, verif si existe + verif la taille si plus grd que 8GiB
echo ""
lsblk -p -o name,size
echo ""
echo -e "Select the devise or enter \"display devices\" "
echo ""
dev=""
valid="not"
comfirm=""
until [[ "$valid" == "yes"  ]]
do
        read dev
        if [ "$dev" == "display devices"  ]
        then
		clear
		echo -e "Select the devise or enter \"display devices\" "
		echo "" 
                lsblk -p -o name,size
		echo ""
		echo -e "Select the devise or enter \"display devices\" "
        else
                if (lsblk -f | grep -wq $dev) 
                then
                        echo -e "select this device?" $dev "yes for yes or no for no"
                        read comfirm
                        if [ "$comfirm" == "yes" ]
                        then
                                valid="yes"
                        fi
                else
                        echo -e "this device not exist"
                fi
        fi
done
echo ""
echo ""

#Demonter la partition 
read -p "Appuyer sur une touche pour continuer ... "
echo demontage de la device selectionner
umount /dev/$dev 2> /dev/null
echo ""
echo "" 

#trouver le fichier image de la distribution et copier sur la device precedement selectionner
read -p "Appuyer sur une touche pour continuer ... "
echo copie du fichier image Raspbian sur la device 
sudo dd bs=4M if=/home/$user/Documents/$file of=/dev/$dev status=progress conv=fsync

