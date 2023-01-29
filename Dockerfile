FROM archlinux:latest
RUN pacman -Suy --noconfirm --needed git base-devel bc clang cpio github-cli jq lld llvm python
RUN useradd -m xanmod_builder
USER xanmod_builder
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]
