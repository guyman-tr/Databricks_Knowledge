# Review Needed — BI_DB_dbo.BI_DB_ClubUsersDataRemarketingGoogle

Generated: 2026-04-23 | Batch 71

## Tier 4 Items (Unverified)

None — all columns resolved to Tier 1 or Tier 2.

## Questions for Reviewer

1. **Downstream consumers**: Is this table consumed only by Google Ads, or do other internal tools read it? No downstream SP/view references found in SSDT.
2. **Monthly freeze caveat**: Equity/TotalDeposits/ClusterDetail are frozen to BOMonth — is this intentional for the Google Ads use case? Confirm no real-time audience update is expected.
3. **LTV column**: The SP uses `Revenue8Y_LTV_New` directly, but the LTV_BI_Actual wiki recommends `Revenue8Y_LTV_New_Group_LTV` as the primary signal. Is this a known gap?
4. **NULL ClusterDetail (1.6%, ~11,908 rows)**: Unclustered customers are still included. Confirm this is intentional for remarketing.

## Known Limitations

- Equity / TotalDeposits / ClusterDetail are **monthly snapshot values** (BOMonth anchor), not real-time.
- LTV uses `Revenue8Y_LTV_New` (individual prediction only) — no group-level fallback in this table.
- ROUND_ROBIN / HEAP — not suitable for large analytical joins; this is an export table.
