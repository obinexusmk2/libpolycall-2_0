# LibPolyCall v2 - Multi-Language FFI Protocol Library
# Author: Nnamdi Michael Okpala
# Repository: github.com/obinexus/libpolycall-v2
# Docker Hub: obinexus/libpolycall
#
# Separation of concerns:
# - builder: compiler toolchain only, discarded after build
# - runtime: native libpolycall artifacts and configuration only
# - development: optional language runtimes, tooling, and binding source

ARG UBUNTU_VERSION=24.04

FROM ubuntu:${UBUNTU_VERSION} AS builder

LABEL stage=builder

ENV DEBIAN_FRONTEND=noninteractive
ENV POLYCALL_VERSION=2.0.0

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    gcc \
    make \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build/libpolycall

COPY CMakeLists.txt Makefile LICENSE README.md ./
COPY include/ include/
COPY src/ src/
COPY config/cmake/ config/cmake/

RUN cmake -S . -B _docker_build \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/staging \
    && cmake --build _docker_build --parallel \
    && cmake --install _docker_build \
    && echo "LibPolyCall compiled successfully"

FROM ubuntu:${UBUNTU_VERSION} AS runtime

ARG POLYCALL_UID=10001
ARG POLYCALL_GID=10001

ENV DEBIAN_FRONTEND=noninteractive
ENV POLYCALL_HOME=/opt/polycall
ENV POLYCALL_ENV=production
ENV ZERO_TRUST=enabled
ENV PATH="${POLYCALL_HOME}/bin:${PATH}"
ENV LD_LIBRARY_PATH="${POLYCALL_HOME}/lib:/usr/local/lib:/usr/lib"

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

RUN groupadd -g ${POLYCALL_GID} polycall \
    && useradd -m -s /sbin/nologin -u ${POLYCALL_UID} -g polycall polycall \
    && mkdir -p \
        ${POLYCALL_HOME}/lib \
        ${POLYCALL_HOME}/bin \
        ${POLYCALL_HOME}/include \
        ${POLYCALL_HOME}/config \
        /var/log/polycall \
        /workspace \
    && chown -R polycall:polycall ${POLYCALL_HOME} /var/log/polycall /workspace

COPY --from=builder --chown=polycall:polycall /staging/lib/ ${POLYCALL_HOME}/lib/
COPY --from=builder --chown=polycall:polycall /staging/include/ ${POLYCALL_HOME}/include/
COPY --from=builder --chown=polycall:polycall /staging/bin/ ${POLYCALL_HOME}/bin/
COPY --chown=polycall:polycall config/ ${POLYCALL_HOME}/config/

RUN ldconfig -n ${POLYCALL_HOME}/lib

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD test -f ${POLYCALL_HOME}/lib/libpolycall.so || exit 1

WORKDIR /workspace

USER polycall

LABEL org.opencontainers.image.title="LibPolyCall v2"
LABEL org.opencontainers.image.description="Universal FFI protocol bridging Python, Node.js, Go, Java, and COBOL with zero-trust security"
LABEL org.opencontainers.image.authors="Nnamdi Michael Okpala <nnamdi@obinexuscomputing.com>"
LABEL org.opencontainers.image.vendor="OBINexus Computing"
LABEL org.opencontainers.image.source="https://github.com/obinexus/libpolycall-v2"
LABEL org.opencontainers.image.url="https://hub.docker.com/r/obinexus/libpolycall"
LABEL org.opencontainers.image.documentation="https://github.com/obinexus/libpolycall-v2/tree/main/docs"
LABEL org.opencontainers.image.version="2.0.0"
LABEL org.opencontainers.image.revision="main"
LABEL org.opencontainers.image.created="2024-01-01T00:00:00Z"
LABEL org.opencontainers.image.licenses="MIT"

CMD ["/bin/sh", "-c", "echo 'LibPolyCall v2 - Multi-Language FFI Protocol' && echo 'Version: 2.0.0' && echo 'Home: /opt/polycall' && echo '---' && ls -lh ${POLYCALL_HOME}/lib/libpolycall* 2>/dev/null || echo 'Library files not found' && exec /bin/sh"]

FROM runtime AS development

USER root

ENV CMAKE_BUILD_TYPE=Debug

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    curl \
    gdb \
    gcc \
    git \
    make \
    nano \
    nodejs \
    npm \
    python3 \
    python3-pip \
    lua5.4 \
    vim \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p ${POLYCALL_HOME}/bindings ${POLYCALL_HOME}/examples \
    && chown -R polycall:polycall ${POLYCALL_HOME}/bindings ${POLYCALL_HOME}/examples

COPY --chown=polycall:polycall bindings/ ${POLYCALL_HOME}/bindings/
COPY --chown=polycall:polycall examples/ ${POLYCALL_HOME}/examples/

WORKDIR /workspace

USER polycall

LABEL stage=development

# Keep the default Docker build production-grade even when --target is omitted.
FROM runtime AS production
