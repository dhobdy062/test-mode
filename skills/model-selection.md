# Model Selection & Task Tool

## Multi-Provider Support (v5.0.0)

Loki Mode supports three AI providers. Claude has full features; Codex and Gemini run in **degraded mode** (sequential execution only, no Task tool, no parallel agents).

| Provider | Full Features | Degraded | CLI Flag |
|----------|---------------|----------|----------|
| **Claude Code** | Yes | No | `--provider claude` (default) |
| **OpenAI Codex CLI** | No | Yes | `--provider codex` |
| **Google Gemini CLI** | No | Yes | `--provider gemini` |

**Degraded mode limitations:**
- No Task tool (cannot spawn subagents)
- No parallel execution (sequential RARV cycle only)
- No MCP server integration
- Single model with parameter adjustment (effort/thinking level)

---

## Abstract Model Tiers

| Tier | Purpose | Claude | Codex | Gemini |
|------|---------|--------|-------|--------|
| **planning** | PRD analysis, architecture, system design | opus | effort=xhigh | thinking=high |
| **development** | Feature implementation, complex bugs, tests | sonnet | effort=high | thinking=medium |
| **fast** | Unit tests, docs, linting, simple tasks | haiku | effort=low | thinking=low |

---

## Model Selection by SDLC Phase

| Tier | SDLC Phases | Examples |
|------|-------------|----------|
| **planning** | Bootstrap, Discovery, Architecture | PRD analysis, system design, technology selection, API contracts |
| **development** | Development, QA, Deployment | Feature implementation, complex bugs, integration/E2E tests, code review, deployment |
| **fast** | All other operations (parallel for Claude) | Unit tests, docs, bash commands, linting, monitoring |

**Claude-specific model names:** opus, sonnet, haiku
**Codex effort levels:** xhigh, high, medium, low
**Gemini thinking levels:** high, medium, low

## Task Tool Examples (Claude Only)

**NOTE:** Task tool is Claude-specific. Codex and Gemini run in degraded mode without subagents.

```python
# Planning tier (opus) for Bootstrap, Discovery, Architecture
Task(subagent_type="Plan", model="opus", description="Design system architecture", prompt="...")
Task(subagent_type="Plan", model="opus", description="Analyze PRD requirements", prompt="...")

# Development tier (sonnet) for Development, QA, and Deployment
Task(subagent_type="general-purpose", model="sonnet", description="Implement API endpoint", prompt="...")
Task(subagent_type="general-purpose", model="sonnet", description="Write integration tests", prompt="...")
Task(subagent_type="general-purpose", model="sonnet", description="Deploy to production", prompt="...")

# Fast tier (haiku) for everything else (PREFER for parallelization)
Task(subagent_type="general-purpose", model="haiku", description="Run unit tests", prompt="...")
Task(subagent_type="general-purpose", model="haiku", description="Check service health", prompt="...")
```

### Provider Detection in Code

```bash
# In run.sh, check provider before using Task tool
if [ "${PROVIDER_HAS_TASK_TOOL:-false}" = "true" ]; then
    # Claude: Use Task tool with parallel agents
    Task(model="haiku", description="Run tests", prompt="...")
else
    # Codex/Gemini: Run sequentially without subagents
    # Execute RARV cycle in main thread
fi
```

## Task Categories

**Opus (Bootstrap -> Architecture - Planning ONLY):**
- Bootstrap: Project setup, dependency analysis, environment configuration
- Discovery: PRD analysis, requirement extraction, gap identification
- Architecture: System design, technology selection, schema design, API contracts

**Sonnet (Development -> Deployment):**
- Development: Feature implementation, API endpoints, complex bug fixes, database migrations
- QA: Integration tests, E2E tests, security scanning, performance testing, code review
- Deployment: Release automation, infrastructure provisioning, monitoring setup

**Haiku (Operations - Use Extensively in Parallel):**
- Writing/running unit tests
- Generating documentation
- Running bash commands (npm install, git operations)
- Simple bug fixes (typos, imports, formatting)
- File operations, linting, static analysis
- Monitoring, health checks, log analysis

## Parallelization Strategy (Claude Only)

**NOTE:** Parallelization requires Task tool, which is Claude-specific. Codex and Gemini run sequentially.

```python
# Claude: Launch 10+ Haiku agents in parallel for unit test suite
for test_file in test_files:
    Task(subagent_type="general-purpose", model="haiku",
         description=f"Run unit tests: {test_file}",
         run_in_background=True)

# Codex/Gemini: Run tests sequentially (no parallelization)
for test_file in test_files:
    run_test(test_file)  # Sequential execution
```

## Extended Thinking Mode

**Use thinking prefixes for complex planning:**

| Prefix | When to Use | Example |
|--------|-------------|---------|
| `"think"` | Standard planning | Architecture outlines, feature scoping |
| `"think hard"` | Complex decisions | System design, trade-off analysis |
| `"ultrathink"` | Critical/ambiguous | Multi-service architecture, security design |

```python
Task(
    subagent_type="Plan",
    model="opus",
    description="Design auth architecture",
    prompt="think hard about the authentication architecture. Consider OAuth vs JWT..."
)
```

**When to use:** Discovery, Architecture, Critical decisions
**When NOT to use:** Haiku tasks, repetitive work, obvious implementations

## Prompt Repetition for Haiku

**For Haiku on structured tasks, repeat prompts 2x to improve accuracy 4-5x.**

```python
base_prompt = "Run unit tests in tests/ directory and report results"
repeated_prompt = f"{base_prompt}\n\n{base_prompt}"  # 2x repetition
Task(model="haiku", description="Run unit tests", prompt=repeated_prompt)
```

**Research:** Accuracy improves from 21.33% to 97.33% (arXiv 2512.14982v1)

**When to apply:** Unit tests, linting, parsing, list operations
**When NOT to apply:** Opus/Sonnet, creative tasks, complex reasoning

## Advanced Parameters

**Background Agents:**
```python
Task(description="Long analysis task", run_in_background=True, prompt="...")
# Returns immediately with output_file path
```

**Agent Resumption:**
```python
result = Task(description="Complex refactor", prompt="...")
# Later: resume with agent_id
Task(resume="agent-abc123", prompt="Continue from where you left off")
```

## Confidence-Based Routing

| Confidence | Tier | Behavior |
|------------|------|----------|
| >= 0.95 | Auto-Approve | Direct execution, no review |
| 0.70-0.95 | Direct + Review | Execute then validate |
| 0.40-0.70 | Supervisor Mode | Full coordination with review |
| < 0.40 | Human Escalation | Too uncertain |

```python
# Simple tasks -> Direct dispatch to Haiku
Task(model="haiku", description="Fix import in utils.py", prompt="...")

# Complex tasks -> Supervisor orchestration
Task(description="Implement user authentication with OAuth", prompt="...")
```
