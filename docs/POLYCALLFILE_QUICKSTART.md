# Polycallfile Quick Start Guide
**LibPolyCall-v1 Configuration & Orchestration**

---

## What is a Polycallfile?

The **Polycallfile** is the single source of truth for orchestrating your entire LibPolyCall ecosystem:
- Which language bindings to use
- How to route requests (Node.js vs Python vs Go vs COBOL)
- Database, queue, and driver configurations
- Security policies and compliance rules
- Telemetry and monitoring
- Extensions and plugins

**It's like Docker Compose, but for polyglot architectures.**

---

## File Format Options

### Option 1: XML (Formal Specification)
```bash
polycall -f Polycallfile.xml
```
**Best for**: Enterprise deployments, formal validation, integration with CI/CD tools

**Validation**:
```bash
xmllint --schema schema/Polycallfile.xsd Polycallfile.xml --valid
```

### Option 2: TOML (Developer-Friendly)
```bash
polycall -f Polycallfile.toml
```
**Best for**: Rapid development, human readability, version control-friendly

**Conversion**:
```bash
polycall convert Polycallfile.toml -o Polycallfile.xml
```

### Option 3: Auto-Detect
```bash
polycall
```
Automatically finds `Polycallfile.xml` or `Polycallfile.toml` in current directory

---

## Naming Convention Quick Reference

### Language Bindings
```
Format:  {language}-polycall
Examples:
├── node-polycall       (Node.js binding)
├── python-polycall     (Python binding)
├── go-polycall         (Go binding)
├── java-polycall       (Java binding)
└── cobol-polycall      (COBOL mainframe binding)
```

### System Drivers
```
Format:  polycall-{system}
Examples:
├── polycall-postgres   (PostgreSQL driver)
├── polycall-redis      (Redis driver)
├── polycall-rabbitmq   (RabbitMQ driver)
└── polycall-kafka      (Kafka driver)
```

### Extensions
```
Format:  polycall-{feature}
Examples:
├── polycall-jwt-auth        (JWT authentication)
├── polycall-rate-limit      (Rate limiting)
└── polycall-request-logging (Request logging)
```

### Plugins
```
Format:  polycall-plugin-{domain}
Examples:
├── polycall-plugin-banking-kyc      (Banking KYC/AML)
└── polycall-plugin-ecommerce-cart   (E-commerce cart)
```

---

## Creating Your First Polycallfile

### Step 1: Copy Template
```bash
cp examples/Polycallfile.toml ./Polycallfile.toml
```

### Step 2: Edit for Your Environment
```toml
[metadata]
name = "My Custom System"
organization = "My Organization"

[bindings."node-polycall"]
# Configure Node.js port
[bindings."node-polycall".server]
port = 8080

# Add your PostgreSQL connection
[drivers.postgres]
host = "my-database-host"
database = "my_database"
```

### Step 3: Validate
```bash
polycall validate Polycallfile.toml
```

Output:
```
✓ Polycallfile is valid
✓ All platforms found
✓ All bindings configured
✓ All drivers available
✓ Security policy is zero-trust
✓ Ready to start
```

### Step 4: Dry Run
```bash
polycall -f Polycallfile.toml --dry-run
```

Shows what will happen WITHOUT actually starting services.

### Step 5: Start
```bash
polycall -f Polycallfile.toml
```

---

## Platform Definition Example

Define what runtimes you support:

```toml
[platforms."nodejs-18"]
name = "Node.js 18.x LTS"
type = "nodejs"
version = "18.16.0"
memory_limit = "512M"
cpu_limit = 2
capabilities = ["async-await", "native-modules", "ffi-support"]
```

**Reference in bindings**:
```toml
[bindings."node-polycall"]
target_platform = "nodejs-18"  # Declares which platform this runs on
```

---

## Binding Configuration Pattern

All bindings follow the same structure:

```toml
[bindings."BINDING-ID"]
name = "Human-Readable Name"
target_platform = "PLATFORM-ID"

# FFI (Foreign Function Interface)
[bindings."BINDING-ID".ffi]
type = "native"  # or "cgo", "jni", "unix-socket", etc.
library = "libpolycall.so"

# Registry (where package is published)
registry_type = "npm"  # or "pypi", "maven", "go-module"
registry_package = "@scope/package-name"

# Server (if this binding runs a server)
[bindings."BINDING-ID".server]
port = 8080
bind = "127.0.0.1"

# Dependencies
[bindings."BINDING-ID".dependencies]
dep1 = ">=1.0.0"
dep2 = ">=2.0.0"
```

---

## Driver Configuration Pattern

Connect to external systems:

```toml
[drivers.postgres]
name = "PostgreSQL Driver"
host = "localhost"
port = 5432
database = "mydb"
pool_size = 20

[drivers.redis]
name = "Redis Cache"
host = "localhost"
port = 6379

[drivers.rabbitmq]
name = "RabbitMQ Messaging"
host = "localhost"
port = 5672

[[drivers.rabbitmq.exchanges]]
name = "polycall.events"
type = "topic"
```

---

## Security Configuration

Zero-trust policy (all requests must be authenticated):

```toml
[security]
mode = "zero-trust"

[security.tls]
enabled = true
version = "1.3"
cert_file = "/etc/polycall/certs/server.crt"
key_file = "/etc/polycall/certs/server.key"
require_client_cert = true

[security.auth]
method = "mTLS"  # Mutual TLS required

[security.crypto]
signature_algorithm = "HMAC-SHA256"

# Role-Based Access Control
[security.rbac.roles.admin]
permissions = ["*"]

[security.rbac.roles.developer]
permissions = ["binding:read", "operation:execute"]
```

---

## Network Routing

Route different paths to different bindings:

```toml
[[network.routes]]
path = "/api/*"
binding = "node-polycall"  # REST API via Node.js

[[network.routes]]
path = "/admin/*"
binding = "python-polycall"  # Admin via Python

[[network.routes]]
path = "/compute/*"
binding = "go-polycall"  # Heavy computation via Go

[[network.routes]]
path = "/legacy/*"
binding = "cobol-polycall"  # Mainframe via COBOL daemon
```

---

## Telemetry & Observability

Enable metrics, tracing, and logging:

```toml
[telemetry]
enabled = true

[telemetry.tracing]
enabled = true
exporter = "jaeger"
jaeger_endpoint = "http://localhost:6831"

[telemetry.metrics]
enabled = true
exporter = "prometheus"
prometheus_port = 9090

[telemetry.logging]
level = "info"
format = "json"
log_file = "/var/log/polycall/polycall.log"
```

---

## Extensions (Built-in Features)

Add optional features without plugins:

```toml
[extensions.jwt-auth]
enabled = true
name = "JWT Authentication"
type = "authentication"
algorithm = "HS256"
expiration = 3600

[extensions.rate-limit]
enabled = true
name = "Rate Limiting"
type = "middleware"
requests_per_second = 100

[extensions.request-logging]
enabled = true
name = "Request Logging"
type = "middleware"
log_level = "info"
```

---

## Plugins (Third-Party Domain Modules)

Deploy domain-specific functionality:

```toml
[[plugins]]
id = "banking-kyc"
enabled = true
name = "KYC/AML Banking Plugin"
source = "plugin-marketplace://obinexus/banking-kyc:1.0.0"
sandbox = true
permissions = ["database:read", "database:write", "external-api:call"]
```

---

## Common Operations

### Validate Configuration
```bash
polycall validate Polycallfile.toml
```

### Show Current Configuration
```bash
polycall config show
```

### Show Resolved Configuration (with env vars)
```bash
polycall config show --resolved
```

### Dry Run (what would happen)
```bash
polycall -f Polycallfile.toml --dry-run
```

### Start with Debug Output
```bash
polycall -f Polycallfile.toml --debug
```

### Check Binding Status
```bash
polycall bindings list
polycall bindings status node-polycall
```

### Check Driver Status
```bash
polycall drivers list
polycall drivers status postgres
```

### View Logs
```bash
polycall logs follow --service node-polycall
polycall logs follow --service postgres
```

### Restart a Binding
```bash
polycall bindings restart node-polycall
```

---

## Environment Variables

Polycallfile supports environment variable substitution:

```toml
[security.auth]
api_key_vault = "hashicorp-vault://secret/polycall/${ENVIRONMENT}/api-keys"

[drivers.postgres]
host = "${DB_HOST}"
port = "${DB_PORT}"
username = "${DB_USER}"
password_vault = "hashicorp-vault://secret/postgres/${ENVIRONMENT}/password"
```

Usage:
```bash
export DB_HOST=mydb.example.com
export DB_PORT=5432
export DB_USER=polycall
export ENVIRONMENT=production

polycall -f Polycallfile.toml
```

---

## Real-World Example: Banking System

```toml
[metadata]
name = "Wire Transfer System"
version = "2.0.0"
organization = "FinTech Corp"

# Node.js for REST API
[bindings."node-polycall"]
target_platform = "nodejs-18"
[bindings."node-polycall".server]
port = 8080

# Python for fraud detection
[bindings."python-polycall"]
target_platform = "python-311"
[bindings."python-polycall".server]
port = 3001

# Go for high-speed transaction processing
[bindings."go-polycall"]
target_platform = "go-1.21"
[bindings."go-polycall".server]
port = 9084

# COBOL mainframe for settlement
[bindings."cobol-polycall"]
target_platform = "cobol-mf"

# PostgreSQL for transaction ledger
[drivers.postgres]
host = "ledger-db.internal"
port = 5432
database = "transactions"

# Redis for rate limiting & session storage
[drivers.redis]
host = "cache.internal"

# Kafka for transaction events
[drivers.kafka]
bootstrap_servers = ["kafka-1:9092", "kafka-2:9092", "kafka-3:9092"]

# Routing
[[network.routes]]
path = "/api/transfers"
binding = "node-polycall"

[[network.routes]]
path = "/api/fraud-check"
binding = "python-polycall"

[[network.routes]]
path = "/api/process"
binding = "go-polycall"

[[network.routes]]
path = "/legacy/*"
binding = "cobol-polycall"

# Security: Zero-trust with mTLS
[security.tls]
enabled = true

[extensions.jwt-auth]
enabled = true

[extensions.rate-limit]
enabled = true
requests_per_second = 10000

# Banking plugin
[[plugins]]
id = "banking-kyc"
enabled = true
name = "KYC/AML"
source = "plugin-marketplace://obinexus/banking-kyc:1.0.0"
```

---

## Migration from Old Config Files

**Old approach** (three separate files):
- `.polycallrc` (per-binding config)
- `config.polycall` (server config)
- Environment variables (scattered)

**New approach** (single Polycallfile):
- `Polycallfile.xml` or `Polycallfile.toml` (everything)
- Single source of truth
- Validated against schema
- Environment-aware

**Migration steps**:
```bash
# 1. Export old configuration
polycall export-legacy > old-config.json

# 2. Convert to Polycallfile
polycall convert-legacy old-config.json -o Polycallfile.toml

# 3. Validate new configuration
polycall validate Polycallfile.toml

# 4. Test with dry-run
polycall -f Polycallfile.toml --dry-run

# 5. Start with new configuration
polycall -f Polycallfile.toml
```

---

## Troubleshooting

### "Polycallfile not found"
```bash
# Ensure file exists in current directory
ls -la Polycallfile.*

# Or specify full path
polycall -f /full/path/to/Polycallfile.toml
```

### "Invalid configuration"
```bash
# Validate against schema
polycall validate Polycallfile.toml

# Show detailed error
polycall validate Polycallfile.toml --verbose
```

### "Binding not found"
```bash
# List available bindings
polycall bindings list

# Check if binding is installed
polycall bindings status node-polycall
```

### "Driver connection failed"
```bash
# Test driver connection
polycall drivers test postgres

# Check driver status
polycall drivers status postgres --verbose
```

---

## Next Steps

1. **Copy example**: `cp examples/Polycallfile.toml ./Polycallfile.toml`
2. **Customize** for your environment
3. **Validate**: `polycall validate Polycallfile.toml`
4. **Start**: `polycall -f Polycallfile.toml`
5. **Monitor**: `polycall logs follow`

---

## Documentation Links

- **Full Specification**: [POLYCALLFILE_SPECIFICATION.md](./POLYCALLFILE_SPECIFICATION.md)
- **XSD Schema**: [schema/Polycallfile.xsd](./schema/Polycallfile.xsd)
- **API Reference**: [docs/API.md](./docs/API.md)
- **Examples**: [examples/](./examples/)

---

## Support

For issues, questions, or contributions:
- **GitHub Issues**: https://github.com/obinexus/libpolycall-v1/issues
- **Email**: nnamdi@obinexuscomputing.com
- **Documentation**: https://docs.obinexuscomputing.com/libpolycall

---

**Version**: 2.0.0
**Last Updated**: March 7, 2026
**Maintained by**: OBINexusComputing
