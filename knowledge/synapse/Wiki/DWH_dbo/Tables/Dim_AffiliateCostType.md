# DWH_dbo.Dim_AffiliateCostType

> Frozen lookup table classifying affiliate marketing cost types — CPA, lead, registration, clicks, sales, etc.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | Legacy DWH SQL Server (via DWH_Migration, Sept 2024) |
| **Refresh** | None — frozen since migration. No active ETL. |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (AffiliateCostTypeID ASC) |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

---

## 1. Business Meaning

Dim_AffiliateCostType classifies the types of costs associated with eToro's affiliate marketing program. Each row represents a different cost model through which affiliates are compensated for driving traffic and conversions to the platform: CPA (cost-per-acquisition), sales commissions, bonuses, registration fees, click-based payments, and more.

This table was migrated from the legacy on-premises DWH SQL Server in September 2024 via `DWH_Migration.Dim_AffiliateCostType`. It has no active ETL — InsertDate and UpdateDate are NULL for all rows, indicating the data was loaded once and never refreshed. The 11 rows (including the ID=0 "N/A" placeholder) appear to be a complete, static enumeration of affiliate cost models.

The table is likely referenced by affiliate cost fact tables (e.g., Dim_Affiliate, affiliate cost reports) to classify marketing expenditure by cost type.

---

## 2. Business Logic

### 2.1 Affiliate Cost Model Classification

**What**: Affiliate cost types define how the platform compensates marketing partners.

**Columns Involved**: `AffiliateCostTypeID`, `Name`

**Rules**:
- **Performance-based**: CPA (5) = Cost Per Acquisition — payment per converted customer; First Position (1) = payment when referred customer opens first trade
- **Revenue-sharing**: Sales (2) = commission on referred customer's trading activity
- **Incentive-based**: Bonus (3) = bonus payments to affiliates; Chargeback (4) = clawback of affiliate commission on reversed transactions
- **Lead generation**: Lead (6) = payment per qualified lead; Registration (7) = payment per registration
- **Traffic-based**: Clicks (8) = payment per click/visit
- **Copy-trade**: Copys (9) = payment related to copy-trade referrals
- **Electronic cost**: eCost (10) = electronic/digital marketing cost classification

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE-distributed with a CLUSTERED INDEX on AffiliateCostTypeID. With only 11 rows, JOINs are always local and fast.

### 3.1b UC (Databricks) Storage & Partitioning

_Pending — resolved during write-objects._

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Affiliate costs by type | JOIN affiliate cost fact table on AffiliateCostTypeID, GROUP BY Name |
| CPA costs only | WHERE AffiliateCostTypeID = 5 |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Affiliate | AffiliateCostTypeID | Resolve cost type for affiliate records |

### 3.4 Gotchas

- **Frozen data**: No active ETL. If new affiliate cost types are introduced, they must be inserted manually.
- **NULL timestamps**: InsertDate and UpdateDate are NULL for all rows — timestamps were never populated during the original load or migration.
- **ID=0 is "N/A"**: Placeholder row for unclassified costs.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Meaning |
|-------|------|---------|
| ★★★ (3) | Tier 2b | DWH_Migration DDL — verified from migration script |
| ★★ (2) | Tier 3 | Live data sampling — observed from actual Synapse data |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | AffiliateCostTypeID | smallint | NO | Primary key identifying the affiliate cost model. 0=N/A, 1=First Position, 2=Sales, 3=Bonus, 4=Chargeback, 5=CPA, 6=Lead, 7=Registration, 8=Clicks, 9=Copys, 10=eCost. (Tier 3 — live data sampling) |
| 2 | Name | varchar(50) | NO | Human-readable label for the affiliate cost type. E.g., "CPA", "Sales", "Lead". NOT NULL — every cost type must have a name. (Tier 3 — live data sampling) |
| 3 | InsertDate | datetime | YES | Intended as ETL insert timestamp but NULL for all 11 rows. Never populated — likely because the original legacy DWH load did not set this column. (Tier 2b — DWH_Migration DDL, confirmed via live data) |
| 4 | UpdateDate | datetime | YES | Intended as ETL update timestamp but NULL for all 11 rows. Never populated. (Tier 2b — DWH_Migration DDL, confirmed via live data) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| AffiliateCostTypeID | Legacy DWH SQL Server | AffiliateCostTypeID | Passthrough |
| Name | Legacy DWH SQL Server | Name | Passthrough |
| InsertDate | Legacy DWH SQL Server | InsertDate | Passthrough (NULL) |
| UpdateDate | Legacy DWH SQL Server | UpdateDate | Passthrough (NULL) |

### 5.2 ETL Pipeline

```
Legacy DWH SQL Server → One-time migration (Sept 2024) → DWH_Migration.Dim_AffiliateCostType → DWH_dbo.Dim_AffiliateCostType
```

| Step | Object | Description |
|------|--------|-------------|
| Source | Legacy DWH SQL Server | On-premises affiliate cost type dictionary |
| Migration | DWH_Migration.Dim_AffiliateCostType | Migration staging (Sept 2024) |
| Target | DWH_dbo.Dim_AffiliateCostType | Final DWH table. Frozen, no active ETL. |

---

## 6. Relationships

### 6.1 References To (this object points to)

This object has no outgoing references.

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Dim_Affiliate | AffiliateCostTypeID | Classifies the cost model for each affiliate partner |

---

## 7. Sample Queries

### 7.1 List all affiliate cost types
```sql
SELECT  AffiliateCostTypeID,
        Name
FROM    [DWH_dbo].[Dim_AffiliateCostType]
WHERE   AffiliateCostTypeID > 0
ORDER BY AffiliateCostTypeID;
```

### 7.2 Count affiliates by cost type
```sql
SELECT  dact.Name AS CostType,
        COUNT(*) AS AffiliateCount
FROM    [DWH_dbo].[Dim_Affiliate] da
JOIN    [DWH_dbo].[Dim_AffiliateCostType] dact
        ON da.AffiliateCostTypeID = dact.AffiliateCostTypeID
GROUP BY dact.Name
ORDER BY AffiliateCount DESC;
```

### 7.3 Show all CPA affiliates
```sql
SELECT  da.*
FROM    [DWH_dbo].[Dim_Affiliate] da
WHERE   da.AffiliateCostTypeID = 5;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. This is a frozen legacy dictionary with self-evident business meaning.

---

*Generated: 2026-03-18 | Quality: 7.2/10 (★★★★☆) | Phases: 7/14*
*Tiers: 0 T1, 2 T2b, 2 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 6/10*
*Object: DWH_dbo.Dim_AffiliateCostType | Type: Table | Production Source: Legacy DWH SQL Server (DWH_Migration)*
