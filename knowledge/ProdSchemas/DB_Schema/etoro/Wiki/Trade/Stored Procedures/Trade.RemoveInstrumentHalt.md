# Trade.RemoveInstrumentHalt

> Removes one or more instruments from the halt-exclusion registry (Trade.InstrumentsExcludedFromHalt), revoking their exemption from platform-wide trading halts.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @instrumentsToRemove (TVP of InstrumentIDs to remove) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.RemoveInstrumentHalt removes instruments from the halt-exclusion list, revoking their exemption from trading halts. When the platform initiates a market halt (e.g., during extreme volatility, regulatory action, or exchange closure), instruments in Trade.InstrumentsExcludedFromHalt remain tradeable. Calling this procedure means those instruments will now be subject to the halt like all others.

This procedure exists as the counterpart to Trade.InsertInstrumentHalt. Risk or operations teams use the pair to dynamically manage the halt-exclusion list: adding exemptions before a planned halt and removing them when the operational or regulatory need expires. The bulk TVP interface allows multiple instruments to be removed in a single call.

Data flow: Caller builds a Trade.InstrumentIDsTbl TVP with the instrument IDs to remove, then passes it as @instrumentsToRemove. The procedure DELETEs all matching rows from Trade.InstrumentsExcludedFromHalt via an INNER JOIN on InstrumentID. Trade.InstrumentsExcludedFromHalt is system-versioned - the deleted rows are end-dated in History.InstrumentsExcludedFromHalt automatically. Callers: MainRates and PSConfigurations system users have EXECUTE permission.

---

## 2. Business Logic

### 2.1 Bulk Delete via TVP Join

**What**: Accepts a batch of InstrumentIDs in a table-valued parameter and deletes all matching rows from the halt-exclusion table in a single DELETE statement.

**Columns/Parameters Involved**: `@instrumentsToRemove`

**Rules**:
- Uses INNER JOIN between Trade.InstrumentsExcludedFromHalt and @instrumentsToRemove on InstrumentID - only rows where InstrumentID exists in BOTH are deleted.
- If an InstrumentID in the TVP is not in InstrumentsExcludedFromHalt (already absent or never halted-excluded), it is silently ignored - no error.
- The procedure has no TRY/CATCH or explicit RETURN - the caller receives @@ERROR implicitly (0 on success).
- System versioning on Trade.InstrumentsExcludedFromHalt captures the deleted rows as history automatically.

**Diagram**:
```
@instrumentsToRemove (TVP: InstrumentID list)
        |
        v
DELETE Trade.InstrumentsExcludedFromHalt
  INNER JOIN @instrumentsToRemove ON InstrumentID
        |
        +-- System versioning: deleted rows captured in History.InstrumentsExcludedFromHalt
        +-- Instruments are now subject to halt operations
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @instrumentsToRemove | Trade.InstrumentIDsTbl (READONLY) | NO | - | CODE-BACKED | Table-valued parameter containing the InstrumentIDs to remove from the halt-exclusion list. Uses the Trade.InstrumentIDsTbl UDT (a TVP type with a single InstrumentID INT column). READONLY - cannot be modified inside the procedure. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @instrumentsToRemove | Trade.InstrumentIDsTbl | UDT (TVP type) | Parameter type definition for the batch of InstrumentIDs. |
| (procedure) | Trade.InstrumentsExcludedFromHalt | Deleter (DELETE) | Removes the matching InstrumentID rows, revoking their halt exemption. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by MainRates and PSConfigurations system users; no stored procedure callers found in SSDT repo.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.RemoveInstrumentHalt (procedure)
├── Trade.InstrumentsExcludedFromHalt (table)
└── Trade.InstrumentIDsTbl (UDT/TVP)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentsExcludedFromHalt | Table | DELETE - removes instruments from halt-exclusion list. |
| Trade.InstrumentIDsTbl | User Defined Type | TVP parameter type for passing batch of InstrumentIDs. |

### 6.2 Objects That Depend On This

No stored procedure dependents found. Called directly by MainRates and PSConfigurations system users/apps.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Remove a single instrument from halt exclusion

```sql
DECLARE @toRemove Trade.InstrumentIDsTbl;
INSERT INTO @toRemove (InstrumentID) VALUES (1);  -- EUR/USD

EXEC Trade.RemoveInstrumentHalt @instrumentsToRemove = @toRemove;
```

### 8.2 Remove multiple instruments in one call

```sql
DECLARE @toRemove Trade.InstrumentIDsTbl;
INSERT INTO @toRemove (InstrumentID) VALUES (1), (2), (5), (10);

EXEC Trade.RemoveInstrumentHalt @instrumentsToRemove = @toRemove;
```

### 8.3 Verify removal (instruments no longer in exclusion list)

```sql
SELECT InstrumentID
FROM Trade.InstrumentsExcludedFromHalt WITH (NOLOCK)
WHERE InstrumentID IN (1, 2, 5, 10);
-- Expected: empty result set after removal
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.RemoveInstrumentHalt | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.RemoveInstrumentHalt.sql*
