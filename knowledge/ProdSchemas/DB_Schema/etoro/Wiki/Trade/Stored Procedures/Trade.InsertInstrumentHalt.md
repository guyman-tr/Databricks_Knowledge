# Trade.InsertInstrumentHalt

> Inserts instruments into Trade.InstrumentsExcludedFromHalt (idempotent - skips already-present instruments), exempting them from trading halt processing.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @instrumentsToInsert Trade.InstrumentIDsTbl (TVP) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.InsertInstrumentHalt is the **halt exemption registration SP**. It adds instruments to `Trade.InstrumentsExcludedFromHalt` - the whitelist of instruments that should not be subject to trading halt processing. Instruments on this list remain tradeable even when a broader halt signal is issued.

The name "InsertInstrumentHalt" is somewhat misleading - the SP does not insert a halt event; it inserts instruments into the *exclusion from halt* list. Called by rate and configuration services (MainRates, PSConfigurations) when instruments need to be designated as halt-exempt.

The insert is idempotent: instruments already present in the table are silently skipped via `WHERE NOT EXISTS`, preventing duplicate key violations.

---

## 2. Business Logic

### 2.1 Idempotent Insert (Deduplication)

**What**: Only inserts instruments not already present in Trade.InstrumentsExcludedFromHalt.

**Columns/Parameters Involved**: `@instrumentsToInsert`, `Trade.InstrumentsExcludedFromHalt.InstrumentID`

**Rules**:
- `WHERE NOT EXISTS (SELECT 1 FROM Trade.InstrumentsExcludedFromHalt AS Target WHERE Target.InstrumentID = Source.InstrumentID)`
- Instruments already on the exclusion list are silently skipped
- New instruments are inserted; no error on duplicates

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @instrumentsToInsert | Trade.InstrumentIDsTbl | NO | - | CODE-BACKED | TVP (READONLY) of instrument IDs to add to the halt exclusion list. Each row provides one InstrumentID. Already-present instruments are silently skipped. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (inserts into / reads) | Trade.InstrumentsExcludedFromHalt | WRITER + READER | Inserts new instruments; reads existing to deduplicate |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| MainRates service | EXEC Trade.InsertInstrumentHalt | Caller | Rate service registers halt-exempt instruments |
| PSConfigurations service | EXEC Trade.InsertInstrumentHalt | Caller | PS configurations service registers halt-exempt instruments |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.InsertInstrumentHalt (procedure)
|- Trade.InstrumentsExcludedFromHalt (table, read + write)
`-- Trade.InstrumentIDsTbl (UDT, TVP type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentsExcludedFromHalt | Table | Deduplication check + insert destination |
| Trade.InstrumentIDsTbl | User-Defined Table Type | TVP parameter type |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| MainRates | Application | Registers halt-exempt instruments |
| PSConfigurations | Application | Registers halt-exempt instruments |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| WHERE NOT EXISTS | Deduplication | Instruments already in table are silently skipped; idempotent |

---

## 8. Sample Queries

### 8.1 Add instruments to halt exclusion list

```sql
DECLARE @Instruments Trade.InstrumentIDsTbl
INSERT INTO @Instruments (InstrumentID) VALUES (1001), (1002)
EXEC Trade.InsertInstrumentHalt @instrumentsToInsert = @Instruments
```

### 8.2 Check current halt exclusion list

```sql
SELECT InstrumentID FROM Trade.InstrumentsExcludedFromHalt WITH (NOLOCK) ORDER BY InstrumentID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 8/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 permissions files analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InsertInstrumentHalt | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.InsertInstrumentHalt.sql*
