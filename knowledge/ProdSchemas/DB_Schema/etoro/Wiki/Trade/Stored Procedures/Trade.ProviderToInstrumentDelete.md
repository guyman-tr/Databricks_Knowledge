# Trade.ProviderToInstrumentDelete

> Removes a provider-instrument configuration row from Trade.ProviderToInstrument by provider and instrument, decommissioning trading of that instrument through the specified provider.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ProviderID + @InstrumentID (composite PK of the deleted row) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.ProviderToInstrumentDelete is the DELETE writer for Trade.ProviderToInstrument. It removes the configuration row for a given (ProviderID, InstrumentID) pair, effectively deregistering an instrument from a provider and disabling all trading of that instrument through that route.

This procedure exists to provide a controlled, single-point DELETE path for ProviderToInstrument rows. The table is system-versioned (History.TradeProviderToInstrument), so a DELETE has side effects - the system versioning captures the deleted row as a history entry automatically. Centralizing the DELETE here ensures clean removal.

Data flow: Called by ops/admin tools when an instrument is being removed from a provider (e.g., instrument delisted, provider route discontinued). After deletion, the instrument can no longer be opened through this provider. Open positions are unaffected by the row deletion itself - they carry their own config snapshot. The procedure returns @@ERROR (0 on success, SQL error number on failure).

---

## 2. Business Logic

### 2.1 Exact-Match PK Delete

**What**: Deletes exactly one row identified by the (ProviderID, InstrumentID) composite PK.

**Columns/Parameters Involved**: `@ProviderID`, `@InstrumentID`

**Rules**:
- If no row exists for the given PK, the DELETE is a no-op (0 rows affected), but @@ERROR is still 0.
- System versioning records the deleted row in History.TradeProviderToInstrument automatically.
- Open positions referencing this (ProviderID, InstrumentID) pair are not cascade-deleted; the procedure only removes the config row.
- RETURN @@ERROR: returns 0 on success, SQL error number on constraint violation or other failure.

**Diagram**:
```
Caller -> Trade.ProviderToInstrumentDelete(@ProviderID, @InstrumentID)
    |
    v
DELETE Trade.ProviderToInstrument WHERE ProviderID=@ProviderID AND InstrumentID=@InstrumentID
    |
    +-- System versioning: row end-dated in History.TradeProviderToInstrument
    +-- RETURN @@ERROR
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ProviderID | INTEGER | NO | - | CODE-BACKED | Identifies the execution provider whose instrument link is being removed. Part of the composite PK filter. FK to Trade.Provider. |
| 2 | @InstrumentID | INTEGER | NO | - | CODE-BACKED | Identifies the instrument being deregistered from the provider. Part of the composite PK filter. FK to Trade.Instrument. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ProviderID + @InstrumentID | Trade.ProviderToInstrument | Deleter (DELETE) | Removes the row with this composite key. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by ops/admin tools directly; no stored procedure callers discovered in the SSDT repo.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ProviderToInstrumentDelete (procedure)
└── Trade.ProviderToInstrument (table)
      ├── Trade.Provider (table)
      └── Trade.Instrument (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ProviderToInstrument | Table | DELETE - removes the specified provider-instrument config row. |

### 6.2 Objects That Depend On This

No dependents found in SSDT repo. Called directly by ops/admin application tools.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Delete a provider-instrument config

```sql
EXEC Trade.ProviderToInstrumentDelete
    @ProviderID = 1,
    @InstrumentID = 1234;
```

### 8.2 Verify deletion

```sql
SELECT COUNT(*) AS RowCount
FROM Trade.ProviderToInstrument WITH (NOLOCK)
WHERE ProviderID = 1 AND InstrumentID = 1234;
-- Expected: 0
```

### 8.3 Check history after deletion (system versioning)

```sql
SELECT ProviderID, InstrumentID, PresentationCode, Enabled, SysStartTime, SysEndTime
FROM History.TradeProviderToInstrument WITH (NOLOCK)
WHERE ProviderID = 1 AND InstrumentID = 1234
ORDER BY SysStartTime DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ProviderToInstrumentDelete | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.ProviderToInstrumentDelete.sql*
