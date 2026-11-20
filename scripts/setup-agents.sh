#!/usr/bin/env bash
set -euo pipefail

echo "=== Setting up Router+Workers agents ==="

# Copy OpenCode agent configuration
if [ -f opencode.jsonc ]; then
  mkdir -p ~/.config/opencode
  cp opencode.jsonc ~/.config/opencode/opencode.jsonc
  echo "OpenCode agent config installed to ~/.config/opencode/opencode.jsonc"
fi

# Verify agents are configured
if command -v opencode &>/dev/null; then
  echo ""
  echo "Configured agents:"
  opencode models 2>/dev/null | head -5 || echo "(opencode not available in this context)"
fi

echo ""
echo "=== Agent setup complete ==="
echo "Agents: router, planner, coder, reviewer"
echo "Router is the primary agent (default_agent: router)"
echo ""
echo "Usage:"
echo "  opencode                    # Start with router as default"
echo "  @planner <task>            # Delegate to planner"
echo "  @coder <task>              # Delegate to coder"
echo "  @reviewer <task>           # Delegate to reviewer"
