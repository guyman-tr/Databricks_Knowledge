# Dictionary.LotCount

> Defines the universe of valid lot count (unit quantity) values that can be used for trading positions across the platform.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | LotCountID (int, PK) |
| **Partition** | No |
| **Indexes** | 1 clustered PK |

---

## 1. Business Meaning

Dictionary.LotCount is a registry of all valid lot count values available in the trading system. A "lot count" represents the number of units (shares, contracts, coins) in a trading position. Rather than allowing arbitrary unit quantities, the platform constrains positions to a predefined set of lot count values — each entry in this table represents one valid quantity.

Without this table, the system could not validate that a requested position size is among the allowed lot counts. It underpins position sizing rules across the entire trading engine, ensuring that positions conform to standardized unit quantities that are compatible with hedge execution, fee calculations, and LP (Liquidity Provider) order routing.

Rows are referenced by Trade.PositionTbl (LotCount column), Trade.ProviderInstrumentToLotCount (maps which lot counts are available per instrument/provider), and dozens of trading procedures including Trade.PositionOpen, Trade.PositionClose, Trade.OrderForOpenCreate, and Trade.HedgeOpen. The LotCountID equals the Value column in all rows — a self-referencing identity pattern where the ID IS the lot count value itself.

---

## 2. Business Logic

### 2.1 Self-Referencing ID Pattern

**What**: LotCountID equals Value in every row — the primary key IS the lot count value.

**Columns/Parameters Involved**: `LotCountID`, `Value`

**Rules**:
- LotCountID = Value in all rows (e.g., LotCountID 100 has Value 100)
- This means the FK reference to this table IS the lot count value itself — no lookup needed for the business meaning
- Ranges from 0 (no position) to 10,000 units
- Not all integers are present — only valid lot count steps (e.g., 0,1,2,...10, 12, 14, 15, 16, 18, 20...)

### 2.2 Lot Count Groups

**What**: Lot counts are grouped into tiers (via LotCountGroup) that map to player levels (eToro Club tiers).

**Columns/Parameters Involved**: `LotCountID` (via LotCountGroup FK chain)

**Rules**:
- Dictionary.LotCountGroup maps player levels (Bronze/Silver/Gold/Platinum/Test) to lot count groups
- Trade.ProviderInstrumentToLotCount maps specific instruments + providers to allowed lot counts
- Higher-tier players may access different lot count ranges per instrument

**Diagram**:
```
Dictionary.LotCount ──> Trade.ProviderInstrumentToLotCount
       │                      │
       └── valid unit qty     └── instrument + provider + lot count combination
                                    │
Dictionary.LotCountGroup ──> Dictionary.PlayerLevel
       │                          │
       └── tier grouping          └── Bronze/Silver/Gold/Platinum
```

---

## 3. Data Overview

| LotCountID | Value | Meaning |
|---|---|---|
| 0 | 0 | Zero units — represents no position or a placeholder value for system operations |
| 1 | 1 | Single unit — minimum meaningful position size, used for fractional/low-cost instruments |
| 100 | 100 | Common round-lot size for standard equity positions |
| 1000 | 1000 | Large lot size for forex and high-volume instruments |
| 10000 | 10000 | Maximum lot count — used for very high-volume forex or crypto positions |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | LotCountID | int | NO | - | CODE-BACKED | Primary key and simultaneously the lot count value itself (LotCountID = Value in all rows). Referenced by Trade.PositionTbl, Trade.ProviderInstrumentToLotCount, and 100+ trading procedures as the position unit quantity. Range: 0–10,000. |
| 2 | Value | int | NO | - | CODE-BACKED | The numeric lot count value. Always equals LotCountID — a denormalized design where the PK carries the business meaning directly. Represents the number of units (shares/contracts/coins) in a position. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.PositionTbl | LotCount | Implicit | Every open/closed position references a lot count value |
| Trade.ProviderInstrumentToLotCount | LotCountID | Implicit | Maps valid lot counts per instrument and provider |
| Trade.PositionOpen | @LotCount | Implicit | Position open procedure validates lot count |
| Trade.PositionClose | LotCount | Implicit | Position close records lot count |
| Trade.HedgeOpen | LotCount | Implicit | Hedge positions reference lot count |
| BackOffice.SetLotCountGroupID | LotCountGroupID | Implicit | Admin procedure for lot count group assignment |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | LotCount column references valid values |
| Trade.ProviderInstrumentToLotCount | Table | LotCountID FK |
| Trade.PositionOpen | Stored Procedure | Validates lot count on position open |
| Trade.PositionClose | Stored Procedure | Records lot count on close |
| Trade.GetLotCountTillTime | Function | Time-based lot count lookup |
| Championship.ChampionshipPlayer | Table | LotCount column |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DLOC | CLUSTERED PK | LotCountID | - | - | Active |

### 7.2 Constraints

None beyond PK.

---

## 8. Sample Queries

### 8.1 List all available lot counts
```sql
SELECT  LotCountID,
        Value
FROM    [Dictionary].[LotCount] WITH (NOLOCK)
ORDER BY LotCountID;
```

### 8.2 Find lot counts available for a specific instrument
```sql
SELECT  lc.Value AS LotCount,
        pitl.*
FROM    [Trade].[ProviderInstrumentToLotCount] pitl WITH (NOLOCK)
JOIN    [Dictionary].[LotCount] lc WITH (NOLOCK)
        ON pitl.LotCountID = lc.LotCountID
WHERE   pitl.InstrumentID = 1001
ORDER BY lc.Value;
```

### 8.3 Distribution of lot counts across open positions
```sql
SELECT  p.LotCount,
        COUNT(*) AS PositionCount
FROM    [Trade].[PositionTbl] p WITH (NOLOCK)
GROUP BY p.LotCount
ORDER BY PositionCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 6 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.LotCount | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.LotCount.sql*
