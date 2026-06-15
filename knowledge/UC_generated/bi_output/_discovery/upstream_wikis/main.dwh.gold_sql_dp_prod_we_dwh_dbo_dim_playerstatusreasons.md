# DWH_dbo.Dim_PlayerStatusReasons

> Lookup table defining 44 reason codes explaining why a customer's account status was changed -- from compliance/AML actions and KYC failures to chargebacks, user-initiated closures, and administrative decisions.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.PlayerStatusReasons |
| **Refresh** | Daily |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (PlayerStatusReasonID ASC) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons` |
| **UC Format** | Delta |
| **UC Partitioned By** | None (44 rows) |
| **UC Table Type** | Managed |

---

## 1. Business Meaning

Dim_PlayerStatusReasons is the first level of a two-tier reason classification hierarchy for account status changes. When an account is blocked, suspended, restricted, or closed, the system records both the new status (Dim_PlayerStatus) and the broad reason category for the change. This table provides that top-level category.

The 44 reason codes (IDs 0-43) span the full range of account status change triggers: compliance/AML investigations (IDs 6, 10, 11, 18), KYC failures (1, 2, 39), risk flags (4, 7, 14, 25, 34, 35), fraud/chargebacks (5, 23, 24, 30-32), user-initiated actions (3, 20, 21, 22), payment issues (13, 16, 17, 38), and administrative decisions (8, 9, 12, 19, 37, 40-43). ID=0 (None) is the default when no reason has been explicitly recorded.

This table works as a hierarchy with Dim_PlayerStatusSubReasons -- Reason gives the broad category (e.g., "Chargeback"), and SubReason provides granular detail (e.g., "ACH CHBK", "Credit Card CHBK"). Dim_Customer and Fact_SnapshotCustomer store both PlayerStatusReasonID and PlayerStatusSubReasonID for every customer.

Data originates from `etoro.Dictionary.PlayerStatusReasons` on etoroDB-REAL, exported daily via Generic Pipeline, then loaded from `DWH_staging.etoro_Dictionary_PlayerStatusReasons` by SP_Dictionaries_DL_To_Synapse using TRUNCATE + INSERT passthrough.

---

## 2. Business Logic

### 2.1 Reason Categories

**What**: Major groupings of the 44 account status change reasons.

**Columns Involved**: `PlayerStatusReasonID`, `Name`

**Rules**:
- **ID=0 (None)**: Default state -- no explicit reason recorded. Included in production table, not a DWH-only sentinel.
- **Compliance/AML** (6, 10, 11, 18): AML-Account Closed, AML, AML review, WCH match (World Check sanctions screening)
- **KYC/Verification** (1, 2, 27, 39): Failed Verification, Expired Document, Pending Docs, KYC
- **Risk/Fraud** (4, 7, 14, 15, 25, 34, 35): Risk, HRC (High Risk Country), Risk Check, 3rd Party, Abuse, Abusive Trading, Hacked Account
- **Chargebacks** (5, 23, 24, 30, 31, 32): Chargeback, ACH Chargeback, PWMB Chargeback, CheckoutChargeback, CheckoutRetrievel, CheckoutCaptureDecline
- **User-Initiated** (3, 20, 21, 22): CloseAccountByUser, Right to be forgotten (GDPR), Self-Service, By request
- **Payment Issues** (13, 16, 17, 38): Overpayment, PayPal Investigation, NOC/NOF/RFI, Deposits
- **Account Types** (26, 28, 29, 36): Affiliate Account, Employee Account, PI Account, Partners & PIs
- **Administrative** (8, 9, 12, 19, 37, 40, 42, 43): Underage, Deceased, Off Market Abuse, Other, CS management decision, Account Closed, Corporate, Gap
- **Regulatory** (33, 41): eToro Money Restriction, Tax (FATCA/CRS)

### 2.2 Reason-SubReason Hierarchy

**What**: Reasons are further refined by sub-reasons stored in Dim_PlayerStatusSubReasons.

**Columns Involved**: `PlayerStatusReasonID`

**Rules**:
- Not every reason is valid for every status -- BackOffice.PlayerStatusToReason governs valid status-to-reason combinations (production side).
- Not every sub-reason is valid for every reason -- BackOffice.PlayerStatusReasonToSubReason governs valid reason-to-subreason combinations (production side).
- Both PlayerStatusReasonID and PlayerStatusSubReasonID are stored together on Dim_Customer and Fact_SnapshotCustomer.
- ID=0 (None) is the default -- use `WHERE PlayerStatusReasonID > 0` to filter to customers with explicit status change reasons.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE-distributed with a CLUSTERED INDEX on PlayerStatusReasonID. With 44 rows, performance is never a concern. JOIN to Dim_Customer or Fact_SnapshotCustomer on PlayerStatusReasonID is straightforward.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, this table lands as `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons`. With 44 rows, no partitioning or Z-ORDER is needed.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| What reason was given for a blocked customer? | JOIN Dim_Customer ON PlayerStatusReasonID |
| Count customers blocked per reason | GROUP BY PlayerStatusReasonID on Fact_SnapshotCustomer |
| Filter to AML-related reasons only | WHERE PlayerStatusReasonID IN (6, 10, 11, 18) |
| Exclude "no reason" rows | WHERE PlayerStatusReasonID > 0 |
| What sub-reasons exist under a reason? | JOIN Dim_PlayerStatusSubReasons -- mapping in production BackOffice only |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON dc.PlayerStatusReasonID = dpsr.PlayerStatusReasonID | Resolve reason name per customer |
| DWH_dbo.V_Dim_Customer | ON vdc.PlayerStatusReasonID = dpsr.PlayerStatusReasonID | View-level reason resolution |
| DWH_dbo.Fact_SnapshotCustomer | ON fsc.PlayerStatusReasonID = dpsr.PlayerStatusReasonID | Reason in daily snapshots |
| DWH_dbo.Fact_SnapshotCustomerCloseYear | ON fsccy.PlayerStatusReasonID = dpsr.PlayerStatusReasonID | Reason in year-end snapshots |

### 3.4 Gotchas

- **Name is nullable**: Unlike most DWH dimension columns, `Name` is varchar(50) NULL. Handle NULL safely: `ISNULL(Name, 'Unknown')`.
- **ID=0 is a real production row (None)**: Unlike other Dim_ tables, there is no DWH-only ID=0 sentinel -- row 0 comes directly from production and means "no reason specified".
- **ETL staleness**: UpdateDate = 2026-03-11 for all rows (8+ days as of 2026-03-19) -- consistent with known SP_Dictionaries_DL_To_Synapse disruption across the schema.
- **Reason-SubReason mapping not in DWH**: The valid Reason->SubReason combinations are only in production BackOffice.PlayerStatusReasonToSubReason. DWH has both dimension tables but not the mapping table.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| **** | Tier 1 - upstream wiki verbatim | (Tier 1 - upstream wiki, Dictionary.PlayerStatusReasons) |
| *** | Tier 2 - Synapse SP code | (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | PlayerStatusReasonID | int | NO | Primary key identifying the account status change reason. Range 0-43. 0=None (no reason -- real production row, not a DWH placeholder). FK used by Dim_Customer, Fact_SnapshotCustomer, V_Dim_Customer, and Fact_SnapshotCustomerCloseYear. Represents first-level classification in the Reason->SubReason hierarchy. (Tier 1 - upstream wiki, Dictionary.PlayerStatusReasons) |
| 2 | Name | varchar(50) | YES | Human-readable reason label (nullable). Key values: None (0), Failed Verification (1), Chargeback (5), AML-Account Closed (6), HRC (7), AML (10), AML review (11), WCH match (18), Right to be forgotten (20), Self-Service (21), eToro Money Restriction (33), Abusive Trading (34), Hacked Account (35), Tax (41). Used in BackOffice reporting and customer history views. (Tier 1 - upstream wiki, Dictionary.PlayerStatusReasons) |
| 3 | UpdateDate | datetime | NO | ETL load timestamp -- set to GETDATE() on each SP_Dictionaries_DL_To_Synapse run. Does not reflect production data modification time. All rows share the same timestamp per reload (2026-03-11 as of last load). (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| PlayerStatusReasonID | Dictionary.PlayerStatusReasons | PlayerStatusReasonID | passthrough |
| Name | Dictionary.PlayerStatusReasons | Name | passthrough |
| UpdateDate | -- | -- | ETL-computed: GETDATE() on reload |

Full production documentation: see upstream wiki `Dictionary/Tables/Dictionary.PlayerStatusReasons.md`

### 5.2 ETL Pipeline

```
etoro.Dictionary.PlayerStatusReasons
  -> Generic Pipeline (daily, Override/full-load)
  -> Bronze/etoro/Dictionary/PlayerStatusReasons/
  -> DWH_staging.etoro_Dictionary_PlayerStatusReasons
  -> SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT SELECT)
  -> DWH_dbo.Dim_PlayerStatusReasons
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Dictionary.PlayerStatusReasons | Production reason dictionary (etoroDB-REAL) -- 2 data cols + metadata, 44 rows |
| Lake | Bronze/etoro/Dictionary/PlayerStatusReasons/ | Daily full export via Generic Pipeline (Override, 1440 min) |
| Staging | DWH_staging.etoro_Dictionary_PlayerStatusReasons | Raw staging import -- passthrough cols |
| ETL | SP_Dictionaries_DL_To_Synapse (line ~999) | TRUNCATE + INSERT SELECT; UpdateDate=getdate() |
| Target | DWH_dbo.Dim_PlayerStatusReasons | 44 rows, 3 cols, REPLICATE + CLUSTERED INDEX |

---

## 6. Relationships

### 6.1 References To (this object points to)

N/A -- leaf dictionary table with no outgoing foreign key references.

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Dim_Customer | PlayerStatusReasonID | Customer's current status change reason |
| DWH_dbo.V_Dim_Customer | PlayerStatusReasonID | View exposing reason for customer dimension |
| DWH_dbo.Fact_SnapshotCustomer | PlayerStatusReasonID | Reason in daily customer snapshot |
| DWH_dbo.Fact_SnapshotCustomerCloseYear | PlayerStatusReasonID | Reason in year-end customer snapshot |

---

## 7. Sample Queries

### 7.1 List all status change reasons

```sql
SELECT PlayerStatusReasonID,
       Name
FROM   [DWH_dbo].[Dim_PlayerStatusReasons]
ORDER BY PlayerStatusReasonID;
```

### 7.2 Count customers by status reason (excluding "no reason")

```sql
SELECT  dpsr.Name            AS StatusReason,
        COUNT(*)             AS CustomerCount
FROM    [DWH_dbo].[Dim_Customer] dc
JOIN    [DWH_dbo].[Dim_PlayerStatusReasons] dpsr
        ON dc.PlayerStatusReasonID = dpsr.PlayerStatusReasonID
WHERE   dc.PlayerStatusReasonID > 0
GROUP BY dpsr.Name
ORDER BY CustomerCount DESC;
```

### 7.3 Find all AML and compliance-blocked customers

```sql
SELECT  dc.CID,
        dpsr.Name  AS StatusReason
FROM    [DWH_dbo].[Dim_Customer] dc
JOIN    [DWH_dbo].[Dim_PlayerStatusReasons] dpsr
        ON dc.PlayerStatusReasonID = dpsr.PlayerStatusReasonID
WHERE   dc.PlayerStatusReasonID IN (6, 10, 11, 18)  -- AML variants + WCH match
ORDER BY dc.CID;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Quality: 8.5/10 (****) | Phases: 7/14 (Simple-Dict fast-path)*
*Tiers: 2 T1, 1 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 9/10*
*Object: DWH_dbo.Dim_PlayerStatusReasons | Type: Table | Production Source: etoro.Dictionary.PlayerStatusReasons*
