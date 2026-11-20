#!/usr/bin/env bash
set -euo pipefail

echo "=== Setting up Rakazo in Codespaces ==="

# Ensure Docker is available
if ! command -v docker &>/dev/null; then
  echo "ERROR: Docker not found. Ensure docker-in-docker feature is enabled."
  exit 1
fi

# Wait for Docker daemon
echo "Waiting for Docker daemon..."
for i in $(seq 1 30); do
  if docker info &>/dev/null; then
    break
  fi
  sleep 2
done

if ! docker info &>/dev/null; then
  echo "ERROR: Docker daemon not ready after 60s"
  exit 1
fi

echo "Docker is ready."

# Create Rakazo directory
mkdir -p rakazo
cd rakazo

# Download and run installer (prepare-only so we can customize .env)
if [ ! -f .env ]; then
  echo "Downloading Rakazo installer..."
  curl -fsSLO https://raw.githubusercontent.com/elie222/rakazo/main/infra/compose/install-images.sh
  bash install-images.sh --prepare-only
fi

# Configure .env for Codespaces
echo "Configuring .env for Codespaces..."

# Generate secrets if not already set
if grep -q 'BETTER_AUTH_SECRET=""' .env 2>/dev/null || ! grep -q 'BETTER_AUTH_SECRET' .env; then
  sed -i "s|BETTER_AUTH_SECRET=.*|BETTER_AUTH_SECRET=$(openssl rand -hex 32)|" .env
fi
if grep -q 'ENCRYPTION_KEY=""' .env 2>/dev/null || ! grep -q 'ENCRYPTION_KEY' .env; then
  sed -i "s|ENCRYPTION_KEY=.*|ENCRYPTION_KEY=$(openssl rand -hex 32)|" .env
fi
if grep -q 'SCREEN_PROXY_SECRET=""' .env 2>/dev/null || ! grep -q 'SCREEN_PROXY_SECRET' .env; then
  sed -i "s|SCREEN_PROXY_SECRET=.*|SCREEN_PROXY_SECRET=$(openssl rand -hex 32)|" .env
fi
if grep -q 'SANDBOX_SUPERVISOR_TOKEN=""' .env 2>/dev/null || ! grep -q 'SANDBOX_SUPERVISOR_TOKEN' .env; then
  sed -i "s|SANDBOX_SUPERVISOR_TOKEN=.*|SANDBOX_SUPERVISOR_TOKEN=$(openssl rand -hex 32)|" .env
fi

# Set Codespaces-specific values
# Use Docker sandbox provider (available in Codespaces via DinD)
sed -i 's|^SANDBOX_PROVIDER=.*|SANDBOX_PROVIDER=docker|' .env

# Disable idle sleep in Codespaces (containers are ephemeral anyway)
sed -i 's|^SANDBOX_IDLE_MS=.*|SANDBOX_IDLE_MS=0|' .env

# Set memory limits appropriate for Codespaces
sed -i 's|^RAKAZO_COMPUTER_MEMORY=.*|RAKAZO_COMPUTER_MEMORY=2g|' .env
sed -i 's|^RAKAZO_COMPUTER_CPUS=.*|RAKAZO_COMPUTER_CPUS=2|' .env

# Set public origins to Codespaces forwarded URL
# Codespaces URL pattern: https://<name>-5173.app.github.dev
CODESPACE_NAME="${CODESPACE_NAME:-codespace}"
FORWARDED_URL="https://${CODESPACE_NAME}-5173.app.github.dev"
sed -i "s|^BETTER_AUTH_URL=.*|BETTER_AUTH_URL=${FORWARDED_URL}|" .env
sed -i "s|^WEB_ORIGIN=.*|WEB_ORIGIN=${FORWARDED_URL}|" .env
sed -i "s|^API_URL=.*|API_URL=${FORWARDED_URL}|" .env
sed -i "s|^RAKAZO_HOST=.*|RAKAZO_HOST=${CODESPACE_NAME}-5173.app.github.dev|" .env

echo ""
echo "=== Rakazo setup complete ==="
echo "Web UI will be available at: ${FORWARDED_URL}"
echo ""
echo "To start Rakazo:"
echo "  cd rakazo && bash install-images.sh"
echo ""
echo "Or to start manually:"
echo "  cd rakazo && docker compose --env-file .env -f infra/compose/docker-compose.images.yml up -d"
echo ""
echo "NOTE: Set OPENROUTER_API_KEY or another model provider key in rakazo/.env"
echo "      before starting, or connect a model in the UI after signup."
