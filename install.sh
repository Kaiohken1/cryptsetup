PASSWORD="$1"

mkdir -p /var/setup

dd if=/dev/zero of=/var/setup/env.img bs=1M count=5120

losetup -f /var/setup/env.img

echo $PASSWORD | cryptsetup luksFormat /dev/loop0
echo $PASSWORD | cryptsetup luksOpen /dev/loop0 crypt

mkfs.ext4 -L ENV /dev/mapper/crypt

mkdir -p /mnt/secure_env
mount /dev/mapper/crypt /mnt/secure_env
chown -R $SUDO_USER:$SUDO_USER /var/setup /mnt/secure_env
