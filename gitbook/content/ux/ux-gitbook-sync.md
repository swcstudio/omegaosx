# UX Design: GitBook Sync for OmegaOS W3.x Documentation

## Overview
**Feature:** GitBook Integration & Auto-Sync  
**UX Focus:** Contributor and Developer Experience for docs navigation, search, and collaboration.  
**Date:** 2025-11-12  
**Principles:** Intuitive (search-first), Collaborative (comments/versions), Accessible (mobile/dark mode), Maintainable (auto-sync from book/src/).  

Shifts from static mdBook GH Pages to interactive GitBook, enhancing usability for kernel deep-dives (e.g., VirtIO-GPU guides) without changing authoring workflow.

## User Personas
- **Documenter/Contributor (Primary):** Edits book/src/; needs seamless push-to-live.
- **Kernel Learner (Secondary):** Searches "WEB3.ARL GPU" ; expects instant results, embeds.
- **Integrator:** Browses Epics/PRD; wants versioned history for rfcs/.

## UX Goals
- **Seamless Sync:** Edit book/src/ → CI auto-deploys to GitBook (no manual upload).
- **Search Excellence:** Full-text across 1108 .rs files summaries; fuzzy match "framekernel TCB".
- **Navigation:** Auto-TOC from SUMMARY.md; sidebar with sections (Kernel, OSXDK, WEB3).
- **Collaboration:** Inline comments on architecture.md; version compare for Sprint updates.
- **Accessibility:** Dark/light themes; mobile sidebar; alt-text for diagrams (e.g., GPU flow).

## Key Interactions & Flows
### 1. Content Authoring & Sync (Documenter Flow)
- **Trigger:** Edit book/src/kernel.md, git commit/push.
- **Steps:**
  1. CI (.github/workflows/publish_website.yml) runs sync-mdbook-to-gitbook.sh → rsync to gitbook/content/.
  2. gitbook push → Live update in <5min (email notification optional).
  3. Preview local: mdbook serve (existing) or gitbook serve (new hybrid).
- **UX Elements:** Script output: "Synced 25 MD files; pushed to GitBook space". GitBook dashboard shows diff (added GPU section).
- **Pain Points Mitigated:** No dual authoring; SUMMARY.md compatible (script tweaks indents).

### 2. Discovery & Reading (Learner Flow)
- **Trigger:** Visit https://omegaosx.gitbook.io/book/.
- **Steps:**
  1. Search bar: "VirtIO-GPU AR" → Results: Highlights in deep-dive-device.md, links to product-brief-virtio-gpu.md.
  2. Sidebar TOC: Expand "Epics" → Jump to Epic 6 GPU story.
  3. Read mode: Dark theme toggle; embed code snippets (e.g., sys_gpu_render example).
  4. Mobile: Collapsible sidebar; infinite scroll for book/.
- **UX Elements:** Search facets (e.g., filter "Sprint 4"); related links (e.g., "See PRD Epic 6"). Breadcrumbs: Home > Kernel > GPU.
- **Pain Points Mitigated:** Static GH Pages slow load → GitBook CDN; no search → Instant fuzzy.

### 3. Collaboration & Feedback (Integrator Flow)
- **Trigger:** PR to book/src/.
- **Steps:**
  1. GitBook review: Comment on rfcs/gpu.md ("Add ROCm alt?").
  2. Version switch: Compare v1.0 vs Sprint 4 (gitbook versions).
  3. Analytics: Dashboard views (hot: WEB3.ARL Guide).
- **UX Elements:** Inline edits (if enabled); @mentions for contributors. Export MD for local mdbook.
- **Pain Points Mitigated:** Fragmented feedback → Unified comments; lost history → GitBook snapshots.

## Wireframes/Sketch (Conceptual)
- **Landing Page:** Hero: "OmegaOS W3.x Book" with search bar; sections: Overview, Deep-Dives (9), Epics (11).
- **Search Results:** Card layout: Title, snippet, path (e.g., "docs/ux-virtio-gpu.md: AR viewport flow").
- **Doc Page:** Right sidebar TOC; bottom comments; theme switcher.
- **CI Log:** "Sync: 5 new MD (GPU briefs); Deploy: Success to gitbook.io".

## Metrics & Validation
- **DevX:** Sync time <1min; 90% search relevance (user test).
- **Engagement:** >50% pages/search use; mobile views >20%.
- **Accessibility:** WCAG AA (alt-text, contrast); test with screen readers.

## Risks & Mitigations
- **Adoption Barrier:** Hybrid confusion → README.md guide: "Edit book/src/, preview mdbook, live GitBook".
- **Sync Breaks:** SUMMARY mismatch → Script validation (diff check).
- **Free Tier Limits:** 3 books → Use one space; upgrade if needed.

## Next Steps
- Implement sync script & CI (1 SP).
- User test with 5 contributors (search tasks).
- Embed in book.toml (mdbook plugin?).

Generated via BMAD core-workflow UX (iFlow CLI). Focus: DevX for docs; aligns with Epic 9.