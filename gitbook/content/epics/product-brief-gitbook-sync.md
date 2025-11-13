# Product Brief: GitBook Documentation Sync for OmegaOS W3.x

## Overview
**Product Name:** GitBook Integration & Sync Tool  
**Version:** 1.0 Setup (Epic 9 Extension)  
**Target Audience:** Contributors, developers using OmegaOS docs for kernel dev, WEB3.ARL integration.  
**Date:** 2025-11-12  
**Status:** Proposed (Research Complete, Implementation Pending)  

This feature upgrades OmegaOS documentation from static mdBook (book/) to interactive GitBook hosting (gitbook.com), with automated sync via scripts and GitHub CI. Enables searchable, versioned docs for framekernel architecture, OSXDK guides, and WEB3 features, improving contributor onboarding and SEO for production-ready kernel adoption.

## Problem Statement
Current docs are mdBook-generated HTML on GH Pages (via .github/workflows/publish_website.yml), limited to static sites:
- No full-text search or mobile themes, hindering kernel deep-dives (e.g., process/ AR containers).
- Manual updates for book/src/ (rfcs/, kernel/); no auto-sync to hosted platform.
- Poor SEO for "secure Rust kernel WEB3.ARL", missing analytics for Epic 9 (Testing & Docs).
Result: Low contributor engagement; fragmented access to GPU/zk prototypes from Sprint 4.

## Solution
**Core Features:**
- **Source Sync:** rsync book/src/ to gitbook/content/ preserving SUMMARY.md TOC. Script: sync-mdbook-to-gitbook.sh (exclude images/, handle frontmatter tags: gpu, arl).
- **CLI Integration:** @gitbook/cli for build/serve/push. Local preview: gitbook serve (localhost:4000); auth with GITBOOK_TOKEN.
- **CI/CD Automation:** Update publish_website.yml: Add Node.js setup, run sync script, gitbook push on main/PR to book/**. Secrets: GITBOOK_TOKEN, SPACE_ID.
- **GitBook Enhancements:** Interactive sections (WEB3.ARL Guide, GPU Integration); embed diagrams (architecture.md flows); auto-TOC from folders.
- **Hybrid Mode:** Keep mdBook for local (mdbook serve); GitBook for hosted (https://omegaosx.gitbook.io/book/).

**Technical Specs:**
- **Story Points:** 2-3 SP (script 1SP, CI update 1SP, test 0.5SP).
- **Dependencies:** Node.js 18+ (npm i -g @gitbook/cli); existing mdBook in book/book.toml.
- **API/Script:** sync-mdbook-to-gitbook.sh: rsync -av book/src/ gitbook/content/; gitbook/.gitbook.yaml (root: ./content, title: OmegaOS Book).
- **Testing:** Manual: ./sync.sh && gitbook serve; CI: Trigger on book/ changes, verify deploy.
- **Build:** Add to Makefile (make gitbook: sync && cd gitbook && gitbook push).

**Architecture Fit:** Non-kernel; repo-level tool. Integrates with .github/ workflows; no TCB impact.

## Benefits & Value
- **Usability:** Full search (e.g., "VirtIO-GPU ARL"), dark mode, mobile – 2x faster onboarding.
- **Collaboration:** Version history, comments on rfcs/; analytics for hot sections (e.g., security/zk).
- **SEO:** Auto-sitemaps, meta tags for "OmegaOS W3.x Rust kernel"; boosts GitHub stars.
- **Efficiency:** Auto-sync reduces manual exports; hybrid keeps local mdBook.
- **ROI:** Completes Epic 9 (Docs); supports Sprint 4 GPU rollout with interactive guides.

## Risks & Mitigations
- **Structure Mismatch:** mdBook indented SUMMARY vs GitBook folders – Script flatten; test links.
- **Vendor Lock:** Free tier limits – Fallback GH Pages; export MD anytime.
- **CI Overhead:** Node.js ~200MB – Cache in Actions; run only on book/ paths.
- **Auth Issues:** Token expiry – Rotate in repo secrets.

## Next Steps
1. Create gitbook/ dir & sync script (1 day).
2. Setup GitBook space, add token to secrets.
3. Update workflow YAML, test on branch.
4. Publish initial book/; add to README.md.

**Approval Gate:** Enhances Epic 9; validates via user feedback on search/SEO.

Generated via BMAD core-workflow product-brief (iFlow CLI).