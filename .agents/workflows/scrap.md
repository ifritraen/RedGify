---
description: Start ultra-token-efficient, high-fidelity web scraping or selector prototyping using the local Scrapling CLI.
---
When the user executes `/scrap` or requests a website scrape:

1. **Token-Efficient Extraction via Scrapling CLI**:
   - Immediately execute a local terminal command using the `scrapling extract` command to retrieve the target data.
   - For simple HTTP extraction:
     `scrapling extract get "<URL>" --selector "<SELECTOR>"`
   - For dynamically rendered pages or anti-bot/Cloudflare bypassed pages, use `fetch` or `stealthy-fetch`:
     `scrapling extract stealthy-fetch "<URL>" --selector "<SELECTOR>"`
   - Never load raw HTML source files directly into the AI context. Always use Scrapling locally to extract the target data first to conserve token quota.

2. **Verify & Prototype**:
   - Ensure the command execution yields accurate elements. If needed, refine selectors and re-run the CLI tool locally.

3. **Adapt to Workspace Architecture**:
   - Locate the project language (e.g. Python, Node.js, Dart/Flutter) and integrate these verified selectors into the project's native file architecture (e.g. creating scraping classes, API parsers, or service models).

4. **Return Results Concisely**:
   - Output the extracted data in a clean, compact markdown table or list, alongside a brief snippet of the implemented code.
