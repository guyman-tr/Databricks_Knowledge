---
table: BI_DB_dbo.BI_DB_USA_Equity_Deposits
type: review-needed
batch: 37
---

# Review Notes: BI_DB_USA_Equity_Deposits

## Phase 16 Adversarial Evaluation

| Dimension | Weight | Score | Notes |
|-----------|--------|-------|-------|
| Tier Accuracy | 25% | 9.0 | RegulationName/CountryName/StateName correctly T1; financial aggregates T2; Revenue correctly T4 |
| Upstream Fidelity | 20% | 9.0 | Verbatim copy from Dim_Regulation.Name, Dim_Country.Name, Dim_State_and_Province.Name; Fact_SnapshotEquity descriptions used for equity columns |
| Completeness | 20% | 9.0 | All 14 columns documented; HAVING filter documented; 'NULL' string gotcha documented; deprecated Revenue warned |
| Business Meaning | 15% | 8.0 | US equity regulatory context clear; regulation values enumerated; grain documented |
| Data Evidence | 10% | 9.0 | 295,046 rows, date range 20190101-20260412, 3 regulation values, ~55 state combinations confirmed via live queries |
| Shape Fidelity | 10% | 10.0 | ROUND_ROBIN + CLUSTERED INDEX (DateID ASC) correctly documented |

**Weighted Score: 8.95 / 10.0 ✅ PASS (threshold: 7.5)**

---

## Items Requiring Human Review

### HIGH: Revenue column deprecation status
The `Revenue` column is sourced from `BI_DB_dbo.BI_DB_DDR_CID_Level`, which appears in the explicit blacklist as decommissioned. However:
- The SP still references it via a `SP_DDR` dependency in OpsDB
- It is unclear whether `BI_DB_DDR_CID_Level` still has any rows (it could be empty or stale)
- If the table was ever backfilled before decommissioning, historical rows pre-decommission might have non-zero Revenue
**Action**: Verify whether any Revenue > 0 exists in the table: `SELECT TOP 10 * FROM BI_DB_dbo.BI_DB_USA_Equity_Deposits WHERE Revenue != 0`. If rows exist, document the cutoff date.

### MEDIUM: HAVING filter behavior with deprecated Revenue
The HAVING clause includes `DDR_Revenue` in its sum: `SUM(RealizedEquity + Total_Deposits_Amount + Total_Deposits + DDR_Revenue) > 0`. Since `DDR_Revenue` is always 0, the effective filter is `SUM(RealizedEquity + Total_Deposits_Amount + Total_Deposits) > 0`. Note that `Total_Deposits` (a count integer) is added to dollar amounts, which is likely a SP logic quirk rather than intentional. This means segments with zero equity and zero deposits but with a non-zero deposit count would still pass the HAVING filter, and vice versa.
**Action**: Confirm with SP owner whether the inclusion of `Total_Deposits` count in the HAVING dollar sum is intentional.

### LOW: Exact column sourcing for Total_Deposits_Amount from Fact_CustomerAction
The SP uses `CASE WHEN ActionTypeID=7 THEN SUM(ISNULL(fca.Amount, 0)) ELSE 0 END` and aggregates these inside a `GROUP BY fca.RealCID, fca.ActionTypeID` in the `#Deposits` temp table. The result is then SUM-aggregated again in `#Pop_Full_Data_Agg`. The final `Total_Deposits_Amount` in the output represents the total deposit amount for each regulation/country/state segment — which is correct but involves two aggregation levels.

### LOW: StateName geography note
`Dim_State_and_Province` is an IP-geolocation-based region table with only 181 rows. StateName therefore reflects the IP-detected state at registration, not the legally declared state of residence. This may differ from regulatory filing addresses.
**Action**: Add a caveat to any regulatory reports that use StateName as a jurisdiction proxy.
