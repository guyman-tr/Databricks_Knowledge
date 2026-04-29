# Review Needed: BI_DB_dbo.BI_DB_TIN_Gap

## Items Requiring Human Review

### Tier 4 / Low-Confidence Items

None -- all columns have traceable lineage (10 Tier 1 from upstream wikis, 19 Tier 2 from SP logic, 1 Tier 5 for UpdateDate).

### Questions for Reviewers

1. **Base population freeze source**: The SP reads from `External_Bi_Output_Uploads_TIN_Gaps_Freeze6`. What defines this frozen population? When was Freeze6 created, and are there plans for Freeze7 or a transition to a live population? Customers registered after the freeze date are permanently excluded from this table regardless of their TIN status.

2. **PII in Email and TaxCode columns**: The table contains customer email addresses (Email) and tax identification numbers (TaxCode_1/2/3). Confirm that appropriate access controls (row-level security, column masking, or workspace-level restrictions) are enforced for this table. These columns should not appear in unsecured reports or exports.

3. **Group classification validation**: The Group column uses equity thresholds ($10 for A, $30 for B1/B2) and 12-month activity windows. Are these thresholds still current for the remediation project, or have they been revised? The C group uses PlayerLevelID IN (2, 6, 7) -- confirm these IDs still map to PI/Club members in current Dim_PlayerLevel.

4. **Google Sheet exclusion list**: The SP excludes specific CIDs from a Google Sheet. How is this list maintained? Is there a risk of stale exclusions or missed updates? What is the sync mechanism between Google Sheets and the External table?

5. **TIN_Null_With_Reason $5,000 threshold**: Reason code 4 only applies when lifetime deposits >= $5,000. Is this threshold regulatory (CRS-mandated) or a business decision? Does it need periodic review?

6. **Lifetime Deposits source ambiguity**: The exact source of the Lifetime Deposits column is unclear -- it could come from Fact_CustomerAction aggregation or V_Liabilities. The wiki marks this as Tier 2 but the precise source table and calculation should be confirmed from SP code.

7. **Ind column NULL handling for Ind_Done**: When a customer has fewer than 3 tax countries, Ind_2 and/or Ind_3 are NULL. Confirm that the SP treats NULL Ind values as resolved (not as gaps) when computing Ind_Done. If NULL is treated as unresolved, customers with 1 tax country could never reach Ind_Done=1.

8. **Annual Income_KYC data type**: This column is nvarchar(max), suggesting it may contain free-text or structured JSON rather than a numeric value. Confirm the expected format and whether it is reliably parseable for numeric analysis.

### Cross-Object Consistency

- **CID uniqueness**: The table grain is one row per CID. Confirm no duplicate CIDs exist after the pivot logic (a CID with more than 3 tax countries could be silently truncated to 3 slots).
- **Dim_Country alignment**: TaxCountry_1/2/3 and KYC_Country both resolve through Dim_Country.Name. If the country dictionary changes (renames, merges), historical meaning of these fields shifts on the next load.
- **BI_DB_PositionPnL dependency**: Open Positions is counted from BI_DB_PositionPnL. If BI_DB_PositionPnL loads after SP_TIN_Gap on a given day, the open positions count may be stale (from prior day). Confirm OpsDB scheduling order.

### Potential Issues

- **No historical tracking**: TRUNCATE+INSERT with no date parameter means there is no built-in way to track remediation progress over time. If historical trend analysis is needed, a separate snapshot mechanism would be required.
- **UpdateDate as Tier 5**: UpdateDate is GETDATE() at insert time with no upstream lineage. Marked Tier 5 (expert review) as its exact semantics (load start vs. load end) depend on SP execution timing.

### Corrections from Prior Reviews

None.
