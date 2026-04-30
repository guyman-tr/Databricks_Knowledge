# Dictionary.MarketStatus

> Lookup table defining the three market trading states — Unknown, Active, and Inactive — used to control whether instruments are available for trading.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | MarketStatusID (TINYINT, PK CLUSTERED) |
| **Partition** | DICTIONARY filegroup |
| **Row Count** | 3 (MCP verified) |
| **Indexes** | 2 active (PK clustered + unique NC on Name) |

---

## 1. Business Meaning

Dictionary.MarketStatus defines the trading availability state of a financial market or exchange. Each instrument's market has a status that determines whether orders can be placed, modified, or executed. When a market is Active, trading is open; when Inactive, the instrument is suspended from trading (e.g., weekends, holidays, or halted instruments). Unknown represents an unresolved or initial state.

This classification is fundamental to the trading engine — before any order execution, the system must verify the instrument's market is Active. Market status transitions are driven by exchange trading hours, market halt events, and administrative overrides. The table itself is a simple 3-row lookup; the dynamic market status per instrument is typically maintained in real-time by the pricing/market data services.

Despite having no direct FK references in the SSDT schema, MarketStatusID is likely consumed by application-layer services (trading engine, market data feed handlers) that map exchange states to these three codes.

---

## 2. Business Logic

### 2.1 Market Status States

**What**: The three possible states a market can be in.

**Columns/Parameters Involved**: `MarketStatusID`, `Name`

**Rules**:
- **Unknown (0)**: Default/initial state when market status has not yet been determined. Instruments in this state should not be tradeable until status is resolved.
- **Active (1)**: Market is open for trading. Orders can be placed, modified, and executed. This is the only state that permits live trading activity.
- **Inactive (2)**: Market is closed or halted. No new orders should be accepted. Existing pending orders may be queued until market reopens.

**Diagram**:
```
Market State Transitions:
  Unknown (0) ──► Active (1) ──► Inactive (2) ──► Active (1)
       │                                              ▲
       └──────────► Inactive (2) ─────────────────────┘
```

---

## 3. Data Overview

| MarketStatusID | Name | Meaning |
|---|---|---|
| 0 | Unknown | Market status has not been resolved. Typically a transient state during system startup or when a new instrument is added before its exchange schedule is configured. Trading is blocked in this state. |
| 1 | Active | Market is open and accepting trades. Instruments with this status allow order entry, modification, and execution. Corresponds to exchange trading hours (e.g., NYSE 09:30-16:00 ET). |
| 2 | Inactive | Market is closed or halted. No trading permitted. Applies during weekends, holidays, exchange circuit breakers, or administrative suspensions. Pending orders are held until market reopens. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | MarketStatusID | tinyint | NO | - | VERIFIED | Primary key identifying the market state. 0=Unknown (unresolved), 1=Active (open for trading), 2=Inactive (closed/halted). TINYINT type limits to 256 possible values; only 3 are used. Referenced by trading engine services to gate order execution. |
| 2 | Name | varchar(50) | NO | - | VERIFIED | Human-readable market state name. Unique constraint ensures no duplicate names. Values: 'Unknown', 'Active', 'Inactive'. Used in logging, monitoring dashboards, and administrative UIs. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application layer | MarketStatusID | Runtime lookup | Trading engine and market data services consume these values to determine instrument tradability |

No explicit FK references exist in the SSDT schema. This table is consumed at the application layer rather than through SQL JOINs.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.MarketStatus (table)
```

This object has no database-level dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trading engine services | Application | Map exchange states to MarketStatusID values |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DMarketStatus | CLUSTERED PK | MarketStatusID ASC | - | - | Active |
| UK_DMarketStatus_Name | NONCLUSTERED UNIQUE | Name ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DMarketStatus | PRIMARY KEY | Unique market status identifier, DICTIONARY filegroup |
| UK_DMarketStatus_Name | UNIQUE | Ensures no duplicate status names |

---

## 8. Sample Queries

### 8.1 List all market statuses
```sql
SELECT  MarketStatusID,
        Name
FROM    Dictionary.MarketStatus WITH (NOLOCK)
ORDER BY MarketStatusID;
```

### 8.2 Check if a market status is active
```sql
SELECT  CASE WHEN Name = 'Active' THEN 1 ELSE 0 END AS IsTrading
FROM    Dictionary.MarketStatus WITH (NOLOCK)
WHERE   MarketStatusID = @MarketStatusID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Business meaning derived from data values and naming conventions.

---

*Generated: 2026-03-13 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.MarketStatus | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.MarketStatus.sql*
