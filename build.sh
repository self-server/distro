
sudo apt-get install \
  debootstrap \
  squashfs-tools \
  xorriso \
  isolinux \
  syslinux-efi \
  grub-pc-bin \
  grub-efi-amd64-bin \
  mtools

mkdir dist

sudo debootstrap \
  --arch=amd64 \
  --variant=minbase \
  bullseye \
  dist/chroot \
  http://ftp.us.debian.org/debian/

sudo cp chroot.sh dist/chroot/
sudo cp src/apt.conf dist/chroot/etc/apt/apt.conf
sudo cp src/selfserver dist/chroot/usr/sbin/selfserver

sudo chroot dist/chroot/ ./chroot.sh 


# back in host os (ie, my desktop)
sudo mkdir -p dist/{staging/{EFI/boot,boot/grub/x86_64-efi,isolinux,live},tmp}
sudo mksquashfs \
    dist/chroot \
    dist/staging/live/filesystem.squashfs \
    -e boot

sudo cp dist/chroot/boot/vmlinuz-* dist/staging/live/vmlinuz && \
sudo cp dist/chroot/boot/initrd.img-* dist/staging/live/initrd    
sudo cp src/isolinux.cfg dist/staging/isolinux/isolinux.cfg
sudo cp src/grub.cfg dist/staging/boot/grub/grub.cfg
sudo cp src/grub-standalone.cfg dist/tmp/grub-standalone.cfg

sudo touch dist/staging/SELFSERVER

sudo cp /usr/lib/ISOLINUX/isolinux.bin dist/staging/isolinux/ && \
sudo cp /usr/lib/syslinux/modules/bios/* dist/staging/isolinux/

sudo cp -r /usr/lib/grub/x86_64-efi/* dist/staging/boot/grub/x86_64-efi/

sudo cp src/selfserver.ico dist/staging/selfserver.ico
sudo cp src/autorun.inf dist/staging/autorun.inf

sudo grub-mkstandalone \
    --format=x86_64-efi \
    --output=dist/tmp/bootx64.efi \
    --locales="" \
    --fonts="" \
    "boot/grub/grub.cfg=dist/tmp/grub-standalone.cfg"

cd dist/staging/EFI/boot && \
  sudo dd if=/dev/zero of=efiboot.img bs=1M count=20 && \
  sudo mkfs.vfat efiboot.img && \
  sudo mmd -i efiboot.img efi efi/boot && \
  sudo mcopy -vi efiboot.img ../../../tmp/bootx64.efi ::efi/boot/ && \
  cd ../../../..

xorriso \
    -as mkisofs \
    -iso-level 3 \
    -o "selfserver.iso" \
    -full-iso9660-filenames \
    -volid "SELFSERVER" \
    -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
    -eltorito-boot \
        isolinux/isolinux.bin \
        -no-emul-boot \
        -boot-load-size 4 \
        -boot-info-table \
        --eltorito-catalog isolinux/isolinux.cat \
    -eltorito-alt-boot \
        -e /EFI/boot/efiboot.img \
        -no-emul-boot \
        -isohybrid-gpt-basdat \
    -append_partition 2 0xef dist/staging/EFI/boot/efiboot.img \
    "dist/staging"