# Guideline Plugin

The **Guideline** plugin consolidates core engineering and design principles into a single location for software development and design standardization.

## Included Skills

### 1. `karpathy` (`/guideline:karpathy`)
* **Description**: Andrej Karpathy's 11 practical coding principles to mitigate LLM hallucinations and standard developer mistakes.
* **Usage**: Proactively load Andrej Karpathy's verbatim guidelines into your session context before starting any active coding, code generation, or heavy debugging.
* **Keywords**: "Karpathy 가이드라인", "코딩 가이드라인"

### 2. `restful-api` (`/guideline:restful-api`)
* **Description**: Industry-standard RESTful API design rules covering URL paths, HTTP methods, status codes, standard headers, and security practices.
* **Usage**: Execute this skill when designing new web APIs, generating endpoints, or performing architecture reviews on backend microservices.
* **Keywords**: "REST API 설계", "REST API 리뷰", "API 가이드라인"

---

## Installation & Configuration

No manual installation is required. The plugin is auto-discovered per `.claude-plugin/marketplace.json`.

```bash
# Example skill invocations (in Claude Code/Gemini CLI)
/guideline:karpathy
/guideline:restful-api
```
