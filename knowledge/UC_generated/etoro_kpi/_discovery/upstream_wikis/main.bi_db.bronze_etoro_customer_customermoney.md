# Customer.CustomerMoney

> The current balance table for all 18.7M customers: one row per CID storing Credit (available cash), BonusCredit, RealizedEquity, TotalCash, and BSLRealFunds - all USD-denominated. As of March 2026, this table is being replaced by a split multi-currency architecture (CustomerMoneyByCurrency + CustomerAccount), after which CustomerMoney will become a backward-compatible VIEW.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Table |
| **Key Identifier** | CID (int, PK) |
| **Partition** | No (MAIN filegroup, PAGE compression) |
| **Indexes** | 1 (clustered PK, fillfactor=90, PAGE compression) |

---

## 1. Business Meaning

Customer.CustomerMoney is the live balance table for every eToro customer - the single source of truth for a customer's current financial position. Every deposit, withdrawal, position open/close, fee, bonus award, and chargeback ultimately updates one or more fields in this table for the affected CID.

With 18.7 million rows (one per customer) and approximately 56 stored procedures writing to it, this is one of the highest-traffic tables in the platform. 107+ objects (95 SPs, 9 views, 3 functions) read from it. Almost all balance writes are routed through Customer.SetBalance (a central router that delegates to specific SetBalance* procedures based on CreditTypeID).

**Field semantics** (all USD-denominated):
- `Credit`: The customer's current available balance - the money they can use for trading. This is the core field updated by every financial transaction.
- `BonusCredit`: Promotional/bonus credits awarded separate from real funds.
- `RealizedEquity`: Running total of realized value - accumulates on deposits and position close proceeds, decreases on withdrawals. Answers: "How much realized value does this customer have?"
- `TotalCash`: Reconciled cash total maintained by Trade.UpdateTotalCash reconciliation job.
- `BSLRealFunds`: Real funds threshold for Balance Stop Loss - the safety floor that triggers position liquidation if equity drops below it.

**Multi-Currency Migration** (in progress as of March 2026): A decision was made on March 8, 2026 (Mor/Architect, unanimous team, leadership present) to split CustomerMoney into two new tables using "Alternative A":
- `Customer.CustomerMoneyByCurrency`: per-currency rows (Credit per currency, one row per CID+CurrencyId)
- `Customer.CustomerAccount`: account-level row (BonusCredit, RealizedEquity, BSLRealFunds, GCID - all USD/account-level)
- `CustomerMoney` itself will become a backward-compatible VIEW that aggregates the new tables and presents the existing column interface to the ~107 consumers that currently read from it.

---

## 2. Business Logic

### 2.1 Balance Write Architecture

**What**: Almost all balance writes funnel through Customer.SetBalance, a central router that dispatches to specific sub-procedures based on the CreditTypeID parameter.

**Columns/Parameters Involved**: `CID`, `Credit`, `BonusCredit`, `RealizedEquity`, `TotalCash`, `BSLRealFunds`

**Rules**:
- 56 stored procedures write to this table (25 direct, 31 indirect)
- Customer.SetBalance routes by CreditTypeID -> delegates to SetBalance* variants
- Every deposit: Credit increases, RealizedEquity increases (real funds)
- Every withdrawal: Credit decreases, RealizedEquity decreases
- Position open: Credit decreases (reserved), no RealizedEquity change
- Position close (profit): Credit increases, RealizedEquity increases with proceeds
- Position close (loss): Credit decreases by loss amount
- Bonus award: BonusCredit increases (tracked separately from real Credit)

### 2.2 BSLRealFunds - Balance Stop Loss

**What**: BSLRealFunds is the USD threshold used by the BSL system to determine when a customer's equity has fallen to the point that positions must be liquidated.

**Columns/Parameters Involved**: `BSLRealFunds`, `Credit`

**Rules**:
- Updated by PostMIMOOperations (the post-deposit/post-withdrawal update pipeline)
- Represents real funds deposited (not bonus); when equity drops to BSLRealFunds threshold, the liquidation mechanism triggers
- BSL is confirmed to aggregate all balances into a single USD number (account-wide concept, confirmed in multi-currency design)
- Default = 0; most customers show 0 unless they have open positions with BSL configured

### 2.3 TotalCash - Reconciliation Field

**What**: TotalCash is maintained by a reconciliation job (Trade.UpdateTotalCash) rather than by event-driven increments. It uses the dbo.dtPrice user-defined type (DECIMAL precision for price values).

**Columns/Parameters Involved**: `TotalCash`

**Rules**:
- TotalCash uses type dbo.dtPrice (not raw money) - higher precision for price/cash calculations
- Maintained by reconciliation batch, not inline writes
- Classification as per-currency or account-level is an open question in the multi-currency design (to be resolved based on what Trade.UpdateTotalCash computes)

### 2.4 Multi-Currency Migration Path

**What**: CustomerMoney (current table) will be replaced by a VIEW after Phase 2 of the multi-currency migration.

**Rules**:
- Phase 2 (planned): Creates Customer.CustomerMoneyByCurrency (per-currency) and Customer.CustomerAccount (account-level)
- CustomerMoney becomes a VIEW joining both new tables, converting to USD for backward compatibility
- Migration strategy: migrate writes to new tables, CustomerMoney view provides read compatibility
- Credit classified as per-currency (each CID+CurrencyId has its own Credit balance)
- RealizedEquity, BonusCredit, BSLRealFunds classified as account-level (USD-only for MVP)
- TotalCash classification: open (decision pending on how UpdateTotalCash computes it)

---

## 3. Data Overview

| CID | GCID | Credit | BonusCredit | RealizedEquity | TotalCash | BSLRealFunds | Meaning |
|---|---|---|---|---|---|---|---|
| -1 | 1983586 | 355,555 | 0 | 355,555 | 355,555 | 0 | System/test account: large round-number credit, no BSL, equity = credit (all real funds) |
| 15 | 1983588 | 108,864 | 1,792.43 | 109,415.66 | 109,365.37 | 24.77 | High-value account: mix of real credit and bonus, BSL active, RealizedEquity slightly above Credit |
| 5 | 1983587 | 0 | 0 | 0.10 | 10,000 | 0 | Test account: zero credit but $10k TotalCash (reconciliation offset), tiny RealizedEquity |

*18,744,975 total rows. GCID present on all sample rows, indicating CustomerMoney tracks both CID and GCID for customer identity.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | VERIFIED | Customer ID - primary key. Matches CID in Customer.CustomerStatic. One row per customer. |
| 2 | GCID | int | YES | - | VERIFIED | Group Customer ID - same as Customer.CustomerStatic.GCID. Redundant storage for lookup performance - avoids join to CustomerStatic for GCID resolution. Confirmed as account-level field (not per-currency) in multi-currency design. |
| 3 | Credit | money | NO | - | VERIFIED | Current available cash balance in USD. The primary trading balance - what the customer can use to open positions. Updated by every financial event (deposit, withdrawal, position open/close, fee, bonus). Classified as per-currency in the upcoming multi-currency migration (Credit becomes per CID+CurrencyId). |
| 4 | BonusCredit | money | YES | 0 | VERIFIED | Promotional/bonus credits, separate from real funds. Default = 0. Confirmed as account-level (USD-only) in multi-currency design (March 8 decision). |
| 5 | RealizedEquity | money | YES | 0 | VERIFIED | Running total of realized value: increases on deposits and position close proceeds, decreases on withdrawals. Answers "how much has the customer realized?" Confirmed as account-level (single USD number) in multi-currency design - Mor: "Realized equity is per account." |
| 6 | TotalCash | dbo.dtPrice | YES | - | VERIFIED | Reconciled cash total maintained by Trade.UpdateTotalCash reconciliation job. Uses dtPrice UDT (higher decimal precision than money). Per-currency vs account-level classification is open in multi-currency design. |
| 7 | BSLRealFunds | money | YES | 0 | VERIFIED | Real funds threshold for Balance Stop Loss (BSL) system. Updated by PostMIMOOperations. When customer equity drops to this level, BSL liquidation triggers. BSL is account-wide (USD aggregate), confirmed as account-level field. Default = 0. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerStatic | Implicit | CID is the customer identity; no FK constraint declared |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.SetBalance | CID | PRIMARY WRITER | Central balance router - almost all balance writes go through this |
| Trade.UpdateTotalCash | CID | WRITER | Reconciliation job that maintains TotalCash |
| History.ActiveCredit_BIGINT | CID | Related | Append-only ledger; CustomerMoney holds the current state, ActiveCredit holds the full history |
| History.ActiveCreditExtended | CID | Related | Copy-trade credit snapshot; feeds from CustomerMoney |
| Customer.CustomerMoneyByCurrency | CID | Future replacement | New per-currency table (multi-currency migration Phase 2) |
| Customer.CustomerAccount | CID | Future replacement | New account-level table (multi-currency migration Phase 2) |
| (107+ objects) | CID | READERS | 95 SPs, 9 views, 3 functions read balance data from this table |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no FK dependencies.

### 6.1 Objects This Depends On

No FK constraints declared.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.SetBalance | Stored Procedure | Central write router - 56 write-path procedures funnel through here |
| Trade.UpdateTotalCash | Stored Procedure | Reconciliation writer for TotalCash |
| History.ActiveCredit_BIGINT | Table | Append-only transaction ledger complementing this current-state table |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CustomerMoney | CLUSTERED | CID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_CustomerMoney | PRIMARY KEY | CID must be unique - one balance row per customer (PAGE compression) |
| DFCC_BonusCredit | DEFAULT | BonusCredit = 0 |
| CCST_RealizedEquity | DEFAULT | RealizedEquity = 0 |
| DF_CustomerCustomerMoney_BSLRealFunds | DEFAULT | BSLRealFunds = 0 |

---

## 8. Sample Queries

### 8.1 Get balance for a customer

```sql
SELECT
    cm.CID,
    cm.GCID,
    cm.Credit,
    cm.BonusCredit,
    cm.RealizedEquity,
    cm.TotalCash,
    cm.BSLRealFunds
FROM Customer.CustomerMoney cm WITH (NOLOCK)
WHERE cm.CID = 15
```

### 8.2 Find customers with active BSL (non-zero BSLRealFunds)

```sql
SELECT
    CID,
    Credit,
    BSLRealFunds,
    RealizedEquity
FROM Customer.CustomerMoney WITH (NOLOCK)
WHERE BSLRealFunds > 0
ORDER BY BSLRealFunds DESC
```

### 8.3 Balance distribution summary

```sql
SELECT
    CASE
        WHEN Credit = 0 THEN 'Zero Balance'
        WHEN Credit < 100 THEN 'Under $100'
        WHEN Credit < 1000 THEN '$100 - $1,000'
        WHEN Credit < 10000 THEN '$1,000 - $10,000'
        ELSE 'Over $10,000'
    END AS BalanceTier,
    COUNT(*) AS CustomerCount
FROM Customer.CustomerMoney WITH (NOLOCK)
GROUP BY
    CASE
        WHEN Credit = 0 THEN 'Zero Balance'
        WHEN Credit < 100 THEN 'Under $100'
        WHEN Credit < 1000 THEN '$100 - $1,000'
        WHEN Credit < 10000 THEN '$1,000 - $10,000'
        ELSE 'Over $10,000'
    END
ORDER BY CustomerCount DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Multi-Currency Database Schema Changes](https://etoro-jira.atlassian.net/wiki/spaces/TRAD/pages/14019264620) | Confluence (TRAD) | Complete field classification: Credit=per-currency, BonusCredit/RealizedEquity/BSLRealFunds=account-level, TotalCash=open. Alternative A (Split Tables) decided March 8, 2026. CustomerMoney becomes VIEW. 56 write SPs, 107+ read objects enumerated. |
| [Equity Calculator Multi-Currency Support](https://etoro-jira.atlassian.net/wiki/spaces/TRAD/pages/14035615822) | Confluence (TRAD) | Credit and AvailableCredit become per-currency. Positions and PnL remain in USD. Equity calculator design for multi-currency. |
| [Multi-Currency Balance API](https://etoro-jira.atlassian.net/wiki/spaces/TRAD/pages/14028570661) | Confluence (TRAD) | Trading.BalanceService new microservice replaces Billing SP entry-points. MIMO (Money In Money Out) terminology for deposits/withdrawals. |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.5/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 9/10)*
*Confidence: 0 EXPERT, 7 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 3 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.CustomerMoney | Type: Table | Source: etoro/etoro/Customer/Tables/Customer.CustomerMoney.sql*
