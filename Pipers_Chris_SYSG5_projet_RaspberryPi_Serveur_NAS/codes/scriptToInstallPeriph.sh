#! /bin/bash

#Selection de la devise
lsblk -p -o name,label,type,size
dev=""
valid="not"
comfirm=""
until [[ "$valid" == "yes"  ]]
do
        echo -e "Select the devise or enter \"display devices\" "
        read dev
        if [ "$dev" == "display devices"  ]
        then
                clear
                lsblk -p -o name,label,type,size
        else
                if lsblk -f | grep -wq $dev 
                then
                        echo -e "select this device? " $dev " yes for yes or not for not"
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

# demonter et formater la device ( format en ext3 ou ext4 )
umount /dev/$dev
mkfs.ext4 /dev/$dev

#creation des repertoires sur le disque et attribuer les groupes et droits
sudo mkdir /home/files/public/disk1
sudo chown -R root:users /home/files/public/disk1
sudo chmod -R ug=rwx,or=rx /home/files/public/disk1

#monté le systeme de fichier pour le device selectionné
sudo mount /dev/$dev /home/files/public/disk1

#montage automatique au demarrage en ajoutant à la fin du fichier /etc/fstab
echo "/dev/sda1 /home/files/public/disk1 auto noatime,nofail 0 0" >> /etc/fstab
