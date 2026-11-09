#!/bin/bash
set -euo pipefail

cd /tmp/arch-work
mapfile -t packages < <(awk 'NF && $1 !~ /^#/ {print $1}' packages.txt)
pacman-key --init
pacman-key --populate archlinux
# The Docker builder blocks Landlock, so skip only that part of the download sandbox.
pacman -Syu --needed --noconfirm --disable-sandbox-filesystem "${packages[@]}"

useradd --create-home --user-group --uid 1000 --groups wheel --shell /bin/zsh user
printf '%%wheel ALL=(ALL:ALL) ALL\n' > /etc/sudoers.d/arch-work
chmod 0440 /etc/sudoers.d/arch-work
visudo -cf /etc/sudoers

install -o user -g user -m 0644 dotfiles/.profile dotfiles/.zprofile dotfiles/.zshrc dotfiles/.p10k.zsh /home/user/
install -d -o user -g user /home/user/.config/mise
install -o user -g user -m 0644 mise.toml /home/user/.config/mise/config.toml

runuser -u user -- bash -se <<'SETUP'
cd "$HOME"
git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git .oh-my-zsh
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git .oh-my-zsh/custom/themes/powerlevel10k
for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
    ln -s "/usr/share/zsh/plugins/$plugin" ".oh-my-zsh/custom/plugins/$plugin"
done
mise install
mise cache clear
SETUP

cd /
bash /tmp/arch-work/scripts/smoke-test.sh
pacman -Scc --noconfirm
rm -rf /tmp/arch-work /home/user/.cache /etc/pacman.d/gnupg
