---
table: BI_DB_dbo.BI_DB_eTorian_NetProfit
type: review-needed
batch: 37
---

# Review Notes: BI_DB_eTorian_NetProfit

## Phase 16 Adversarial Evaluation

| Dimension | Weight | Score | Notes |
|-----------|--------|-------|-------|
| Tier Accuracy | 25% | 9.5 | UserName/CloseDate T1 from DWH wiki; NetProfit_* columns correctly T2 (SP aggregations of T1 source); CID correctly T2 (population-filtered); UpdateDate T2 |
| Upstream Fidelity | 20% | 9.5 | Verbatim copy from Dim_Position.NetProfit and Dim_Customer.UserName; Dim_Instrument InstrumentTypeID mapping included verbatim from DWH wiki |
| Completeness | 20% | 9.5 | All 8 columns documented; eTorian population filter fully explained; instrument type mapping table included; end-of-month companion table noted |
| Business Meaning | 15% | 9.0 | PI program context clear; Popular Investor exclusion from IsValidCustomer noted; negative values documented; zero-means-no-positions-of-that-type documented |
| Data Evidence | 10% | 9.0 | 358,925 rows, 2,979 unique CIDs, date range 2021-01-01–2026-04-12 confirmed via live data |
| Shape Fidelity | 10% | 10.0 | HASH(CID) + CLUSTERED INDEX (CloseDate ASC) correctly documented |

**Weighted Score: 9.2 / 10.0 ✅ PASS (threshold: 7.5)**

---

## Items Requiring Human Review

### MEDIUM: AccountTypeID IN (7, 13) meaning not confirmed
The population filter uses `AccountTypeID IN (7, 13)`. From `Dim_Customer` wiki, AccountTypeID distribution shows these are in the "others <6K" category with no specific documentation for values 7 and 13. These are likely "eTorian Elite" or "Popular Investor Pro" sub-types, but the exact business meaning is not confirmed from available documentation.
**Action**: Confirm with the PI program team what AccountTypeID 7 and 13 represent. Add to this documentation once confirmed.

### MEDIUM: RealCID=149 hardcoded exception
The SP includes `OR fsc.RealCID = 149` as a permanent population inclusion. This bypasses all the standard eTorian filters (PlayerLevelID, AccountTypeID, etc.). The purpose of this exception is undocumented.
**Action**: Identify CID=149 and confirm why it's hardcoded. If it's a system/admin account, note this in the wiki.

### LOW: NetProfit currency assumption
`Dim_Position.NetProfit` is described as "in position currency" — meaning forex positions may have NetProfit in non-USD currencies depending on the quote currency. However, in eToro's DWH, position amounts are typically normalized to USD in the ETL. Verify whether NetProfit in this table is always in USD or currency-dependent.
**Action**: Check with DWH team whether Dim_Position.NetProfit is always USD-normalized or can reflect foreign currency amounts.

### LOW: InstrumentTypeIDs 3, 7, 8, 9 not covered
The three NetProfit bucket CASE statements only cover types 1, 2, 4, 5, 6, 10. If a position has an InstrumentTypeID outside these values (3, 7, 8, 9), its NetProfit would contribute 0 to all three columns. The Dim_Instrument wiki confirms these IDs are "unused gaps for historical reasons," so in practice this produces no data loss — but should be monitored if new instrument types are introduced.
