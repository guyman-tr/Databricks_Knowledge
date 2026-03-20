# DWH_dbo.Dim_RiskStatus

> Lookup table defining the 90 granular risk flag reasons that can be attached to a customer account (e.g., OverTheLimit, BinToRegCountryConflict, Affiliate Multiple Accounts, FundingStolenReportedByProcessor). Distinct from Dim_RiskClassification (overall level) and Dim_RiskManagementStatus (per-deposit outcome). 74 active, 16 inactive (IsActive=0).

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.RiskStatus |
| **Refresh** | Daily via SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (RiskStatusID ASC) |
| | |
| **UC Target** | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_riskstatus |
| **UC Format** | Parquet |
| **UC Partitioned By** | _Pending - resolved during write-objects_ |
| **UC Table Type** | Gold (Synapse export) |

---

## 1. Business Meaning

Dim_RiskStatus defines specific risk flags or reasons attached to individual customer accounts. Unlike Dim_RiskClassification (overall customer risk level) or Dim_RiskManagementStatus (per-deposit check outcome), Dim_RiskStatus captures the granular *reason* for a customer risk flag - e.g., OverTheLimit (2), BinToRegCountryConflict (6), Affiliate Multiple Accounts (10), High Risk Account Country (17), FundingStolenReportedByProcessor, CreditCardBruteForce. (Tier 1 - upstream wiki, Dictionary.RiskStatus)

RiskStatusID is stored on BackOffice.Customer and indicates the most recent primary risk reason. BackOffice procedures track risk status changes over time. History.RiskStatus logs all historical changes. Billing.FundingCustomerRisk links a RiskStatusID to funding/customer combinations at risk events.

The DWH version has 90 rows (IDs 0-90, with gaps), with 74 active and 16 inactive. Inactive rows (IsActive=False) represent legacy or deprecated risk flags - e.g., CHBK CAL (15), CHBK Leumi (16), CHBK B&S (18), CHBK GlobalCollect (19), Upon Request (13). The production source adds a RiskCategoryID column for grouping (velocity, country conflicts, fraud, multiple accounts) which is dropped by the DWH ETL.

Loaded daily by SP_Dictionaries_DL_To_Synapse via TRUNCATE+INSERT from DWH_staging.etoro_Dictionary_RiskStatus.

---

## 2. Business Logic

### 2.1 Risk Flag Taxonomy

**What**: Risk status reasons fall into logical categories (though RiskCategoryID itself is dropped from DWH).

**Columns Involved**: `RiskStatusID`, `Name`, `IsActive`

**Key Status Groups** (Tier 1 - upstream wiki):
- Baseline: None (0), Normal (1) - no active risk flag
- Limit/velocity: OverTheLimit (2), FTDOverDailyLimit (3), TooManyCreditCards (4)
- Country conflicts: BinToRegCountryConflict (6), LoginToRegCountryConflict (8), High Risk Account Country (17)
- Affiliate: Affiliate Multiple Accounts (10), Affiliate Dormant Accounts (11)
- Investigation: PayPal Investigation (12), Relations (14)
- Chargebacks (inactive): CHBK CAL (15), CHBK Leumi (16), CHBK B&S (18), CHBK GlobalCollect (19)
- Other/newer: entries with higher IDs not visible in TOP 20 sample

### 2.2 IsActive Flag

**What**: Distinguishes currently used risk flags from deprecated legacy entries.

**Rules**:
- IsActive=True (74 rows): Currently used in risk evaluation and customer assignment
- IsActive=False (16 rows): Legacy/deprecated - primarily chargebacks and obsolete categories
- Analytics filtering: Use `WHERE IsActive = 1` to exclude deprecated flags from dashboards

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE-distributed with CLUSTERED INDEX on RiskStatusID. With 90 rows, REPLICATE is optimal. Join on RiskStatusID directly.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, the Gold export at `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_riskstatus` is Parquet. Read the entire table for any lookup.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Resolve RiskStatusID to name | `LEFT JOIN DWH_dbo.Dim_RiskStatus rs ON rs.RiskStatusID = fact.RiskStatusID` |
| Active risk flags only | `WHERE rs.IsActive = 1` |
| Customers flagged by active risk | `WHERE RiskStatusID NOT IN (0, 1) AND IsActive = 1` |

### 3.3 Gotchas

- **RiskCategoryID not in DWH**: Production Dictionary.RiskStatus has a RiskCategoryID FK to Dictionary.RiskCategories (for grouping by velocity/country/fraud/etc). This column is dropped by the DWH ETL. Group by Name pattern matching or hardcode IDs for category analysis.
- **DWHRiskStatusID = RiskStatusID**: Always equal. Prefer RiskStatusID for joins.
- **StatusID always 1**: Hardcoded Active for all rows. Distinct from IsActive.
- **IsActive=False rows**: Include in joins (they appear on historical records) but filter for current analysis.
- **ID gaps**: Not all IDs 0-90 are present. Some IDs were likely deleted from production.
- **Three distinct risk dimensions**: When working with customer risk data, understand the difference - RiskClassification (overall level e.g. High/Medium), RiskStatus (granular flag reason e.g. BinToRegCountryConflict), RiskManagementStatus (per-deposit check result e.g. DeclinedBlackListCountry).

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★★☆ | Tier 1 - Upstream wiki verbatim | `(Tier 1 - upstream wiki, Dictionary.RiskStatus)` |
| ★★★☆☆ | Tier 2 - Synapse SP code | `(Tier 2 - SP code)` |
| ★★☆☆☆ | Tier 3 - Live data | `(Tier 3 - live data)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RiskStatusID | int | NO | Primary key identifying the risk flag reason. 0=None, 1=Normal, 2=OverTheLimit, 3=FTDOverDailyLimit, 4=TooManyCreditCards, 5=Too Many PayPal Accounts, 6=BinToRegCountryConflict, 7=DepositNameConflict, 8=LoginToRegCountryConflict, 10=Affiliate Multiple Accounts, 17=High Risk Account Country, and many more up to ID 90. Stored in BackOffice.Customer.RiskStatusID. (Tier 1 - upstream wiki, Dictionary.RiskStatus) |
| 2 | Name | varchar(200) | YES | Human-readable risk flag name. Mix of PascalCase codes and plain English (e.g., "Too Many PayPal Accounts", "Negative Paramaters Relations"). Used in risk reports, compliance alerts, and BackOffice dashboards. (Tier 1 - upstream wiki, Dictionary.RiskStatus) |
| 3 | IsActive | bit | NO | Whether this risk flag is currently in use. True=active (74 rows), False=deprecated/legacy (16 rows, mostly CHBK-related). Filter on IsActive=1 for current risk analysis. (Tier 1 - upstream wiki, Dictionary.RiskStatus) |
| 4 | DWHRiskStatusID | int | YES | ETL-computed alias of RiskStatusID - always equals RiskStatusID. `[RiskStatusID] as [DWHRiskStatusID]` in SP_Dictionaries_DL_To_Synapse. DWH-specific field. Use RiskStatusID for joins. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 5 | StatusID | int | YES | Hardcoded 1 (Active) for all rows by ETL. Not present in production Dictionary.RiskStatus. Distinct from IsActive. Not a meaningful filter. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 6 | UpdateDate | datetime | YES | GETDATE() at SP_Dictionaries reload time. Not a business date. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 7 | InsertDate | datetime | YES | GETDATE() at SP_Dictionaries reload time. Same value as UpdateDate (TRUNCATE+INSERT pattern). (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| RiskStatusID | etoro.Dictionary.RiskStatus | RiskStatusID | passthrough |
| Name | etoro.Dictionary.RiskStatus | Name | passthrough |
| IsActive | etoro.Dictionary.RiskStatus | IsActive | passthrough |
| DWHRiskStatusID | - | - | ETL-computed: [RiskStatusID] aliased |
| StatusID | - | - | ETL-computed: hardcoded 1 |
| UpdateDate | - | - | ETL-computed: GETDATE() |
| InsertDate | - | - | ETL-computed: GETDATE() |

**Lost from production**:

| Production Column | Reason Dropped |
|-------------------|----------------|
| RiskCategoryID | Not carried to DWH; FK to Dictionary.RiskCategories grouping |

Full production documentation: see upstream wiki Dictionary/Tables/Dictionary.RiskStatus.md

### 5.2 ETL Pipeline

```
etoro.Dictionary.RiskStatus -> Generic Pipeline -> DWH_staging.etoro_Dictionary_RiskStatus -> SP_Dictionaries_DL_To_Synapse -> DWH_dbo.Dim_RiskStatus
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Dictionary.RiskStatus | 90 current rows (IDs 0-90 with gaps), 74 active |
| Staging | DWH_staging.etoro_Dictionary_RiskStatus | Raw import |
| ETL | SP_Dictionaries_DL_To_Synapse | TRUNCATE + INSERT. Adds DWHRiskStatusID, StatusID, UpdateDate, InsertDate. Drops RiskCategoryID. |
| Target | DWH_dbo.Dim_RiskStatus | 90 rows |
| Export | Generic Pipeline (daily) | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_riskstatus |

---

## 6. Relationships

### 6.1 References To (this object points to)

Production RiskCategoryID FK (to Dictionary.RiskCategories) is dropped by ETL.

### 6.2 Referenced By (other objects point to this)

No DWH_dbo views or procedures reference this table in the SSDT repo. Fact tables carrying RiskStatusID can join for label resolution.

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.CustomerStatic | RiskStatusID | Customer primary risk flag reason |

---

## 7. Sample Queries

### 7.1 List active risk flags
```sql
SELECT
    RiskStatusID,
    Name,
    IsActive
FROM [DWH_dbo].[Dim_RiskStatus]
WHERE IsActive = 1 AND RiskStatusID > 1
ORDER BY RiskStatusID
```

### 7.2 Customer count by risk flag
```sql
SELECT
    rs.Name AS RiskFlag,
    COUNT(DISTINCT cs.CustomerID) AS flagged_customers
FROM [DWH_dbo].[CustomerStatic] cs
LEFT JOIN [DWH_dbo].[Dim_RiskStatus] rs
    ON rs.RiskStatusID = cs.RiskStatusID
WHERE rs.RiskStatusID > 1
GROUP BY rs.Name
ORDER BY flagged_customers DESC
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped - Atlassian MCP not available.)

---

*Generated: 2026-03-19 | Quality: 8.0/10 (★★★★☆) | Phases: 7/14 (fast-path)*
*Tiers: 3 T1, 4 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 9/10, Logic: 8/10, Relationships: 5/10, Sources: 9/10*
*Object: DWH_dbo.Dim_RiskStatus | Type: Table | Production Source: etoro.Dictionary.RiskStatus*
