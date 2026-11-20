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
- `OPENCODE_GO_API_KEY` — OpenCode Go (OpenAI-compatible, see below)

Or connect a model in the Rakazo UI after signup.

### OpenCode Go (本機 opencode 對接)

OpenCode Go 提供 OpenAI 相容的 API 端點，可直接與 Rakazo 對接：

1. **取得 API Key**：前往 [OpenCode Console](https://opencode.ai/console) → API Keys
2. **設定環境變數**：在 `rakazo/.env` 中加入：
   ```
   OPENCODE_GO_API_KEY=oc_sk_...
   ```
3. **在 Rakazo UI 中新增自訂 Provider**：
   - Provider 類型：OpenAI Compatible
   - Base URL：`https://opencode.ai/inference/openai/v1`
   - API Key：你的 `OPENCODE_GO_API_KEY`
   - Model ID：`deepseek-v4.1-flash`（或其他可用模型）
4. **可用模型**：
   - `deepseek-v4.1-flash` — DeepSeek V4.1 Flash（快速、低成本）
   - 其他模型請參考 [OpenCode Console Models](https://opencode.ai/docs/console/models)

> **注意**：OpenCode Go 的 API Key 格式為 `oc_sk_...`，與 OpenCode Console 的 key 不同。
> OpenCode Go 是訂閱制（含用量），適合需要穩定模型存取的場景。

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

## Multi-Agent Setup (Router + Workers)

This repository includes a pre-configured 4-agent architecture:

| Agent | Role | Permissions |
|-------|------|-------------|
| **Router** | Routes tasks to workers | read, search, subagent |
| **Planner** | Explores and plans | read, search, web |
| **Coder** | Implements code | read, edit, shell |
| **Reviewer** | Reviews code quality | read, search |

### Configuration

The agent configuration is in `opencode.jsonc`. It is automatically installed
to `~/.config/opencode/opencode.jsonc` during Codespace creation.

### Usage

```bash
# Start OpenCode with Router as default agent
opencode

# Delegate to specific workers
@planner "Plan the implementation of user authentication"
@coder "Implement the auth module based on the plan"
@reviewer "Review the auth implementation"
```

### Delegation Flow

```
User → Router → @Planner → Plan → Router
                    → @Coder → Implement → Router
                    → @Reviewer → Review → Router
                         → Summary → User
```

For detailed agent setup instructions, see the `mnpl-rakazo` and `mnpl-agent` skills.
