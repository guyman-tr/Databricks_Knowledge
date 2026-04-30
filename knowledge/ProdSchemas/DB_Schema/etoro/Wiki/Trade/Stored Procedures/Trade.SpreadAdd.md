# Trade.SpreadAdd

> Creates a new spread record for a provider-instrument pair, obtaining a system-generated SpreadID via Internal.GetSpreadID, and returns the new ID as an OUTPUT parameter.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @SpreadID (OUTPUT) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

A spread defines the bid/ask price differential for a specific instrument offered by a specific liquidity provider. This procedure is the creation entry point for `Trade.Spread` records - it allocates a new system ID (via the centralized `Internal.GetSpreadID` ID generator) and inserts the spread definition. The caller receives the new SpreadID back through the OUTPUT parameter.

The centralized ID allocation via `Internal.GetSpreadID` ensures SpreadIDs are unique across the system and avoids identity column conflicts. The transaction wrapping ensures atomicity between ID allocation and record insertion.

---

## 2. Business Logic

### 2.1 Centralized ID Allocation

**What**: SpreadID is not an IDENTITY column; it is allocated by calling `Internal.GetSpreadID`.

**Columns/Parameters Involved**: `@SpreadID OUTPUT`, `Internal.GetSpreadID`

**Rules**:
- EXECUTE @Answer = Internal.GetSpreadID @SpreadID OUTPUT
- If @Answer != 0 -> ROLLBACK and RETURN @Answer (ID allocation failed)
- The SpreadID allocated is passed both to the INSERT and returned to the caller via OUTPUT

### 2.2 Error Handling

**What**: Both the ID allocation and INSERT are checked for errors within the same transaction.

**Rules**:
- ID allocation failure (@Answer != 0): ROLLBACK, RETURN @Answer
- INSERT failure (@@ERROR != 0): ROLLBACK, RAISERROR(60000, 16, 1, 'Trade.SpreadAdd', @LocalError), RETURN 60000
- On success: COMMIT, RETURN 0

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SpreadID | INTEGER OUTPUT | NO | - | CODE-BACKED | OUTPUT: the newly assigned SpreadID allocated by Internal.GetSpreadID and inserted into Trade.Spread. |
| 2 | @ProviderID | INTEGER | NO | - | CODE-BACKED | Liquidity provider this spread belongs to. FK to Trade.Provider (or Trade.ProviderToInstrument). |
| 3 | @InstrumentID | INTEGER | NO | - | CODE-BACKED | Trading instrument this spread applies to. FK to Trade.ProviderToInstrument. |
| 4 | @Bid | INTEGER | NO | - | CODE-BACKED | Bid price component of the spread, stored as integer (pips or basis points). |
| 5 | @Ask | INTEGER | NO | - | CODE-BACKED | Ask price component of the spread, stored as integer (pips or basis points). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @SpreadID | Internal.GetSpreadID | Executor | Allocates the next available SpreadID; returns via OUTPUT param |
| SpreadID, ProviderID, InstrumentID, Bid, Ask | Trade.Spread | Writer | Inserts new spread record |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.SpreadAdd (procedure)
+-- Internal.GetSpreadID (procedure) [allocate new SpreadID]
+-- Trade.Spread (table) [insert new spread record]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Internal.GetSpreadID | Stored Procedure | Allocates next SpreadID, returns via OUTPUT parameter |
| Trade.Spread | Table | Target for INSERT of new spread definition |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No callers found in Trade SP folder | - | Called by admin/configuration tooling |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Error code 60000 | Convention | Standard error code for procedure-level failures in the Trade schema |
| SET NOCOUNT ON | Performance | Suppresses rowcount messages |

---

## 8. Sample Queries

### 8.1 Add a new spread

```sql
DECLARE @NewSpreadID INT;
EXEC Trade.SpreadAdd
    @SpreadID   = @NewSpreadID OUTPUT,
    @ProviderID = 1,
    @InstrumentID = 500,
    @Bid        = 5,
    @Ask        = 5;
SELECT @NewSpreadID AS NewSpreadID;
```

### 8.2 View all spreads for an instrument

```sql
SELECT SpreadID, ProviderID, InstrumentID, Bid, Ask
FROM Trade.Spread WITH (NOLOCK)
WHERE InstrumentID = 500
ORDER BY ProviderID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers found | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.SpreadAdd | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.SpreadAdd.sql*
