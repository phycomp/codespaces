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
ensure_secret() {
  local key="$1"
  local val
  val=$(grep "^${key}=" .env 2>/dev/null | cut -d= -f2- | tr -d '"' || true)
  if [ -z "$val" ]; then
    local newval
    newval=$(openssl rand -hex 32)
    if grep -q "^${key}=" .env 2>/dev/null; then
      sed -i "s|^${key}=.*|${key}=${newval}|" .env
    else
      echo "${key}=${newval}" >> .env
    fi
  fi
}

ensure_secret "BETTER_AUTH_SECRET"
ensure_secret "ENCRYPTION_KEY"
ensure_secret "SCREEN_PROXY_SECRET"
ensure_secret "SANDBOX_SUPERVISOR_TOKEN"

# Set Codespaces-specific values
# Use Docker sandbox provider (available in Codespaces via DinD)
if grep -q "^SANDBOX_PROVIDER=" .env; then
  sed -i 's|^SANDBOX_PROVIDER=.*|SANDBOX_PROVIDER=docker|' .env
else
  echo "SANDBOX_PROVIDER=docker" >> .env
fi

# Disable idle sleep in Codespaces
if grep -q "^SANDBOX_IDLE_MS=" .env; then
  sed -i 's|^SANDBOX_IDLE_MS=.*|SANDBOX_IDLE_MS=0|' .env
else
  echo "SANDBOX_IDLE_MS=0" >> .env
fi

# Set memory limits appropriate for Codespaces
if grep -q "^RAKAZO_COMPUTER_MEMORY=" .env; then
  sed -i 's|^RAKAZO_COMPUTER_MEMORY=.*|RAKAZO_COMPUTER_MEMORY=2g|' .env
else
  echo "RAKAZO_COMPUTER_MEMORY=2g" >> .env
fi
if grep -q "^RAKAZO_COMPUTER_CPUS=" .env; then
  sed -i 's|^RAKAZO_COMPUTER_CPUS=.*|RAKAZO_COMPUTER_CPUS=2|' .env
else
  echo "RAKAZO_COMPUTER_CPUS=2" >> .env
fi

# Set public origins to Codespaces forwarded URL
CODESPACE_NAME="${CODESPACE_NAME:-codespace}"
FORWARDED_URL="https://${CODESPACE_NAME}-5173.app.github.dev"
for key in BETTER_AUTH_URL WEB_ORIGIN API_URL; do
  if grep -q "^${key}=" .env; then
    sed -i "s|^${key}=.*|${key}=${FORWARDED_URL}|" .env
  else
    echo "${key}=${FORWARDED_URL}" >> .env
  fi
done
if grep -q "^RAKAZO_HOST=" .env; then
  sed -i "s|^RAKAZO_HOST=.*|RAKAZO_HOST=${CODESPACE_NAME}-5173.app.github.dev|" .env
else
  echo "RAKAZO_HOST=${CODESPACE_NAME}-5173.app.github.dev" >> .env
fi

# === OpenCode Go Model Configuration ===
# OpenCode Go provides an OpenAI-compatible API at:
#   https://opencode.ai/inference/openai/v1/chat/completions
# Set OPENCODE_GO_API_KEY to enable OpenCode Go as a model provider.
echo ""
echo "=== OpenCode Go Model Setup ==="
echo "To use OpenCode Go models with Rakazo:"
echo "  1. Get your API key from https://opencode.ai/console"
echo "  2. Set OPENCODE_GO_API_KEY in rakazo/.env"
echo "  3. In Rakazo UI, add a custom OpenAI-compatible provider:"
echo "     Base URL: https://opencode.ai/inference/openai/v1"
echo "     API Key:  (your OPENCODE_GO_API_KEY)"
echo "     Model:    deepseek-v4.1-flash (or other available model)"
echo ""
# If OPENCODE_GO_API_KEY is already set in environment, write it to .env
if [ -n "${OPENCODE_GO_API_KEY:-}" ]; then
  if grep -q "^OPENCODE_GO_API_KEY=" .env; then
    sed -i "s|^OPENCODE_GO_API_KEY=.*|OPENCODE_GO_API_KEY=${OPENCODE_GO_API_KEY}|" .env
  else
    echo "OPENCODE_GO_API_KEY=${OPENCODE_GO_API_KEY}" >> .env
  fi
  echo "OPENCODE_GO_API_KEY configured from environment."
fi

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
echo "Model providers (set one in rakazo/.env):"
echo "  - OPENROUTER_API_KEY  (OpenRouter - supports many models)"
echo "  - OPENAI_API_KEY      (OpenAI)"
echo "  - ANTHROPIC_API_KEY   (Anthropic)"
echo "  - OPENCODE_GO_API_KEY (OpenCode Go - OpenAI-compatible)"
echo "  Or connect a model in the Rakazo UI after signup."
