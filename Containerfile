ARG DEBIAN_RELEASE=bookworm-20240311-slim
# Debian 12.5
FROM docker.io/library/debian:$DEBIAN_RELEASE

RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive \
    apt-get install \
      --assume-yes \
      --no-install-recommends \
      ca-certificates \
      cmake \
      curl \
      g++ \
      git \
      libpython3-stdlib \
      libssl-dev \
      make \
      ninja-build \
      pkg-config \
      python3-minimal \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*
# rustc (dist profile) builds *slowly* on a pi5 - took 3+hours to fail a build

# shamelessly stolen from "docker init"
ARG UID=10001
RUN adduser \
    --disabled-password \
    --gecos "" \
    --shell "/sbin/nologin" \
    --uid "${UID}" \
    builduser
USER builduser

WORKDIR /build
# clone repos
ARG RUST_REPO=https://github.com/rust-lang/rust.git
ARG RUST_TAG=1.77.1
ARG EZA_REPO=https://github.com/eza-community/eza.git
ARG EZA_TAG=v0.18.9
RUN git clone \
      -c advice.detachedHead=false \
      --depth 1 \
      --branch "$RUST_TAG" \
      "$RUST_REPO" \
 && git clone \
      -c advice.detachedHead=false \
      --depth 1 \
      --branch "$EZA_TAG" \
      "$EZA_REPO"

# build rust compiler (eza needs rustc > 1.70.0 or something
ARG RUST_PROFILE=compiler
RUN cd rust \
 && printf 'profile = "%s"\nchange-id = 102579\n' "$RUST_PROFILE" > config.toml \
 && ./x build

# build eza
RUN cd eza \
 && PATH=$PATH:/build/rust/build/aarch64-unknown-linux-gnu/stage0/bin cargo install --path .
# installs to /home/builduser/.cargo/bin/eza

CMD ["/bin/bash"]
