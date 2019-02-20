#!/bin/bash
echo accorder droit au fichier a modifier
sudo chmod 777 /../etc/default/grub
sudo chmod 777 /../etc/grub.d/10_linux
sudo chmod 777 /../etc/grub.d/30_os-prober

echo changer le temps de delai GRUB
sed -i 's/GRUB_TIMEOUT=.*/GRUB_TIMEOUT=60/g' /../etc/default/grub
echo changement de l os par defaut
grub2-set-default '0'

echo  changement du nom des os
if grep -q 'troisieme=\\ troisi\\ème\\ ann\\ée' /../etc/grub.d/10_linux
then
echo trouver
else
echo non trouver
sed -i '19a troisieme=\\ troisi\\ème\\ ann\\ée' /../etc/grub.d/10_linux
sed -i 's/os="$1"/os="$1""$troisieme"/g' /../etc/grub.d/10_linux
fi

if grep -q 'deuxi\ème\ ann\ée' /../etc/grub.d/30_os-prober
then
echo trouver
else
echo non trouver
sed -i 's/"$OS $onstr"/"$OS $onstr \ deuxi\ème\ ann\ée"/g' /../etc/grub.d/30_os-prober
fi

echo changement ordre des os
mv /../etc/grub.d/10_linux /../etc/grub.d/30_linux
mv /../etc/grub.d/30_os-prober /../etc/grub.d/10_os-prober

grub2-mkconfig -o /boot/grub2/grub.cfg
