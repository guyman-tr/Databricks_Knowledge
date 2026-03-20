# DWH_dbo.Dim_RiskManagementStatus

> Lookup table defining the 70 deposit risk management check outcome statuses. Status 1 (Success) means a deposit passed all risk checks; all other statuses identify a specific block/decline reason (card blacklist, velocity, KYC level, fraud, country conflict, etc.).

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.RiskManagementStatus |
| **Refresh** | Daily via SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (RiskManagementStatusID ASC) |
| | |
| **UC Target** | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_riskmanagementstatus |
| **UC Format** | Parquet |
| **UC Partitioned By** | _Pending - resolved during write-objects_ |
| **UC Table Type** | Gold (Synapse export) |

---

## 1. Business Meaning

Dim_RiskManagementStatus defines the outcome status of deposit risk management checks. When a deposit is attempted, the payment risk engine evaluates it against multiple rules and assigns a RiskManagementStatusID to the deposit. Status 1 (Success) means the deposit passed all checks. All other statuses (IDs 2-69) identify a specific block or decline reason - card velocity, BIN blacklists, geographic restrictions, KYC level insufficiency, fraud signals (ML, Sift), or business rules. (Tier 1 - upstream wiki, Dictionary.RiskManagementStatus)

This table is the central enumeration for all deposit risk decisions. Billing.Deposit stores RiskManagementStatusID per deposit, making this dimension essential for any deposit risk analytics in the DWH.

The DWH has 70 rows (IDs 0-69). ID=0 (N/A) is a sentinel row with midnight timestamp, likely representing deposits where no risk check was performed. Production Dictionary.RiskManagementStatus has 69 rows (IDs 1-69). The DWH ETL adds DWHRiskManagementStatusID (= ID alias) and StatusID (hardcoded 1).

Loaded daily by SP_Dictionaries_DL_To_Synapse via TRUNCATE+INSERT from DWH_staging.etoro_Dictionary_RiskManagementStatus.

---

## 2. Business Logic

### 2.1 Deposit Risk Check Outcome

**What**: A single RiskManagementStatusID is assigned to each deposit after the risk engine evaluates it.

**Columns Involved**: `RiskManagementStatusID`, `Name`

**Rules**:
- ID=1 (Success): Deposit cleared all checks - proceeds to payment processing
- ID=2-69 (Block/Decline): Each ID maps to a specific check that failed or triggered a block
- ID=0 (N/A): Sentinel row for deposits without a risk check result (midnight timestamp)

**Key Block Categories** (from live data and upstream wiki):
- Card/account blacklists: CardIsBlocked (2), BinInBlackList (3), BlockedPayPalAccount (6), BlockedNetellerAccount (7), DeclinedBlockedMoneyBookersAccount (8)
- Limits: MemberLimit (4), FundingTypeLimit (5), OverTheLimit (12), MultipleDepositsAggregatedAmount (17)
- Geographic: DeclinedBlackListCountry (10), LoginToRegCountryConflict (18)
- Technical/KYC: DeclinedHighRiskDeposit (11), DeclinedTooManyCreditCards (13)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE-distributed with CLUSTERED INDEX on RiskManagementStatusID. With 70 rows, REPLICATE is optimal. Join on RiskManagementStatusID directly.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, the Gold export at `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_riskmanagementstatus` is Parquet. Read the entire table for any lookup.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Resolve RiskManagementStatusID in Billing.Deposit | `LEFT JOIN DWH_dbo.Dim_RiskManagementStatus rms ON ISNULL(dep.RiskManagementStatusID, 0) = rms.RiskManagementStatusID` |
| Blocked deposit count by reason | `WHERE rms.RiskManagementStatusID != 1 GROUP BY rms.Name` |
| Successful deposits | `WHERE rms.RiskManagementStatusID = 1` |

### 3.3 Gotchas

- **ID=0 is sentinel (midnight timestamp)**: InsertDate/UpdateDate = 00:00:00 while all other rows have ~02:13 timestamp. Use `ISNULL(RiskManagementStatusID, 0)` when joining from Billing.Deposit to catch NULL risk status values.
- **DWHRiskManagementStatusID = RiskManagementStatusID**: These always have the same value. Prefer RiskManagementStatusID for joins.
- **StatusID always 1**: Hardcoded Active for all rows. Not a meaningful filter.
- **70 rows in DWH, 69 in production**: ID=0 (N/A) is a DWH sentinel not present in production Dictionary.RiskManagementStatus (which starts at ID=1).
- **No DWH views join this table**: No DWH_dbo views or SPs reference Dim_RiskManagementStatus in SSDT. Joins must be built manually.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★★☆ | Tier 1 - Upstream wiki verbatim | `(Tier 1 - upstream wiki, Dictionary.RiskManagementStatus)` |
| ★★★☆☆ | Tier 2 - Synapse SP code | `(Tier 2 - SP code)` |
| ★★☆☆☆ | Tier 3 - Live data | `(Tier 3 - live data)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RiskManagementStatusID | int | NO | Primary key identifying the deposit risk check outcome. 0=N/A (sentinel), 1=Success, 2-69=specific block/decline reason. See Section 2.1 for key values. Referenced by Billing.Deposit.RiskManagementStatusID. (Tier 1 - upstream wiki, Dictionary.RiskManagementStatus) |
| 2 | Name | varchar(50) | NO | Internal code name for the risk outcome. Used in analytics and risk dashboards. Values include: Success, CardIsBlocked, BinInBlackList, MemberLimit, FundingTypeLimit, DeclinedHighRiskDeposit, DeclinedBlackListCountry, KYCLevel0-3, ML, ThreeDsVerificationFail, BusinessRuleRisk, and others. (Tier 1 - upstream wiki, Dictionary.RiskManagementStatus) |
| 3 | DWHRiskManagementStatusID | int | YES | ETL-computed alias of RiskManagementStatusID - always equals RiskManagementStatusID. `[RiskManagementStatusID] as [DWHRiskManagementStatusID]` in SP_Dictionaries_DL_To_Synapse. DWH-specific field. Use RiskManagementStatusID for joins. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 4 | StatusID | int | YES | Hardcoded 1 (Active) for all rows by ETL. Not present in production Dictionary.RiskManagementStatus. Not a meaningful filter. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 5 | UpdateDate | datetime | YES | GETDATE() at SP_Dictionaries reload time for IDs 1-69. ID=0 has midnight (00:00:00) timestamp - sentinel row behavior. (Tier 2 - SP_Dictionaries_DL_To_Synapse; Tier 3 - live data for ID=0 anomaly) |
| 6 | InsertDate | datetime | YES | GETDATE() at SP_Dictionaries reload time for IDs 1-69. ID=0 has midnight (00:00:00). Same pattern as UpdateDate. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| RiskManagementStatusID | etoro.Dictionary.RiskManagementStatus | RiskManagementStatusID | passthrough |
| Name | etoro.Dictionary.RiskManagementStatus | Name | passthrough |
| DWHRiskManagementStatusID | - | - | ETL-computed: [RiskManagementStatusID] aliased |
| StatusID | - | - | ETL-computed: hardcoded 1 |
| UpdateDate | - | - | ETL-computed: GETDATE() |
| InsertDate | - | - | ETL-computed: GETDATE() |

Full production documentation: see upstream wiki Dictionary/Tables/Dictionary.RiskManagementStatus.md

### 5.2 ETL Pipeline

```
etoro.Dictionary.RiskManagementStatus -> Generic Pipeline -> DWH_staging.etoro_Dictionary_RiskManagementStatus -> SP_Dictionaries_DL_To_Synapse -> DWH_dbo.Dim_RiskManagementStatus
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Dictionary.RiskManagementStatus | 69 rows (IDs 1-69) |
| Staging | DWH_staging.etoro_Dictionary_RiskManagementStatus | Raw import; includes ID=0 N/A sentinel |
| ETL | SP_Dictionaries_DL_To_Synapse | TRUNCATE + INSERT. Adds DWHRiskManagementStatusID, StatusID, InsertDate, UpdateDate. |
| Target | DWH_dbo.Dim_RiskManagementStatus | 70 rows (IDs 0-69) |
| Export | Generic Pipeline (daily) | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_riskmanagementstatus |

---

## 6. Relationships

### 6.1 References To (this object points to)

N/A - no foreign key columns.

### 6.2 Referenced By (other objects point to this)

No DWH_dbo views or procedures reference this table in the SSDT repo. Fact tables with RiskManagementStatusID can join for label resolution.

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| Billing.Deposit (production) | RiskManagementStatusID | Each deposit's risk check outcome |

---

## 7. Sample Queries

### 7.1 List all statuses
```sql
SELECT
    RiskManagementStatusID,
    Name,
    StatusID
FROM [DWH_dbo].[Dim_RiskManagementStatus]
WHERE RiskManagementStatusID > 0
ORDER BY RiskManagementStatusID
```

### 7.2 Deposit block rate by reason (example)
```sql
SELECT
    rms.Name AS BlockReason,
    COUNT(*) AS blocked_count
FROM [DWH_dbo].[Fact_BillingDeposit] dep
LEFT JOIN [DWH_dbo].[Dim_RiskManagementStatus] rms
    ON ISNULL(dep.RiskManagementStatusID, 0) = rms.RiskManagementStatusID
WHERE rms.RiskManagementStatusID <> 1
GROUP BY rms.Name
ORDER BY blocked_count DESC
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped - Atlassian MCP not available.)

---

*Generated: 2026-03-19 | Quality: 8.0/10 (★★★★☆) | Phases: 7/14 (fast-path)*
*Tiers: 2 T1, 3 T2, 1 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 9/10, Logic: 8/10, Relationships: 5/10, Sources: 9/10*
*Object: DWH_dbo.Dim_RiskManagementStatus | Type: Table | Production Source: etoro.Dictionary.RiskManagementStatus*
