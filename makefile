# Go parameters
BINARY_NAME=openwechat
MAIN_PACKAGE=./cmd/main.go
GO=go

# Build directory
BUILD_DIR=build

# Version and build information
VERSION?=1.0.0
BUILD_DATE=$(shell date +%Y-%m-%d-%H:%M:%S)
COMMIT_HASH=$(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")

# Build flags
LDFLAGS=-ldflags "-X main.Version=${VERSION} -X main.BuildDate=${BUILD_DATE} -X main.CommitHash=${COMMIT_HASH}"

# Platform specific configurations
LINUX_ARCHS=amd64 arm64
WINDOWS_ARCHS=amd64 386
DARWIN_ARCHS=amd64 arm64

# Deploy configurations
# Default values (can be overridden via environment variables)
DEPLOY_USER?=root
DEPLOY_HOST?=123.60.183.5
DEPLOY_PATH?=/root
DEPLOY_PORT?=22
DEPLOY_ARCH?=amd64
DEPLOY_OS?=linux

# Make sure required directories exist
$(shell mkdir -p ${BUILD_DIR})

.PHONY: all clean build linux windows darwin deploy help

all: clean linux windows darwin

# Build for current platform
build:
	@echo "Building for current platform..."
	@${GO} build ${LDFLAGS} -o ${BUILD_DIR}/${BINARY_NAME} ${MAIN_PACKAGE}
	@echo "✅ Build complete: ${BUILD_DIR}/${BINARY_NAME}"

# Build for Linux
linux:
	@echo "🐧 Building for Linux..."
	@for arch in ${LINUX_ARCHS}; do \
		echo "  → Building for linux/$$arch..."; \
		GOOS=linux GOARCH=$$arch ${GO} build ${LDFLAGS} \
			-o ${BUILD_DIR}/${BINARY_NAME}-linux-$$arch ${MAIN_PACKAGE}; \
		echo "    ✓ Completed ${BINARY_NAME}-linux-$$arch"; \
	done
	@echo "✅ Linux builds complete!"

# Build for Windows
windows:
	@echo "🪟 Building for Windows..."
	@for arch in ${WINDOWS_ARCHS}; do \
		echo "  → Building for windows/$$arch..."; \
		GOOS=windows GOARCH=$$arch ${GO} build ${LDFLAGS} \
			-o ${BUILD_DIR}/${BINARY_NAME}-windows-$$arch.exe ${MAIN_PACKAGE}; \
		echo "    ✓ Completed ${BINARY_NAME}-windows-$$arch.exe"; \
	done
	@echo "✅ Windows builds complete!"

# Build for macOS
darwin:
	@echo "🍎 Building for macOS..."
	@for arch in ${DARWIN_ARCHS}; do \
		echo "  → Building for darwin/$$arch..."; \
		GOOS=darwin GOARCH=$$arch ${GO} build ${LDFLAGS} \
			-o ${BUILD_DIR}/${BINARY_NAME}-darwin-$$arch ${MAIN_PACKAGE}; \
		echo "    ✓ Completed ${BINARY_NAME}-darwin-$$arch"; \
	done
	@echo "✅ macOS builds complete!"

# Deploy to target machine
deploy: check-deploy-vars
	@echo "🚀 Deploying to ${DEPLOY_HOST}..."
	@echo "  → OS: ${DEPLOY_OS}, Architecture: ${DEPLOY_ARCH}"
	@echo "  → Target path: ${DEPLOY_PATH}"

	@# Create remote directory if it doesn't exist
	@ssh -p ${DEPLOY_PORT} ${DEPLOY_USER}@${DEPLOY_HOST} "mkdir -p ${DEPLOY_PATH}"

	@# Determine the correct binary name based on OS
	$(eval BINARY_SUFFIX := $(if $(filter windows,${DEPLOY_OS}),.exe,))
	$(eval REMOTE_BINARY := ${BINARY_NAME}-${DEPLOY_OS}-${DEPLOY_ARCH}${BINARY_SUFFIX})

	@# Check if the binary exists
	@if [ ! -f "${BUILD_DIR}/${REMOTE_BINARY}" ]; then \
		echo "❌ Binary ${REMOTE_BINARY} not found. Building it first..."; \
		make ${DEPLOY_OS}; \
	fi

	@# Deploy the binary
	@echo "  → Copying binary to target machine..."
	@scp -P ${DEPLOY_PORT} ${BUILD_DIR}/${REMOTE_BINARY} \
		${DEPLOY_USER}@${DEPLOY_HOST}:${DEPLOY_PATH}/${BINARY_NAME}

	@# Set executable permissions
	@ssh -p ${DEPLOY_PORT} ${DEPLOY_USER}@${DEPLOY_HOST} \
		"chmod +x ${DEPLOY_PATH}/${BINARY_NAME}"

	@echo "✅ Deploy complete!"
	@echo "   Binary location: ${DEPLOY_PATH}/${BINARY_NAME}"

# Check required deploy variables
check-deploy-vars:
	@if [ -z "${DEPLOY_HOST}" ]; then \
		echo "❌ Error: DEPLOY_HOST is not set"; \
		exit 1; \
	fi

# Run tests
test:
	@echo "Running tests..."
	@${GO} test -v ./...

# Clean build directory
clean:
	@echo "Cleaning build directory..."
	@rm -rf ${BUILD_DIR}/*
	@echo "✅ Clean complete!"

# Show help
help:
	@echo "Available commands:"
	@echo "  make build    - Build for current platform"
	@echo "  make linux    - Build for Linux (${LINUX_ARCHS})"
	@echo "  make windows  - Build for Windows (${WINDOWS_ARCHS})"
	@echo "  make darwin   - Build for macOS (${DARWIN_ARCHS})"
	@echo "  make all      - Build for all platforms"
	@echo "  make clean    - Clean build directory"
	@echo "  make test     - Run tests"
	@echo "  make deploy   - Deploy to target machine"
	@echo ""
	@echo "Deploy configuration (can be set via environment variables):"
	@echo "  DEPLOY_USER   - Target machine username (default: root)"
	@echo "  DEPLOY_HOST   - Target machine hostname (required)"
	@echo "  DEPLOY_PATH   - Deploy path (default: /opt/myapp)"
	@echo "  DEPLOY_PORT   - SSH port (default: 22)"
	@echo "  DEPLOY_OS     - Target OS (default: linux)"
	@echo "  DEPLOY_ARCH   - Target architecture (default: amd64)"
	@echo ""
	@echo "Example deploy command:"
	@echo "  make deploy DEPLOY_HOST=192.168.1.100 DEPLOY_PATH=/apps/myapp DEPLOY_USER=admin"