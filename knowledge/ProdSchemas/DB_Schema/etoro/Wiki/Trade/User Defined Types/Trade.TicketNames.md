# Trade.TicketNames

> A table-valued parameter type for passing batches of ticket names (instrument display names) to stored procedures, used for matching instruments by their human-readable labels.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | TicketName (varchar(50)) |
| **Partition** | N/A |
| **Indexes** | None (heap) |

---

## 1. Business Meaning

Trade.TicketNames is a table-valued parameter (TVP) type for passing sets of ticket names into stored procedures. A "ticket name" is the human-readable display label for a financial instrument (e.g., "Apple", "Bitcoin", "EUR/USD") - distinct from the ticker symbol (e.g., "AAPL", "BTCUSD"). This type enables lookups by display name rather than by internal ID or ticker symbol.

This type exists to support the instrument-to-ticker mapping flow, which resolves human-readable instrument names to their formal ticker symbols. The TicketName column is nullable and uses Latin1_General_BIN binary collation for exact matching.

Application services or ops tools populate this type with instrument display names and pass it to Trade.MatchInstrumentIDToTickerName, which resolves each name to its corresponding InstrumentID and ticker symbol.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a single-column utility type used for name-based instrument resolution.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | TicketName | varchar(50) | YES | - | CODE-BACKED | Instrument display name / ticket name (e.g., "Apple", "Bitcoin", "EUR/USD"). Uses Latin1_General_BIN binary collation for exact case-sensitive matching. Nullable - NULL entries would be ignored by the consuming JOIN. Maximum 50 characters. Note: "Ticket" is a legacy naming convention for instrument display names in the eToro platform. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. TicketName semantically maps to instrument display name columns but there is no declared FK on the type definition.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.MatchInstrumentIDToTickerName | @TicketNames | Parameter (TVP) | Resolves instrument display names to InstrumentIDs and ticker symbols |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.MatchInstrumentIDToTickerName | Stored Procedure | READONLY parameter for instrument name-to-ticker resolution |

---

## 7. Technical Details

### 7.1 Indexes

No indexes. The type is defined as a heap (no clustered index or primary key).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and populate for instrument resolution

```sql
DECLARE @Names Trade.TicketNames;
INSERT INTO @Names (TicketName) VALUES ('Apple'), ('Tesla'), ('Bitcoin');
EXEC Trade.MatchInstrumentIDToTickerName @TicketNames = @Names;
```

### 8.2 Populate from a list of known instrument display names

```sql
DECLARE @InstrNames Trade.TicketNames;
INSERT INTO @InstrNames (TicketName) VALUES ('EUR/USD'), ('GBP/USD'), ('Gold');
EXEC Trade.MatchInstrumentIDToTickerName @TicketNames = @InstrNames;
```

### 8.3 Show how binary collation affects matching

```sql
DECLARE @Names Trade.TicketNames;
INSERT INTO @Names (TicketName) VALUES ('apple'), ('Apple');
SELECT * FROM @Names;
-- Returns 2 rows: 'apple' and 'Apple' are distinct due to Latin1_General_BIN collation
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.TicketNames | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.TicketNames.sql*
