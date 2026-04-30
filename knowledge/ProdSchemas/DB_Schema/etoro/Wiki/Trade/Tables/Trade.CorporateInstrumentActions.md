# Trade.CorporateInstrumentActions

> Records corporate actions (dividends, splits, mergers, etc.) per instrument with effective dates - supports dividend processing, position adjustments, and compliance tracking.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | CorporateInstrumentActionID (int, PK) |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | 2 active (clustered PK, IX_CorporateInstrumentActions_EffectiveDate) |

---

## 1. Business Meaning

Trade.CorporateInstrumentActions stores a history of corporate actions that affect tradeable instruments. Each row represents one event (dividend, stock split, merger, reverse split, rights offer, etc.) tied to a specific instrument and effective date. The table answers "What corporate events happened for this instrument?" and drives dividend payment processing, position airdrops, split adjustments, and compliance reporting.

This table exists because when a listed company pays a dividend, does a stock split, or undergoes a merger, the trading platform must apply the correct treatment to open positions and orders. Without CorporateInstrumentActions, procedures like Trade.PayCashDividendByPayDate, Trade.ExecuteCashPayment, Trade.PositionAirdrop, and Trade.GetCorporateActionType could not determine which instruments have pending corporate actions or what type of action applies. The effective date enables time-based queries for actions within a date range.

Data flows: Rows are likely populated by external corporate action feeds or application services (no INSERT procedure found in etoro SSDT). Trade.GetCorporateInstrumentActions reads all actions with InstrumentID, EffectiveDate, and type resolved via Dictionary.CorporateAction. The table is system-versioned to History.CorporateInstrumentActions for temporal queries. An INSERT trigger (Tr_T_CorporateInstrumentActions_INSERT) fires on insert but performs a no-op update (InstrumentID = InstrumentID) - likely for cache invalidation or downstream sync.

---

## 2. Business Logic

### 2.1 Corporate Action Type Classification

**What**: Each row links to Dictionary.CorporateAction to classify the event type (dividend, split, merger, etc.).

**Columns/Parameters Involved**: `CorporateInstrumentActionType`, `InstrumentID`, `EffectiveDate`

**Rules**:
- CorporateInstrumentActionType FK to Dictionary.CorporateAction.CorporateActionTypeID
- Common types: 1=Dividend, 3=Cash Dividend, 10=Reverse split, 20=Stock Dividend, 21=Stock Split, 33=Merger, 35=Staking
- EffectiveDate is when the action takes effect. Used for "pay by date" logic in dividend procedures
- Trade.GetCorporateInstrumentActions returns InstrumentID, EffectiveDate, and CorporateActionType (resolved from lookup)

**Diagram**:
```
Instrument (e.g., AAPL) --> CorporateInstrumentActions row
    |-- EffectiveDate: 2024-06-15
    |-- CorporateInstrumentActionType: 1 (Dividend)
    v
Dictionary.CorporateAction: 1=Dividend
```

### 2.2 Per-Instrument, Per-Date Uniqueness

**What**: Multiple actions can exist per instrument (e.g., dividend then split) but each row is a distinct event.

**Columns/Parameters Involved**: `InstrumentID`, `EffectiveDate`, `CorporateInstrumentActionType`

**Rules**:
- PK is CorporateInstrumentActionID (surrogate). No unique constraint on (InstrumentID, EffectiveDate, Type)
- Same instrument can have multiple rows for different dates or different action types
- IX_CorporateInstrumentActions_EffectiveDate supports date-range queries

---

## 3. Data Overview

| CorporateInstrumentActionID | InstrumentID | EffectiveDate | CorporateInstrumentActionType | Meaning |
|---|---|---|---|---|
| (Table has 0 rows in environment) | - | - | - | No sample rows. When populated: each row would represent a corporate event (dividend, split, merger) for an instrument on a specific date. Example: InstrumentID=1001 (AAPL), EffectiveDate=2024-06-15, CorporateInstrumentActionType=1 (Dividend) would mean Apple paid a dividend effective that date. |

**Selection criteria for the 5 rows:**
- Table currently empty. DDL and procedure logic define structure. Representative rows would show variety: dividends (1, 3), splits (21), reverse splits (10), mergers (33), crypto staking (35).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CorporateInstrumentActionID | int | NO | IDENTITY(1,1) | CODE-BACKED | Primary key. Surrogate identifier for each corporate action record. |
| 2 | InstrumentID | int | NO | - | CODE-BACKED | FK to Trade.InstrumentMetaData.InstrumentID. The instrument affected by this corporate action. |
| 3 | EffectiveDate | datetime | NO | - | CODE-BACKED | When the corporate action takes effect. Used by dividend payment and position adjustment logic. Indexed (IX_CorporateInstrumentActions_EffectiveDate). |
| 4 | CorporateInstrumentActionType | int | NO | - | CODE-BACKED | FK to Dictionary.CorporateAction.CorporateActionTypeID. Type of action: 1=Dividend, 3=Cash Dividend, 10=Reverse split, 20=Stock Dividend, 21=Stock Split, 33=Merger, 35=Staking, etc. See Dictionary.CorporateAction for full list. |
| 5 | DbLoginName | (computed) | - | - | CODE-BACKED | Computed: suser_name(). Current DB login for audit context. |
| 6 | AppLoginName | (computed) | - | - | CODE-BACKED | Computed: CONVERT(varchar(500), context_info()). Application context for audit. |
| 7 | SysStartTime | datetime2(7) | NO | getutcdate() | CODE-BACKED | System-versioning row start. GENERATED ALWAYS AS ROW START HIDDEN. |
| 8 | SysEndTime | datetime2(7) | NO | '9999-12-31 23:59:59.9999999' | CODE-BACKED | System-versioning row end. GENERATED ALWAYS AS ROW END HIDDEN. History in History.CorporateInstrumentActions. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.InstrumentMetaData | FK | Instrument affected by the corporate action |
| CorporateInstrumentActionType | Dictionary.CorporateAction | FK | Action type (dividend, split, merger, etc.) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetCorporateInstrumentActions | - | SELECT/JOIN | Reads all actions with type from Dictionary.CorporateAction |
| Trade.GetCorporateActionType | - | JOIN | Determines corporate action type for instruments |
| Trade.PayCashDividendByPayDate | - | JOIN | Dividend payment by effective date |
| Trade.ExecuteCashPayment | - | JOIN | Cash payment execution |
| Trade.PositionAirdrop | - | JOIN | Position airdrop on corporate actions |
| History.CorporateInstrumentActions | - | System Versioning | Temporal history table |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.CorporateInstrumentActions (table)
```

Tables have no code-level dependencies. FK targets (Trade.InstrumentMetaData, Dictionary.CorporateAction) are structural only.

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentMetaData | Table | FK: InstrumentID -> InstrumentID |
| Dictionary.CorporateAction | Table | FK: CorporateInstrumentActionType -> CorporateActionTypeID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetCorporateInstrumentActions | Procedure | Reads InstrumentID, EffectiveDate, CorporateActionType |
| Trade.GetCorporateActionType | Procedure | Determines action type |
| Trade.PayCashDividendByPayDate | Procedure | Dividend payment |
| Trade.ExecuteCashPayment | Procedure | Cash payment |
| Trade.PositionAirdrop | Procedure | Position airdrop |
| History.CorporateInstrumentActions | Table | System versioning history |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CorporateInstrumentActions | CLUSTERED PK | CorporateInstrumentActionID ASC | - | - | Active |
| IX_CorporateInstrumentActions_EffectiveDate | NC | EffectiveDate ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_CorporateInstrumentActions | PRIMARY KEY | CorporateInstrumentActionID clustered |
| FK_CorporateActions_CorporateInstrumentActionTypes | FOREIGN KEY | CorporateInstrumentActionType -> Dictionary.CorporateAction.CorporateActionTypeID |
| FK_CorporateInstrumentActions_InstrumentID | FOREIGN KEY | InstrumentID -> Trade.InstrumentMetaData.InstrumentID |
| DF_CorporateInstrumentActions_SysStart | DEFAULT | SysStartTime = getutcdate() |
| DF_CorporateInstrumentActions_SysEnd | DEFAULT | SysEndTime = '9999-12-31 23:59:59.9999999' |
| Tr_T_CorporateInstrumentActions_INSERT | TRIGGER | Fires on INSERT; no-op update for cache/sync |

---

## 8. Sample Queries

### 8.1 Get all corporate actions with type description
```sql
SELECT tca.InstrumentID,
       tca.EffectiveDate,
       dca.Description AS CorporateActionType
FROM Trade.CorporateInstrumentActions tca WITH (NOLOCK)
JOIN Dictionary.CorporateAction dca WITH (NOLOCK)
  ON dca.CorporateActionTypeID = tca.CorporateInstrumentActionType
ORDER BY tca.EffectiveDate DESC, tca.InstrumentID;
```

### 8.2 Corporate actions for an instrument
```sql
SELECT tca.CorporateInstrumentActionID,
       tca.InstrumentID,
       tca.EffectiveDate,
       dca.Description AS CorporateActionType
FROM Trade.CorporateInstrumentActions tca WITH (NOLOCK)
JOIN Dictionary.CorporateAction dca WITH (NOLOCK)
  ON dca.CorporateActionTypeID = tca.CorporateInstrumentActionType
WHERE tca.InstrumentID = 1001
ORDER BY tca.EffectiveDate DESC;
```

### 8.3 Corporate actions within date range
```sql
SELECT tca.InstrumentID,
       imd.InstrumentDisplayName,
       tca.EffectiveDate,
       dca.Description AS CorporateActionType
FROM Trade.CorporateInstrumentActions tca WITH (NOLOCK)
JOIN Dictionary.CorporateAction dca WITH (NOLOCK)
  ON dca.CorporateActionTypeID = tca.CorporateInstrumentActionType
LEFT JOIN Trade.InstrumentMetaData imd WITH (NOLOCK)
  ON imd.InstrumentID = tca.InstrumentID
WHERE tca.EffectiveDate >= '2024-01-01'
  AND tca.EffectiveDate < '2024-12-31'
ORDER BY tca.EffectiveDate, tca.InstrumentID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 7.8/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.CorporateInstrumentActions | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.CorporateInstrumentActions.sql*
