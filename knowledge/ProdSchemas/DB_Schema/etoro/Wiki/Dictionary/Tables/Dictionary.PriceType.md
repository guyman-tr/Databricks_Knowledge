# Dictionary.PriceType

> Lookup table defining 2 price data modes — RealTime (live streaming) and Snapshot (periodic polling) — controlling how instrument prices are delivered.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | PriceTypeID (INT, PK) |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

Dictionary.PriceType defines the two price delivery modes for instruments on the eToro platform. Instruments can receive prices either as a real-time streaming feed (continuous price updates pushed from the exchange/provider) or as periodic snapshots (prices fetched at intervals).

This table exists because different instruments require different pricing models based on their market, liquidity, and exchange capabilities. Highly liquid instruments like major forex pairs and top stocks use real-time streaming for tight spreads and fast execution. Less liquid or exotic instruments may use snapshot pricing, which is more cost-effective but provides less granular price data.

The PriceTypeID is used in instrument configuration to control the price feed mode for each instrument.

---

## 2. Business Logic

### 2.1 Price Delivery Mode

**What**: Two mutually exclusive price delivery modes control how instrument prices are received and processed.

**Columns/Parameters Involved**: `PriceTypeID`, `Name`

**Rules**:
- **RealTime (0)** — Continuous streaming price feed. Prices are pushed from the exchange/provider as they change. Provides the most current pricing but consumes more bandwidth and processing resources.
- **Snapshot (1)** — Periodic polling of prices at defined intervals. Prices are fetched on a schedule rather than streamed continuously. Lower resource consumption but prices may be slightly delayed between polls.

**Diagram**:
```
Price Delivery Modes
├── 0 = RealTime  → Continuous stream → Tick-by-tick updates → Low latency
└── 1 = Snapshot   → Periodic poll    → Interval updates    → Lower cost
```

---

## 3. Data Overview

| PriceTypeID | Name | Meaning |
|---|---|---|
| 0 | RealTime | Continuous streaming price feed — prices are pushed from the exchange as they change. Used for major forex pairs, top equities, and high-volume instruments where tight spreads and fast execution are critical. |
| 1 | Snapshot | Periodic price polling — prices are fetched at defined intervals. Used for less liquid instruments, exotic markets, or instruments where real-time streaming is not available or cost-effective. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PriceTypeID | int | NO | - | CODE-BACKED | Primary key identifying the price delivery mode. 0=RealTime (streaming), 1=Snapshot (periodic polling). Used in instrument price feed configuration. |
| 2 | Name | varchar(50) | NO | - | CODE-BACKED | Human-readable label for the price type. "RealTime" or "Snapshot". Used in instrument configuration and price source management. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

No direct FK consumers found in the SSDT codebase. Used in instrument price feed configuration at the application layer.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found in SSDT codebase.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary_PriceType | CLUSTERED PK | PriceTypeID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Dictionary_PriceType | PRIMARY KEY | Unique price type identifier |

---

## 8. Sample Queries

### 8.1 List all price types
```sql
SELECT  PriceTypeID,
        Name
FROM    [Dictionary].[PriceType] WITH (NOLOCK)
ORDER BY PriceTypeID;
```

### 8.2 Identify the real-time type ID
```sql
SELECT  PriceTypeID
FROM    [Dictionary].[PriceType] WITH (NOLOCK)
WHERE   Name = 'RealTime';
```

### 8.3 Display price types with descriptions
```sql
SELECT  PriceTypeID,
        Name,
        CASE PriceTypeID
            WHEN 0 THEN 'Continuous streaming — tick-by-tick price updates'
            WHEN 1 THEN 'Periodic polling — interval-based price fetching'
        END AS Description
FROM    [Dictionary].[PriceType] WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.PriceType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.PriceType.sql*
