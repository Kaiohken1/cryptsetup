umount /mnt/secure_env

cryptsetup luksClose crypt

losetup -d /dev/loop0
