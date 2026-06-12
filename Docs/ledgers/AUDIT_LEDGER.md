# NightRaven Audit Ledger

Append-only. Every Auditor Agent stores results here — findings, scores, risks, recommendations. Auditors consume Build Ledger entries, project state, and source code; they never modify code.

Entry format:

```
## [YYYY-MM-DD] <AuditorAgent> — <scope>
- Event: AuditStarted | AuditCompleted
- Findings: <severity-tagged list, file:line where applicable>
- Scores: <domain n/100>
- Risks: ...
- Recommendations: ...
- Full report: docs/audits/<timestamp>/ (if a full /audit run)
```

---
