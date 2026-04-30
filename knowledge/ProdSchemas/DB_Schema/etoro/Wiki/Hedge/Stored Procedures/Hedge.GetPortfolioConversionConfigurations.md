# Hedge.GetPortfolioConversionConfigurations

> Returns portfolio conversion configuration rows that map synthetic (non-expiry) instruments to their corresponding futures hedging instruments, with optional filtering by source or target instrument ID.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @instrumentID + @instrumentIDToHedge - optional dual filter; NULL for either returns all |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.GetPortfolioConversionConfigurations` loads the mapping table that tells the hedge engine how to convert a customer's synthetic instrument position into a futures hedging position. eToro offers customers "non-expiry" versions of commodity and index futures (e.g., Crude Oil or S&P 500 contracts without a fixed expiry date). Internally, these must be hedged using real expiring futures contracts traded on exchanges. The `Hedge.PortfolioConversionConfigurations` table stores the mapping from synthetic instrument to the actual futures instrument used for hedging, along with a multiplier that accounts for contract sizing differences.

This procedure exists to allow the hedge engine to query this mapping either in bulk (both parameters NULL - returns all mappings) or filtered (looking up the hedge instrument for a specific synthetic instrument, or finding all synthetics that hedge into a given futures contract). The `Multiplier` column handles contract rolling: when rolling from one futures contract month to the next, `Multiplier=0` signals that the position should be closed (not converted), while `Multiplier=1` (or another value) signals an active conversion ratio.

The temporal columns `SysStartTime` and `SysEndTime` are included in the output, making the procedure temporal-aware - the caller can inspect when each mapping was active, useful for reconciliation or historical analysis.

Data flows as follows: the hedge engine (or a portfolio conversion process) calls this procedure to discover which futures instrument to use when hedging a specific synthetic. The result drives the conversion logic: expose customer positions in InstrumentID as hedge positions in InstrumentIDToHedge, scaled by Multiplier.

---

## 2. Business Logic

### 2.1 Optional Dual-Filter with ISNULL Pass-Through

**What**: Both parameters use the `ISNULL(@param, column)` pattern, making each filter optional independently. Passing NULL for both returns all rows; passing a value for either restricts the result set.

**Columns/Parameters Involved**: `@instrumentID`, `@instrumentIDToHedge`, `InstrumentID`, `InstrumentIDToHedge`

**Rules**:
- `WHERE InstrumentID = ISNULL(@instrumentID, InstrumentID)`: when @instrumentID is NULL, the condition is always true (InstrumentID = InstrumentID). When non-NULL, filters to that specific source instrument.
- `WHERE InstrumentIDToHedge = ISNULL(@instrumentIDToHedge, InstrumentIDToHedge)`: same pattern for the target hedge instrument.
- Both filters are ANDed - passing both parameters returns only the specific mapping between those two instruments.
- The ISNULL pattern is query-plan-unfriendly on large tables (parameter sniffing issue), but the configuration table is small (static mapping), so this is not a concern in practice.

**Diagram**:
```
Call scenarios:
  EXEC Hedge.GetPortfolioConversionConfigurations NULL, NULL
       -> Returns ALL mappings (full configuration load)

  EXEC Hedge.GetPortfolioConversionConfigurations @instrumentID=100, NULL
       -> Returns all futures instruments that hedge synthetic instrument 100

  EXEC Hedge.GetPortfolioConversionConfigurations NULL, @instrumentIDToHedge=200
       -> Returns all synthetics that are hedged via futures instrument 200

  EXEC Hedge.GetPortfolioConversionConfigurations @instrumentID=100, @instrumentIDToHedge=200
       -> Returns the specific mapping (100 -> 200) if it exists
```

### 2.2 Temporal Column Exposure

**What**: SysStartTime and SysEndTime are included in the output, exposing the system-versioning period boundaries for each row.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`

**Rules**:
- SysStartTime = UTC timestamp when this mapping row became active
- SysEndTime = '9999-12-31...' for current rows; earlier timestamp for rows moved to history
- Included to allow callers to detect when a mapping was last updated and to support reconciliation against historical configurations
- Current rows only are returned (not historical) - this reads from the base table, not the FOR SYSTEM_TIME history

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @instrumentID | int | YES | NULL | VERIFIED | Source (synthetic) instrument filter. NULL = return all source instruments. Non-NULL = return only mappings where InstrumentID equals this value. Used by the hedge engine to look up which futures instrument hedges a specific synthetic. |
| 2 | @instrumentIDToHedge | int | YES | NULL | VERIFIED | Target (futures) instrument filter. NULL = return all target instruments. Non-NULL = return only mappings where InstrumentIDToHedge equals this value. Used to find all synthetic instruments routed through a specific futures contract. |

**Output columns** (from Hedge.PortfolioConversionConfigurations):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 3 | InstrumentID | int | NO | - | VERIFIED | The synthetic (non-expiry) instrument on the eToro customer side. This is what customers see and trade. FK to Trade.Instrument. |
| 4 | InstrumentIDToHedge | int | NO | - | VERIFIED | The actual futures instrument used to hedge the synthetic position. This is what eToro trades with the LP. FK to Trade.Instrument. Changes on contract roll (new futures expiry = new InstrumentIDToHedge). |
| 5 | Multiplier | decimal | YES | - | VERIFIED | Contract sizing ratio between synthetic and futures. Multiplier=0 signals contract roll closure (position is closed, not converted). Multiplier=1 indicates a 1:1 size relationship. Other values account for lot size differences between the synthetic and futures contract. |
| 6 | SysStartTime | datetime2(7) | NO | - | VERIFIED | UTC timestamp when this mapping row became the current version. Indicates when this synthetic-to-futures assignment was last established. |
| 7 | SysEndTime | datetime2(7) | NO | - | VERIFIED | UTC timestamp when this row version expires. '9999-12-31...' for active rows. Earlier timestamp for rows that have since been superseded by a contract roll. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (reads) | Hedge.PortfolioConversionConfigurations | SELECT | Source of all synthetic-to-futures hedge mappings. Filtered optionally by source or target instrument. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge server application | - | Caller | Called to load portfolio conversion mappings for synthetic instrument hedge routing. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.GetPortfolioConversionConfigurations (procedure)
└── Hedge.PortfolioConversionConfigurations (table)
      ├── Trade.Instrument (table) [FK target for InstrumentID]
      └── Trade.Instrument (table) [FK target for InstrumentIDToHedge]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.PortfolioConversionConfigurations | Table | SELECTed with NOLOCK - source of all synthetic-to-futures instrument mappings |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge server application | External | READER - loads conversion mappings to route synthetic instrument hedges to correct futures contracts |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure. The table uses WITH (NOLOCK) hint. The ISNULL pattern in the WHERE clause prevents index seeks when parameters are NULL (full scan). With a small configuration table, this is not a concern.

### 7.2 Constraints

N/A for Stored Procedure. The table is system-versioned (temporal). This procedure reads only current rows. Historical mappings (previous futures contract months) are in the associated history table. The SysStartTime/SysEndTime columns returned allow callers to track configuration change history without querying the history table directly.

---

## 8. Sample Queries

### 8.1 Load all portfolio conversion configurations
```sql
EXEC [Hedge].[GetPortfolioConversionConfigurations] NULL, NULL;
```

### 8.2 Find the futures instrument used to hedge a specific synthetic
```sql
EXEC [Hedge].[GetPortfolioConversionConfigurations]
    @instrumentID = 100,
    @instrumentIDToHedge = NULL;
```

### 8.3 Find all synthetics routed through a specific futures contract
```sql
EXEC [Hedge].[GetPortfolioConversionConfigurations]
    @instrumentID = NULL,
    @instrumentIDToHedge = 200;
```

### 8.4 Direct table query with temporal context
```sql
SELECT  InstrumentID,
        InstrumentIDToHedge,
        Multiplier,
        SysStartTime,
        SysEndTime
FROM    [Hedge].[PortfolioConversionConfigurations] WITH (NOLOCK)
ORDER BY InstrumentID, SysStartTime DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.GetPortfolioConversionConfigurations | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.GetPortfolioConversionConfigurations.sql*
