#! /bin/bash

# commande pour activer boot USB
comfirm=""
echo Voulez vous activer le boot USB? Attention ceci est irréversible
echo valider l'activation ? yes / no
read comfirm
if [ "$comfirm" == "yes" ]
then
	sudo echo program_usb_boot_mode=1 | sodo tee -a /boot/config.txt
	echo reboot necessaire 
	read -p "Appuyer sur une touche pour redémmarer"
	sudo reboot
echo ""
echo ""
echo "Vérifier que l'option est bien activer aprés le reboot, la réponse doit être 3020000A"
echo "sudo vcgencmd otp_dump | grep 17"
read -p "Appuyer sur une touche pour continuer ... "

fi
