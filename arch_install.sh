# Originally: https://github.com/Bugswriter/arch-linux-magic/blob/master/arch_install.sh
# == MY ARCH SETUP INSTALLER == #
#part1
printf '\033c'
echo "Welcome to Syzygianinfern0's arch installer script"
sed -i "s/^#ParallelDownloads = 5$/ParallelDownloads = 15/" /etc/pacman.conf
pacman --noconfirm -Sy archlinux-keyring
loadkeys us
timedatectl set-ntp true
lsblk
echo "Enter the drive: "
read drive
cfdisk $drive
echo "Enter the linux partition: "
read partition
mkfs.ext4 $partition
read -p "Did you also create efi partition? [y/n]" answer
if [[ $answer = y ]]; then
    echo "Enter EFI partition: "
    read efipartition
    mkfs.vfat -F 32 $efipartition
fi
mount $partition /mnt
pacstrap /mnt base base-devel linux linux-firmware
genfstab -U /mnt >>/mnt/etc/fstab
sed '1,/^#part2$/d' $(basename $0) >/mnt/arch_install2.sh
chmod +x /mnt/arch_install2.sh
arch-chroot /mnt ./arch_install2.sh
exit

#part2
printf '\033c'
pacman -S --noconfirm sed
sed -i "s/^#ParallelDownloads = 5$/ParallelDownloads = 15/" /etc/pacman.conf
ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8" >>/etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >/etc/locale.conf
echo "KEYMAP=us" >/etc/vconsole.conf
echo "Hostname: "
read hostname
echo $hostname >/etc/hostname
echo "127.0.0.1       localhost" >>/etc/hosts
echo "::1             localhost" >>/etc/hosts
echo "127.0.1.1       $hostname.localdomain $hostname" >>/etc/hosts
mkinitcpio -P
passwd
pacman --noconfirm -S grub efibootmgr os-prober
echo "Enter EFI partition: "
read efipartition
mkdir /boot/efi
mount $efipartition /boot/efi
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
sed -i 's/quiet/pci=noaer/g' /etc/default/grub
sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=0/g' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

packages=(
    xorg-server xorg-xinit xorg-xkill xorg-xsetroot xorg-xbacklight xorg-xprop                     # xorg
    noto-fonts noto-fonts-emoji noto-fonts-cjk ttf-jetbrains-mono ttf-joypixels ttf-font-awesome   # fonts
    sxiv mpv zathura zathura-pdf-mupdf firefox                                                     # essential apps
    man-db dosfstools ntfs-3g git brightnessctl xdotool jq dash zsh xdg-user-dirs                  # core tools
    fzf xclip maim sxhkd ffmpeg imagemagick libnotify                                              # essential tools
    arc-gtk-theme papirus-icon-theme xcompmgr dunst slock cowsay xwallpaper python-pywal unclutter # customization
    dhcpcd connman wpa_supplicant rsync aria2                                                      # networking
    zip unzip unrar p7zip                                                                          # zip
    pipewire pipewire-pulse pamixer mpd ncmpcpp bluez bluez-utils                                  # sound and bluetooth
)
pacman -S --noconfirm $packages

read -p "Select your GPU [ 1=>Intel 2=>AMD 3=>Nvidia 4=>vmware ] " gpu
if [[ $gpu = 1 ]]; then
    pacman -S --noconfirm xf86-video-intel
elif [[ $gpu = 2 ]]; then
    pacman -S --noconfirm xf86-video-amdgpu
elif [[ $gpu = 3 ]]; then
    pacman -S --noconfirm nvidia nvidia-utils nvidia-settings
elif [[ $gpu = 4 ]]; then
    pacman -S --noconfirm xf86-video-vmware
fi

systemctl enable NetworkManager.service
mv /bin/sh /bin/sh.bak
ln -s dash /bin/sh
echo "%wheel ALL=(ALL) NOPASSWD: ALL" >>/etc/sudoers
echo "Enter Username: "
read username
useradd -m -G wheel -s /bin/zsh $username
passwd $username
echo "Pre-Installation Finish Reboot now"
ai3_path=/home/$username/arch_install3.sh
sed '1,/^#part3$/d' arch_install2.sh >$ai3_path
chown $username:$username $ai3_path
chmod +x $ai3_path
su -c $ai3_path -s /bin/sh $username
exit

#part3
printf '\033c'
cd $HOME
git clone --separate-git-dir=$HOME/.dotfiles https://github.com/bugswriter/dotfiles.git tmpdotfiles
rsync --recursive --verbose --exclude '.git' tmpdotfiles/ $HOME/
rm -r tmpdotfiles
# dwm: Window Manager
git clone --depth=1 https://github.com/Bugswriter/dwm.git ~/.local/src/dwm
sudo make -C ~/.local/src/dwm install

# st: Terminal
git clone --depth=1 https://github.com/Bugswriter/st.git ~/.local/src/st
sudo make -C ~/.local/src/st install

# dmenu: Program Menu
git clone --depth=1 https://github.com/Bugswriter/dmenu.git ~/.local/src/dmenu
sudo make -C ~/.local/src/dmenu install

# dmenu: Dmenu based Password Prompt
git clone --depth=1 https://github.com/ritze/pinentry-dmenu.git ~/.local/src/pinentry-dmenu
sudo make -C ~/.local/src/pinentry-dmenu clean install

# dwmblocks: Status bar for dwm
git clone --depth=1 https://github.com/bugswriter/dwmblocks.git ~/.local/src/dwmblocks
sudo make -C ~/.local/src/dwmblocks install

# pikaur: AUR helper
git clone https://aur.archlinux.org/pikaur.git
cd pikaur
makepkg -fsri
cd
pikaur -S libxft-bgra-git yt-dlp-drop-in update-grub
update-grub
mkdir dox dwns mux pix pub vids

ln -s ~/.config/x11/xinitrc .xinitrc
ln -s ~/.config/shell/profile .zprofile
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
mv ~/.oh-my-zsh ~/.config/zsh/oh-my-zsh
rm ~/.zshrc ~/.zsh_history
alias dots='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
dots config --local status.showUntrackedFiles no
exit
