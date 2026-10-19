# 🤝 Contributor Guide (Developers, Designers, QA & Community Volunteers)

> **Welcome to Refuge — Powering [Belong on the Spectrum](https://www.belongonthespectrum.com/)**  
> Whether you are a non-technical community volunteer, a UI/UX designer, a student/apprentice, or a seasoned Flutter & Dart engineer, **you belong here**.

---

## 1. Ways to Contribute (Technical & Non-Technical)

### 🌟 For Non-Technical Contributors & Community Volunteers
- **Test Sensory Comfort**: Try switching between our 4 sensory presets (*High Clarity*, *Warm Calm*, *Low Stimulus Dark*, and *Low Motion*) on your phone or computer and let us know if any screen feels visually overwhelming.
- **Review Community Copy & Guidelines**: Help refine the welcoming language in `Start Here & Introduce Yourself`, `Announcements`, and `Community Guidelines` (**Issue #29**).
- **Assist with Circle.so CSV Exports**: Help export and verify community history ahead of the **October 31st Circle.so cutover** (**Issue #41**).

### 💻 For Developers, Students & Mentees
We practice strict **Ticket-Driven Development (TDD + BDD)**:
1. **Pick a GitHub Issue**: Browse [Open Issues](https://github.com/neiljaywarner/refuge/issues). Every issue includes a human-readable summary and a **`🤖 LLM Execution Brief`** comment.
2. **Create an Isolated Git Worktree (Never Push Directly to `main`)**:
   ```bash
   git worktree add .worktrees/issue-<ID>-<slug> -b feat/#<ID>-<slug>
   ```
3. **Follow Red-Green-Refactor BDD**:
   - Write or update a human-readable `.feature` scenario under `test/features/`.
   - Build the feature using **CodeWithAndrea Feature-First Architecture** (`presentation` / `application` / `domain` / `data`) and **`hooks_riverpod` (`HookConsumerWidget`)**.
   - Verify zero analyzer warnings (`dart analyze`) and 100% passing tests (`flutter test`).
4. **Zero PII & Zero API Keys**:
   - Never commit real emails, member CSVs, `passwords.yaml`, or `firebase_options.dart`.
5. **Open a Pull Request & Triage CodeRabbit Feedback**:
   - Link the issue (`Closes #<ID>`), review `@coderabbitai` comments, and merge once all checks are green!
