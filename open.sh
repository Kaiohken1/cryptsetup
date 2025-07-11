PASSWORD="$1"

losetup -f /var/setup/env.img

echo $PASSWORD | cryptsetup luksOpen /dev/loop0 crypt

mkdir -p /mnt/secure_env
mount /dev/mapper/crypt /mnt/secure_env
