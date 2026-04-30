# Trade.InstrumentSpread

> Per-instrument, per-feed bid/ask spread configuration that defines how each tradeable instrument is quoted and how spread thresholds are monitored across price feeds.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | InstrumentID, FeedID (composite PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK) |

---

## 1. Business Meaning

Trade.InstrumentSpread stores the bid/ask spread configuration for each tradeable instrument, scoped by price feed. While Trade.Instrument defines what instruments exist (buy/sell currency pairs), this table defines HOW each instrument is quoted - the spread offset from the mid-price that eToro applies when displaying buy and sell prices to customers. Each row answers: "For this instrument on this feed, what are the Bid offset, Ask offset, spread type, and acceptable spread threshold?"

This table exists because the dealing desk configures different spread parameters per instrument and per feed. Primary feed (FeedID=1) and secondary feed (FeedID=2) can have different spread values for the same instrument, reflecting different liquidity or market conditions. Without it, the trading engine could not construct bid/ask prices or validate that live spreads stay within acceptable limits (MarketSpreadThreshold).

Data is created via Trade.InsertInstrumentRealTable when instruments are added to the platform. Trade.CheckValidInstruments reads it to validate instrument eligibility and can insert missing spread rows. Trade.GetOrderForOpenOvt, Trade.GetOrderForCloseOvt, and Trade.ManualPositionClose join to it to resolve spread context for orders and positions. System versioning tracks all row changes to History.InstrumentSpread. Audit triggers (ASM-generated) log INSERT, UPDATE, and DELETE to History.AuditHistory.

---

## 2. Business Logic

### 2.1 Per-Instrument, Per-Feed Spread Configuration

**What**: Each (InstrumentID, FeedID) pair has one spread configuration row. Multiple feeds can have different spread values for the same instrument.

**Columns/Parameters Involved**: `InstrumentID`, `FeedID`, `Bid`, `Ask`, `SpreadTypeID`

**Rules**:
- Primary feed (FeedID=1) is used by order execution and position close logic; secondary feed (FeedID=2) serves alternate pricing
- Bid is typically negative (subtract from mid-price), Ask is typically positive (add to mid-price) - together they define the spread width
- SpreadTypeID=1 (SpreadInPips): Bid/Ask are pip values; SpreadTypeID=2 (PrecentageSpread): Bid/Ask are percentage factors
- ReferenceBid and ReferenceAsk provide baseline rates for spread calculation; they default to 0

**Diagram**:
```
InstrumentID=1 (EUR/USD), FeedID=1: Bid=-2, Ask=2  -> 4 pip spread
InstrumentID=1 (EUR/USD), FeedID=2: Bid=-2, Ask=1  -> 3 pip spread (tighter on secondary)
InstrumentID=2 (USD/JPY), FeedID=1: Bid=-1, Ask=1, SpreadThresholdTypeID=2 (NOE)
```

### 2.2 Spread Threshold Monitoring

**What**: MarketSpreadThreshold defines the maximum acceptable spread before the system flags the instrument. The unit of measurement is determined by SpreadThresholdTypeID.

**Columns/Parameters Involved**: `MarketSpreadThreshold`, `SpreadThresholdTypeID`, `ReferenceBid`, `ReferenceAsk`

**Rules**:
- SpreadThresholdTypeID=1 (NOP): threshold in pips (Number of Pips) - standard for forex/CFD
- SpreadThresholdTypeID=2 (NOE): threshold in tick entries (Number of Entries) - used for price feed density monitoring
- When live spread exceeds MarketSpreadThreshold, monitoring/alerting can trigger
- ReferenceBid/ReferenceAsk provide fallback baseline when computing spread deviation

---

## 3. Data Overview

| InstrumentID | FeedID | SpreadTypeID | Bid | Ask | MarketSpreadThreshold | SpreadThresholdTypeID | Meaning |
|--------------|--------|--------------|-----|-----|----------------------|----------------------|---------|
| 1 | 1 | 1 | -2 | 2 | 2 | 1 | EUR/USD primary feed: 4 pip spread, 2 pip threshold (NOP) |
| 1 | 2 | 1 | -2 | 1 | 3 | 1 | EUR/USD secondary feed: 3 pip spread, 3 pip threshold |
| 2 | 1 | 1 | -1 | 1 | 1 | 2 | USD/JPY primary: 2 pip spread, threshold in tick entries (NOE) |
| 3 | 1 | 1 | -1 | 1 | 1 | 1 | GBP/USD primary: standard 2 pip spread and 1 pip threshold |
| 4 | 2 | 1 | -1 | 2 | 3 | 1 | Secondary feed with asymmetric spread (ask wider than bid). Used when primary feed unavailable or for feed comparison. |

**Selection criteria for the 5 rows:**
- Rows showing both FeedID=1 and FeedID=2 for same instrument
- Rows with SpreadThresholdTypeID=1 (NOP) and 2 (NOE) to show both measurement units
- Variety of Bid/Ask and MarketSpreadThreshold values

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | FK to Trade.Instrument. The tradeable instrument this spread config applies to. |
| 2 | SpreadTypeID | int | NO | - | VERIFIED | How spread values are expressed: 1=SpreadInPips (absolute pips), 2=PrecentageSpread (percentage of rate). (Dictionary.SpreadType) |
| 3 | Bid | decimal(10,4) | NO | - | CODE-BACKED | Bid-side spread offset. Typically negative (pips subtracted from mid-price). Interpreted per SpreadTypeID. |
| 4 | Ask | decimal(10,4) | NO | - | CODE-BACKED | Ask-side spread offset. Typically positive (pips added to mid-price). Interpreted per SpreadTypeID. |
| 5 | MarketSpreadThreshold | decimal(10,4) | NO | - | CODE-BACKED | Maximum acceptable spread before alerting. Unit determined by SpreadThresholdTypeID. |
| 6 | ReferenceBid | decimal(12,6) | NO | 0 | CODE-BACKED | Baseline bid rate for spread calculation. Default 0. |
| 7 | ReferenceAsk | decimal(12,6) | NO | 0 | CODE-BACKED | Baseline ask rate for spread calculation. Default 0. |
| 8 | SpreadThresholdTypeID | int | NO | 1 | VERIFIED | Threshold unit: 1=NOP (Number of Pips), 2=NOE (Number of Entries). (Dictionary.SpreadThresholdType) |
| 9 | FeedID | smallint | NO | 1 | CODE-BACKED | Price feed identifier. 1=primary feed (used by execution), 2=secondary feed. |
| 10 | DbLoginName | nvarchar(128) | YES | (computed) | CODE-BACKED | Computed: suser_name(). Database login that last modified the row. |
| 11 | AppLoginName | varchar(500) | YES | (computed) | CODE-BACKED | Computed: CONVERT(varchar(500), context_info()). Application context from session. |
| 12 | SysStartTime | datetime2(7) | NO | getutcdate() | CODE-BACKED | Temporal start. Set when row becomes current. System versioning. |
| 13 | SysEndTime | datetime2(7) | NO | 9999-12-31 | CODE-BACKED | Temporal end. 9999-12-31 for current rows. System versioning. |
| 14 | HostName | nvarchar(128) | YES | (computed) | CODE-BACKED | Computed: host_name(). Server host that last modified the row. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | FK | Each spread config belongs to one tradeable instrument |
| SpreadTypeID | Dictionary.SpreadType | FK | Spread measurement convention (pips vs percentage) |
| SpreadThresholdTypeID | Dictionary.SpreadThresholdType | FK | Threshold unit (NOP vs NOE) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.InsertInstrumentRealTable | INSERT target | Writer | Inserts spread config when instruments are added |
| Trade.CheckValidInstruments | SELECT, INSERT | Reader/Writer | Validates instrument exists in spread table; inserts if missing |
| Trade.GetOrderForOpenOvt | tis (JOIN) | Reader | Resolves spread for open order valuation |
| Trade.GetOrderForCloseOvt | tis (JOIN) | Reader | Resolves spread for close order valuation |
| Trade.ManualPositionClose | ins (FROM) | Reader | Reads spread for manual close pricing |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.InstrumentSpread (table)
```

This object has no code-level dependencies. Tables are leaf nodes. FK targets (Trade.Instrument, Dictionary.SpreadType, Dictionary.SpreadThresholdType) are structural only.

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Instrument | Table | FK InstrumentID |
| Dictionary.SpreadType | Table | FK SpreadTypeID |
| Dictionary.SpreadThresholdType | Table | FK SpreadThresholdTypeID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.InsertInstrumentRealTable | Procedure | INSERTs spread rows for new instruments |
| Trade.CheckValidInstruments | Procedure | SELECTs to validate instrument; INSERTs missing rows |
| Trade.GetOrderForOpenOvt | Procedure | LEFT JOIN for spread context |
| Trade.GetOrderForCloseOvt | Procedure | LEFT JOIN for spread context |
| Trade.ManualPositionClose | Procedure | FROM for spread values (FeedID=1) |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_TradeInstrumentSpread | CLUSTERED | InstrumentID, FeedID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_TradeInstrumentSpread | PRIMARY KEY | InstrumentID, FeedID - unique per instrument per feed |
| FK_InstrumentSpreadInstrumentID_TradeInstrumentID | FOREIGN KEY | InstrumentID -> Trade.Instrument.InstrumentID |
| FK_InstrumentSpreadTypeID_DictionarySpreadTypeID | FOREIGN KEY | SpreadTypeID -> Dictionary.SpreadType.SpreadTypeID |
| FK_InstrumentSpread_SpreadThresholdTypeID | FOREIGN KEY | SpreadThresholdTypeID -> Dictionary.SpreadThresholdType.SpreadThresholdTypeID |
| Default_InstrumentSpread_ReferenceBid | DEFAULT | ReferenceBid = 0 |
| Default_InstrumentSpread_ReferenceAsk | DEFAULT | ReferenceAsk = 0 |
| DF_InstrumentSpread_SpreadThresholdTypeID | DEFAULT | SpreadThresholdTypeID = 1 |
| (unnamed) | DEFAULT | FeedID = 1 |
| DF_InstrumentSpread_SysStart | DEFAULT | SysStartTime = getutcdate() |
| DF_InstrumentSpread_SysEnd | DEFAULT | SysEndTime = 9999-12-31 |
| PERIOD FOR SYSTEM_TIME | SYSTEM VERSIONING | SysStartTime, SysEndTime -> History.InstrumentSpread |

---

## 8. Sample Queries

### 8.1 Spread config for an instrument across feeds
```sql
SELECT  ISP.InstrumentID,
        ISP.FeedID,
        ISP.Bid,
        ISP.Ask,
        ISP.MarketSpreadThreshold,
        ST.Name AS SpreadType,
        STT.Name AS ThresholdType
FROM    Trade.InstrumentSpread ISP WITH (NOLOCK)
JOIN    Dictionary.SpreadType ST WITH (NOLOCK) ON ST.SpreadTypeID = ISP.SpreadTypeID
JOIN    Dictionary.SpreadThresholdType STT WITH (NOLOCK) ON STT.SpreadThresholdTypeID = ISP.SpreadThresholdTypeID
WHERE   ISP.InstrumentID = 1
ORDER BY ISP.FeedID;
```

### 8.2 Instruments with primary feed spread config
```sql
SELECT  I.InstrumentID,
        ISP.Bid,
        ISP.Ask,
        ISP.MarketSpreadThreshold
FROM    Trade.Instrument I WITH (NOLOCK)
JOIN    Trade.InstrumentSpread ISP WITH (NOLOCK)
    ON ISP.InstrumentID = I.InstrumentID AND ISP.FeedID = 1
WHERE   I.IsDeleted = 0
ORDER BY I.InstrumentID;
```

### 8.3 Spread config with instrument and lookup names
```sql
SELECT  I.InstrumentID,
        ISP.FeedID,
        ST.Name AS SpreadType,
        STT.Name AS ThresholdType,
        ISP.Bid,
        ISP.Ask,
        ISP.MarketSpreadThreshold
FROM    Trade.InstrumentSpread ISP WITH (NOLOCK)
JOIN    Trade.Instrument I WITH (NOLOCK) ON I.InstrumentID = ISP.InstrumentID
JOIN    Dictionary.SpreadType ST WITH (NOLOCK) ON ST.SpreadTypeID = ISP.SpreadTypeID
JOIN    Dictionary.SpreadThresholdType STT WITH (NOLOCK) ON STT.SpreadThresholdTypeID = ISP.SpreadThresholdTypeID
WHERE   ISP.InstrumentID IN (1, 2, 3)
ORDER BY ISP.InstrumentID, ISP.FeedID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 8.9/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,4,5,7,8*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 5 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InstrumentSpread | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.InstrumentSpread.sql*
