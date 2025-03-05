FROM golang:1.22-alpine

WORKDIR /app

<<<<<<< HEAD
# Install build dependencies
RUN apk add --no-cache git

# Copy Go module files first for better caching
COPY go.* ./
RUN go mod download || echo "Warning: go mod download failed"
=======
# Install necessary tools
RUN apk add --no-cache curl git

# Copy Go module files first for better caching
COPY go.* ./
RUN go mod download || echo "No dependencies to download"
>>>>>>> 9e30e5b76e4d65b3a636a903fea9283ea412735f

# Copy the rest of the application
COPY . .

<<<<<<< HEAD
# Check if server.go exists and print directory contents
RUN ls -la
RUN if [ -f server.go ]; then echo "server.go exists"; else echo "server.go does not exist!"; fi

# Attempt build with verbose output
RUN go build -v -o server server.go || (echo "BUILD FAILED!" && exit 1)

EXPOSE 8080

=======
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
>>>>>>> 9e30e5b76e4d65b3a636a903fea9283ea412735f
CMD ["./server"]