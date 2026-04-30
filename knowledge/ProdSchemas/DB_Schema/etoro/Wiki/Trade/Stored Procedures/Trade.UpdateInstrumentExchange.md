# Trade.UpdateInstrumentExchange

> Updates both the ExchangeID (FK) and the denormalized Exchange (text) columns in Trade.InstrumentMetaData for a single instrument, resolving the exchange name from Dictionary.ExchangeInfo.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentID - identifies the instrument to update |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.UpdateInstrumentExchange reassigns an instrument to a different exchange. `Trade.InstrumentMetaData` stores the exchange assignment in two forms: `ExchangeID` (integer FK to `Dictionary.ExchangeInfo`) and `Exchange` (denormalized text copy of the exchange name). Both must be kept in sync - this procedure is the single write path that ensures they are updated together atomically.

The procedure first resolves the exchange name from `Dictionary.ExchangeInfo` using the supplied `@ExchangeID`, then sets both columns in a single UPDATE. This denormalization exists for read performance - queries that need the exchange name can read it directly from InstrumentMetaData without joining to ExchangeInfo.

Typical use case: an instrument is relisted on a different exchange (e.g., a company moves from NYSE to NASDAQ), requiring both the exchange FK and the display name to be updated.

---

## 2. Business Logic

### 2.1 Exchange Name Resolution (Denormalized Write)

**What**: Resolves the exchange description text from Dictionary.ExchangeInfo before updating, ensuring the denormalized Exchange column stays in sync with ExchangeID.

**Columns/Parameters Involved**: `@ExchangeID`, `Dictionary.ExchangeInfo.ExchangeDescription`, `Trade.InstrumentMetaData.ExchangeID`, `Trade.InstrumentMetaData.Exchange`

**Rules**:
- Step 1: `SELECT @ExchangeName = ExchangeDescription FROM Dictionary.ExchangeInfo WHERE ExchangeID=@ExchangeID`
- Step 2: `UPDATE Trade.InstrumentMetaData SET ExchangeID=@ExchangeID, Exchange=@ExchangeName WHERE InstrumentID=@InstrumentID`
- If @ExchangeID does not exist in Dictionary.ExchangeInfo: @ExchangeName remains NULL -> Exchange column set to NULL
- No error raised for unknown ExchangeID - caller must supply a valid ID
- Both FK and text are set atomically in the same UPDATE

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | INT | NO | - | CODE-BACKED | Instrument to update. Targets Trade.InstrumentMetaData.InstrumentID. |
| 2 | @ExchangeID | INT | NO | - | CODE-BACKED | Exchange to assign. Must exist in Dictionary.ExchangeInfo. Sets both ExchangeID and the denormalized Exchange text column. If not found in ExchangeInfo, Exchange is set to NULL. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT (name resolution) | Dictionary.ExchangeInfo | Read | Resolves ExchangeDescription text for the supplied ExchangeID |
| UPDATE target | Trade.InstrumentMetaData | Modifier | Sets ExchangeID and Exchange (denormalized name) for @InstrumentID |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase - no callers found in SSDT. Invoked by instrument configuration tooling.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.UpdateInstrumentExchange (procedure)
+-- Dictionary.ExchangeInfo (table)
+-- Trade.InstrumentMetaData (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.ExchangeInfo | Table | Resolves ExchangeDescription text for @ExchangeID |
| Trade.InstrumentMetaData | Table | UPDATE target for ExchangeID and Exchange columns |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (instrument configuration tooling) | - | Called when reassigning an instrument to a different exchange |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. No TRY/CATCH. No NOLOCK on ExchangeInfo lookup (reads current data). No existence check for @InstrumentID.

---

## 8. Sample Queries

### 8.1 Update exchange for an instrument
```sql
EXEC Trade.UpdateInstrumentExchange
    @InstrumentID = 1001,
    @ExchangeID   = 5;    -- e.g., NASDAQ
```

### 8.2 Verify current exchange assignment
```sql
SELECT im.InstrumentID, im.ExchangeID, im.Exchange,
       ei.ExchangeDescription
FROM   Trade.InstrumentMetaData im WITH (NOLOCK)
LEFT JOIN Dictionary.ExchangeInfo ei WITH (NOLOCK) ON ei.ExchangeID = im.ExchangeID
WHERE  im.InstrumentID = 1001;
```

### 8.3 Check for mismatches between ExchangeID and Exchange text
```sql
SELECT im.InstrumentID, im.ExchangeID, im.Exchange,
       ei.ExchangeDescription
FROM   Trade.InstrumentMetaData im WITH (NOLOCK)
LEFT JOIN Dictionary.ExchangeInfo ei WITH (NOLOCK) ON ei.ExchangeID = im.ExchangeID
WHERE  im.Exchange <> ei.ExchangeDescription
   OR  (im.Exchange IS NULL AND ei.ExchangeDescription IS NOT NULL);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: - | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers found | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.UpdateInstrumentExchange | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.UpdateInstrumentExchange.sql*
