#!/bin/bash

get_answer() {

	read -p 'Continue? [Y/n]:' answer

	if [ "$answer" = 'y' ] || [ "$answer" = 'yes' ] || [ "$answer" = 'YES' ] || [ "$answer" = 'Y' ] 
	then
		echo "Continuing..."
		return 1
	else
		echo "Exiting..."
		exit 0
	fi
}

echo 'This script was created by Benjamin Lodzhevsky'
echo 'This program will install Arch with consideration for UEFI!'
echo 'The minumum disk size for this program is 30 GiB'


read -p 'Please specify disk to install to: ' disk

#if the users enters /dev/sdx/ this changes it to /dev/sdx
if [ "${disk:(-1)}" = '/' ]
then
	let str_disk_length=${#disk}-1
	disk=${disk:0:$str_disk_length}
	echo $disk
fi


if [ "$(partprobe -d -s $disk)" != "$disk: gpt partitions" ] #checks if there is data on disk
then
	echo 'There is data on this disk! Continuing will result in data loss.'
	get_answer
fi


sfdisk -d "$disk" > old_partition_table #stores the old partition table incase of disaster

#this is equal to 30 GiB 
let min_disksize=62914560

if [ $disksize -lt $min_disksize ] 
then
       echo 'This drive is too small!'
       exit 0
fi

#this is equal to 8 GiB and this is the size of the swap disk
let swap_size=16777216
#this is equal to 500 MiB and this is the size for the efi partition
let efi_size=1024000

#makes the first needed partitions
sfdisk "$disk" <<-EOF	
,$efi_size,C12A7328-F81F-11D2-BA4B-00A0C93EC93B,*
,$swap_size,0657FD6D-A4AB-43C4-84E5-0933C84B4F4F  
EOF

#then the rest of the space is dedicated to the root user
sfdisk "$disk" -a <<-EOF
,,4F68BCE3-E8CD-4DB1-96E7-FBCAF984B709
EOF

#formats the file system and makes swap
mkfs.fat -F32 "$disk"1
mkswap "$disk"2
mkfs.ext4 "$disk"3
swapon "$disk"2

mount "$disk"3 /mnt

#installs arch
pacstrap /mnt base linux-firmware linux base-devel efibootmgr grub vim nano networkmanager

genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt

hwclock --systohc

sed 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8' /etc/locale.gen
locale-gen

read -p 'Please enter your hostname' hostname
echo $hostname >> /etc/hostname

echo "127.0.0.1\tlocalhost\n::1\tlocalhost\n127.0.1.1\t$hostname.localdomain\t$hostname"
#puts entries for the hosts file

echo 'Please enter your root password!'
passwd

echo 'Script has finished





