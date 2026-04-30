# History.CashoutRange

> Manual version archive for cashout (withdrawal) fee schedules; each row defines a fee tier for a specific fee group and amount range, with validity periods capturing how the fee structure has changed over time.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | HistoryFeeID - IDENTITY PK CLUSTERED |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered on HistoryFeeID) |

---

## 1. Business Meaning

History.CashoutRange is a manually-maintained version archive for eToro's cashout (customer withdrawal) fee schedules. Each row defines a fee tier: for a given CashoutFeeGroup and withdrawal amount range (FromValue to ToValue), what flat fee (Fee) is charged. The ValidFrom and ValidTo columns capture when each fee configuration was in effect.

Customers are assigned to a CashoutFeeGroup - Default, Exempt, or Discount - which determines which fee schedule applies to their withdrawals. The Default group has standard tiered fees; the Exempt group pays no withdrawal fees; the Discount group has reduced fees for large withdrawals.

This table is a pre-temporal predecessor to Trade.CashoutRange. It was maintained by DBA scripts when fee schedules changed (2010 initial setup, 2020 revision). All active procedures now read from Trade.CashoutRange (a SQL Server temporal table), while History.CashoutRange serves as a static historical record of the 2010-2020 period.

---

## 2. Business Logic

### 2.1 Fee Schedule Tiers by Group

**What**: Three fee groups (Default, Exempt, Discount) each with amount-range brackets mapping to flat fees.

**Columns/Parameters Involved**: `CashoutFeeGroupID`, `FromValue`, `ToValue`, `Fee`, `IsDefault`, `ValidFrom`, `ValidTo`

**Rules**:
- `CashoutFeeGroupID`: 1=Default, 2=Exempt, 3=Discount (FK to Dictionary.CashoutFeeGroup)
- `IsDefault=true` marks the Default group rows (CashoutFeeGroupID=1)
- `ValidTo='3000-01-01 00:00:00.000'` serves as "open-ended / currently active" sentinel value
- Amount range is inclusive on FromValue and exclusive on ToValue boundary (next tier starts at ToValue+0.01)
- No procedure writes to this table in the current codebase; data was inserted by DBA scripts

**2010 Fee Schedule (IDs 1-6)**:
| Group | From | To | Fee |
|---|---|---|---|
| 1 - Default | $20 | $200 | $5 |
| 1 - Default | $200.01 | $500 | $10 |
| 1 - Default | $500.01 | $100,000,000 | $25 |
| 2 - Exempt | $20 | $100,000,000 | $0 |
| 3 - Discount | $20 | $500 | $0 |
| 3 - Discount | $500.01 | $100,000,000 | $10 |

**2020 Fee Schedule Update (IDs 7-10)**:
| Group | From | To | Fee | Change |
|---|---|---|---|---|
| 1 - Default | $1 | $100,000,000 | $5 | Simplified to flat fee; minimum lowered from $20 |
| 2 - Exempt | $1 | $100,000,000 | $0 | Minimum lowered from $20 |
| 3 - Discount | $1 | $500 | $0 | Minimum lowered from $20 |
| 3 - Discount | $500.01 | $100,000,000 | $5 | Fee reduced from $10 |

**Current live schedule** is in Trade.CashoutRange (temporal), which matches the 2020 configuration above.

---

## 3. Data Overview

| HistoryFeeID | CashoutFeeGroupID | FromValue | ToValue | Fee | ValidFrom |
|---|---|---|---|---|---|
| 1 | 1 (Default) | $20 | $200 | $5 | 2010-06-27 (superseded) |
| 2 | 1 (Default) | $200.01 | $500 | $10 | 2010-06-27 (superseded) |
| 3 | 1 (Default) | $500.01 | $100M | $25 | 2010-06-27 (superseded) |
| 4 | 2 (Exempt) | $20 | $100M | $0 | 2010-06-27 (superseded) |
| 5 | 3 (Discount) | $20 | $500 | $0 | 2010-06-27 (superseded) |
| 6 | 3 (Discount) | $500.01 | $100M | $10 | 2010-06-27 (superseded) |
| 7 | 2 (Exempt) | $1 | $100M | $0 | 2020-03-16 (active) |
| 8 | 3 (Discount) | $1 | $500 | $0 | 2020-03-16 (active) |
| 9 | 3 (Discount) | $500.01 | $100M | $5 | 2020-03-16 (active) |
| 10 | 1 (Default) | $1 | $100M | $5 | 2020-03-16 (active) |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | HistoryFeeID | int | NO | IDENTITY | VERIFIED | Surrogate PK. Auto-incremented IDENTITY(1,1). |
| 2 | CashoutFeeGroupID | int | YES | - | VERIFIED | FK to Dictionary.CashoutFeeGroup: 1=Default (standard tiered fees), 2=Exempt (no fee), 3=Discount (reduced fee). Determines which fee bracket set applies to the customer. |
| 3 | FromValue | money | YES | - | VERIFIED | The minimum withdrawal amount (inclusive) for this fee tier to apply. E.g., 20.00 means the fee applies starting at $20. |
| 4 | ToValue | money | YES | - | VERIFIED | The maximum withdrawal amount (inclusive) for this fee tier. E.g., 200.00 means amounts up to $200 fall into this tier. 100,000,000 represents the practical upper bound. |
| 5 | Fee | money | YES | - | VERIFIED | The flat fee charged when the withdrawal amount falls within [FromValue, ToValue] for this CashoutFeeGroup. 0.00 for Exempt and lower Discount tiers. |
| 6 | IsDefault | bit | YES | 0 | VERIFIED | Marks rows belonging to the Default fee group (CashoutFeeGroupID=1). True for group 1 rows only. Redundant with CashoutFeeGroupID=1 but used as a quick filter. |
| 7 | ValidFrom | datetime | YES | - | VERIFIED | UTC timestamp when this fee configuration became effective. Two distinct values observed: 2010-06-27 (initial setup) and 2020-03-16 (revision). |
| 8 | ValidTo | datetime | YES | - | VERIFIED | UTC timestamp when this fee configuration expired. '3000-01-01 00:00:00.000' is the sentinel value for "currently active" - rows with this value represent the current fee schedule captured in this archive. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CashoutFeeGroupID | Dictionary.CashoutFeeGroup | FK (FK_DCCF) | Fee group classification for this tier |

### 5.2 Referenced By (other objects point to this)

No procedure references found in the codebase. Active procedures read from Trade.CashoutRange.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.CashoutFeeGroup
  -> History.CashoutRange (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.CashoutFeeGroup | Table | FK - fee group classification |

### 6.2 Objects That Depend On This

No active dependents. Trade.CashoutRange (temporal table with HISTORY_TABLE = History.TradeCashoutRange) is the modern replacement used by all current procedures.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HICF | CLUSTERED PK | HistoryFeeID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HICF | PRIMARY KEY | HistoryFeeID - surrogate PK |
| FK_DCCF | FOREIGN KEY | CashoutFeeGroupID -> Dictionary.CashoutFeeGroup(CashoutFeeGroupID) |
| (DEFAULT) | DEFAULT | IsDefault = 0 |

Storage: ON [PRIMARY] filegroup.

---

## 8. Sample Queries

### 8.1 View the fee schedule as it stood at a specific date
```sql
SELECT h.HistoryFeeID, cfg.Name AS FeeGroup, h.FromValue, h.ToValue, h.Fee, h.ValidFrom
FROM [History].[CashoutRange] h
JOIN [Dictionary].[CashoutFeeGroup] cfg ON h.CashoutFeeGroupID = cfg.CashoutFeeGroupID
WHERE h.ValidFrom <= @AsOfDate AND h.ValidTo >= @AsOfDate
ORDER BY h.CashoutFeeGroupID, h.FromValue
```

### 8.2 Current fee schedule snapshot in this archive
```sql
SELECT cfg.Name AS FeeGroup, h.FromValue, h.ToValue, h.Fee
FROM [History].[CashoutRange] h
JOIN [Dictionary].[CashoutFeeGroup] cfg ON h.CashoutFeeGroupID = cfg.CashoutFeeGroupID
WHERE h.ValidTo = '3000-01-01 00:00:00.000'
ORDER BY h.CashoutFeeGroupID, h.FromValue
```

### 8.3 Fee that would apply for a given amount and group (active schedule)
```sql
SELECT h.Fee, cfg.Name AS FeeGroup
FROM [History].[CashoutRange] h
JOIN [Dictionary].[CashoutFeeGroup] cfg ON h.CashoutFeeGroupID = cfg.CashoutFeeGroupID
WHERE h.CashoutFeeGroupID = @CashoutFeeGroupID
  AND @Amount BETWEEN h.FromValue AND h.ToValue
  AND h.ValidTo = '3000-01-01 00:00:00.000'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 6 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed (Billing.WithdrawRequestAdd, Customer.GetMiscData, Billing.WithdrawalService_GetCustomerFeeGroups - all read Trade.CashoutRange not this table) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.CashoutRange | Type: Table | Source: etoro/etoro/History/Tables/History.CashoutRange.sql*
