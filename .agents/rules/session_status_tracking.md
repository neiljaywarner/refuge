# Rule: Mandatory Ongoing Session Status Tracking File

Every single session MUST have an active markdown status file named `<date>_selah_session.md` (e.g. `10oct_2026_selah_session.md`) located in the workspace root, maintained and proactively updated throughout every milestone of the session.

### Mandatory File Structure
1. **TL;DR**: Ultra-concise high-level state of the app and current focus.
2. **Executive Summary**: High-level overview of accomplishments, current blockers, and architecture state.
3. **Mini-Milestones Table**: Comprehensive table including:
   - Milestone ID & Title
   - Scope / Description
   - Start Time (`YYYY-MM-DD HH:MM:SS`)
   - End Time (`YYYY-MM-DD HH:MM:SS` or `IN-PROGRESS`)
   - Status (`COMPLETE`, `IN-PROGRESS`, `PENDING`)
   - Proof / Verification artifact
4. **Where We Are Right Now & Next 3 Priorities**: Clear explanation of current progress and the next 3 immediate tactical wins.
5. **FAQ**: Common questions, architectural decisions, and design rationale.
6. **Troubleshooting Guide**: Known error signatures, root causes, diagnostic checks, and mitigation steps.
7. **Appendix**: Relevant device IDs, URLs, commit hashes, telemetry logs, and CLI verification snippets.
