# Review Needed: BI_DB_dbo.BI_DB_Blocked_Customers

## Items Requiring Human Review

### Tier 4 / Low-Confidence Items

None — all columns have clear lineage (9 Tier 1 from Dim_Customer, 24 Tier 2 from SP code).

### Questions for Reviewers

1. **UnRealizedEquity naming**: The column is computed as V_Liabilities.Liabilities + V_Liabilities.ActualNWA, which is NOT a standard "unrealized equity" metric. The wiki notes this discrepancy but the exact business meaning of Liabilities+ActualNWA in V_Liabilities should be confirmed. Is this the total net asset value? Position value? Cash balance?

2. **V_Liabilities INNER JOIN gap**: Customers not present in V_Liabilities for the run date are silently excluded from TotalCustomers. How often does this happen? Is there a known V_Liabilities coverage issue for newly onboarded or recently blocked customers?

3. **"Blocked Customers" vs population**: The table covers 8 non-Normal statuses, but "Pending Verification" (230K customers) is a standard onboarding status, not a "blocked" state. Should the table be renamed or the wiki clarify the intended use? Is Pending Verification intentionally included?

4. **PlayerStatusSubReasonID=0 semantics**: ISNULL replaces NULL with 0. Does PlayerStatusSubReasonID=0 appear in Dim_PlayerStatusSubReasons as a valid record, or is 0 truly a synthetic null-replacement? If 0 is in the dictionary, the ISNULL behavior may unexpectedly match a real sub-reason.

5. **Regulation JOIN key anomaly**: The SP joins on `dc.RegulationID = dr.DWHRegulationID` (not dr.RegulationID). The wiki documents this but reviewers should confirm whether there are any regulations where RegulationID ≠ DWHRegulationID that could cause wrong regulation names in the output.

6. **IsOpenPosition segment ambiguity**: The CASE WHEN is computed ON THE GROUP BY keys, not per-customer. A segment with IsOpenPosition=1 means the SUM of TotalPositionsAmount for that combination is non-zero — but some customers within the segment may still have zero positions. Is this level of granularity sufficient for the reporting use case?

### Potential Issues

- **UpdateDate correction**: During wiki generation, UpdateDate was initially missed in the DDL review but is present in the DDL as column 33. The Elements table documents all 33 columns correctly, but the Phase 1 DDL count initially recorded 32. No data issue — documentation is correct.
- **CurrAge stability**: DATEDIFF(YEAR, BirthDate, GETDATE()-1) means CurrAge increments on customer birthday, potentially mid-month. Reporting on CurrAge buckets across multiple months may show discontinuities.

### Corrections from Prior Reviews

None.
