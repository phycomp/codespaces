# Rakazo on GitHub Codespaces

Deploy [Rakazo](https://rakazo.com) — an open-source, self-hosted AI agent platform — in GitHub Codespaces.

## What is Rakazo?

Rakazo is a platform for running persistent AI teammates (bots) with their own memory, routines, and computer access. Each bot can use a browser, terminal, and files. Run it with any model (OpenAI, Anthropic, OpenRouter, Ollama, etc.).

## Quick Start

1. **Create a Codespace** from this repository (use 4+ cores, 8GB+ RAM)
2. The setup script runs automatically and configures Rakazo
3. Set your model provider API key in `rakazo/.env`
4. Start Rakazo:
   ```bash
   cd rakazo && bash install-images.sh
   ```
5. Open the forwarded port 5173 in your browser
6. Register the first account (becomes deployment owner)

## Requirements

- GitHub Codespaces with **4+ CPUs** and **8GB+ RAM** (recommended)
- A model provider API key (OpenRouter, OpenAI, Anthropic, etc.)
- Docker-in-Docker is configured automatically via devcontainer features

## Configuration

### Model Provider

Set one of these in `rakazo/.env`:
- `OPENROUTER_API_KEY` — OpenRouter (supports many models)
- `OPENAI_API_KEY` — OpenAI
- `ANTHROPIC_API_KEY` — Anthropic

Or connect a model in the Rakazo UI after signup.

### Sandbox Provider

In Codespaces, Docker (via DinD) is used by default. Bot computers run as containers within the Codespace.

### Resource Limits

Adjust in `rakazo/.env`:
- `RAKAZO_COMPUTER_MEMORY` — Memory per computer (default: 2g)
- `RAKAZO_COMPUTER_CPUS` — CPUs per computer (default: 2)
- `SANDBOX_IDLE_MS` — Idle timeout before pausing (default: 0 = never in Codespaces)

## Architecture

```
Codespace Container (Docker-in-Docker)
├── Rakazo Web (port 5173)
├── Rakazo API (port 3100, internal)
├── Rakazo Worker (background)
├── PostgreSQL 18
└── Bot Computers (Docker containers)
```

## Troubleshooting

- **Docker not available**: Ensure the Codespace was created with the devcontainer config in `.devcontainer/`
- **Port not accessible**: Check the "Ports" tab in VS Code and ensure port 5173 is forwarded
- **Out of memory**: Increase Codespace machine size or reduce `RAKAZO_COMPUTER_MEMORY`
- **Setup failed**: Re-run `bash scripts/setup-rakazo.sh`

## Links

- [Rakazo Website](https://rakazo.com)
- [Rakazo Docs](https://rakazo.com/docs/)
- [Rakazo GitHub](https://github.com/elie222/rakazo)
- [Rakazo Self-Hosting Guide](https://rakazo.com/docs/self-host/)
