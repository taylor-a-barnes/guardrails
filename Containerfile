FROM docker.io/taylorabarnes/devenv

ENV PATH="$PATH:/root/.local/bin"

# Install rust
ENV RUST_VERSION=1.93.0
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain ${RUST_VERSION}
ENV PATH="/root/.cargo/bin:${PATH}"

COPY .podman/interface.sh /.podman/interface.sh

