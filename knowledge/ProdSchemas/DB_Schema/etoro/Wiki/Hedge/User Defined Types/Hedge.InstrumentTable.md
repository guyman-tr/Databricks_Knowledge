# Hedge.InstrumentTable

> Minimal table-valued parameter type for passing a set of instrument IDs to stored procedures that operate on a caller-specified list of instruments.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | User Defined Type (TABLE type) |
| **Key Identifier** | No primary key (heap TVP) |
| **Partition** | N/A |
| **Indexes** | None |

---

## 1. Business Meaning

`Hedge.InstrumentTable` is the simplest possible TVP type in the Hedge schema - a single nullable `InstrumentID` column with no constraints. It enables callers to pass a variable-length list of instrument IDs to a stored procedure without string manipulation or XML encoding.

Its only known consumer, `Hedge.SetInstrumentActivity`, uses it to receive the list of instruments whose activity state should be updated in bulk. By accepting a TVP, the SP can process an arbitrary number of instruments in a single call rather than requiring the caller to invoke it once per instrument.

The nullable `InstrumentID` (unlike most single-column ID TVPs which are NOT NULL) suggests this type was designed permissively - perhaps to accommodate NULLs as a "wildcard all instruments" signal, or simply for convenience.

---

## 2. Business Logic

### 2.1 Instrument Set Passing

**What**: The TVP is a container for a caller-defined set of InstrumentIDs to be acted upon.

**Columns/Parameters Involved**: `InstrumentID`

**Rules**:
- No PK constraint - duplicate InstrumentIDs in the set are silently allowed (consumer must handle deduplication if needed).
- `InstrumentID` is nullable - a NULL row in the TVP may signal "apply to all instruments" depending on the consumer SP's logic.
- Consumer (`SetInstrumentActivity`) uses this to scope instrument activity changes to only the instruments in the batch.
- Implicit FK to Trade.Instrument.

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | YES | - | CODE-BACKED | Identifier of a trading instrument (stock, crypto, forex pair, etc.). Implicit FK to Trade.Instrument. NULL-allowed - the consumer SP (Hedge.SetInstrumentActivity) may treat NULL rows as a "process all" directive. No uniqueness constraint - duplicates allowed. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | Implicit | Values correspond to trading instrument IDs |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.SetInstrumentActivity | @Instruments parameter | TVP parameter | Receives the list of instruments whose activity state should be updated |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.SetInstrumentActivity | Stored Procedure | Receives a batch of instrument IDs to update their activity state |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| (none) | - | - | - | - | - |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and use to set instrument activity
```sql
DECLARE @Instruments [Hedge].[InstrumentTable]
INSERT INTO @Instruments (InstrumentID) VALUES (100), (200), (300)

EXEC [Hedge].[SetInstrumentActivity] @Instruments = @Instruments, @IsActive = 1
```

### 8.2 View current instrument activity in the hedge configuration
```sql
SELECT IC.InstrumentID, IC.IsActive, IC.HedgeServerID
FROM [Hedge].[InstrumentConfiguration] IC WITH (NOLOCK)
WHERE IC.IsActive = 1
ORDER BY IC.InstrumentID
```

### 8.3 Check inactive instruments
```sql
SELECT II.InstrumentID, II.DeactivationReason, II.DeactivatedAt
FROM [Hedge].[InactiveInstruments] II WITH (NOLOCK)
ORDER BY II.DeactivatedAt DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 7.8/10 (Elements: 10/10, Logic: 6/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.InstrumentTable | Type: User Defined Type | Source: etoro/etoro/Hedge/User Defined Types/Hedge.InstrumentTable.sql*
