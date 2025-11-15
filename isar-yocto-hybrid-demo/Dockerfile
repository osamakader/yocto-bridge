FROM ghcr.io/siemens/kas/kas:4.0
RUN sudo apt-get update \
 && sudo apt-get install -y --no-install-recommends mmdebstrap schroot sbuild qemu-user-static bubblewrap arch-test reprepro\
 && sudo rm -rf /var/lib/apt/lists/*