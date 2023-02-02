FROM archlinux:latest
RUN pacman -Suy --noconfirm --needed git base-devel bc clang cpio github-cli jq lld llvm python
RUN useradd -m xanmod_builder
USER xanmod_builder
RUN mkdir /home/xanmod_builder/.config
COPY modprobed.db /home/xanmod_builder/.config/modprobed.db
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]
