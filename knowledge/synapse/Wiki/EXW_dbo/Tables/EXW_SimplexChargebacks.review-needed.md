# EXW_dbo.EXW_SimplexChargebacks — Review Notes

**Generated**: 2026-04-20  
**Batch**: 11  
**Quality Score**: 8.5/10

---

## Tier 4 Items (Reviewer Verification Needed)

| Column | Issue | Action Required |
|--------|-------|----------------|
| Payment_ID | Identified as matching EXW_SimplexMapping.long_id (GUID format) | Confirm join key with payment ops |
| Is_Simplex_Liable | All values = "1" in 5-row dataset — could have more values if backfilled | Note for future if data ever grows |
| CB Funds Status | Free text — values like "2. Funds returned by the AB - fee on Simplex 2019_10" unclear | "AB" likely = Acquiring Bank; confirm |
| ARN | Identified as cross-referenceable with EXW_ECPBank.uti | Verify UTI=ARN mapping with ECP Bank integration team |

## Open Questions

1. **Why only 5 rows?** Was chargeback tracking manually maintained for a brief period and then abandoned, or is this an incomplete export? The Simplex integration spanned 2019-2022 and processed 103K transactions (EXW_SimplexMapping) but only 5 chargebacks were recorded.
2. **Currency of Chbk_AMT ($)**: The column name says "$" but all transactions were EUR/GBP. Confirm if amounts were converted to USD or if the name is misleading.
3. **Is_Simplex_Liable as nvarchar**: Stored as text "1" not integer — was this intentional? Might indicate it was imported from a CSV/Excel source.

## No Critical Blockers

All hard phase gates passed. Wiki accurately reflects the 5-row archive.
