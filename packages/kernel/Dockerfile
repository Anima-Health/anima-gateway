# Multi-stage build for optimized Rust binary
FROM rust:latest as builder

# Install dependencies
RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Create app directory
WORKDIR /app

# Copy all source files
COPY . .

# Build release binary
RUN cargo build --release --bin api

# Runtime stage
FROM debian:bookworm-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    libssl3 \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -m -u 1000 anima && mkdir -p /app && chown -R anima:anima /app

WORKDIR /app

# Copy binary from builder
COPY --from=builder /app/target/release/api ./anima-kernel

# Copy static files
COPY web-folder ./web-folder

# Copy .env template
RUN echo "PORT=8080\nREDUCT_TOKEN=" > .env

# Switch to non-root user
USER anima

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Run the application
CMD ["./anima-kernel"]
