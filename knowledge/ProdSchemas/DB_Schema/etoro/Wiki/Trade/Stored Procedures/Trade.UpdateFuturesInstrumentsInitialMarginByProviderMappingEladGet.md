# Trade.UpdateFuturesInstrumentsInitialMarginByProviderMappingEladGet

> Despite the "Update" prefix, this is a read-only SELECT procedure: returns existing Trade.FuturesInstrumentsInitialMarginByProviderMapping rows for the (InstrumentID, ProviderID) pairs supplied in the TVP. A developer debug/inspection tool.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @i (TVP - Trade.Tv_FuturesInstrumentsInitialMarginByProviderMapping) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.UpdateFuturesInstrumentsInitialMarginByProviderMappingEladGet is a read-only lookup procedure that returns the current initial margin records from `Trade.FuturesInstrumentsInitialMarginByProviderMapping` for a specific set of (InstrumentID, ProviderID) pairs. Despite the "Update" prefix in its name, it performs only a SELECT - no data is modified.

The "Elad" infix and the "Get" suffix indicate this is a developer-authored debugging or inspection utility - likely created by a developer named Elad to verify the state of the margin table after running `Trade.UpdateFuturesInstrumentsInitialMarginByProviderMapping`. The naming convention mirrors the pattern of dev-authored "check what I just did" procedures found throughout the schema (similar to other "JUNK_" or developer-named SPs).

The procedure accepts the same TVP type as the write procedure, allowing a caller to pass the same batch they just wrote and immediately read back what is stored in the table for those pairs - a round-trip verification pattern.

---

## 2. Business Logic

### 2.1 TVP-Filtered Lookup

**What**: Returns all columns from Trade.FuturesInstrumentsInitialMarginByProviderMapping for the (InstrumentID, ProviderID) pairs present in the input TVP.

**Columns/Parameters Involved**: `@i.InstrumentID`, `@i.ProviderID`, `Trade.FuturesInstrumentsInitialMarginByProviderMapping.*`

**Rules**:
- `SELECT Fu.* FROM @i A INNER JOIN Trade.FuturesInstrumentsInitialMarginByProviderMapping Fu ON A.InstrumentID=Fu.InstrumentID AND A.ProviderID=Fu.ProviderID`
- Returns all columns (Fu.*) for matched rows: InstrumentID, ProviderID, InitialMargin, DbLoginName, AppLoginName, SysStartTime, SysEndTime
- If a pair in the TVP does not exist in the table, that row is silently omitted (INNER JOIN)
- No filtering by status or date - returns live temporal rows only (not History table)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @i | Trade.Tv_FuturesInstrumentsInitialMarginByProviderMapping READONLY | NO | - | CODE-BACKED | TVP containing the (InstrumentID, ProviderID) pairs to look up. The same type used by the write procedure Trade.UpdateFuturesInstrumentsInitialMarginByProviderMapping. The InitialMargin column in the TVP is ignored on input (only InstrumentID and ProviderID are used for the JOIN). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @i | Trade.Tv_FuturesInstrumentsInitialMarginByProviderMapping | TVP | Input parameter type (InstrumentID, ProviderID, InitialMargin) - only InstrumentID and ProviderID are used |
| SELECT source | Trade.FuturesInstrumentsInitialMarginByProviderMapping | Read | Returns all columns for matched (InstrumentID, ProviderID) pairs |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase - no callers found in SSDT. Developer debug utility; invoked manually.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.UpdateFuturesInstrumentsInitialMarginByProviderMappingEladGet (procedure)
+-- Trade.Tv_FuturesInstrumentsInitialMarginByProviderMapping (TVP type)
+-- Trade.FuturesInstrumentsInitialMarginByProviderMapping (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Tv_FuturesInstrumentsInitialMarginByProviderMapping | User Defined Type (TVP) | Input parameter type for specifying the (InstrumentID, ProviderID) pairs to look up |
| Trade.FuturesInstrumentsInitialMarginByProviderMapping | Table | SELECT source - returns all columns for matched pairs |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (developer tooling) | - | Manual inspection after running the write procedure |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. No SET NOCOUNT ON. No TRY/CATCH. Read-only; no data modifications.

---

## 8. Sample Queries

### 8.1 Look up margin values for a set of instrument-provider pairs
```sql
DECLARE @Pairs Trade.Tv_FuturesInstrumentsInitialMarginByProviderMapping;

INSERT INTO @Pairs (InstrumentID, ProviderID, InitialMargin)
VALUES
  (500, 3, 0),  -- InitialMargin ignored on input
  (501, 3, 0),
  (502, 3, 0);

EXEC Trade.UpdateFuturesInstrumentsInitialMarginByProviderMappingEladGet @i = @Pairs;
-- Returns: all current rows in FuturesInstrumentsInitialMarginByProviderMapping for these pairs
```

### 8.2 Direct table query equivalent
```sql
SELECT InstrumentID, ProviderID, InitialMargin, AppLoginName, SysStartTime
FROM   Trade.FuturesInstrumentsInitialMarginByProviderMapping WITH (NOLOCK)
WHERE  InstrumentID IN (500, 501, 502)
  AND  ProviderID = 3;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: - | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 6/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers found | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.UpdateFuturesInstrumentsInitialMarginByProviderMappingEladGet | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.UpdateFuturesInstrumentsInitialMarginByProviderMappingEladGet.sql*
