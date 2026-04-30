# Trade.GetExcludeHaltInstruments

> Returns a paginated list of instruments excluded from trading halt rules plus the total record count, for UI or API consumption.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | InstrumentID list (paginated), TotalRecords count |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure returns the set of instruments that are explicitly excluded from halt rules. When market halts or trading suspensions occur, some instruments may be exempted by configuration; this procedure exposes that whitelist for administration, reporting, or client display. Without it, callers would query Trade.InstrumentsExcludedFromHalt directly and implement pagination themselves. It exists to support paginated API or admin UIs that list which instruments bypass halt restrictions. Data flows through when an admin views the halt exclusion list, when a client fetches "excluded instruments" for display, or when a background process validates halt logic against the whitelist.

---

## 2. Business Logic

### 2.1 Pagination and Defaults

**What**: Input validation and OFFSET/FETCH pagination for the excluded instruments list.

**Columns/Parameters Involved**: `@pageNumber`, `@pageSize`, `@Offset`

**Rules**:
- If @pageNumber is less than 1, it is set to 1.
- If @pageSize is less than 1, it is set to 10.
- Offset is calculated as (@pageNumber - 1) * @pageSize.
- First result set returns InstrumentID ordered by InstrumentID with OFFSET/FETCH.
- Second result set returns a single row with TotalRecords (COUNT of all rows in the table).

**Diagram**:
```
@pageNumber, @pageSize --> validation --> @Offset
@Offset, @pageSize --> OFFSET @Offset ROWS FETCH NEXT @pageSize ROWS ONLY
Trade.InstrumentsExcludedFromHalt --> Result Set 1 (paginated InstrumentIDs)
Trade.InstrumentsExcludedFromHalt --> Result Set 2 (TotalRecords)
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @pageNumber | INT | - | - | CODE-BACKED | Page index (1-based). Clamped to 1 if less than 1. Controls which slice of the excluded instruments list to return. |
| 2 | @pageSize | INT | - | - | CODE-BACKED | Number of rows per page. Clamped to 10 if less than 1. Controls page size. |
| 3 | InstrumentID | INT | - | - | CODE-BACKED | Primary output in first result set. Identifier of an instrument excluded from halt rules. Ordered by InstrumentID. |
| 4 | TotalRecords | INT | - | - | CODE-BACKED | Primary output in second result set. Total count of instruments excluded from halt. Used for pagination UI. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.InstrumentsExcludedFromHalt | Table | Reads InstrumentID from this table. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Not analyzed in this phase | - | - | - |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetExcludeHaltInstruments (procedure)
└── Trade.InstrumentsExcludedFromHalt (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentsExcludedFromHalt | Table | SELECT InstrumentID, COUNT(*). Source of excluded instruments and total count. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Not analyzed in this phase | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get first page of excluded instruments (default page size)

```sql
EXEC Trade.GetExcludeHaltInstruments
    @pageNumber = 1,
    @pageSize = 10;
```

### 8.2 Get second page with custom page size

```sql
EXEC Trade.GetExcludeHaltInstruments
    @pageNumber = 2,
    @pageSize = 25;
```

### 8.3 Join paginated InstrumentIDs to instrument details for display

```sql
CREATE TABLE #Ids (InstrumentID INT);
INSERT INTO #Ids EXEC Trade.GetExcludeHaltInstruments @pageNumber = 1, @pageSize = 50;

SELECT i.InstrumentID, i.Symbol, i.Name
FROM #Ids t
JOIN Dictionary.Instrument i WITH (NOLOCK) ON i.InstrumentID = t.InstrumentID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 7.0/10 (Elements: 7/10, Logic: 7/10, Relationships: 8/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetExcludeHaltInstruments | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetExcludeHaltInstruments.sql*
