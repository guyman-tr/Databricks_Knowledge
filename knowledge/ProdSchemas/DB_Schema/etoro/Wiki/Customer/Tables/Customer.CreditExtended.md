# Customer.CreditExtended

> Per-customer financial snapshot table storing total account value and per-mirror copy-trading amounts, used for account statement and equity reporting.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Table |
| **Key Identifier** | CID + MirrorID (composite PK, clustered) |
| **Partition** | No (PRIMARY filegroup) |
| **Indexes** | 1 (clustered PK only) |

---

## 1. Business Meaning

Customer.CreditExtended stores a per-customer financial breakdown combining total account balances and per-copy-trade (mirror) amounts. Each customer has at minimum a "totals" row (MirrorID=0) aggregating the entire account, and may have additional per-mirror rows for each active copy trading mirror (CopyTrader relationship). The money columns capture positions, cash, credit, pending cashouts, and stock orders at both the account-total and per-mirror levels.

This table is used by account statement and dashboard reporting (dbo.AccountStatement_GetRealizedEquity, dbo.PR_Dashboard_ORG, dbo.PR_NFA_Account_Statment) to provide a breakdown of a customer's financial exposure. History.ActiveCreditExtended (via synonym dbo.RW_History_ActiveCreditExtended) preserves daily snapshots via Maintenance.JOB_InsertHistoryCreditExtended.

Currently 13 rows, indicating this is used for a small set of customers (likely internal, test, or special-case accounts requiring detailed tracking).

---

## 2. Business Logic

### 2.1 Two-Row Pattern: Account Total vs Per-Mirror

**What**: MirrorID=0 holds the customer-total snapshot; MirrorID>0 holds amounts attributed to a specific copy-trading mirror.

**Columns/Parameters Involved**: `MirrorID`, `TotalPositionsAmount`, `TotalMirrorPositionsAmount`, `MirrorPositionsAmount`, `TotalCash`, `TotalMirrorCash`, `MirrorCash`

**Rules**:
- MirrorID=0 row: Total* columns populated, Mirror-specific columns are NULL
  - TotalPositionsAmount: all positions
  - TotalCash: total cash balance
  - Credit: credit/bonus funds
  - InProcessCashouts: pending withdrawals
  - TotalStockOrders: total value of pending stock orders
- MirrorID>0 row: Mirror-specific columns populated, Total* columns are NULL
  - MirrorPositionsAmount: positions attributed to this specific mirror
  - MirrorCash: cash allocated to this mirror
  - MirrorStockOrders: stock orders for this mirror
- TotalMirror* columns (MirrorID=0 row): aggregate of all mirror rows for the same CID

**Diagram**:
```
CID=2575684:
  MirrorID=0     TotalPositionsAmount=0, TotalCash=1424.41, Credit=1374.41
                 TotalMirrorPositionsAmount=0, TotalMirrorCash=50
  MirrorID=56500 MirrorPositionsAmount=0, MirrorCash=50
                 (portion of the total attributed to this copy)
```

---

## 3. Data Overview

| CID | MirrorID | TotalCash | TotalMirrorCash | Credit | MirrorCash | TotalStockOrders | Meaning |
|---|---|---|---|---|---|---|---|
| 2575684 | 0 | 1424.41 | 50.00 | 1374.41 | NULL | 5000.00 | Account totals for customer 2575684: credit-heavy account with $5000 in stock orders; $50 in copy positions |
| 2575684 | 56500 | NULL | NULL | NULL | 50.00 | NULL | Mirror ID 56500 breakdown: $50 allocated to this specific copy trade |
| 3046419 | 0 | 627.15 | 0 | 627.15 | NULL | 0 | Customer 3046419: cash balance is credit-only; $50 in-process cashout pending |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | CODE-BACKED | Customer ID - part of composite PK. |
| 2 | TotalPositionsAmount | money | YES | - | CODE-BACKED | Total value of all open positions (manual + copy) for the customer. Populated on MirrorID=0 row only; NULL on per-mirror rows. |
| 3 | TotalCash | money | YES | - | CODE-BACKED | Total cash balance (USD) for the account. Populated on MirrorID=0 row only. |
| 4 | Credit | money | YES | - | CODE-BACKED | Credit/bonus balance. For some customers TotalCash equals Credit, indicating the full balance is bonus funds. On MirrorID=0 row. |
| 5 | InProcessCashouts | money | YES | - | CODE-BACKED | Pending withdrawal amount in USD. Funds submitted for cashout but not yet processed. On MirrorID=0 row. |
| 6 | TotalMirrorPositionsAmount | money | YES | - | CODE-BACKED | Aggregate positions amount across ALL active copy-trade mirrors for this customer. On MirrorID=0 row. Equals sum of MirrorPositionsAmount across all per-mirror rows. |
| 7 | TotalMirrorCash | money | YES | - | CODE-BACKED | Aggregate cash allocated across ALL copy-trade mirrors. On MirrorID=0 row. |
| 8 | MirrorID | int | NO | 0 | CODE-BACKED | Copy-trade mirror identifier. 0=account totals row; >0=specific copy-trade relationship (CopyTrader's MirrorID). Default=0 ensures totals row is created on insert. |
| 9 | MirrorPositionsAmount | money | YES | - | CODE-BACKED | Value of open positions attributed to this specific mirror. Populated on per-mirror rows (MirrorID>0) only; NULL on totals row. |
| 10 | MirrorCash | money | YES | - | CODE-BACKED | Cash allocated to this specific mirror. Populated on per-mirror rows only. |
| 11 | TotalStockOrders | money | YES | - | CODE-BACKED | Total value of pending stock orders for the account. Populated on MirrorID=0 row. |
| 12 | TotalMirrorStockOrders | money | YES | - | CODE-BACKED | Aggregate pending stock orders across all mirrors. On MirrorID=0 row. |
| 13 | MirrorStockOrders | money | YES | - | CODE-BACKED | Pending stock orders for this specific mirror. On per-mirror rows. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.RW_Customer_CreditExtended | (synonym) | Synonym | Direct synonym providing alternate access path |
| History.ActiveCreditExtended | CID + MirrorID | History snapshot | Daily archive populated by Maintenance job |
| History.CreditExtended (view) | CID | View | Historical credit view layered on History.ActiveCreditExtended |
| dbo.AccountStatement_GetRealizedEquity | CID | READER | Account statement reporting |
| dbo.PR_Dashboard_ORG | CID | READER | Dashboard financial reporting |
| dbo.PR_NFA_Account_Statment | CID | READER | NFA (regulatory) account statement |
| Maintenance.JOB_InsertHistoryCreditExtended | CID | READER/Writer | Daily snapshot job reading current data into history |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.ActiveCreditExtended | Table | Daily snapshots via Maintenance job |
| dbo.AccountStatement_GetRealizedEquity | Stored Procedure | Account statement equity calculation |
| Maintenance.JOB_InsertHistoryCreditExtended | Stored Procedure | Daily snapshot archive |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CustomerCreditExtended_TempEtoro | CLUSTERED | CID ASC, MirrorID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_CustomerCreditExtended_TempEtoro | PRIMARY KEY | CID + MirrorID must be unique |
| DF_CreditExtended_MirrorID_TempEtoro | DEFAULT | MirrorID = 0 - ensures totals row is the default |

---

## 8. Sample Queries

### 8.1 Get full financial snapshot for a customer

```sql
SELECT
    ce.CID,
    ce.MirrorID,
    ce.TotalPositionsAmount,
    ce.TotalCash,
    ce.Credit,
    ce.InProcessCashouts,
    ce.TotalMirrorCash,
    ce.TotalStockOrders
FROM Customer.CreditExtended ce WITH (NOLOCK)
WHERE ce.CID = 2575684
ORDER BY ce.MirrorID
```

### 8.2 Get account totals only (MirrorID=0)

```sql
SELECT
    CID,
    TotalPositionsAmount,
    TotalCash,
    Credit,
    InProcessCashouts,
    TotalStockOrders
FROM Customer.CreditExtended WITH (NOLOCK)
WHERE MirrorID = 0
ORDER BY CID
```

### 8.3 Breakdown by mirror for a specific customer

```sql
SELECT
    ce.CID,
    ce.MirrorID,
    ce.MirrorPositionsAmount,
    ce.MirrorCash,
    ce.MirrorStockOrders
FROM Customer.CreditExtended ce WITH (NOLOCK)
WHERE ce.CID = 2575684
  AND ce.MirrorID > 0
ORDER BY ce.MirrorID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.CreditExtended | Type: Table | Source: etoro/etoro/Customer/Tables/Customer.CreditExtended.sql*
