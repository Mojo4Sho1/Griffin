# Handoff Template

At the end of each experiment session, copy this template, fill it in, and append it to `docs/research_plan/SESSION_LOG.md`. Also update `STATUS.md` and add an entry to `DECISION_LOG.md`.

---

```markdown
## Session: YYYY-MM-DD — EXPXX <Short Title>

**Experiment ID:** EXPXX

**Task:** <One sentence describing what this session was asked to do.>

**Files read:**
- <list every file inspected>

**Files changed:**
- <list every file created or modified, with a one-line description of the change>

**Commands run:**
- <list every command run, including scripts and python commands>

**Artifacts generated:**
- <list new artifacts in artifacts/ or elsewhere, with paths>

**Main findings:**
<2–5 sentences. What did you discover? Use source-grounded language. Separate facts from interpretations.>

**Evidence:**
- <cite specific files, result IDs, or line numbers supporting each finding>

**Decision:**
<What was decided at the end of this experiment? Did it pass or fail its decision gate? What was the outcome?>

**Recommendation:**
<What should the next Claude instance do first? Which experiment comes next?>

**Risks and uncertainties:**
- <List unresolved questions, unclear assumptions, or things that could invalidate findings>

**Next experiment:** EXPXX — <title>
```

---

## Usage Notes

- Fill in every field. Leave none blank.
- If a field truly has no content (e.g., no artifacts generated), write "none" rather than omitting the field.
- Be specific about file paths and line numbers where relevant.
- Separate measured facts from interpretations. Label interpretations explicitly.
- Do not summarize in a way that obscures uncertainty. If something is ambiguous, say so.
- This log is read by future Claude instances that have no memory of this conversation. Write for someone who just started.
