# DWH_dbo.Dim_PlayerStatusSubReasons

> Lookup table defining 83 granular sub-reason codes for account status changes -- providing the second-level detail beneath Dim_PlayerStatusReasons, covering fraud types, chargeback sources, compliance investigations, AML triggers, and regulatory requirements.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.PlayerStatusSubReasons |
| **Refresh** | Daily |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (PlayerStatusSubReasonID ASC) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons` |
| **UC Format** | Delta |
| **UC Partitioned By** | None (83 rows) |
| **UC Table Type** | Managed |

---

## 1. Business Meaning

Dim_PlayerStatusSubReasons provides the second level of detail for account status changes, working beneath Dim_PlayerStatusReasons. While the Reason gives the broad category (e.g., "Chargeback"), the SubReason gives the specific detail (e.g., "ACH CHBK", "Credit Card CHBK", "PayPal CHBK"). This two-level classification gives compliance, risk, and operations teams the granularity needed for investigation tracking and reporting.

The 83 sub-reasons (IDs 0-82) span: fraud types (Fraud, Fake docs, Attack, Affiliate Fraud, 3rd Party), verification failures (Failed Verification, POI/POA Required), chargeback sources (ACH CHBK, Credit Card CHBK, PayPal CHBK, PWMB CHBK -- 11 variants), screening results (Sanctions, PEP, WCH matches), AML triggers (Investigation, AML Trigger, SAR filed, Law enforcement request), regulatory (FATCA, CRS, W-8BEN, corporate LEI), and operational states (1st Warning, 2nd Warning, Vulnerable Client).

This table is always used together with Dim_PlayerStatusReasons -- both IDs are stored on Dim_Customer and Fact_SnapshotCustomer for every customer. ID=0 (None) is the default when no specific sub-reason has been recorded.

**COLUMN RENAME**: Production column `Name` is renamed to `PlayerStatusSubReasonName` in DWH. All other columns are passthrough.

**ALL COLUMNS NULLABLE**: Unlike Dim_PlayerStatusReasons, all 3 DWH columns (including the PK PlayerStatusSubReasonID) are defined as NULL in the DDL. This is structurally unusual.

Data originates from `etoro.Dictionary.PlayerStatusSubReasons` on etoroDB-REAL, exported daily via Generic Pipeline, then loaded from `DWH_staging.etoro_Dictionary_PlayerStatusSubReasons` by SP_Dictionaries_DL_To_Synapse using TRUNCATE + INSERT with a Name -> PlayerStatusSubReasonName rename.

---

## 2. Business Logic

### 2.1 Sub-Reason Categories

**What**: Major groupings of the 83 sub-reasons.

**Columns Involved**: `PlayerStatusSubReasonID`, `PlayerStatusSubReasonName`

**Rules**:
- **ID=0 (None)**: Default -- no specific sub-reason recorded. Comes from production (not a DWH-only placeholder).
- **Fraud/Abuse** (1-6, 49, 64-65): Fraud, Fake docs, Attack, Affiliate Fraud, 3rd Party, Lost Funds, 3rd Party Trading, Market Abuse, Affiliate Abuse
- **Verification** (7, 24-26, 59, 61, 81-82): Failed Verification, Closed Verification, Selfie, Expired POI/POA, Pending Docs, 15-Day Failure, POI Required, POA Required
- **Chargeback Sources** (35-45): ACH CHBK, Credit Card CHBK, PayPal CHBK, PWMB CHBK, Other MOP CHBK, 3rd Party CHBK, CO Logic CHBK, Currency Difference CHBK, Fraud CHBK, Risk Refunded CHBK, Service/Complaint CHBK
- **Screening** (13-16, 31-34): WCH negative results, Sanctions, PEP Failed Verification, Possible Match (old and new naming)
- **AML/Investigation** (17-21, 73-74): Investigation, Cross Border, AML Trigger, Business Method, Mixed Funds, SAR Filed, Law Enforcement Request
- **Deposit-Related** (22-23, 29, 46-48, 53, 69, 78-79): FTD, Redeposit, PWMB Failed Deposit, 3rd Party FTD/Business MOP/Redeposit, ACH Failed Deposit, Preapproved Monitoring, Failed Min FTD, Failed Deposit
- **Warnings** (62-63): 1st Warning, 2nd Warning/Termination
- **Account Types** (54-58): Affiliate Account, Affiliate Re-linked, Affiliate Terminated, PI 2nd Account, PI Account
- **Regulatory** (60, 66-68, 70-72, 76): Corp Expired LEI, FATCA, CRS, FATCA0013, Corporate LEI issues, Corporate/SMSF Pending Docs, W-8BEN
- **Other** (8-12, 50-52, 75, 77, 80): Service/technical issues, Risk Refunded, Currency Differences, CO Logic, No Triggers, PayPal Investigation, Risk Check, Low Risk, Vulnerable Client, Negative Balance, UAE PASS Reactivation

**Abbreviation Glossary**: CHBK=Chargeback, POI=Proof of Identity, POA=Proof of Address, FTD=First Time Deposit, MOP=Method of Payment, PWMB=eToro Money, LEI=Legal Entity Identifier, PEP=Politically Exposed Person, SAR=Suspicious Activity Report, WCH=World Check, CRS=Common Reporting Standard, FATCA=Foreign Account Tax Compliance Act.

### 2.2 Reason-SubReason Hierarchy

**What**: Sub-reasons are always paired with a parent reason.

**Columns Involved**: `PlayerStatusSubReasonID`

**Rules**:
- Used alongside PlayerStatusReasonID -- both are stored on Dim_Customer.
- In production, valid Reason->SubReason combinations are governed by BackOffice.PlayerStatusReasonToSubReason (not replicated to DWH).
- ID=0 (None) as sub-reason typically accompanies ID=0 (None) as reason -- meaning neither level has been explicitly set.
- Use `WHERE PlayerStatusSubReasonID > 0` to filter to customers with explicit sub-reason classifications.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE-distributed with a CLUSTERED INDEX on PlayerStatusSubReasonID. With 83 rows, performance is never a concern. All columns are nullable -- apply ISNULL() defensively.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, this table lands as `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons`. With 83 rows, no partitioning or Z-ORDER is needed.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| What sub-reason for a customer? | JOIN Dim_Customer ON PlayerStatusSubReasonID |
| Find all chargeback sub-reasons | WHERE PlayerStatusSubReasonName LIKE '%CHBK%' |
| Count customers by sub-reason | GROUP BY PlayerStatusSubReasonID on Fact_SnapshotCustomer |
| Exclude "no sub-reason" rows | WHERE PlayerStatusSubReasonID > 0 |
| Combine with parent reason | JOIN BOTH Dim_PlayerStatusReasons AND Dim_PlayerStatusSubReasons |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON dc.PlayerStatusSubReasonID = dpssr.PlayerStatusSubReasonID | Resolve sub-reason per customer |
| DWH_dbo.V_Dim_Customer | ON vdc.PlayerStatusSubReasonID = dpssr.PlayerStatusSubReasonID | View-level sub-reason resolution |
| DWH_dbo.Fact_SnapshotCustomer | ON fsc.PlayerStatusSubReasonID = dpssr.PlayerStatusSubReasonID | Sub-reason in daily snapshots |
| DWH_dbo.Fact_SnapshotCustomerCloseYear | ON fsccy.PlayerStatusSubReasonID = dpssr.PlayerStatusSubReasonID | Sub-reason in year-end snapshots |

### 3.4 Gotchas

- **Column rename**: Production `Name` -> DWH `PlayerStatusSubReasonName`. Do NOT query for `Name` in DWH; the column does not exist.
- **ALL columns nullable**: PlayerStatusSubReasonID itself is defined as NULL in the DDL (unusual for a PK). Handle potential NULLs defensively even on the ID column.
- **ID=0 is a real production row**: Row 0 (None) comes from production -- not a DWH-only ETL placeholder.
- **CHBK abbreviation**: All chargeback sub-reasons use the abbreviation "CHBK" not "Chargeback". Filter with LIKE '%CHBK%' to find them.
- **ETL staleness**: UpdateDate = 2026-03-11 (8+ days stale as of 2026-03-19) -- consistent with schema-wide SP_Dictionaries_DL_To_Synapse disruption.
- **Reason-SubReason mapping not in DWH**: The valid Reason->SubReason combination table (BackOffice.PlayerStatusReasonToSubReason) is only in production. DWH does not replicate it.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| **** | Tier 1 - upstream wiki verbatim | (Tier 1 - upstream wiki, Dictionary.PlayerStatusSubReasons) |
| *** | Tier 2 - Synapse SP code | (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | PlayerStatusSubReasonID | int | YES | Primary key identifying the granular sub-reason (NOTE: DDL allows NULL -- unusual for a PK). Range 0-82. 0=None (real production row, not DWH placeholder). FK used by Dim_Customer, Fact_SnapshotCustomer, V_Dim_Customer, and Fact_SnapshotCustomerCloseYear. Provides second-level detail beneath PlayerStatusReasonID. (Tier 1 - upstream wiki, Dictionary.PlayerStatusSubReasons) |
| 2 | PlayerStatusSubReasonName | varchar(50) | YES | Human-readable sub-reason label (renamed from production `Name`). Nullable. Key abbreviations: CHBK=Chargeback, POI=Proof of Identity, POA=Proof of Address, FTD=First Time Deposit, MOP=Method of Payment, PWMB=eToro Money, SAR=Suspicious Activity Report, WCH=World Check. Key values: Fraud (1), Fake docs (2), ACH CHBK (35), Credit Card CHBK (36), PayPal CHBK (37), SAR filed (73), FATCA (66), W-8BEN (76), Vulnerable Client (75). (Tier 1 - upstream wiki, Dictionary.PlayerStatusSubReasons) |
| 3 | UpdateDate | datetime | YES | ETL load timestamp -- set to GETDATE() on each SP_Dictionaries_DL_To_Synapse run. Does not reflect production data modification time. All rows share same timestamp per reload (2026-03-11 as of last load). Also nullable in DWH DDL. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| PlayerStatusSubReasonID | Dictionary.PlayerStatusSubReasons | PlayerStatusSubReasonID | passthrough |
| PlayerStatusSubReasonName | Dictionary.PlayerStatusSubReasons | Name | rename (Name -> PlayerStatusSubReasonName) |
| UpdateDate | -- | -- | ETL-computed: GETDATE() on reload |

Full production documentation: see upstream wiki `Dictionary/Tables/Dictionary.PlayerStatusSubReasons.md`

### 5.2 ETL Pipeline

```
etoro.Dictionary.PlayerStatusSubReasons
  -> Generic Pipeline (daily, Override/full-load)
  -> Bronze/etoro/Dictionary/PlayerStatusSubReasons/
  -> DWH_staging.etoro_Dictionary_PlayerStatusSubReasons
  -> SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT SELECT, Name -> PlayerStatusSubReasonName)
  -> DWH_dbo.Dim_PlayerStatusSubReasons
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Dictionary.PlayerStatusSubReasons | Production sub-reason dictionary (etoroDB-REAL) -- 2 data cols, 83 rows |
| Lake | Bronze/etoro/Dictionary/PlayerStatusSubReasons/ | Daily full export via Generic Pipeline (Override, 1440 min) |
| Staging | DWH_staging.etoro_Dictionary_PlayerStatusSubReasons | Raw staging import -- Name col stored as `Name` |
| ETL | SP_Dictionaries_DL_To_Synapse (line ~1015) | TRUNCATE + INSERT SELECT; Name -> PlayerStatusSubReasonName rename; UpdateDate=getdate() |
| Target | DWH_dbo.Dim_PlayerStatusSubReasons | 83 rows, 3 cols, REPLICATE + CLUSTERED INDEX |

---

## 6. Relationships

### 6.1 References To (this object points to)

N/A -- leaf dictionary table with no outgoing foreign key references.

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Dim_Customer | PlayerStatusSubReasonID | Customer's current status change sub-reason |
| DWH_dbo.V_Dim_Customer | PlayerStatusSubReasonID | View exposing sub-reason for customer dimension |
| DWH_dbo.Fact_SnapshotCustomer | PlayerStatusSubReasonID | Sub-reason in daily customer snapshot |
| DWH_dbo.Fact_SnapshotCustomerCloseYear | PlayerStatusSubReasonID | Sub-reason in year-end customer snapshot |

---

## 7. Sample Queries

### 7.1 List all chargeback sub-reasons

```sql
SELECT PlayerStatusSubReasonID,
       PlayerStatusSubReasonName
FROM   [DWH_dbo].[Dim_PlayerStatusSubReasons]
WHERE  PlayerStatusSubReasonName LIKE '%CHBK%'
ORDER BY PlayerStatusSubReasonID;
```

### 7.2 Count customers by sub-reason (excluding none)

```sql
SELECT  dpssr.PlayerStatusSubReasonName  AS SubReason,
        COUNT(*)                          AS CustomerCount
FROM    [DWH_dbo].[Dim_Customer] dc
JOIN    [DWH_dbo].[Dim_PlayerStatusSubReasons] dpssr
        ON dc.PlayerStatusSubReasonID = dpssr.PlayerStatusSubReasonID
WHERE   dc.PlayerStatusSubReasonID > 0
GROUP BY dpssr.PlayerStatusSubReasonName
ORDER BY CustomerCount DESC;
```

### 7.3 Full reason + sub-reason for each customer

```sql
SELECT  dc.CID,
        dpsr.Name                         AS Reason,
        dpssr.PlayerStatusSubReasonName   AS SubReason
FROM    [DWH_dbo].[Dim_Customer] dc
JOIN    [DWH_dbo].[Dim_PlayerStatusReasons] dpsr
        ON dc.PlayerStatusReasonID = dpsr.PlayerStatusReasonID
JOIN    [DWH_dbo].[Dim_PlayerStatusSubReasons] dpssr
        ON dc.PlayerStatusSubReasonID = dpssr.PlayerStatusSubReasonID
WHERE   dc.PlayerStatusReasonID > 0
ORDER BY dc.CID;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Quality: 8.5/10 (****) | Phases: 7/14 (Simple-Dict fast-path)*
*Tiers: 2 T1, 1 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 9/10*
*Object: DWH_dbo.Dim_PlayerStatusSubReasons | Type: Table | Production Source: etoro.Dictionary.PlayerStatusSubReasons*
