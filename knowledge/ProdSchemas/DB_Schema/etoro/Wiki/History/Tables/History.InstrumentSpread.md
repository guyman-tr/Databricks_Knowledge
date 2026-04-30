# History.InstrumentSpread

> Temporal history table capturing all changes to per-instrument spread configuration, preserving the complete audit trail of bid/ask spread offsets and market spread thresholds applied to each instrument on each price feed.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | Clustered index on (SysEndTime, SysStartTime) - temporal history access pattern |
| **Partition** | No |
| **Indexes** | 1 active (clustered on SysEndTime, SysStartTime, PAGE compressed) |

---

## 1. Business Meaning

History.InstrumentSpread is the SQL Server system-versioning history table for `Trade.InstrumentSpread`, which defines the bid and ask spread adjustments applied to each instrument's market price on each feed. These spread values directly determine what price customers see when trading: the raw market price from providers is offset by the Bid and Ask adjustments configured here before being shown to customers. A wider spread means higher trading cost for customers.

This history table enables investigation of pricing anomalies by answering "what spread was configured for instrument 797 on May 15 2024 when customer complaints were reported?" and "when did the spread on EUR/USD change and who changed it?" It is essential for best-execution audits, regulatory reviews, and financial reconciliation where the spread configuration at the time of a trade must be verified.

Data is written here automatically via SQL Server SYSTEM_VERSIONING (triggered by any DML on Trade.InstrumentSpread) AND additionally via ASM-managed audit triggers that log column-level changes to History.AuditHistory. This double-logging provides both temporal query capability and column-level change detail. The live table uses a composite PK (InstrumentID, FeedID), supporting different spread configurations per instrument per price feed.

---

## 2. Business Logic

### 2.1 Spread Adjustment Model

**What**: Bid and Ask values are offsets applied to the raw market price to produce the customer-facing price.

**Columns/Parameters Involved**: `Bid`, `Ask`, `SpreadTypeID`, `ReferenceBid`, `ReferenceAsk`

**Rules**:
- SpreadTypeID = 1 (SpreadInPips): Bid and Ask are pip offsets. Negative Bid widens the spread on the sell side. Live data shows Bid = -2 and Ask = 1-2 pips.
- SpreadTypeID = 2 (PrecentageSpread): Bid and Ask are percentage adjustments from the reference price. ReferenceBid and ReferenceAsk (default 0) provide the baseline for percentage calculations.
- Customer-facing price = Market price + adjustment: customer sell price = market bid + Bid offset; customer buy price = market ask + Ask offset.
- Example: Market Bid = 1.2000, Bid offset = -2 pips (= -0.0002) -> Customer sell = 1.1998.

**Diagram**:
```
Market Price (from provider)
    Market Bid -----> + Bid offset (-2 pips) -----> Customer Sell Price (1.1998)
    Market Ask -----> + Ask offset (+1 pip)  -----> Customer Buy Price  (1.2001)
                                  |
                        Spread = Ask - Bid = 3 pips
```

### 2.2 Market Spread Threshold

**What**: Guards against using a market price when the raw provider spread exceeds a configured threshold, indicating abnormal market conditions.

**Columns/Parameters Involved**: `MarketSpreadThreshold`, `SpreadThresholdTypeID`

**Rules**:
- SpreadThresholdTypeID = 1 (NOP = Number Of Pips): Threshold is in pips
- SpreadThresholdTypeID = 2 (NOE = Number Of Events): Threshold is in event count units
- If the raw market spread (ask - bid from provider) exceeds MarketSpreadThreshold, the pricing engine may reject or flag the price as abnormal
- Live data shows MarketSpreadThreshold = 3-6 pips for SpreadTypeID=1 instruments

### 2.3 Dual Audit Mechanism

**What**: Changes to Trade.InstrumentSpread are recorded both via temporal SYSTEM_VERSIONING and via ASM audit triggers.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`, `DbLoginName`, `AppLoginName`, `HostName`

**Rules**:
- SYSTEM_VERSIONING writes the full old row here on any UPDATE or DELETE
- ASM audit triggers (AuditDelete_, AuditInsert_, AuditUpdate_) write column-level old/new values to History.AuditHistory
- This table captures FULL row snapshots; History.AuditHistory captures individual column changes
- Both mechanisms record the same change independently

---

## 3. Data Overview

| InstrumentID | SpreadTypeID | Bid | Ask | MarketSpreadThreshold | SpreadThresholdTypeID | FeedID | Meaning |
|---|---|---|---|---|---|---|---|
| 797 | 1 (pips) | -2 | 1 | 3 | 1 (NOP) | 1 | Former spread config for instrument 797: 3-pip total spread (2 sell + 1 buy), 3-pip market threshold |
| 794 | 1 (pips) | -2 | 2 | 6 | 1 (NOP) | 1 | Former 4-pip spread for instrument 794 with 6-pip market threshold before latest change |
| 793 | 1 (pips) | -2 | 2 | 6 | 1 (NOP) | 1 | Former 4-pip spread for instrument 793, similar configuration to 794 |
| 792 | 1 (pips) | -2 | 2 | 6 | 1 (NOP) | 1 | Former spread for instrument 792 - a block of similar instruments changed together |
| 791 | 1 (pips) | -2 | 2 | 6 | 1 (NOP) | 1 | Former spread for instrument 791 in the same configuration block |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | The trading instrument this spread configuration applies to. Part of composite PK (InstrumentID, FeedID) in the live table. FK to Trade.Instrument(InstrumentID). |
| 2 | SpreadTypeID | int | NO | - | VERIFIED | Spread unit type: 1=SpreadInPips (spread values are pip offsets), 2=PrecentageSpread (spread values are percentages from reference price). FK to Dictionary.SpreadType. Live data shows SpreadTypeID=1 exclusively. |
| 3 | Bid | decimal(10,4) | NO | - | VERIFIED | Bid price offset applied to the raw market bid. Negative values widen the sell spread (customer gets a worse sell price than market). Example: -2 pips means the customer sell price is 2 pips below market bid. |
| 4 | Ask | decimal(10,4) | NO | - | VERIFIED | Ask price offset applied to the raw market ask. Positive values widen the buy spread (customer pays more than market ask). Example: +1 pip means the customer buy price is 1 pip above market ask. |
| 5 | MarketSpreadThreshold | decimal(10,4) | NO | - | CODE-BACKED | Maximum acceptable raw market spread (ask minus bid from provider). If the provider's spread exceeds this threshold, the price may be flagged or rejected as abnormal. Unit determined by SpreadThresholdTypeID. |
| 6 | ReferenceBid | decimal(12,6) | NO | 0 | CODE-BACKED | Reference bid price used as baseline for SpreadTypeID=2 (percentage-based) spread calculation. Defaults to 0. Not used when SpreadTypeID=1 (pips). |
| 7 | ReferenceAsk | decimal(12,6) | NO | 0 | CODE-BACKED | Reference ask price used as baseline for SpreadTypeID=2 (percentage-based) spread calculation. Defaults to 0. Not used when SpreadTypeID=1 (pips). |
| 8 | SpreadThresholdTypeID | int | NO | 1 | VERIFIED | Unit type for MarketSpreadThreshold: 1=NOP (Number Of Pips), 2=NOE (Number Of Events). FK to Dictionary.SpreadThresholdType. Defaults to 1. |
| 9 | FeedID | smallint | NO | 1 | CODE-BACKED | Price feed this spread configuration applies to. Part of composite PK. DEFAULT 1 = primary feed. Same instrument can have different spread configs per feed. |
| 10 | DbLoginName | nvarchar(128) | YES | - | CODE-BACKED | SQL Server login that made the change. Computed from suser_name() in live table; stored here statically. |
| 11 | AppLoginName | varchar(500) | YES | - | CODE-BACKED | Application-level user context at time of change. Computed from context_info() in live table; stored here statically. |
| 12 | SysStartTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this spread configuration became active in Trade.InstrumentSpread. |
| 13 | SysEndTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this spread configuration was superseded. |
| 14 | HostName | nvarchar(128) | YES | - | CODE-BACKED | Host machine name at time of change. Computed from host_name() in live table; stored here statically. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | Implicit (FK in live table) | The instrument whose spread history is recorded. |
| SpreadTypeID | Dictionary.SpreadType | Implicit (FK in live table) | Spread unit type: pips or percentage. |
| SpreadThresholdTypeID | Dictionary.SpreadThresholdType | Implicit (FK in live table) | Market spread threshold unit type: NOP or NOE. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.InstrumentSpread | SYSTEM_VERSIONING | Temporal Source | Live table that populates this history table. |
| History.AuditHistory | SchemaName='Trade', TableName='InstrumentSpread' | Trigger-based | ASM audit triggers also log column-level changes to AuditHistory in parallel. |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies. (Temporal history table - passive receiver of change data.)

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentSpread | Table | Live temporal table whose history is stored here |
| Price.SetSpread | Stored Procedure | Writer - updates spread configuration, generating history rows |
| Price.InsertPricingConfiguration | Stored Procedure | Writer - inserts pricing config including spread settings |
| Trade.GetOrderForOpenOvt | Stored Procedure | Reader - reads spread config for OVT order processing |
| Trade.GetOrderForCloseOvt | Stored Procedure | Reader - reads spread config for OVT order closing |
| Trade.GetInstrumentWithSpread | Stored Procedure | Reader - retrieves instrument with current spread data |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_InstrumentSpread | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

### 7.2 Constraints

None. (History tables do not have PK, FK, or CHECK constraints.)

---

## 8. Sample Queries

### 8.1 Find historical spread configuration for a specific instrument at a point in time
```sql
DECLARE @AsOf datetime2 = '2024-05-01 00:00:00'
SELECT
    InstrumentID,
    SpreadTypeID,
    Bid,
    Ask,
    MarketSpreadThreshold,
    SpreadThresholdTypeID,
    FeedID,
    SysStartTime,
    SysEndTime
FROM History.InstrumentSpread WITH (NOLOCK)
WHERE InstrumentID = 10
  AND SysStartTime <= @AsOf
  AND SysEndTime > @AsOf
ORDER BY FeedID
```

### 8.2 Find all spread changes for an instrument with change attribution
```sql
SELECT
    h.InstrumentID,
    h.FeedID,
    h.SpreadTypeID,
    h.Bid,
    h.Ask,
    h.MarketSpreadThreshold,
    h.SysStartTime AS ActiveFrom,
    h.SysEndTime AS ActiveTo,
    h.DbLoginName,
    h.AppLoginName,
    h.HostName
FROM History.InstrumentSpread h WITH (NOLOCK)
WHERE h.InstrumentID = 100
ORDER BY h.FeedID, h.SysStartTime
```

### 8.3 Find largest spread increases over the last year
```sql
SELECT
    InstrumentID,
    FeedID,
    Bid AS OldBid,
    Ask AS OldAsk,
    (Ask - Bid) AS OldSpreadWidth,
    SysEndTime AS ChangedAt,
    DbLoginName
FROM History.InstrumentSpread WITH (NOLOCK)
WHERE SysEndTime > DATEADD(year, -1, GETUTCDATE())
  AND (Ask - Bid) > 5  -- spread wider than 5 pips
ORDER BY (Ask - Bid) DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specifically for this object. The following page provides related context:

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Changing OMS price source - IG/BBG](https://etoro-jira.atlassian.net/wiki/spaces/TKB/pages/12853281028/Changing+OMS+price+source+-+IG+BBG) | Confluence | Operational procedure for changing price source configuration, relevant to spread setup workflow |

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.InstrumentSpread | Type: Table | Source: etoro/etoro/History/Tables/History.InstrumentSpread.sql*
