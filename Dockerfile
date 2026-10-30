FROM ubuntu:noble AS noble-livepatch

WORKDIR /build
SHELL ["/bin/bash", "-x", "-e", "-c"]

VOLUME ["/build/patches", "/build/kmods"]

# Copy repository seed files (big! 3.5GB each)
COPY --chown=root:root repo-seed /build/repo-seed

# Install packages
RUN <<EOC
apt-get update

echo 'tzdata tzdata/Areas select Etc' | debconf-set-selections
echo 'tzdata tzdata/Zones/Etc select UTC' | debconf-set-selections

# necessary for builds
apt-get install -y flex bison bc libssl-dev libelf-dev dwarves \
    rsync kmod cpio zstd gawk pkg-config build-essential \
    rustc rust-src rustfmt bindgen-0.65 clang libclang-dev \
	kmod git curl lsb-release

# quality-of-life
apt-get install -y --no-install-recommends less vim ripgrep bash-completion

apt-get clean

ln -sf /usr/bin/bindgen-0.85 /usr/local/bin/bindgen

EOC

# Install kpatch
RUN <<EOC
cd /tmp
KPATCH_VERSION="0.9.11"
curl -SLl -o kpatch-${KPATCH_VERSION}.tar.gz https://github.com/dynup/kpatch/archive/refs/tags/v${KPATCH_VERSION}.tar.gz
tar xzf kpatch-${KPATCH_VERSION}.tar.gz
cd kpatch-${KPATCH_VERSION}
make -j $(nproc)
make install
cd /tmp
rm -rf kpatch-${KPATCH_VERSION} kpatch-${KPATCH_VERSION}.tar.gz

EOC

# Copy helper scripts
RUN --mount=type=bind,source=transfer,target=/transfer <<EOC
install -oroot -groot -m0755 /transfer/init-repos /build/
install -oroot -groot -m0644 /transfer/kpatch-shellrc /root/
install -oroot -groot -m0755 /transfer/build-patch /usr/local/bin/

echo 'source $HOME/kpatch-shellrc' > /root/.bash_aliases

EOC
