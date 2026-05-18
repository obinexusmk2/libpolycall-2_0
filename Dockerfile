# ─────────────────────────────────────────────────────────────────────────────
# LibPolyCall v2 - Multi-Language FFI Protocol Library
# Author: Nnamdi Michael Okpala
# Repository: github.com/obinexus/libpolycall-v2
# Docker Hub: obinexus/libpolycall
# ─────────────────────────────────────────────────────────────────────────────

# ─── Stage 1: Builder ──────────────────────────────────────────────────────────
FROM ubuntu:22.04 AS builder

LABEL stage=builder

ENV DEBIAN_FRONTEND=noninteractive
ENV POLYCALL_VERSION=2.0.0

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    gcc \
    make \
    git \
    python3 \
    lua5.4 \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build/libpolycall

# Copy entire source
COPY . .

# Make scripts executable (handle cases where scripts don't exist)
RUN chmod +x build.sh check_compile.sh 2>/dev/null || true

# Run build script if it exists
RUN if [ -f build.sh ]; then bash build.sh 2>&1; fi || true

# CMake build - compile C library with optimizations
RUN mkdir -p _docker_build && \
    cd _docker_build && \
    cmake -DCMAKE_BUILD_TYPE=Release \
          -DCMAKE_INSTALL_PREFIX=/staging \
          .. && \
    make -j$(nproc) && \
    make install && \
    echo "✓ LibPolyCall compiled successfully"

# ─── Stage 2: Runtime (Production) ────────────────────────────────────────────
FROM ubuntu:22.04 AS runtime

ENV DEBIAN_FRONTEND=noninteractive
ENV POLYCALL_HOME=/opt/polycall
ENV POLYCALL_ENV=production
ENV ZERO_TRUST=enabled
ENV PATH="${POLYCALL_HOME}/bin:${PATH}"
ENV LD_LIBRARY_PATH="${POLYCALL_HOME}/lib:/usr/local/lib:/usr/lib"

# Install runtime dependencies only
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    libssl3 \
    python3 \
    python3-minimal \
    lua5.4 \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Create non-root user for security
RUN useradd -m -s /sbin/nologin -u 1000 polycall && \
    mkdir -p ${POLYCALL_HOME}/lib \
             ${POLYCALL_HOME}/bin \
             ${POLYCALL_HOME}/config \
             ${POLYCALL_HOME}/bindings \
             /var/log/polycall && \
    chown -R polycall:polycall ${POLYCALL_HOME} /var/log/polycall

# Copy compiled artifacts from builder - conditionally with fallback
COPY --from=builder --chown=polycall:polycall /staging/lib/ ${POLYCALL_HOME}/lib/
COPY --from=builder --chown=polycall:polycall /staging/include/ ${POLYCALL_HOME}/include/
COPY --from=builder --chown=polycall:polycall /staging/bin/ ${POLYCALL_HOME}/bin/

# Copy configuration and bindings if they exist
COPY --from=builder --chown=polycall:polycall /build/libpolycall/config/ ${POLYCALL_HOME}/config/
COPY --from=builder --chown=polycall:polycall /build/libpolycall/bindings/ ${POLYCALL_HOME}/bindings/

# Update dynamic library cache
RUN ldconfig -n ${POLYCALL_HOME}/lib

# Health check - verify library is accessible
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD test -f ${POLYCALL_HOME}/lib/libpolycall.so || exit 1

# Set working directory
WORKDIR /workspace

# Switch to non-root user
USER polycall

# OpenContainer Image Labels (OCI standard)
LABEL org.opencontainers.image.title="LibPolyCall v2"
LABEL org.opencontainers.image.description="Universal FFI protocol bridging Python, Node.js, Go, Java, and COBOL with zero-trust security"
LABEL org.opencontainers.image.authors="Nnamdi Michael Okpala <nnamdi@obinexuscomputing.com>"
LABEL org.opencontainers.image.vendor="OBINexus Computing"
LABEL org.opencontainers.image.source="https://github.com/obinexus/libpolycall-v2"
LABEL org.opencontainers.image.url="https://hub.docker.com/r/obinexus/libpolycall"
LABEL org.opencontainers.image.documentation="https://github.com/obinexus/libpolycall-v2/docs"
LABEL org.opencontainers.image.version="2.0.0"
LABEL org.opencontainers.image.revision="main"
LABEL org.opencontainers.image.created="2024-01-01T00:00:00Z"
LABEL org.opencontainers.image.licenses="MIT"

# Default command - display library info and stay alive for interactive use
CMD ["/bin/sh", "-c", "echo 'LibPolyCall v2 - Multi-Language FFI Protocol' && echo 'Version: 2.0.0' && echo 'Home: /opt/polycall' && echo '---' && ls -lh ${POLYCALL_HOME}/lib/libpolycall* 2>/dev/null || echo 'Library files not found' && exec /bin/sh"]

# ─── Stage 3: Development (Optional) ──────────────────────────────────────────
FROM runtime AS development

USER root

ENV CMAKE_BUILD_TYPE=Debug

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    gcc \
    make \
    git \
    gdb \
    vim \
    nano \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /libpolycall

USER polycall

LABEL stage=development
