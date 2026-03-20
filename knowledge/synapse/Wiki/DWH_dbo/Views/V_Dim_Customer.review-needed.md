# Review Sidecar — DWH_dbo.V_Dim_Customer

## Confidence Summary

| Tier | Count | Description |
|------|-------|-------------|
| Tier 1 | 7 | Resolved columns — Country, Affiliate, Language, VerificationLevel, PlayerStatus, PlayerLevel, Regulation |
| Tier 2 | 84 | Passthrough from Dim_Customer with type casts |

## Unverified Claims

| # | Claim | Source | Confidence |
|---|-------|--------|------------|
| 1 | INNER JOINs intentionally filter orphaned customers | View DDL — could be LEFT JOIN oversight | Medium |
| 2 | AffiliatesGroupsName is the correct affiliate display name | Dim_Affiliate schema | High |

## Reviewer Corrections

*(None yet — pending reviewer pass)*

## Quality Breakdown

| Dimension | Score | Notes |
|-----------|-------|-------|
| **Overall** | **8/10** | Large denormalized view — comprehensive but many unresolved FK IDs remain |
