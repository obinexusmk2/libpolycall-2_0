# ─────────────────────────────────────────────────────────────
# OBINexus libpolycall-v2
# Author: Nnamdi Michael Okpala
# Repo: github.com/obinexusmk2/libpolycall-v2
#
# Real repo structure:
#   bindings/ config/ contrib/ core/ daemon/ docs/ legacy/ tools/
#   CMakeLists.txt  Makefile  build.sh  check_compile.sh
# ─────────────────────────────────────────────────────────────

# ── Stage 1: Builder ─────────────────────────────────────────
FROM ubuntu:22.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    build-essential cmake gcc make git \
    python3 lua5.4 nodejs npm \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /libpolycall

# Copy entire repo
COPY . .

# Make scripts executable
RUN chmod +x build.sh check_compile.sh 2>/dev/null || true

# Run your existing build script
RUN bash build.sh 2>&1 || true

# CMake build
RUN mkdir -p _docker_build && \
    cd _docker_build && \
    cmake -DCMAKE_BUILD_TYPE=Release \
          -DCMAKE_INSTALL_PREFIX=/staging \
          .. && \
    make -j$(nproc) && \
    make install

# ── Stage 2: Runtime ─────────────────────────────────────────
FROM ubuntu:22.04 AS runtime

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    python3 lua5.4 nodejs \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /staging/             /usr/local/
COPY --from=builder /libpolycall/config/  /etc/polycall/config/
COPY --from=builder /libpolycall/bindings/ /usr/local/share/polycall/bindings/

RUN ldconfig

WORKDIR /workspace

LABEL org.opencontainers.image.title="libpolycall-v2"
LABEL org.opencontainers.image.authors="Nnamdi Michael Okpala"
LABEL org.opencontainers.image.source="https://github.com/obinexusmk2/libpolycall-v2"
LABEL org.opencontainers.image.version="2.0.0"

CMD ["sh", "-c", "echo 'OBINexus libpolycall v2' && ls /usr/local/lib/libpolycall* 2>/dev/null && echo '#hacc #noghosting'"]
