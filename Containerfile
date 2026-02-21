FROM docker.io/taylorabarnes/devenv

ENV PATH="$PATH:/root/.local/bin"

# Install jq, which is needed for the requirements index script
RUN apt-get update && \
    apt install -y jq

# Install Claude
RUN curl -fsSL https://claude.ai/install.sh | bash

# Install rust
ENV RUST_VERSION=1.93.0
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain ${RUST_VERSION}
ENV PATH="/root/.cargo/bin:${PATH}"

COPY .podman/interface.sh /.podman/interface.sh

