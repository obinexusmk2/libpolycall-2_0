# Docker Hub Publishing - LibPolyCall v2

## Quick Start

### 1. **Login to Docker Hub**
```bash
docker login -u <your-docker-username>
# Enter your Docker Hub password or token
```

### 2. **Build the Production Image**
```bash
docker build -t obinexus/libpolycall:2.0.0 \
             -t obinexus/libpolycall:latest \
             --target runtime \
             .
```

### 3. **Verify the Build**
```bash
docker run --rm obinexus/libpolycall:latest
```

Output should show:
```
LibPolyCall v2 - Multi-Language FFI Protocol
Version: 2.0.0
Home: /opt/polycall
---
-rwxr-xr-x 1 root root ... /opt/polycall/lib/libpolycall.so
```

### 4. **Push to Docker Hub**
```bash
docker push obinexus/libpolycall:2.0.0
docker push obinexus/libpolycall:latest
```

### 5. **Verify on Docker Hub**
- Visit: https://hub.docker.com/r/obinexus/libpolycall
- Both tags (2.0.0 and latest) should appear

---

## Automated Publishing with Script

Use the provided publishing script:

```bash
chmod +x scripts/publish-docker-hub.sh

# With credentials passed via environment
export DOCKER_HUB_USER="your-username"
export DOCKER_HUB_TOKEN="your-token-or-password"
./scripts/publish-docker-hub.sh
```

Or with interactive login:
```bash
./scripts/publish-docker-hub.sh
```

---

## Image Details

**Tags Available:**
- `obinexus/libpolycall:2.0.0` - Specific version (recommended for production)
- `obinexus/libpolycall:latest` - Always points to newest stable

**Multi-Stage Build:**
- **Builder Stage**: Compiles C library (CMake + GCC)
- **Runtime Stage**: Minimal production image with native library artifacts and configuration only
- **Development Stage**: Optional build tools, Python 3, Node.js/npm, Lua, bindings, and examples

**Security Features:**
- Non-root service user (`polycall:polycall`, UID 10001 by default)
- Health check included (`HEALTHCHECK`)
- Minimal attack surface in the production runtime image
- OCI-compliant labels

**Image Size:**
- Builder: ~600MB (development)
- Runtime: minimal Ubuntu base plus libpolycall artifacts

---

## Pull & Run Examples

### Basic Run
```bash
docker pull obinexus/libpolycall:latest
docker run -it obinexus/libpolycall:latest
```

### Interactive Shell with Library Access
```bash
docker run -it --rm \
  -v $(pwd)/workspace:/workspace \
  obinexus/libpolycall:latest \
  /bin/sh
```

### Mount for Development
```bash
docker run -it --rm \
  -v /opt/polycall/lib:/app/polycall/lib:ro \
  -w /workspace \
  obinexus/libpolycall:latest \
  /bin/bash
```

### Use as Base Image
In your own Dockerfile:
```dockerfile
FROM obinexus/libpolycall:2.0.0

# Your application here
```

---

## Docker Compose Usage

```yaml
version: '3.8'

services:
  polycall-app:
    image: obinexus/libpolycall:2.0.0
    container_name: my-polycall-app
    environment:
      - POLYCALL_ENV=production
      - ZERO_TRUST=enabled
    volumes:
      - ./config:/opt/polycall/config:ro
      - ./data:/workspace
    restart: unless-stopped
```

---

## Development Image (Optional)

To build the development stage with build tools:

```bash
docker build -t obinexus/libpolycall:2.0.0-dev \
             --target development \
             .

docker run -it --rm \
  -v $(pwd):/libpolycall \
  obinexus/libpolycall:2.0.0-dev \
  /bin/bash
```

---

## Troubleshooting

### Login Issues
```bash
# Use personal access token instead of password
docker logout
docker login -u <username> --password-stdin < your-token.txt
```

### Tag Already Exists
To overwrite existing tags:
```bash
docker push obinexus/libpolycall:2.0.0 --force
```

### Verify Push Success
```bash
# Check Docker Hub
docker pull obinexus/libpolycall:2.0.0
docker inspect obinexus/libpolycall:2.0.0 | head -20
```

### View Image Metadata
```bash
docker inspect obinexus/libpolycall:2.0.0 --format='{{json .Config.Labels}}' | jq
```

---

## CI/CD Integration (GitHub Actions)

```yaml
name: Publish to Docker Hub

on:
  push:
    tags:
      - 'v*'

jobs:
  push:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - uses: docker/setup-buildx-action@v2
      
      - uses: docker/login-action@v2
        with:
          username: ${{ secrets.DOCKER_HUB_USERNAME }}
          password: ${{ secrets.DOCKER_HUB_TOKEN }}
      
      - uses: docker/build-push-action@v4
        with:
          context: .
          target: runtime
          push: true
          tags: |
            obinexus/libpolycall:${{ github.ref_name }}
            obinexus/libpolycall:latest
```

---

## Support & Documentation

- **GitHub**: https://github.com/obinexus/libpolycall-v2
- **Documentation**: https://github.com/obinexus/libpolycall-v2/tree/main/docs
- **Issues**: https://github.com/obinexus/libpolycall-v2/issues
