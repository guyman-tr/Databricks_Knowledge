# eMoney_dbo.eMoney_UserData_Marketing

> Customer-grain eToro Money user snapshot for marketing automation, providing one row per eligible eTM customer with account program, card and IBAN usage flags, and transaction recency. Contains 2,010,838 rows (one per GCID), refreshed daily via TRUNCATE+INSERT. Account creation dates range from 2020-11-09 (first eTM accounts) to 2026-04-12. Designed for marketing team segmentation and campaign targeting.

| Property | Value |
|----------|-------|
| **Schema** | eMoney_dbo |
| **Object Type** | Table |
| **Production Source** | eMoney_dbo.eMoney_Dim_Account + eMoney_Dim_Transaction via SP_eMoney_UserData_Marketing |
| **Refresh** | TRUNCATE + INSERT daily (idempotency guard: skips if UpdateDate >= today); currently commented out in SP_eMoney_Execute_Group_One (SP 11); last updated 2026-04-12 |
| **Synapse Distribution** | HASH(RealCID) |
| **Synapse Index** | HEAP |
| **UC Target** | `bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_userdata_marketing` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |

---

## 1. Business Meaning

`eMoney_UserData_Marketing` is a **customer-grain daily snapshot** designed for the marketing automation team. Each row represents **one eligible eToro Money customer** with their current product state and key engagement signals.

The table answers: "For each eTM customer right now — what product are they on, have they used their card or IBAN, and have they transacted recently?" This makes it the primary table for email/campaign targeting logic that segments customers by engagement level.

Population: 2,010,838 customers. Excludes:
- GCID=0 (cancelled accounts)
- IsTestAccount=1 (test/internal accounts)
- CurrencyBalanceStatusID=4 (Blocked balances)
- Secondary accounts (only GCID_Unique_Count=1 — primary account per customer)

`Date_Inserted` is the eTM account creation date (from `eMoney_Dim_Account.AccountCreateDate`) — NOT the date the row was inserted into this table. All rows are replaced on each TRUNCATE+INSERT cycle.

**Program distribution**: IBAN 95.4%, Card 4.6%. The dominant product is IBAN Standard UK (27.8%) and IBAN EU Green (64.2%).

**Usage flags**: 46% of customers have IBAN transactions (`IBANUsage=1`); only ~1.3% have card transactions (`CardUsage=1`). 16.4% have transacted in the last 3 months (`HasTransactionsLast3Months=1`).

**Status**: SP is commented out in `SP_eMoney_Execute_Group_One` (SP 11) as of the most recent revision. Last TRUNCATE+INSERT on 2026-04-12 (9 days ago as of 2026-04-21).

---

## 2. Business Logic

### 2.1 Card Usage Flag

**What**: Binary flag indicating whether a customer has ever used their eTM card.

**Columns Involved**: `CardUsage`, `CardId`, `LastCardStatus`

**Rules**:
- `CardUsage = 1` if customer has any transaction in `eMoney_Dim_Transaction` with TxTypeID IN (1, 2, 3, 4, 9) (card transaction types)
- `CardUsage = 0` otherwise (never used card, including customers with no card)
- `LastCardStatus = 'NotOrdered'` when `CardCreateDate IS NULL` (customer has no card at all); otherwise reflects the current card status from `eMoney_Dim_Account`

### 2.2 IBAN Usage Flag

**What**: Binary flag indicating whether a customer has ever executed an IBAN transaction. `IBANUsed` is an exact duplicate of `IBANUsage`.

**Columns Involved**: `IBANUsage`, `IBANUsed`

**Rules**:
- `IBANUsage = 1` if customer has any transaction with TxTypeID IN (5, 6, 7, 8, 13) (IBAN/bank transfer transaction types)
- `IBANUsed = CASE WHEN IBANUsage = 1 THEN 1 ELSE 0 END` — identical to `IBANUsage` in all cases; this column appears to be a legacy duplicate
- Do not use both columns — use `IBANUsage`

### 2.3 Transaction Recency Flag

**What**: Binary flag indicating recent activity (last 90 days = approximately 3 months).

**Columns Involved**: `HasTransactionsLast3Months`

**Rules**:
- `HasTransactionsLast3Months = 1` if customer has any transaction in `eMoney_Dim_Transaction` with `TxLocalDateID >= 90 days ago` (calculated at SP runtime as DATEADD(month, -3, GETDATE()))
- `HasTransactionsLast3Months = 0` otherwise

### 2.4 Program and Sub-Program Classification

**What**: Identifies the customer's current eTM product tier and geography.

**Columns Involved**: `Program`, `SubProgram`

**Rules**:
- `Program`: 'iban' or 'card' (lowercase text from AccountProgram in eMoney_Dim_Account)
- `SubProgram` (15 distinct values): IBAN EU Green (64%), IBAN Standard UK (28%), Card Standard UK (3%), IBAN Green AUS (2%), IBAN EU Black (1%), Card Black EU (1%), Card Premium UK (1%), Card Green EU (<1%), IBAN Black AUS, IBAN LIMITED EU, IBAN Green DKK, Card Premium UAE, IBAN Black DKK, IBAN LIMITED UK, and NULL (~112 rows with no sub-program)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(RealCID) ensures CID-level aggregations are single-node. The 2M-row table is compact and suitable for direct queries without filters. Since all rows represent the current state of active customers (daily TRUNCATE+INSERT), no date filter is needed for current-state queries.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Customers with IBAN but no transactions (dormant) | `WHERE IBANUsage=1 AND HasTransactionsLast3Months=0` |
| Card holders by sub-program | `WHERE Program='card' GROUP BY SubProgram` |
| Recently active eTM customers | `WHERE HasTransactionsLast3Months=1` |
| Customers to target for card activation | `WHERE CardUsage=0 AND CardId IS NOT NULL AND LastCardStatus='NotActivated'` |
| New eTM accounts (joined in last 30 days) | `WHERE Date_Inserted >= DATEADD(day,-30,GETDATE())` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| eMoney_dbo.eMoney_Dim_Account | `eMoney_UserData_Marketing.GCID = eMoney_Dim_Account.GCID AND GCID_Unique_Count=1` | Full account details |
| DWH_dbo.Dim_Customer | `eMoney_UserData_Marketing.RealCID = Dim_Customer.RealCID` | Trading account attributes |
| eMoney_dbo.eMoney_AM_Target | `eMoney_UserData_Marketing.GCID = eMoney_AM_Target.GCID AND Report_Date='...'` | Add AM assignment |

### 3.4 Gotchas

- **`Date_Inserted` is NOT insert date**: This is `AccountCreateDate` (when the eTM account was opened), not when the row entered this table. Naming is misleading.
- **`IBANUsed` = `IBANUsage` always**: These are duplicate columns — use only `IBANUsage`
- **Usage flags are lifetime, not recent**: `CardUsage` and `IBANUsage` reflect all-time usage; only `HasTransactionsLast3Months` is recency-aware
- **Table is stale**: Last update 2026-04-12 (~9 days old as of 2026-04-21) — SP commented out
- **No card customers show `LastCardStatus='NotOrdered'`**: This is an SP-injected sentinel, not a value from the dictionary table; `eMoney_Dictionary_CardStatus` does not have a 'NotOrdered' value

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Description sourced verbatim from upstream production database wiki (highest confidence) |
| Tier 2 | Description derived from SP code, DDL, or DWH wiki (high confidence) |
| Tier 3 | Inferred from column name, data pattern, or business context (medium confidence) |
| Tier 4 | Best available knowledge — limited upstream documentation (lower confidence) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | GCID | int | YES | Global Customer ID. Identifies the customer across all eToro platforms (trading, crypto, fiat). Part of the unique constraint with AccountGuid. Used in Confluence queries as the primary customer lookup key. (Tier 1 — dbo.FiatAccount) |
| 2 | RealCID | int | YES | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Renamed from RealCID in DWH_dbo.Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| 3 | Date_Inserted | date | YES | eTM account creation date (eMoney_Dim_Account.AccountCreateDate). Despite the name, this is NOT when the row was inserted into this table — the table is fully replaced on each TRUNCATE+INSERT. Ranges from 2020-11-09 (first eTM accounts) to 2026-04-12. (Tier 2 — SP_eMoney_UserData_Marketing via eMoney_Dim_Account) |
| 4 | Program | nvarchar(256) | YES | Account program display name for AccountProgramID, resolved from eMoney_Dictionary_AccountProgram. Values: 'iban' (95.4%), 'card' (4.6%). (Tier 2 — SP_eMoney_Dim_Account) |
| 5 | CardId | int | YES | Auto-incrementing surrogate primary key. Referenced by FiatCardStatuses.CardId, FiatCardInstances (implicit), and CardsProvidersMapping.CardId. NULL if the customer has no card. (Tier 1 — dbo.FiatCards) |
| 6 | CardUsage | int | YES | 1 if the customer has any eTM card transaction (TxTypeID IN 1,2,3,4,9 in eMoney_Dim_Transaction); 0 otherwise. Lifetime flag, not recency-bounded. (Tier 2 — SP_eMoney_UserData_Marketing via eMoney_Dim_Transaction) |
| 7 | IBANUsage | int | YES | 1 if the customer has any IBAN/bank transfer transaction (TxTypeID IN 5,6,7,8,13 in eMoney_Dim_Transaction); 0 otherwise. Lifetime flag. (Tier 2 — SP_eMoney_UserData_Marketing via eMoney_Dim_Transaction) |
| 8 | LastCardStatus | nvarchar(32) | YES | Current card status. 'NotOrdered' if CardCreateDate IS NULL (no card issued); otherwise reflects eMoney_Dim_Account.CardStatus. Values: NotOrdered, NotActivated, Activated, Expired, Blocked, Stolen, Lost, Risk, Suspended (9 values). Note: 'NotOrdered' is an SP-injected sentinel absent from eMoney_Dictionary_CardStatus. (Tier 2 — SP_eMoney_UserData_Marketing via eMoney_Dim_Account) |
| 9 | IBANUsed | int | YES | **DUPLICATE of IBANUsage** — CASE WHEN IBANUsage=1 THEN 1 ELSE 0 END, always identical to IBANUsage. Use IBANUsage instead. (Tier 2 — SP_eMoney_UserData_Marketing) |
| 10 | HasTransactionsLast3Months | int | YES | 1 if the customer has any eTM transaction with TxLocalDateID in the past 90 days (from SP run date); 0 otherwise. The only recency-bounded flag in this table. (Tier 2 — SP_eMoney_UserData_Marketing via eMoney_Dim_Transaction) |
| 11 | CardCreatedDate | date | YES | Date portion of CardCreateTime. DWH-derived: CAST(CardCreateTime AS DATE). NULL if no card issued. (Tier 2 — SP_eMoney_Dim_Account) |
| 12 | UpdateDate | datetime | YES | ETL run timestamp (GETDATE() at time of SP execution). All rows share the same UpdateDate (TRUNCATE+INSERT makes all rows simultaneous). Used for idempotency check: if MAX(UpdateDate) >= today, SP skips. (Tier 2 — SP_eMoney_UserData_Marketing) |
| 13 | SubProgram | nvarchar(256) | YES | Sub-program display name for AccountSubProgramID, resolved from eMoney_dbo.SubPrograms (16 active programs across UK/EU/AUS regions). Values (15 distinct): IBAN EU Green (64%), IBAN Standard UK (28%), Card Standard UK (3%), IBAN Green AUS (2%), IBAN EU Black (1%), Card Black EU, Card Premium UK, Card Green EU, IBAN Black AUS, IBAN LIMITED EU, IBAN Green DKK, Card Premium UAE, IBAN Black DKK, IBAN LIMITED UK, NULL. (Tier 2 — SP_eMoney_Dim_Account) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| GCID | eMoney_dbo.eMoney_Dim_Account | GCID | Passthrough |
| RealCID | eMoney_dbo.eMoney_Dim_Account | CID | Rename |
| Date_Inserted | eMoney_dbo.eMoney_Dim_Account | AccountCreateDate | Rename (misnamed as "inserted") |
| Program | eMoney_dbo.eMoney_Dim_Account | AccountProgram | Rename |
| CardId | eMoney_dbo.eMoney_Dim_Account | CardID | Rename |
| CardUsage | eMoney_dbo.eMoney_Dim_Transaction | TxTypeID | 1 if TxTypeID IN (1,2,3,4,9) |
| IBANUsage | eMoney_dbo.eMoney_Dim_Transaction | TxTypeID | 1 if TxTypeID IN (5,6,7,8,13) |
| LastCardStatus | eMoney_dbo.eMoney_Dim_Account | CardStatus, CardCreateDate | 'NotOrdered' override when CardCreateDate IS NULL |
| IBANUsed | eMoney_dbo.eMoney_Dim_Transaction | TxTypeID | Redundant copy of IBANUsage |
| HasTransactionsLast3Months | eMoney_dbo.eMoney_Dim_Transaction | TxLocalDateID | 1 if any tx in last 90 days |
| CardCreatedDate | eMoney_dbo.eMoney_Dim_Account | CardCreateDate | Rename |
| UpdateDate | SP | GETDATE() | ETL timestamp |
| SubProgram | eMoney_dbo.eMoney_Dim_Account | AccountSubProgram | Rename |

### 5.2 ETL Pipeline

```
eMoney_dbo.eMoney_Dim_Account (primary source)
  Filter: GCID<>0, GCID_Unique_Count=1, IsTestAccount=0, CurrencyBalanceStatusID<>4
  + eMoney_dbo.eMoney_Dim_Transaction (CardUsage/IBANUsage/HasTxLast3Months flags)
    |-- SP_eMoney_UserData_Marketing (TRUNCATE + INSERT; daily idempotency guard) ---|
    |   Orchestrated via: SP_eMoney_Execute_Group_One (SP 11)                         |
    |   STATUS: Currently commented out — last run 2026-04-12                         |
    v
eMoney_dbo.eMoney_UserData_Marketing
  (2,010,838 rows, one per GCID, 2020-11-09 to 2026-04-12)
    |
    |-- UC Gold: _Not_Migrated ---|
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| GCID | eMoney_dbo.eMoney_Dim_Account.GCID | Primary eTM account (via ETL; GCID_Unique_Count=1) |
| RealCID | DWH_dbo.Dim_Customer.RealCID | eToro trading account identity |
| CardId | eMoney_dbo.eMoney_Dim_Account.CardID | Card record reference |
| CardUsage/IBANUsage | eMoney_dbo.eMoney_Dim_Transaction | Transaction type usage flags |

### 6.2 Referenced By (other objects point to this)

No known downstream consumers documented in existing wikis. Designed for marketing automation external exports.

---

## 7. Sample Queries

### Marketing Segmentation: Engaged vs Dormant IBAN Customers

```sql
SELECT Program,
       SubProgram,
       SUM(CASE WHEN HasTransactionsLast3Months=1 THEN 1 ELSE 0 END) AS active_customers,
       SUM(CASE WHEN HasTransactionsLast3Months=0 AND IBANUsage=1 THEN 1 ELSE 0 END) AS dormant_users,
       COUNT(*) AS total_customers
FROM [eMoney_dbo].[eMoney_UserData_Marketing]
GROUP BY Program, SubProgram
ORDER BY total_customers DESC;
```

### Card Activation Opportunities (Card Issued but Not Yet Used)

```sql
SELECT SubProgram,
       COUNT(*) AS activation_opportunity
FROM [eMoney_dbo].[eMoney_UserData_Marketing]
WHERE CardId IS NOT NULL
  AND CardUsage = 0
  AND LastCardStatus = 'NotActivated'
GROUP BY SubProgram
ORDER BY activation_opportunity DESC;
```

### New eTM Customers in Last 30 Days

```sql
SELECT Program,
       SubProgram,
       COUNT(*) AS new_customers,
       SUM(IBANUsage) AS already_used_iban,
       SUM(CardUsage) AS already_used_card
FROM [eMoney_dbo].[eMoney_UserData_Marketing]
WHERE Date_Inserted >= DATEADD(day, -30, GETDATE())
GROUP BY Program, SubProgram
ORDER BY new_customers DESC;
```

---

## 8. Atlassian Knowledge Sources

SP header: Created 2021-10-02 by eMoney & Wallet Data Analytics Team. Last change 2025-11-10 by Inessa (duplication handling). No Confluence sources found.

---

*Generated: 2026-04-21 | Quality: 8.9/10 | Phases: 11/14*
*Tiers: 3 T1, 10 T2, 0 T3, 0 T4, 0 T5 | Elements: 13/13, Logic: 4 sections*
*Object: eMoney_dbo.eMoney_UserData_Marketing | Type: Table | Production Source: SP_eMoney_UserData_Marketing (eMoney_Dim_Account, eMoney_Dim_Transaction)*
