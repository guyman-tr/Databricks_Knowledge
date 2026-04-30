# BackOffice.GetOverdraftOverTheWeekend

> Identifies customers whose account credit would fall below zero if the end-of-week holding fee is applied to their open positions that survive the weekend.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | View |
| **Key Identifier** | CID - one row per at-risk customer |
| **Partition** | N/A |
| **Indexes** | N/A (defined on base tables) |

---

## 1. Business Meaning

`BackOffice.GetOverdraftOverTheWeekend` is a risk alert view that flags customers whose account balance (Credit) would go negative after the weekend holding fee is charged. eToro charges an `EndOfWeekFee` (per lot) on positions that remain open over the weekend (`CloseOnEndOfWeek=0`). This view computes each customer's total weekend fee exposure and surfaces those whose Credit cannot cover it.

This view exists so that operations/risk teams can proactively act before the weekend fee batch run - reaching out to customers, reducing exposure, or applying margin calls before the fees create negative balances. Without it, a batch fee deduction could silently push accounts into overdraft.

Data is computed at query time from live open positions (`Trade.Position`), instrument-level weekend fee rates (`Trade.ProviderToInstrument.EndOfWeekFee`), and customer balances (`Customer.Customer.Credit`). The view only surfaces the problem cases: customers where `Credit - TotalWeekendFee < 0`.

---

## 2. Business Logic

### 2.1 Weekend Overdraft Risk Detection

**What**: Identifies accounts that cannot absorb the upcoming end-of-week holding fee on their surviving open positions.

**Columns/Parameters Involved**: `CID`, `Fee`, `IsReal`

**Rules**:
- Only positions with `CloseOnEndOfWeek = 0` are included - positions set to auto-close at end of week do not incur the weekend fee
- Fee per position = `EndOfWeekFee * LotCountDecimal` (fee rate from `Trade.ProviderToInstrument`, scaled by lot size)
- Total fee per customer = `SUM(EndOfWeekFee * LotCountDecimal)` across all their weekend-surviving positions
- A customer is flagged when: `Customer.Credit - TotalFee < 0` (their credit balance minus the fee goes negative)
- `IsReal` on the output allows filtering between real-money and demo accounts

**Diagram**:
```
Trade.Position (open positions)
  WHERE CloseOnEndOfWeek = 0
  JOIN Trade.ProviderToInstrument ON (InstrumentID, ProviderID)
         |
    SUM(EndOfWeekFee * LotCountDecimal) per CID
         |
         v
    Fees subquery: {CID, TotalFee}
         |
    JOIN Customer.Customer WHERE Credit - TotalFee < 0
         |
         v
  Output: flagged customers at overdraft risk
```

---

## 3. Data Overview

*Live data not available - view joins large Trade and Customer tables. Results only present during periods when accounts have weekend-surviving open positions and insufficient credit.*

| CID | FirstName | IsReal | Email | Fee |
|-----|-----------|--------|-------|-----|
| (example) | John | 1 | john@example.com | 45.50 |
| (example) | Maria | 1 | maria@example.com | 120.00 |

*Each row represents a real (or demo) customer whose credit balance is less than their total weekend holding fee. The Fee column shows the total amount that would be charged to their account.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | INT (from Customer.Customer) | NO | - | CODE-BACKED | Customer identifier. Unique per row - one row per customer whose account would overdraft. Joins the fee subquery to Customer.Customer and is the basis for the overdraft filter (`Credit - Fee < 0`). |
| 2 | FirstName | NVARCHAR (from Customer.Customer) | YES | - | CODE-BACKED | Customer's first name. From `Customer.Customer.FirstName`. Provided for identification/contact purposes so BackOffice staff can look up or contact the at-risk customer. |
| 3 | IsReal | BIT (from Customer.Customer) | NO | - | CODE-BACKED | Indicates whether this is a real-money account (1) or a demo account (0). From `Customer.Customer.IsReal`. Allows operations to distinguish between real financial risk (IsReal=1) and demo simulation risk (IsReal=0) and prioritize accordingly. |
| 4 | Email | NVARCHAR (from Customer.Customer) | YES | - | CODE-BACKED | Customer's registered email address. From `Customer.Customer.Email`. Used by operations staff to contact the customer about their overdraft risk before the weekend fee batch runs. |
| 5 | Fee | DECIMAL (computed aggregate) | YES | - | VERIFIED | Total weekend holding fee that would be charged to this customer. Computed as `SUM(Trade.ProviderToInstrument.EndOfWeekFee * Trade.Position.LotCountDecimal)` across all weekend-surviving open positions (`CloseOnEndOfWeek=0`). This is the amount that, when subtracted from `Credit`, would produce a negative balance. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, CloseOnEndOfWeek, LotCountDecimal, InstrumentID, ProviderID | Trade.Position | Source (cross-schema, NOLOCK) | Provides open positions filtered to those that survive the weekend (CloseOnEndOfWeek=0). |
| EndOfWeekFee | Trade.ProviderToInstrument | Lookup (cross-schema, NOLOCK) | Provides the per-lot weekend holding fee rate for each instrument/provider combination. |
| CID, FirstName, IsReal, Email, Credit | Customer.Customer | Source + Filter (cross-schema, NOLOCK) | Provides customer details and the Credit balance used to detect overdraft (`Credit - Fee < 0`). |

### 5.2 Referenced By (other objects point to this)

No dependents found in the BackOffice schema.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetOverdraftOverTheWeekend (view)
├── Trade.Position (cross-schema view)
├── Trade.ProviderToInstrument (cross-schema table)
└── Customer.Customer (cross-schema table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | Cross-schema View | Subquery FROM (alias TPOS, NOLOCK) - open positions filtered to CloseOnEndOfWeek=0 |
| Trade.ProviderToInstrument | Cross-schema Table | Subquery JOIN (alias TPTI, NOLOCK) - provides EndOfWeekFee rate per (InstrumentID, ProviderID) |
| Customer.Customer | Cross-schema Table | Outer JOIN (alias CCST, NOLOCK) - filtered to rows where `Credit - Fee < 0` |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

N/A for view. Note: The overdraft filter (`Credit - Fees.Fee < 0`) is applied as a JOIN condition, not a WHERE clause. All three sources use `WITH(NOLOCK)` to reduce lock contention on active production tables.

---

## 8. Sample Queries

### 8.1 Get all at-risk customers sorted by fee size

```sql
SELECT CID, FirstName, Email, Fee
FROM BackOffice.GetOverdraftOverTheWeekend WITH (NOLOCK)
WHERE IsReal = 1
ORDER BY Fee DESC
```

### 8.2 Count real-money accounts at overdraft risk

```sql
SELECT COUNT(*) AS AtRiskAccounts, SUM(Fee) AS TotalFeeExposure
FROM BackOffice.GetOverdraftOverTheWeekend WITH (NOLOCK)
WHERE IsReal = 1
```

### 8.3 Find high-risk accounts with large fee exposure

```sql
SELECT CID, FirstName, Email, Fee
FROM BackOffice.GetOverdraftOverTheWeekend WITH (NOLOCK)
WHERE IsReal = 1
  AND Fee > 100
ORDER BY Fee DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/7 (Phase 2 skipped - large table)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetOverdraftOverTheWeekend | Type: View | Source: etoro/etoro/BackOffice/Views/BackOffice.GetOverdraftOverTheWeekend.sql*
