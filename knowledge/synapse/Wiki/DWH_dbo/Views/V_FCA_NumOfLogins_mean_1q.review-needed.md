# Review Sidecar — DWH_dbo.V_FCA_NumOfLogins_mean_1q

## Unverified Claims (Tier 3-4)

No Tier 3-4 claims — all columns either computed (Tier 2) or inherited from Fact_CustomerAction wiki (Tier 1).

## Open Questions

1. **Downstream consumers**: No SSDT references found. Likely consumed by external FCA reporting tools or BI extracts — verify with regulatory/compliance team.
2. **ActionTypeID = 14 mapping**: Confirmed as "Login" from Fact_CustomerAction wiki dictionary. No dictionary table lookup needed.
3. **NOLOCK risk**: The view uses `WITH(NOLOCK)` on Fact_CustomerAction. During ETL windows, uncommitted rows could affect the COUNT. Assess if this is acceptable for regulatory reporting.

## Reviewer Corrections

*(Empty — awaiting reviewer input)*
