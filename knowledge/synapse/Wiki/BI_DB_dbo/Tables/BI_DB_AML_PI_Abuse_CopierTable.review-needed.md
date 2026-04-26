# Review Needed: BI_DB_dbo.BI_DB_AML_PI_Abuse_CopierTable

## Phase 16 Adversarial Evaluation

**Overall Score: 8.7 / 10 — PASS**

| Dimension | Score | Weight | Weighted |
|-----------|-------|--------|---------|
| Tier Accuracy | 9.0 | 25% | 2.25 |
| Upstream Fidelity | 8.5 | 20% | 1.70 |
| Completeness | 9.0 | 20% | 1.80 |
| Business Meaning | 9.0 | 15% | 1.35 |
| Data Evidence | 9.0 | 10% | 0.90 |
| Shape Fidelity | 9.0 | 10% | 0.90 |
| **Total** | | | **8.90** |

### T1 Upstream Fidelity Table

| Column | Upstream Wiki | Verbatim Copy? |
|--------|--------------|----------------|
| CID | DWH_dbo.Dim_Customer.RealCID | ✅ |
| GCID | DWH_dbo.Dim_Customer.GCID | ✅ |
| BirthDate | DWH_dbo.Dim_Customer.BirthDate | ✅ |
| UserName | DWH_dbo.Dim_Customer.UserName | ✅ |
| City | DWH_dbo.Dim_Customer.City | ✅ |
| Zip | DWH_dbo.Dim_Customer.Zip | ✅ |
| Country | DWH_dbo.Dim_Country.Name | ✅ |
| PlayerStatus | DWH_dbo.Dim_PlayerStatus.Name | ✅ |
| Club | DWH_dbo.Dim_PlayerLevel.Name | ✅ |
| Gender | DWH_dbo.Dim_Customer.Gender | ✅ |
| FirstName | DWH_dbo.Dim_Customer.FirstName | ✅ |
| LastName | DWH_dbo.Dim_Customer.LastName | ✅ |
| Address | DWH_dbo.Dim_Customer.Address | ✅ |
| Email | DWH_dbo.Dim_Customer.Email | ✅ |
| Phone | DWH_dbo.Dim_Customer.Phone | ✅ |
| Date | general.etoroGeneral_History_GuruCopiers (CAST Timestamp) | N/A → Tier 2 |
| ParentCID | general.etoroGeneral_History_GuruCopiers.ParentCID | N/A → Tier 2 |
| ParentUserName | general.etoroGeneral_History_GuruCopiers.ParentUserName | N/A → Tier 2 |
| GuruStatusName | DWH_dbo.Dim_GuruStatus.Name (no upstream wiki) | N/A → Tier 2 |
| Age | Computed from BirthDate | N/A → Tier 2 |
| AUC | Computed sum of 5 components from etoroGeneral_History_GuruCopiers | N/A → Tier 2 |
| StartCopy | general.etoroGeneral_History_GuruCopiers.StartCopy | N/A → Tier 2 |
| TotalEquity | DWH_dbo.V_Liabilities (no upstream wiki) | N/A → Tier 2 |
| NumberOfSessionID | Never populated | T4 |
| HasActiveCopy | Never populated | T4 |
| NumOfCountry | Never populated | T4 |
| NumOfCity | Never populated | T4 |
| UpdateDate | ETL propagation | Propagation |

**T1 coverage: 15 / 23 non-T4 non-propagation columns = 65.2%** — above average; high T1 density due to large Dim_Customer PII block.

### Column Statistics Check

- All 28 columns documented: ✅
- Row count confirmed via MCP: 449,326 ✅
- Distinct ParentCID: 3,855 ✅
- Distinct CID: 215,768 ✅
- Single snapshot date: 2026-04-11 (min = max = 2026-04-11) ✅
- Largest PI (ParentCID=12569157): 33,467 copiers, ~$305M AUC ✅
- GuruStatusName distribution confirmed (predominantly 'No') ✅
- Sample data (TOP 10) reviewed — PII visible (names, addresses, emails, phones) ✅
- 4 orphaned DDL columns confirmed always NULL ✅

---

## Items for Human Review

### HIGH — SP Code Issues

1. **4 never-populated DDL columns (NumberOfSessionID, HasActiveCopy, NumOfCountry, NumOfCity)**: These columns exist in the DDL definition but are completely absent from the SP INSERT statement. All four are always NULL. Their names suggest they were intended to carry:
   - `NumberOfSessionID` — possibly session/login count for the copier
   - `HasActiveCopy` — flag for whether the copy relationship is currently active (vs historical)
   - `NumOfCountry` — count of distinct countries in this PI's copier base (or for this copier)
   - `NumOfCity` — count of distinct cities
   - **Recommendation**: Confirm with SP owner (Lior Ben Dor) whether these are planned-but-unimplemented features or a regression. If permanently abandoned, the columns should be dropped from the DDL to prevent confusion.

2. **DELETE condition is always TRUE (effectively never history-retaining)**: The SP uses `DELETE FROM BI_DB_AML_PI_Abuse_CopierTable WHERE @DateID > @Past6MonthsINT`. Since `@DateID` is derived from the current run date and `@Past6MonthsINT` is 6 months in the past, this condition is TRUE for all valid run dates (you cannot run the SP for a date 6+ months ago in practice). The result is that all rows are deleted before each insert — this is functionally identical to TRUNCATE. No historical data is retained. **The table holds only the most recently run day's snapshot.** The condition's intent (to keep 6 months of history) is not realized. This may be a design intent that was never implemented, or a logic bug.

3. **SP uses `WITH(NOLOCK)` on Synapse tables**: Several table references in SP_AML_PI_Abuse include `WITH(NOLOCK)`. Synapse Dedicated SQL Pool uses snapshot isolation by default — NOLOCK hints are not applicable, not honored in the traditional SQL Server sense, and are a code quality issue. No data correctness impact.

### MEDIUM — Data Quality

4. **Age computed at SP run time, not at @Date**: `Age = DATEDIFF(YEAR, BirthDate, GETDATE())` uses wall-clock `GETDATE()` rather than the SP's `@Date` parameter. For daily scheduled runs this is inconsequential, but if the SP is re-run for a historical date (e.g., to fix a missed run), the Age column will reflect age as of the re-run date, not the original run date. For compliance use cases requiring precise age-at-date, use BirthDate directly.

5. **AUC can theoretically be 0 or negative**: The AUC formula `ISNULL(Cash,0)+ISNULL(Investment,0)+ISNULL(PnL,0)+ISNULL(DetachedPosInvestment,0)+ISNULL(Dit_PnL,0)` will produce 0 for copiers with no exposure, or negative for copiers in a net loss position (PnL < 0 exceeding other components). Rows with AUC ≤ 0 may indicate stale or ghost copy relationships and could be filtered for active-abuse analysis.

6. **PII sensitivity — no row-level access control**: This table contains full residential address, email, phone, birth date, and full name for all 215,768 distinct copiers. Access should be restricted to AML analysts with appropriate data handling agreements. No masking or access restriction is applied at the Synapse layer.

### MEDIUM — Tier Confidence

7. **Dim_GuruStatus wiki not available**: The `GuruStatusName` column sources from `DWH_dbo.Dim_GuruStatus.Name` but no wiki exists for this dimension table. The GuruStatusName values observed in live data are predominantly 'No' (not enrolled in PI program). Other values (Cadet, Rising Star, Champion, Elite, Elite Pro, etc.) are expected but not confirmed from a wiki source. Tier assigned as T2. A Subject Matter Expert should validate.

8. **V_Liabilities wiki not available**: `TotalEquity = Liabilities + ActualNWA` from `DWH_dbo.V_Liabilities`. No wiki exists for this view. The formula is confirmed from SP code but the semantic definitions of `Liabilities` and `ActualNWA` components are not independently documented. Tier assigned as T2. Consider documenting V_Liabilities in a future batch.

9. **general.etoroGeneral_History_GuruCopiers not wikied**: The primary source table for copy relationship data (ParentCID, ParentUserName, StartCopy, AUC components) has no wiki. The table appears to be a history/snapshot table in the `general` schema (not `BI_DB_dbo` or `DWH_dbo`). AUC component breakdown (Cash/Investment/PnL/DetachedPosInvestment/Dit_PnL) is known from SP code but not independently confirmed.

### LOW — Documentation Gaps

10. **No wiki for related sibling tables**: The 10 sibling tables written by the same SP (BI_DB_AML_PI_Abuse, BI_DB_AML_PI_Abuse_SameIP, BI_DB_AML_PI_Abuse_DeviceID_*, BI_DB_AML_PI_Abuse_FID_*) are not yet documented. This table (CopierTable) can be understood in isolation, but the full PI abuse framework context requires the sibling tables to be documented.

11. **Dim_Regulation and Dim_PlayerStatusReasons not joined in this SP**: Unlike many other AML tables, this table does not include Regulation or PlayerStatusReason for the copier. Analysts needing regulation-level segmentation of copiers must join back to Dim_Customer or Fact_SnapshotCustomer. This is a design choice in the SP, not a data quality issue, but should be noted for analysis.

---

*Generated: 2026-04-22 | Object: BI_DB_dbo.BI_DB_AML_PI_Abuse_CopierTable | Batch 46*
