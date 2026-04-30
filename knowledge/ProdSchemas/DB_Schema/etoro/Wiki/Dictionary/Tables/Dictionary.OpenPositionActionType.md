# Dictionary.OpenPositionActionType

> Lookup table defining the 18 triggers/reasons for opening a new trading position — used for attribution, analytics, and fee routing.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (INT, no PK constraint — DDL anomaly) |
| **Partition** | DICTIONARY partition scheme |
| **Indexes** | 0 active (no indexes defined — DDL anomaly) |

---

## 1. Business Meaning

Dictionary.OpenPositionActionType defines every possible trigger or reason that can create a new position on the eToro platform. Whether a user manually buys, a CopyTrading leader opens a position, a corporate action splits shares, or a recurring investment executes — each scenario has a distinct action type recorded with the opened position.

This table is essential for understanding position origin and for regulatory reporting. It distinguishes between user-initiated trades (manual, copy-trading), system-generated positions (dividends, corporate actions, contract rollovers), and operational corrections. This attribution affects fee calculations, investment performance reporting, and compliance audit trails.

The action type is written to Trade.PositionTbl when a position opens and is immutable thereafter. It is read by reporting procedures, DWH exports, and account statement generation. Notably, this table has **no primary key or indexes** in the DDL — a design anomaly that may indicate it was created as a simple reference table without formal constraint enforcement.

---

## 2. Business Logic

### 2.1 Position Origin Categories

**What**: Open actions group by who/what initiated the position creation.

**Columns/Parameters Involved**: `ID`, `OpenPositionActionName`

**Rules**:
- **User-initiated** (0=Customer): User manually placed a trade
- **CopyTrading** (1=Hierarchical Open, 8=Add Funds, 16=Alignment): Driven by copy relationship with a leader
- **System-generated** (4=Stock Dividend, 5=Corporate Action, 2=Reopen, 9=Reinvestment): Created by automated business events
- **Operational** (6=Technical Issue, 7=Adjustment, 10=Admin, 15=Technical): Internal corrections
- **Special** (11=Stacking, 12=Promotion, 13=ACATS_IN, 14=ReedemForNFT, 17=Recurring Investment): Product-specific features
- **Undefined** (-1): Legacy data where the origin was not recorded

**Diagram**:
```
Position Creation Triggers:
├── User (0=Customer) ← majority of positions
├── CopyTrading
│   ├── 1: Hierarchical Open (leader opened)
│   ├── 8: Add Funds (copier adds to copy)
│   └── 16: Alignment (portfolio sync)
├── System Events
│   ├── 4: Stock Dividend
│   ├── 5: Corporate Action (split, merger)
│   ├── 2: Reopen (rollover)
│   └── 9: Reinvestment
├── Operations
│   ├── 7: Operational adjustment
│   └── 10: Admin
└── Special Products
    ├── 11: Stacking (crypto staking)
    ├── 13: ACATS_IN (US account transfer)
    └── 17: Recurring Investment
```

---

## 3. Data Overview

| ID | OpenPositionActionName | Meaning |
|---|---|---|
| 0 | Customer | User manually placed a market or limit order. The most common open type — represents self-directed trading decisions. Full attribution to user for performance tracking. |
| 1 | Hierarchical Open | CopyTrading cascade: the copied trader (leader) opened a position, so this copier's account automatically mirrors the trade. The copier did not choose this specific trade — it was driven by the leader. |
| 5 | Corporate Action | Position automatically created or adjusted by a corporate event (stock split, reverse split, merger, spinoff). Not a user trading decision — driven by the issuing company's corporate action. |
| 13 | ACATS_IN | Position transferred into the account via ACATS (Automated Customer Account Transfer Service) — the US regulatory mechanism for moving brokerage accounts between firms. Position was originally opened elsewhere. |
| 17 | Recurring Investment | Position opened by the automated recurring investment feature. User configured a schedule (e.g., $100/month into S&P 500) and this position was created by the scheduler. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | VERIFIED | Identifier for the open trigger (no PK constraint in DDL). -1=Undefined, 0=Customer, 1=Hierarchical Open, 2=Reopen, 3=Open Open, 4=Stock Dividend, 5=Corporate Action, 6=Technical Issue, 7=Operational adjustment, 8=Add Funds, 9=Reinvestment, 10=Admin, 11=Stacking, 12=Promotion, 13=ACATS_IN, 14=ReedemForNFT, 15=Technical, 16=Alignment, 17=Recurring Investment. Stored with every position for permanent attribution. See [Open Position Action Type](_glossary.md#open-position-action-type). (Dictionary.OpenPositionActionType) |
| 2 | OpenPositionActionName | varchar(100) | NO | - | VERIFIED | Human-readable label for the open trigger. Used in account statements, trading reports, and back-office displays. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.PositionTbl | OpenPositionActionTypeID | Implicit Lookup | Records the open trigger for every position |
| History position tables | OpenPositionActionTypeID | Implicit Lookup | Historical position records reference open action type |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | Stores OpenPositionActionTypeID per position |

---

## 7. Technical Details

### 7.1 Indexes

No indexes defined. **DDL anomaly**: This table has no primary key constraint and no indexes. The ID column is NOT NULL but has no uniqueness enforcement at the database level. This may rely on application-level enforcement or was an oversight during table creation.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all open action types
```sql
SELECT  ID,
        OpenPositionActionName
FROM    [Dictionary].[OpenPositionActionType] WITH (NOLOCK)
ORDER BY ID;
```

### 8.2 Count open positions by creation trigger
```sql
SELECT  opat.OpenPositionActionName,
        COUNT(*) AS PositionCount
FROM    [Trade].[PositionTbl] tp WITH (NOLOCK)
JOIN    [Dictionary].[OpenPositionActionType] opat WITH (NOLOCK)
        ON tp.OpenPositionActionTypeID = opat.ID
WHERE   tp.IsClosed = 0
GROUP BY opat.OpenPositionActionName
ORDER BY PositionCount DESC;
```

### 8.3 Find all corporate-action-generated positions for a customer
```sql
SELECT  tp.PositionID,
        tp.CurrencyID,
        opat.OpenPositionActionName,
        tp.OpenDateTime,
        tp.Amount
FROM    [Trade].[PositionTbl] tp WITH (NOLOCK)
JOIN    [Dictionary].[OpenPositionActionType] opat WITH (NOLOCK)
        ON tp.OpenPositionActionTypeID = opat.ID
WHERE   tp.CID = @CID
        AND tp.OpenPositionActionTypeID IN (4, 5)
ORDER BY tp.OpenDateTime DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to Dictionary.OpenPositionActionType.

---

*Generated: 2026-03-13 | Enriched: - | Quality: 8.4/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.OpenPositionActionType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.OpenPositionActionType.sql*
