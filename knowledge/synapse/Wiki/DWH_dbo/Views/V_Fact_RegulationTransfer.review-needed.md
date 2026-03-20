# Review Sidecar — DWH_dbo.V_Fact_RegulationTransfer

## Confidence Summary

| Tier | Count | Description |
|------|-------|-------------|
| Tier 1 | 2 | TransferDirection, RegulationID — directly visible in DDL |
| Tier 2 | 28 | Remaining columns — passthrough from Fact_RegulationTransfer |

## Unverified Claims

| # | Claim | Source | Confidence |
|---|-------|--------|------------|
| 1 | TransferDirection +1 = inbound, -1 = outbound | View DDL logic — `1` for ToRegulationID, `-1` for FromRegulationID | High |

## Reviewer Corrections

*(None yet — pending reviewer pass)*

## Quality Breakdown

| Dimension | Score | Notes |
|-----------|-------|-------|
| **Overall** | **8.5/10** | Clear UNION ALL pattern with good business meaning |
