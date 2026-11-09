# syntax=docker/dockerfile:1.17
FROM scratch AS configured
ARG ARCH_WSL_SHA256
ADD --checksum=sha256:${ARCH_WSL_SHA256} --unpack=true https://mirror.pkgbuild.com/wsl/latest/archlinux.wsl /

COPY packages.txt mise.toml /tmp/arch-work/
COPY dotfiles/ /tmp/arch-work/dotfiles/
COPY scripts/ /tmp/arch-work/scripts/
COPY wsl/*.conf /etc/
COPY --chmod=0755 wsl/arch-work-setup /usr/lib/wsl/arch-work-setup
COPY --chmod=0644 wsl/arch-work.ico /usr/lib/wsl/arch-work.ico
RUN bash /tmp/arch-work/scripts/provision.sh

FROM configured AS pack
RUN --mount=type=bind,from=configured,target=/rootfs \
    mkdir /out && cd /out && \
    tar --numeric-owner --acls --xattrs --xattrs-include='*' \
        --exclude='./etc/resolv.conf' --exclude='./etc/machine-id' \
        -czf arch-work.wsl -C /rootfs . && \
    bytes="$(stat -c '%s' arch-work.wsl)" && \
    echo "Compressed Arch-Work image: $bytes bytes" && \
    { [ "$bytes" -lt 2147483648 ] || { echo "Image exceeds the GitHub Releases file limit" >&2; exit 1; }; } && \
    sha256sum arch-work.wsl > arch-work.wsl.sha256

FROM scratch
COPY --from=pack /out/ /
