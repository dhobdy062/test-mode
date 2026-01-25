#!/bin/bash
# OpenAI Codex CLI Provider Configuration
# Shell-sourceable config for loki-mode multi-provider support

# Provider Functions (for external use)
# =====================================
# These functions provide a clean interface for external scripts:
#   provider_detect()           - Check if CLI is installed
#   provider_version()          - Get CLI version
#   provider_invoke()           - Invoke with prompt (autonomous mode)
#   provider_invoke_with_tier() - Invoke with tier-specific effort level
#   provider_get_tier_param()   - Map tier name to effort level
#
# Usage:
#   source providers/codex.sh
#   if provider_detect; then
#       provider_invoke "Your prompt here"
#   fi
#
# Note: autonomy/run.sh uses inline invocation for streaming support
# and real-time agent tracking. These functions are intended for
# simpler scripts, wrappers, and external integrations.
# =====================================

# Provider Identity
PROVIDER_NAME="codex"
PROVIDER_DISPLAY_NAME="OpenAI Codex CLI"
PROVIDER_CLI="codex"

# CLI Invocation
# Note: codex uses positional prompt after "exec" subcommand
# VERIFIED: exec --dangerously-bypass-approvals-and-sandbox confirmed in codex exec --help (v0.89.0)
# "Skip all confirmation prompts and execute commands without sandboxing. EXTREMELY DANGEROUS."
PROVIDER_AUTONOMOUS_FLAG="exec --dangerously-bypass-approvals-and-sandbox"
PROVIDER_PROMPT_FLAG=""
PROVIDER_PROMPT_POSITIONAL=true

# Skill System
# Note: Codex CLI does not have a native skills system
PROVIDER_SKILL_DIR=""
PROVIDER_SKILL_FORMAT="none"

# Capability Flags
PROVIDER_HAS_SUBAGENTS=false
PROVIDER_HAS_PARALLEL=false
PROVIDER_HAS_TASK_TOOL=false
PROVIDER_HAS_MCP=false
PROVIDER_MAX_PARALLEL=1

# Model Configuration
# Codex uses single model with effort parameter
# NOTE: "gpt-5.2-codex" is a PLACEHOLDER model name. Update this value when
# official Codex CLI documentation specifies the actual model identifier.
PROVIDER_MODEL_PLANNING="gpt-5.2-codex"
PROVIDER_MODEL_DEVELOPMENT="gpt-5.2-codex"
PROVIDER_MODEL_FAST="gpt-5.2-codex"

# Effort levels (Codex-specific: maps to reasoning time, not model capability)
PROVIDER_EFFORT_PLANNING="xhigh"
PROVIDER_EFFORT_DEVELOPMENT="high"
PROVIDER_EFFORT_FAST="low"

# No Task tool - effort is set via CLI flag
PROVIDER_TASK_MODEL_PARAM=""
PROVIDER_TASK_MODEL_VALUES=()

# Context and Limits
PROVIDER_CONTEXT_WINDOW=128000
PROVIDER_MAX_OUTPUT_TOKENS=32000
PROVIDER_RATE_LIMIT_RPM=60

# Cost (USD per 1K tokens, approximate for GPT-5.2)
PROVIDER_COST_INPUT_PLANNING=0.010
PROVIDER_COST_OUTPUT_PLANNING=0.030
PROVIDER_COST_INPUT_DEV=0.010
PROVIDER_COST_OUTPUT_DEV=0.030
PROVIDER_COST_INPUT_FAST=0.010
PROVIDER_COST_OUTPUT_FAST=0.030

# Degraded Mode
PROVIDER_DEGRADED=true
PROVIDER_DEGRADED_REASONS=(
    "No Task tool subagent support - cannot spawn parallel agents"
    "Single model with effort parameter - no cheap tier for parallelization"
    "No native skills system - SKILL.md must be passed via prompt"
    "No MCP server integration"
)

# Detection function - check if provider CLI is available
provider_detect() {
    command -v codex >/dev/null 2>&1
}

# Version check function
provider_version() {
    codex --version 2>/dev/null | head -1
}

# Invocation function
# Note: Codex uses positional prompt, not -p flag
# Note: Reasoning effort is configured via environment or config, not CLI flag
provider_invoke() {
    local prompt="$1"
    shift
    codex exec --dangerously-bypass-approvals-and-sandbox "$prompt" "$@"
}

# Model tier to effort level parameter (Codex uses effort, not separate models)
provider_get_tier_param() {
    local tier="$1"
    case "$tier" in
        planning) echo "xhigh" ;;
        development) echo "high" ;;
        fast) echo "low" ;;
        *) echo "high" ;;  # default to development tier
    esac
}

# Tier-aware invocation
# Note: Codex CLI does not support effort CLI flags
# Effort must be configured via environment: CODEX_MODEL_REASONING_EFFORT
# This function sets the env var before invocation
provider_invoke_with_tier() {
    local tier="$1"
    local prompt="$2"
    shift 2
    local effort
    effort=$(provider_get_tier_param "$tier")
    CODEX_MODEL_REASONING_EFFORT="$effort" codex exec --dangerously-bypass-approvals-and-sandbox "$prompt" "$@"
}
