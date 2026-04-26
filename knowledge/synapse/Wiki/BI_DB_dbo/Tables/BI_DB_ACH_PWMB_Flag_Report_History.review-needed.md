# Review Needed: BI_DB_dbo.BI_DB_ACH_PWMB_Flag_Report_History

**Generated**: 2026-04-23
**Quality Score**: 6.5/10
**Status**: Needs domain expert review (compliance/AML team)

## Open Questions

1. **What is PWMB?** — PWMB (FundingTypeID=32) appears alongside ACH in cashout SLA rules and AML structuring detection. What does the acronym stand for? Is it "Pre-authorized Wire via Multiple Banks", a proprietary name, or something else?

2. **TotalPendingCOForUser — CO ambiguity** — The "CO" abbreviation is unclear. Does it mean:
   - Compliance Officer (total value pending review by a compliance officer)
   - Client Order (pending client orders value)
   - Cash Out (pending withdrawal amount)
   The column uses `money` type, suggesting a dollar value. Please clarify.

3. **Why is the table empty?** — A backup was created 2024-11-17 and the DDL backup script is dated 2024-12-01, suggesting data existed and was preserved before a cleanup. Was the table truncated after the RealCID schema change (bigint → int)? Is it expected to be repopulated?

4. **Writer SP** — No writer SP was found in SSDT BI_DB_dbo. How was this table populated? Was there an SSIS package, external system push, or on-prem SQL Server agent?

5. **VerifiedPhoneCounty spelling** — The column is named "VerifiedPhoneCounty" (with "County"). Is this intentional (subdivision/county-level phone data) or a longstanding typo for "Country"?

6. **LastMultiIPDaily / FirstMultiIPDaily as bigint** — These dates are stored as bigint, not date. Confirmed as YYYYMMDD integer? Or are they epoch milliseconds? Please confirm the format for correct date arithmetic.

7. **Regulation values** — What are the distinct Regulation values in use? E.g., "NYDFS+FINRA", "ASIC", "UK", "EU" — or other jurisdiction codes?

8. **PlayerStatusID naming** — The column type is nvarchar(1000) but the name ends in "ID" — does it actually store an integer status ID, or the status name/label? (In the Elements section, it is documented as storing the status label based on the nvarchar type.)

## Columns Requiring Confirmation

| Column | Concern |
|--------|---------|
| TotalPendingCOForUser | Tier 4 — CO abbreviation ambiguous. Dollar value. Domain expert needed. |
| LastMultiIPDaily / FirstMultiIPDaily | Tier 3 — bigint date format (YYYYMMDD vs epoch). Confirm format. |
| VerifiedPhoneCounty | Tier 3 — likely "Country" not "County". Confirm naming intent. |
| PlayerStatusID | Tier 3 — nvarchar type suggests label, not integer ID. Confirm semantics. |

## Lineage Gaps

- Production source entirely unknown — no Generic Pipeline, no External Table, no SSDT SP
- No OpsDB registration found
- Backup suggests data existed as recently as Nov 2024 — source discontinued or migrated
- RealCID type change (bigint → int) may indicate CID range constraints were applied

## Related AML Context (NOT writers of this table)

- `SP_AML_BI_Alerts_New` (Pavlina Masoura) — uses PWMB/ACH as FundingType filter for AML_NY001/NY002 US structuring alerts
- `SP_ChargebackReport` — tracks ACH (29) / PWMB (32) cashout SLA compliance
- `SP_Operations_Monthly_KPIs_FullData` — ACH/PWMB cashout KPI reporting
