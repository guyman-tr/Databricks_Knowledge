# History.CorporateInstrumentActions

> Temporal HISTORY_TABLE for Trade.CorporateInstrumentActions - stores 268 versioned snapshots of corporate actions (dividends, splits, mergers) scheduled against instruments.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK - temporal history table (clustered on SysEndTime, SysStartTime) |
| **Partition** | No |
| **Temporal** | Yes - HISTORY_TABLE for Trade.CorporateInstrumentActions |
| **Indexes** | 1 (clustered on SysEndTime ASC, SysStartTime ASC) |
| **Compression** | DATA_COMPRESSION=PAGE, on [DICTIONARY] filegroup |

---

## 1. Business Meaning

History.CorporateInstrumentActions is the SQL Server temporal HISTORY_TABLE for Trade.CorporateInstrumentActions. It stores all prior row versions when corporate action records are inserted, updated, or deleted in the base table.

Trade.CorporateInstrumentActions tracks scheduled corporate actions for financial instruments - events such as stock splits, dividends, and mergers that affect position values. Each row records an action by its type (CorporateInstrumentActionType), the affected instrument (InstrumentID), and when it takes effect (EffectiveDate).

268 rows covering 2023-01-05 to 2025-02-20. The most recent observed action involves InstrumentID=1 (primary index instrument) with ActionType=3, with very short validity windows (SysStartTime=SysEndTime in some rows), indicating rapid sequential updates to the same action record.

---

## 2. Business Logic

### 2.1 Auto-Managed by SQL Server Temporal Versioning

**What**: Every change to a row in Trade.CorporateInstrumentActions writes the prior version here.

**Rules**:
- Never written to directly
- 268 rows = moderate change history for corporate action scheduling
- Rows with SysStartTime=SysEndTime = rows that were written and immediately modified/deleted
- On [DICTIONARY] filegroup - collocated with dictionary/reference data

### 2.2 Corporate Action Types

CorporateInstrumentActionType values observed include type 3. The full value map is defined in Trade.CorporateInstrumentActions / related dictionary tables. Common corporate action types in eToro context: dividends (stock distributions), splits (price adjustments), mergers, delistings.

---

## 3. Data Overview

| Metric | Value |
|--------|-------|
| **Total Rows** | 268 |
| **SysStart Range** | 2023-01-05 to 2025-02-20 |
| **Status** | Inactive since February 2025 |

Sample:

| CorporateInstrumentActionID | InstrumentID | EffectiveDate | ActionType | SysStartTime | SysEndTime |
|----------------------------|-------------|--------------|-----------|-------------|------------|
| 156 | 1 | 2025-02-20 12:13 | 3 | 2025-02-20 11:13 | 2025-02-20 11:13 |
| 155 | 1 | 2025-02-20 12:13 | 3 | 2025-02-20 11:13 | 2025-02-20 11:13 |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CorporateInstrumentActionID | int | NO | - | VERIFIED | ID of the corporate action record. Matches Trade.CorporateInstrumentActions.CorporateInstrumentActionID. |
| 2 | InstrumentID | int | NO | - | VERIFIED | The financial instrument affected by the corporate action. Implicit FK to Trade.InstrumentTbl. Observed: InstrumentID=1. |
| 3 | EffectiveDate | datetime | NO | - | VERIFIED | The scheduled date when the corporate action takes effect (ex-date for dividends, effective date for splits). |
| 4 | CorporateInstrumentActionType | int | NO | - | VERIFIED | Type of corporate action. Observed: 3 (likely dividend, split, or merger). Full value map in Trade schema. |
| 5 | DbLoginName | nvarchar(128) | YES | - | VERIFIED | SQL Server login at time of change. Audit column. |
| 6 | AppLoginName | varchar(500) | YES | - | VERIFIED | Application login from context_info(). Audit column. |
| 7 | SysStartTime | datetime2(7) | NO | - | VERIFIED | When this version became current. Set by SQL Server temporal engine. |
| 8 | SysEndTime | datetime2(7) | NO | - | VERIFIED | When this version was superseded. Set by SQL Server temporal engine. |

---

## 5. Relationships

### 5.1 References To

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (all columns) | Trade.CorporateInstrumentActions | HISTORY_TABLE (temporal) | Auto-managed history table for Trade.CorporateInstrumentActions. |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Compression |
|-----------|------|-------------|-------------|
| ix_CorporateInstrumentActions | CLUSTERED | SysEndTime ASC, SysStartTime ASC | PAGE |

---

## 8. Sample Queries

```sql
-- Full history of corporate actions for an instrument
SELECT CorporateInstrumentActionID, InstrumentID, EffectiveDate,
       CorporateInstrumentActionType, SysStartTime, SysEndTime
FROM Trade.CorporateInstrumentActions
FOR SYSTEM_TIME ALL
WHERE InstrumentID = 1
ORDER BY SysStartTime;
```

---

*Generated: 2026-03-19 | Quality: 8.5/10 (Elements: 8.5/10, Logic: 8.5/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Object: History.CorporateInstrumentActions | Type: Table | Source: etoro/etoro/History/Tables/History.CorporateInstrumentActions.sql*
