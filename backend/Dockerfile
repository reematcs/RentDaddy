FROM golang:1.22-alpine

WORKDIR /app

# Install necessary tools
RUN apk add --no-cache curl git

# Copy Go module files first for better caching
COPY go.* ./
RUN go mod download || echo "No dependencies to download"

# Copy the rest of the application
COPY . .

# Build with explicit error checking
RUN if [ -f server.go ]; then \
    echo "Building server..." && \
    go build -o server server.go && \
    echo "Build successful"; \
    else \
    echo "Error: server.go not found" && exit 1; \
    fi

EXPOSE 8080

# Use the executable directly (will fail clearly if missing)
CMD ["./server"]