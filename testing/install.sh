#!/bin/bash

#This is a lazy script I have for auto-installing Arch.
#It's not officially part of LARBS, but I use it for testing.
#DO NOT RUN THIS YOURSELF because Step 1 is it reformatting /dev/sda WITHOUT confirmation,
#which means RIP in peace qq your data unless you've already backed up all of your drive.

pacman -S --noconfirm dialog || { echo "Error at script start: Are you sure you're running this as the root user? Are you sure you have an internet connection?"; exit; }

dialog --defaultno --title "DON'T BE A BRAINLET!" --yesno "This is an Arch install script that is very rough around the edges.\n\nOnly run this script if you're a big-brane who doesn't mind deleting your entire /dev/sda drive.\n\nThis script is only really for me so I can autoinstall Arch.\n\nt. Luke"  15 60 || exit

dialog --defaultno --title "DON'T BE A BRAINLET!" --yesno "Do you think I'm meming? Only select yes to DELET your entire /dev/sda and reinstall Arch.\n\nTo stop this script, press no."  10 60 || exit

dialog --no-cancel --inputbox "Enter a name for your computer." 10 60 2> comp

dialog --defaultno --title "Time Zone select" --yesno "Do you want use the default time zone(Australia/Perth)?.\n\nPress no for select your own time zone"  10 60 && echo "America/New_York" > tz.tmp || tzselect > tz.tmp

dialog --no-cancel --inputbox "Enter partitionsize in gb, separated by space (root & home)." 10 60 2>psize

pass1=$(dialog --no-cancel --passwordbox "Enter a root password." 10 60 3>&1 1>&2 2>&3 3>&1)
pass2=$(dialog --no-cancel --passwordbox "Retype password." 10 60 3>&1 1>&2 2>&3 3>&1)

while true; do
	[[ "$pass1" != "" && "$pass1" == "$pass2" ]] && break
	pass1=$(dialog --no-cancel --passwordbox "Passwords do not match or are not present.\n\nEnter password again." 10 60 3>&1 1>&2 2>&3 3>&1)
	pass2=$(dialog --no-cancel --passwordbox "Retype password." 10 60 3>&1 1>&2 2>&3 3>&1)
done

export pass="$pass1"



IFS=' ' read -ra SIZE <<< $(cat psize)

re='^[0-9]+$'
if ! [ ${#SIZE[@]} -eq 2 ] || ! [[ ${SIZE[0]} =~ $re ]] || ! [[ ${SIZE[1]} =~ $re ]] ; then
    SIZE=(12 25);
fi

timedatectl set-ntp true

cat <<EOF | fdisk /dev/sda
o
n
p
+${SIZE[0]}G

n
p
+${SIZE[1]}G

w
EOF
partprobe

yes | mkfs.ext4 /dev/sda1
yes | mkfs.ext4 /dev/sda2
mount /dev/sda1 /mnt
mkdir -p /mnt/home
mount /dev/sda2 /mnt/home

pacstrap /mnt base base-devel

genfstab -U /mnt >> /mnt/etc/fstab
cp tz.tmp /mnt/tzfinal.tmp
rm tz.tmp
#curl https://raw.githubusercontent.com/terra1122/LARBS/master/testing/chroot.sh > /mnt/chroot.sh && arch-chroot /mnt bash chroot.sh && rm /mnt/chroot.sh

### BEGIN
arch-chroot /mnt echo "root:$pass" | chpasswd

TZuser=$(cat tzfinal.tmp)

ln -sf /usr/share/zoneinfo/$TZuser /etc/localtime

hwclock --systohc

echo "en_AU.UTF-8 UTF-8" >> /etc/locale.gen
echo "en_AU ISO-8859-1" >> /etc/locale.gen
locale-gen

pacman --noconfirm --needed -S networkmanager
systemctl enable NetworkManager
systemctl start NetworkManager

pacman --noconfirm --needed -S grub && grub-install --target=i386-pc /dev/sda && grub-mkconfig -o /boot/grub/grub.cfg

pacman --noconfirm --needed -S dialog
larbs() { curl -O https://raw.githubusercontent.com/terra1122/archinstaller-v1/phase2.sh && bash phase2.sh ;}
dialog --title "Install all the stuff" --yesno "This install script will easily let you install all the apps.\n\nIf you'd like to install this, select yes, otherwise select no.\n"  15 60 && larbs
### END


mv comp /mnt/etc/hostname

dialog --defaultno --title "Final Qs" --yesno "Reboot computer?"  5 30 && reboot
dialog --defaultno --title "Final Qs" --yesno "Return to chroot environment?"  6 30 && arch-chroot /mnt
clear
