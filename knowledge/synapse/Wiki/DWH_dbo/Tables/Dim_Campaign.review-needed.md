# Review Sidecar — DWH_dbo.Dim_Campaign

## Unverified Columns (Tier 4)

_None — all columns are Tier 3 (structural only, no live data)._

## Open Questions

### Structural
1. **Deprecation candidate** — ETL is commented out. Should this table be dropped from the DWH, or is there a plan to re-enable the campaign feed?
2. **Dynamic Data Masking** — `ParticipatedUsers` and `Description` have DDM applied. Was this masking intentional for a dead table, or a legacy configuration?
3. **Campaign tracking alternative** — If campaign data is tracked elsewhere (e.g., marketing platform, Jira), document the replacement system.

---

*Generated: 2026-03-18*
