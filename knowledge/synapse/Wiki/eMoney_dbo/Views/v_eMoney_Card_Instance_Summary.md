# eMoney_dbo.v_eMoney_Card_Instance_Summary

> Analytics-facing view of `eMoney_Card_Instance_Summary` exposing all columns except the PII field `MaskedPAN`. One row per card instance (CID may have multiple rows). Same row count as base table: 130,301 rows covering 94,556 distinct CIDs. CardCreateDate range 2020-11-10 to 2026-04-11. Use this view for all standard card instance analytics to avoid inadvertent PAN exposure.

| Property | Value |
|----------|-------|
| **Schema** | eMoney_dbo |
| **Object Type** | View |
| **Base Table** | `eMoney_dbo.eMoney_Card_Instance_Summary` |
| **Production Source** | FiatDwhDB.dbo.FiatCardInstances + FiatCardStatuses (via base table SP) |
| **Refresh** | Reflects base table data; no separate refresh schedule. Base table refreshed daily via TRUNCATE+INSERT (SP_eMoney_Card_Instance_Summary). |
| **Synapse Distribution** | Inherits from base table: HASH(CID) |
| **Synapse Index** | Inherits from base table: HEAP |
| **UC Target** | `_Not_Migrated` (view-level UC export not configured; base table has UC Gold target) |
| **PII Exclusion** | MaskedPAN excluded — use base table for authorized PAN reconciliation only |

---

## 1. Business Meaning

`v_eMoney_Card_Instance_Summary` is the **recommended interface** for all eToro Money card instance analytics. It exposes the full schema of `eMoney_Card_Instance_Summary` minus the `MaskedPAN` column (PII — masked card number).

The view exists to reduce the risk of accidental PAN exposure in analytics queries. Both the base table and this view return identical rows — the only difference is the absence of MaskedPAN.

**When to use the view vs. base table**:
- **This view**: All standard analytics — card funnel, activation rates, usage metrics, customer card state
- **Base table (`eMoney_Card_Instance_Summary`)**: Only when `MaskedPAN` is required for card reconciliation or authorized investigation

For full business context, grain, business logic, and sample queries see the base table wiki: `eMoney_Card_Instance_Summary.md`.

**Key statistics** (inherited from base table):
- 130,301 rows / 94,556 distinct CIDs (avg 1.38 instances per customer)
- 45.9% of rows have NULL InstanceActivationDate (never-activated cards)
- InstanceStatus distribution: NotActivated 32.9%, Activated 29.8%, Expired 21.8%, Blocked 11.2%, Stolen 3.4%, Lost 0.8%

---

## 2. Business Logic

### 2.1 PII Exclusion

**What**: The view selects all 18 base table columns except MaskedPAN.

**Columns Involved**: All columns (see Elements section). MaskedPAN is absent.

**Rules**:
- `MaskedPAN` (nvarchar(50), base table column 10) is commented out in the view's SELECT list — `-- [MaskedPAN]`
- All other columns are selected without transformation or aliasing
- No row-level filtering — the view returns all rows from the base table

### 2.2 Inherited Business Logic

All business logic described in `eMoney_Card_Instance_Summary` applies to this view without change. Key patterns:
- One row per card instance (DWH_CardInstanceId) — NOT one row per customer
- `StatusByHighestRNDasc` vs `InstanceStatus` distinction (current customer card vs per-instance state)
- `TxAfterActivationCount` time window (activation to next activation)
- GCID_Unique_Count is always 1 in this table

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

View inherits the base table's HASH(CID) distribution. All distribution characteristics and query patterns from the base table apply directly.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Cards issued but never activated | `WHERE InstanceActivationDate IS NULL` |
| Customers with currently active card | `WHERE StatusByHighestRNDasc = 'Activated'` |
| First card activation per customer | MIN(InstanceActivationDate) OVER (PARTITION BY CID) |
| TX activity during instance active window | Use TxAfterActivationCount directly |
| Current card state of a customer | Use StatusByHighestRNDasc for the latest card assessment |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| eMoney_dbo.eMoney_Dim_Account | `v.CID = mda.CID AND GCID_Unique_Count=1` | Add account program, entity, IBAN status |
| eMoney_dbo.eMoney_Card_Monthly_Snapshot | `v.CID = s.CID` | Monthly card funnel context |
| DWH_dbo.Dim_Customer | `v.CID = dc.RealCID` | Trading profile (club, country) |

### 3.4 Gotchas

- **Multiple rows per CID**: Same as base table — always use `DISTINCT CID` for customer-level counts
- **MaskedPAN absent**: If PAN is needed for any reason (reconciliation, investigation), use the base table with appropriate authorization
- **45.9% null InstanceActivationDate**: Unactivated cards — NULL does not mean "unknown activation date"
- **View doesn't add or transform**: Any query optimization (adding indexes, etc.) must be done on the base table
- **View is not UC-exported**: The UC Gold export targets the base table, not the view

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Description sourced verbatim from upstream production database wiki (highest confidence) |
| Tier 2 | Description derived from SP code, DDL, or DWH wiki (high confidence) |
| Tier 3 | Inferred from column name, data pattern, or business context (medium confidence) |
| Tier 4 | Best available knowledge — limited upstream documentation (lower confidence) |

All descriptions are inherited verbatim from `eMoney_Card_Instance_Summary.md` (same source = same description).

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | bigint | YES | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Renamed from RealCID in DWH_dbo.Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| 2 | ProviderHolderID | bigint | YES | The external provider's (Tribe) identifier for this account holder. Used in all provider API interactions and support queries. Stored as string to accommodate different provider ID formats. DWH note: renamed from `ProviderHolderId`; CAST to INT. (Tier 1 — dbo.AccountsProviderHoldersMapping) |
| 3 | FMI_Date | date | YES | Date of the account's first settled money-in transaction (TxTypeID IN [5,7], TxStatusID=2, HolderAmount≠0). Derived from TxStatusModificationDate of ROW_NUMBER=1 (ASC by TxStatusModificationTime). NULL for accounts that have never funded. Earliest value: 2020-11-10 (UK launch). (Tier 2 — eMoney_Dim_Transaction) |
| 4 | DWH_CardID | bigint | YES | Auto-incrementing surrogate primary key. Referenced by FiatCardStatuses.CardId, FiatCardInstances (implicit), and CardsProvidersMapping.CardId. DWH note: renamed from CardID in eMoney_Dim_Account (originally FiatCards.Id). (Tier 1 — dbo.FiatCards) |
| 5 | ProviderCardID | bigint | YES | Provider-side card identifier from CardsProvidersMapping via eMoney_Account_Mappings. (Tier 2 — SP_eMoney_Dim_Account) |
| 6 | CardCreateDate | date | YES | Date portion of CardCreateTime. DWH-derived: CAST(CardCreateTime AS DATE). (Tier 2 — SP_eMoney_Dim_Account) |
| 7 | IsValidETM | int | YES | eToro Money validity flag. 1 when IsValidCustomer=1 AND IsTestAccount=0 AND IsCancelledAccount=0. Standard filter for eTM production analytics. 1=129,106 rows (99.1%), 0=1,195 (0.9%). (Tier 2 — SP_eMoney_Dim_Account) |
| 8 | GCID_Unique_Count | int | YES | Rank of this currency balance account for its GCID, ordered by AccountCreateTime DESC. 1 = most recently created eMoney account for this customer (the primary account). Customer DWH enrichment columns (CID, ClubID, etc.) are only populated for rank=1 rows. DWH note: always 1 in this table — SP JOIN filters on GCID_Unique_Count=1. (Tier 2 — SP_eMoney_Dim_Account) |
| 9 | DWH_CardInstanceId | bigint | YES | Auto-incrementing surrogate PK of the card instance. Referenced by FiatCardStatuses.CardInstanceId. DWH note: renamed from Id in dbo.FiatCardInstances. (Tier 1 — dbo.FiatCardInstances) |
| 10 | InstanceStatus | nvarchar(50) | YES | Current lifecycle status of THIS specific card instance. Resolved via JOIN on eMoney_Dictionary_CardStatus (newest FiatCardStatuses event by EventTimestamp DESC). 0=NotActivated (32.9%), 1=Activated (29.8%), 2=Blocked (11.2%), 7=Expired (21.8%), 4=Risk, 5=Stolen (3.4%), 6=Lost (0.8%), 3=Suspended, 8=Fraud, NULL=0.1%. (Tier 2 — SP_eMoney_Card_Instance_Summary) |
| 11 | InstanceCreatedDate | date | YES | Date the card instance was first issued — CAST(MIN(FiatCardStatuses.EventTimestamp WHERE CardStatusId=0) AS DATE). First NotActivated event = card creation/delivery. NULL for 1,120 instances with no status history. (Tier 2 — SP_eMoney_Card_Instance_Summary) |
| 12 | InstanceActivationDate | date | YES | Date the cardholder first activated this card instance — CAST(MIN(FiatCardStatuses.EventTimestamp WHERE CardStatusId=1) AS DATE). NULL for 59,932 rows (45.9%) where the card was never activated by the cardholder. (Tier 2 — SP_eMoney_Card_Instance_Summary) |
| 13 | InstanceExpirationDate | date | YES | Expiration date of this card instance. NULL for instances where expiration is not yet set. DWH note: CAST from datetime2 to DATE from FiatCardInstances.CardExpirationDate. (Tier 1 — dbo.FiatCardInstances) |
| 14 | StatusByHighestRNDasc | nvarchar(50) | YES | Status of the customer's most recently created card instance per DWH_CardID (highest RNDasc rank, ordered DESC). Same for all instances of the same DWH_CardID. Use this to assess the customer's current card state across the full issuance history. Values: Activated (42.0%), Expired (28.6%), NotActivated (23.9%), Stolen (3.4%), Lost (1.0%), Blocked (0.9%). (Tier 2 — SP_eMoney_Card_Instance_Summary) |
| 15 | NextActivationDateTime | datetime | YES | Activation timestamp of the next card instance for this CID. NULL when this is the most recent activated instance (no successor). Used to define the upper bound of TxAfterActivationCount window. (Tier 2 — SP_eMoney_Card_Instance_Summary) |
| 16 | TxAfterActivationCount | int | YES | Count of valid settled card transactions (IsValidETM=1, IsTxSettled=1, TxTypeID IN [1,2,3,4]) made by this CID after this instance's ActivationDateTime and before NextActivationDateTime (or all time if NULL). Range: 0–4,150, avg 20.7. 0 for unactivated instances. (Tier 2 — SP_eMoney_Card_Instance_Summary) |
| 17 | UpdateDate | datetime | NO | Timestamp when this record was written by the SP. Set to GETDATE() at TRUNCATE+INSERT time. Reflects the daily SP run, not a business event. (Tier 2 — SP_eMoney_Card_Instance_Summary) |

---

## 5. Lineage

### 5.1 Production Sources

All column lineage is inherited from the base table. See `eMoney_Card_Instance_Summary.lineage.md` for the complete column-level source mapping.

| View Column | Base Table | Transform |
|-------------|-----------|-----------|
| All 17 columns | eMoney_dbo.eMoney_Card_Instance_Summary | Passthrough (no transformation) |
| MaskedPAN | — | Excluded (PII) |

### 5.2 ETL Pipeline

```
FiatDwhDB.dbo.FiatCardInstances + FiatCardStatuses
  |-- SP_eMoney_Card_Instance_Summary (daily TRUNCATE+INSERT) ---|
  v
eMoney_dbo.eMoney_Card_Instance_Summary
  (130K rows, HASH(CID), UC Gold target)
  |-- CREATE VIEW: SELECT all EXCEPT MaskedPAN ---|
  v
eMoney_dbo.v_eMoney_Card_Instance_Summary
  (same 130K rows, 17 cols, analytics interface)
    |
    |-- UC Gold: _Not_Migrated (view-level export not configured) ---|
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer.RealCID | Customer identity |
| DWH_CardID | eMoney_dbo.eMoney_Dim_Account.CardID | Logical card reference |
| InstanceStatus | eMoney_dbo.eMoney_Dictionary_CardStatus | Status name lookup |
| (all columns) | eMoney_dbo.eMoney_Card_Instance_Summary | Base table |

### 6.2 Referenced By (other objects point to this)

This view is the recommended interface for all analytics against the card instance timeline. Referenced by users/analysts avoiding direct base table access.

---

## 7. Sample Queries

### Card Activation Rate by Year of First Issuance

```sql
SELECT YEAR(InstanceCreatedDate) AS issuance_year,
       COUNT(*) AS total_instances,
       SUM(CASE WHEN InstanceActivationDate IS NOT NULL THEN 1 ELSE 0 END) AS activated,
       ROUND(100.0 * SUM(CASE WHEN InstanceActivationDate IS NOT NULL THEN 1 ELSE 0 END) / COUNT(*), 1) AS activation_rate_pct
FROM [eMoney_dbo].[v_eMoney_Card_Instance_Summary]
WHERE IsValidETM = 1
GROUP BY YEAR(InstanceCreatedDate)
ORDER BY issuance_year;
```

### Customers with Currently Active Cards and Transaction History

```sql
SELECT CID,
       FMI_Date,
       CardCreateDate,
       InstanceActivationDate,
       TxAfterActivationCount,
       InstanceStatus,
       StatusByHighestRNDasc
FROM [eMoney_dbo].[v_eMoney_Card_Instance_Summary]
WHERE StatusByHighestRNDasc = 'Activated'
  AND IsValidETM = 1
ORDER BY TxAfterActivationCount DESC;
```

### Card Replacement Analysis (Multiple Instances per Customer)

```sql
SELECT CID,
       COUNT(*) AS instance_count,
       MIN(InstanceCreatedDate) AS first_card_date,
       MAX(InstanceCreatedDate) AS latest_card_date
FROM [eMoney_dbo].[v_eMoney_Card_Instance_Summary]
GROUP BY CID
HAVING COUNT(*) > 1
ORDER BY instance_count DESC;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for v_eMoney_Card_Instance_Summary beyond what was found for the base table. See `eMoney_Card_Instance_Summary.md` Section 8 for base table Atlassian context.

---

*Generated: 2026-04-21 | Quality: 8.9/10 | Phases: 7/14 (view — 7 phases not applicable)*
*Tiers: 4 T1, 13 T2, 0 T3, 0 T4, 0 T5 | Elements: 17/17 (MaskedPAN excluded by design)*
*Object: eMoney_dbo.v_eMoney_Card_Instance_Summary | Type: View | Base Table: eMoney_Card_Instance_Summary*
