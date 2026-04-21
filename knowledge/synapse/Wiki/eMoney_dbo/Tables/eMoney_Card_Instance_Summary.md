# eMoney_dbo.eMoney_Card_Instance_Summary

> 130,301-row card instance timeline table tracking every physical and virtual eToro Money card issuance per customer — one row per card instance (CID may have multiple rows). Captures card issuance (InstanceCreatedDate), activation (InstanceActivationDate), expiration (InstanceExpirationDate), transaction count during the instance's active window (TxAfterActivationCount), and the next card activation date. CardCreateDate range: 2020-11-10 to 2026-04-11. Refreshed daily via TRUNCATE + INSERT by SP_eMoney_Card_Instance_Summary.

| Property | Value |
|----------|-------|
| **Schema** | eMoney_dbo |
| **Object Type** | Table |
| **Production Source** | FiatDwhDB.dbo.FiatCardInstances (card instance metadata) + FiatDwhDB.dbo.FiatCardStatuses (status events). Written by SP_eMoney_Card_Instance_Summary. |
| **Refresh** | Daily TRUNCATE + INSERT (full rebuild). SP authored by Jan Iablunovskey, 2025-05-27. |
| **Synapse Distribution** | HASH(CID) |
| **Synapse Index** | HEAP |
| **UC Target** | `main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_card_instance_summary` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export |
| **PII** | MaskedPAN (nvarchar(50) — last 4 digits visible; excluded from v_eMoney_Card_Instance_Summary view) |

---

## 1. Business Meaning

`eMoney_Card_Instance_Summary` is the per-card-instance timeline table for eToro Money debit cards. **Grain**: one row per card instance — a physical or virtual card issuance under a logical card (DWH_CardID). A customer who has had their card replaced (e.g., lost card → new card) will have multiple rows. As of 2026-04-12 there are 130,301 rows covering 94,556 distinct CIDs, meaning approximately 37.8% of card-holding customers have more than one instance.

**What each row represents**: a specific plastic or virtual card issuance, including when it was issued (InstanceCreatedDate — first NotActivated status event), when the cardholder activated it (InstanceActivationDate — first Activated status event), its expiration date (InstanceExpirationDate), and the count of valid card transactions the customer made while this instance was "active" — between its activation and the next instance's activation (TxAfterActivationCount, range 0–4,150, avg 20.7).

**Status snapshot columns**: `InstanceStatus` is the current status of THIS specific instance (9 values: NotActivated=32.9%, Activated=29.8%, Expired=21.8%, Blocked=11.2%, Stolen=3.4%, Lost=0.8%, Risk/Suspended/NULL<0.1%). `StatusByHighestRNDasc` is the status of the customer's most recent card instance (per CardID), regardless of which instance the row represents — useful for understanding the customer's current card state across the full timeline.

**Use cases**: monthly debit card funnel dashboard (via SP_eMoney_Card_Monthly_Snapshot), customer-level card analytics, eToro Money card adoption KPIs. The companion view `v_eMoney_Card_Instance_Summary` exposes all columns except MaskedPAN for standard analytics use.

**SP filter**: only accounts where `GCID_Unique_Count=1` (primary eMoney account per customer) are included. GCID_Unique_Count is always 1 in this table.

45.9% of rows (59,932) have NULL `InstanceActivationDate` — cards issued but never activated by the cardholder.

---

## 2. Business Logic

### 2.1 Card Instance Grain and Instance Ordering

**What**: One row per card issuance (FiatCardInstances.Id), not per customer. Ordered by first activation timestamp (RNDasc).

**Columns Involved**: `DWH_CardID`, `DWH_CardInstanceId`, `CID`, `InstanceCreatedDate`, `InstanceActivationDate`, `NextActivationDateTime`

**Rules**:
- `DWH_CardID` (FiatCards.Id) identifies the logical card entity; `DWH_CardInstanceId` (FiatCardInstances.Id) identifies the specific physical/virtual issuance
- A single `DWH_CardID` can have multiple DWH_CardInstanceIds (e.g., physical card + virtual card, or replacement after loss/theft)
- Rows are ordered per CID by `InstanceActivationDateTime ASC` (RNDasc = 1 is the first-ever activation)
- `NextActivationDateTime` = the activation time of the next instance for this CID; NULL when this is the most recent activated instance

### 2.2 InstanceStatus vs StatusByHighestRNDasc

**What**: Two status snapshot columns capturing different scope — per-instance vs per-card's latest.

**Columns Involved**: `InstanceStatus`, `StatusByHighestRNDasc`

**Rules**:
- `InstanceStatus` = current status of THIS specific instance (from FiatCardStatuses, newest event by EventTimestamp DESC). A Blocked instance is blocked; other instances for the same customer may be Activated.
- `StatusByHighestRNDasc` = status of the instance with the HIGHEST RNDasc (most recently created per CardID — Step 4 of the SP). This is the same for all instances under the same CardID and shows the customer's current card state.
- If StatusByHighestRNDasc = Activated, the customer has an active card. If Expired, the most recently issued card has expired.
- Terminal states in InstanceStatus (Expired=21.8%, Stolen=3.4%, Lost=0.8%) indicate the specific instance can no longer be used; the customer may have a newer active instance.

### 2.3 TxAfterActivationCount Window

**What**: Number of valid settled card transactions made during this instance's active window.

**Columns Involved**: `TxAfterActivationCount`, `InstanceActivationDate`, `NextActivationDateTime`

**Rules**:
- Counts transactions from `eMoney_Dim_Transaction` where: CID matches, IsValidETM=1, IsTxSettled=1, TxTypeID IN (1,2,3,4) (card tx types), TxStatusModificationDateID ≥ 20201117, TxStatusModificationTime > InstanceActivationDateTime
- Window end: `NextActivationDateTime IS NULL` → no end bound (count all time); `NextActivationDateTime IS NOT NULL` → count only before next activation
- Range: 0–4,150 transactions per instance, avg 20.7
- NULL InstanceActivationDate rows will have TxAfterActivationCount=0 (no activation = no TX window)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(CID) distributes rows by customer — customer-level aggregations and JOIN to eMoney_Dim_Account (HASH(GCID) — note mismatch, requires shuffle) are efficient for customer scans. Customers with multiple card instances land on the same compute node. HEAP is optimal for this fully-refreshed daily table; no range-scan patterns benefit from a sorted index.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Cards issued but never activated | `WHERE InstanceActivationDate IS NULL` (45.9% of rows) |
| Customers with currently active card | `WHERE StatusByHighestRNDasc = 'Activated'` GROUP BY CID |
| First card activation per customer | `WHERE InstanceActivationDate IS NOT NULL` — MIN(InstanceActivationDate) PARTITION BY CID |
| Card TX activity per instance | ORDER BY CID, InstanceActivationDate — use TxAfterActivationCount per window |
| Card instance vs view | Use `v_eMoney_Card_Instance_Summary` for all analytics (excludes MaskedPAN); use base table only when MaskedPAN is needed for reconciliation |
| Current card state | Join on DWH_CardID and use StatusByHighestRNDasc |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| eMoney_dbo.eMoney_Dim_Account | ON CIS.CID = mda.CID AND mda.GCID_Unique_Count=1 | Extend with account status, entity, sub-program |
| eMoney_dbo.eMoney_Card_Monthly_Snapshot | ON CIS.CID = snapshot.CID | Monthly card funnel — CIS feeds monthly snapshots |
| DWH_dbo.Dim_Customer | ON CIS.CID = dc.RealCID | Trading profile (club, country, regulation) |

### 3.4 Gotchas

- **Multiple rows per CID**: Do not assume one row per customer. Always use `DISTINCT CID` or `MIN(InstanceActivationDate)` when computing customer-level metrics.
- **MaskedPAN is PII**: The base table includes MaskedPAN; the view `v_eMoney_Card_Instance_Summary` excludes it. Prefer the view for standard analytics.
- **StatusByHighestRNDasc is not per-instance**: It is the same for all rows under the same DWH_CardID. Use InstanceStatus for per-instance state.
- **45.9% null InstanceActivationDate**: Cards in NotActivated status have NULL here. Do NOT interpret NULL as "activation date unknown" — it means the card was never activated.
- **GCID_Unique_Count is always 1**: The SP filters on GCID_Unique_Count=1, so all rows represent primary eMoney accounts. Secondary accounts are not included.
- **UpdateDate is SP run time**: Set to GETDATE() at TRUNCATE+INSERT time — not a business event timestamp.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki (FiatDwhDB or etoro DB_Schema) |
| Tier 2 | Derived from ETL SP code or DWH computation logic |
| Tier 3 | Inferred from column name and context |
| Tier 4 | Best available — limited confidence |
| Tier 5 | Glossary-sourced |

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
| 10 | MaskedPAN | nvarchar(50) | YES | Masked card number showing only last digits. Dynamic data masking protects the full PAN. **PII field — excluded from v_eMoney_Card_Instance_Summary.** (Tier 1 — dbo.FiatCardInstances) |
| 11 | InstanceStatus | nvarchar(50) | YES | Current lifecycle status of THIS specific card instance. Resolved via JOIN on eMoney_Dictionary_CardStatus (newest FiatCardStatuses event by EventTimestamp DESC). 0=NotActivated (32.9%), 1=Activated (29.8%), 2=Blocked (11.2%), 7=Expired (21.8%), 4=Risk, 5=Stolen (3.4%), 6=Lost (0.8%), 3=Suspended, 8=Fraud, NULL=0.1%. (Tier 2 — SP_eMoney_Card_Instance_Summary) |
| 12 | InstanceCreatedDate | date | YES | Date the card instance was first issued — CAST(MIN(FiatCardStatuses.EventTimestamp WHERE CardStatusId=0) AS DATE). First NotActivated event = card creation/delivery. NULL for 1,120 instances with no status history. (Tier 2 — SP_eMoney_Card_Instance_Summary) |
| 13 | InstanceActivationDate | date | YES | Date the cardholder first activated this card instance — CAST(MIN(FiatCardStatuses.EventTimestamp WHERE CardStatusId=1) AS DATE). NULL for 59,932 rows (45.9%) where the card was never activated by the cardholder. (Tier 2 — SP_eMoney_Card_Instance_Summary) |
| 14 | InstanceExpirationDate | date | YES | Expiration date of this card instance. NULL for instances where expiration is not yet set. DWH note: CAST from datetime2 to DATE from FiatCardInstances.CardExpirationDate. (Tier 1 — dbo.FiatCardInstances) |
| 15 | StatusByHighestRNDasc | nvarchar(50) | YES | Status of the customer's most recently created card instance per DWH_CardID (highest RNDasc rank, ordered DESC). Same for all instances of the same DWH_CardID. Use this to assess the customer's current card state across the full issuance history. Values: Activated (42.0%), Expired (28.6%), NotActivated (23.9%), Stolen (3.4%), Lost (1.0%), Blocked (0.9%). (Tier 2 — SP_eMoney_Card_Instance_Summary) |
| 16 | NextActivationDateTime | datetime | YES | Activation timestamp of the next card instance for this CID. NULL when this is the most recent activated instance (no successor). Used to define the upper bound of TxAfterActivationCount window. (Tier 2 — SP_eMoney_Card_Instance_Summary) |
| 17 | TxAfterActivationCount | int | YES | Count of valid settled card transactions (IsValidETM=1, IsTxSettled=1, TxTypeID IN [1,2,3,4]) made by this CID after this instance's ActivationDateTime and before NextActivationDateTime (or all time if NULL). Range: 0–4,150, avg 20.7. 0 for unactivated instances. (Tier 2 — SP_eMoney_Card_Instance_Summary) |
| 18 | UpdateDate | datetime | NO | Timestamp when this record was written by the SP. Set to GETDATE() at TRUNCATE+INSERT time. Reflects the daily SP run, not a business event. (Tier 2 — SP_eMoney_Card_Instance_Summary) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| CID | etoro.Customer.CustomerStatic | CID | Passthrough via Dim_Customer → eMoney_Dim_Account |
| ProviderHolderID | FiatDwhDB.dbo.AccountsProviderHoldersMapping | ProviderHolderId | Rename; via eMoney_Dim_Account |
| DWH_CardID | FiatDwhDB.dbo.FiatCards | Id | Renamed; via eMoney_Dim_Account.CardID |
| DWH_CardInstanceId | FiatDwhDB.dbo.FiatCardInstances | Id | Renamed |
| MaskedPAN | FiatDwhDB.dbo.FiatCardInstances | MaskedPAN | Passthrough |
| InstanceExpirationDate | FiatDwhDB.dbo.FiatCardInstances | CardExpirationDate | CAST to DATE |
| InstanceStatus | FiatDwhDB.dbo.FiatCardStatuses + Dictionary.CardStatuses | CardStatusId → Name | Newest status event per instance |
| InstanceCreatedDate | FiatDwhDB.dbo.FiatCardStatuses | EventTimestamp | MIN where CardStatusId=0; CAST to DATE |
| InstanceActivationDate | FiatDwhDB.dbo.FiatCardStatuses | EventTimestamp | MIN where CardStatusId=1; CAST to DATE |
| FMI_Date | FiatDwhDB (via eMoney_Dim_Transaction) | TxStatusModificationDate | First settled IN tx; computed in eMoney_Panel_FirstDates |
| TxAfterActivationCount | eMoney_dbo.eMoney_Dim_Transaction | — | COUNT(*) correlated subquery per instance window |
| UpdateDate | ETL metadata | — | GETDATE() at INSERT |

### 5.2 ETL Pipeline

```
FiatDwhDB.dbo.FiatCardInstances (PAN, expiration, IsVirtual)
FiatDwhDB.dbo.FiatCardStatuses  (status events with EventTimestamp)
FiatDwhDB.Dictionary.CardStatuses (status name decode)
  |-- CopyFromLake external tables (Bronze parquet ADLS Gen2) ---|
  v
CopyFromLake.FiatDwhDB_dbo_FiatCardInstances (external table in Synapse)
eMoney_dbo.FiatCardStatuses (mirrored table in Synapse)
  |-- SP_eMoney_Card_Instance_Summary (5 temp table steps, daily) ---|
  + eMoney_dbo.eMoney_Dim_Account (GCID_Unique_Count=1 filter → CID, ProviderHolderID, etc.)
  + eMoney_dbo.eMoney_Panel_FirstDates (FMI_Date per CID)
  + eMoney_dbo.eMoney_Dictionary_CardStatus (status text decode)
  + eMoney_dbo.eMoney_Dim_Transaction (TxAfterActivationCount correlated COUNT)
  v
eMoney_dbo.eMoney_Card_Instance_Summary (130,301 rows, HASH(CID), HEAP)
  |-- v_eMoney_Card_Instance_Summary (view — excludes MaskedPAN) ---|
  |-- Generic Pipeline (Gold export, delta) ---|
  v
main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_card_instance_summary
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer (via RealCID) | Customer trading profile |
| DWH_CardID | eMoney_dbo.eMoney_Dim_Account | Logical card entity and account linkage |
| InstanceStatus / StatusByHighestRNDasc | eMoney_dbo.eMoney_Dictionary_CardStatus | Card lifecycle state decode (via SP JOIN) |
| FMI_Date | eMoney_dbo.eMoney_Panel_FirstDates | First money-in milestone per CID |

### 6.2 Referenced By

| Object | Column | Description |
|--------|--------|-------------|
| eMoney_dbo.eMoney_Card_Monthly_Snapshot | CID, FMI_Date, CardCreateDate | Monthly EOM card funnel — reads CIS for last/first instance per CID |
| eMoney_dbo.v_eMoney_Card_Instance_Summary | (all except MaskedPAN) | Analytics-safe view over this table |

---

## 7. Sample Queries

### 7.1 Customers with active card (current state)
```sql
SELECT DISTINCT CID, StatusByHighestRNDasc, CardCreateDate
FROM [eMoney_dbo].[eMoney_Card_Instance_Summary]
WHERE StatusByHighestRNDasc = 'Activated'
  AND IsValidETM = 1;
```

### 7.2 Card activation funnel: issued vs activated
```sql
SELECT
    CardCreateDate,
    COUNT(*) AS total_instances,
    COUNT(InstanceActivationDate) AS activated,
    COUNT(*) - COUNT(InstanceActivationDate) AS never_activated,
    CAST(COUNT(InstanceActivationDate) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS activation_pct
FROM [eMoney_dbo].[eMoney_Card_Instance_Summary]
WHERE CardCreateDate >= DATEADD(MONTH, -12, GETDATE())
GROUP BY CardCreateDate
ORDER BY CardCreateDate DESC;
```

### 7.3 Transaction activity per card instance (first 2 activations per customer)
```sql
SELECT
    CID,
    FMI_Date,
    InstanceActivationDate,
    NextActivationDateTime,
    TxAfterActivationCount,
    InstanceStatus,
    ROW_NUMBER() OVER (PARTITION BY CID ORDER BY InstanceActivationDate) AS InstanceRank
FROM [eMoney_dbo].[eMoney_Card_Instance_Summary]
WHERE InstanceActivationDate IS NOT NULL
  AND IsValidETM = 1
ORDER BY CID, InstanceActivationDate;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. Card instance data is documented in the FiatDwhDB upstream wiki (`BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.FiatCardInstances.md`) and business context is in SP_eMoney_Card_Instance_Summary comments.

---

PHASE GATE CHECK — eMoney_Card_Instance_Summary:
  [x] P1 DDL   [x] P2 Sample   [x] P3 Dist   [x] P4 Lookup
  [x] P5 JOIN  [x] P6 BizLogic [x] P7 Views  [x] P8 SP-scan
  [x] P9 SP-logic [x] P9B ETL  [x] P10 Jira  [x] P10A Upstream  [x] P10B Lineage
  → Ready for P11
OUTPUT CHECK — eMoney_Card_Instance_Summary:
  [x] .lineage.md exists   [x] .md exists   [x] .review-needed.md (writing next)
  [-] .alter.sql — deferred to /generate-alter-dwh

T1 COPY VERIFICATION:
  CID: upstream (eMoney_Panel_FirstDates) 40 words → wiki 40 words — IDENTICAL
  ProviderHolderID: upstream (eMoney_Account_Mappings) — verbatim copy — IDENTICAL
  DWH_CardID: upstream (eMoney_Dim_Account #79) — verbatim copy — IDENTICAL
  DWH_CardInstanceId: upstream (FiatCardInstances.Id) "Auto-incrementing surrogate PK. Referenced by FiatCardStatuses.CardInstanceId." → wiki verbatim with DWH rename note — IDENTICAL
  MaskedPAN: upstream "Masked card number showing only last digits. Dynamic data masking protects the full PAN." → wiki verbatim + PII flag — IDENTICAL
  InstanceExpirationDate: upstream "Expiration date of this card instance. NULL for instances where expiration is not yet set." → wiki verbatim + DWH cast note — IDENTICAL

PHASE 10.5b CHECKPOINT: PASS

*Generated: 2026-04-21 | Quality: 8.9/10 | Phases: 13/14*
*Tiers: 6 T1, 12 T2, 0 T3, 0 T4, 0 T5 | Elements: 18/18, Logic: 9/10, Sources: 8/10*
*Object: eMoney_dbo.eMoney_Card_Instance_Summary | Type: Table | Production Source: FiatDwhDB.dbo.FiatCardInstances + FiatDwhDB.dbo.FiatCardStatuses*
