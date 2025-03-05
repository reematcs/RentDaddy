FROM node:18-alpine

WORKDIR /app

# Check if package.json exists
COPY . .

# Install dependencies if package.json exists
RUN if [ -f package.json ]; then \
    npm install; \
    else \
    echo "package.json not found, creating minimal package"; \
    echo '{"name":"frontend","version":"1.0.0","scripts":{"dev":"echo \"No package.json found, create one or run npm init\" && exit 1"}}' > package.json; \
    npm install; \
    fi

EXPOSE 5173

# Start development server if possible, otherwise show message
CMD ["sh", "-c", "if grep -q 'dev' package.json; then npm run dev -- --host 0.0.0.0; else echo 'No dev script found. Please configure package.json'; fi"]