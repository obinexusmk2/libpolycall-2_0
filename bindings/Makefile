# bindings/Makefile - Build all language bindings
# Normally invoked via the top-level Makefile.

.PHONY: all node go java rust clean

all: node go java rust

node:
	@echo "=== Node.js binding ==="
	@if [ -f node/package.json ]; then cd node && npm install --production; fi

go:
	@echo "=== Go binding ==="
	@if [ -f go/go.mod ]; then cd go && go build ./...; fi

java:
	@echo "=== Java binding ==="
	@if [ -f java/pom.xml ]; then cd java && mvn package -DskipTests -q; fi

rust:
	@echo "=== Rust SemVerX ==="
	@if [ -f rust-semverx/Cargo.toml ]; then cd rust-semverx && cargo build --release; fi

clean:
	cd node && rm -rf node_modules 2>/dev/null || true
	cd java && mvn clean -q 2>/dev/null || true
	cd rust-semverx && cargo clean 2>/dev/null || true
