# Review Needed: BI_DB_dbo.BI_DB_QMMF_Report_Finance

## Tier 4 Items

None — all columns traced to SP code.

## Review Questions

1. **Column name with space**: `[UnrealizedEquity CFD]` contains a space. This is unusual for DWH columns and will require square bracket quoting in all queries. Was this intentional?

2. **Only CFD equity**: The SP filters IsSettled=0, meaning only CFD (non-settled) positions are included. Settled (real) positions are excluded. Confirm this is the intended business requirement for QMMF reporting.

3. **Credit can be negative**: Sample data shows negative Credit values. Is this expected behavior from V_Liabilities?

4. **Column count discrepancy**: The batch assignment listed 5 columns, but the DDL has 6 (including UpdateDate). This wiki documents all 6 columns per the DDL.

## Corrections Applied

None.
