# Review Sidecar — DWH_dbo.V_FCA_NumOfLogins_mean_1q

## Confidence Summary

| Tier | Count | Description |
|------|-------|-------------|
| Tier 2 | 3 | All columns — from view DDL |

## Unverified Claims

| # | Claim | Source | Confidence |
|---|-------|--------|------------|
| 1 | ActionTypeID = 14 means "Login" | Dim_ActionType lookup — consistent with prior docs | High |
| 2 | Used for FCA regulatory reporting | View naming convention ("FCA" prefix) | Medium |

## Reviewer Corrections

*(None yet — pending reviewer pass)*

## Quality Breakdown

| Dimension | Score | Notes |
|-----------|-------|-------|
| **Overall** | **8/10** | Simple view, clear logic |
