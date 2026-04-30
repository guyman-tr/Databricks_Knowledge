# Price.LiquidityProviderQuantities

> Configuration table that stores quantity thresholds per instrument per liquidity provider type, likely intended to define maximum tradeable quantities or lot sizes for each LP-instrument combination; currently empty and not referenced by any views or stored procedures.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Table |
| **Key Identifier** | (InstrumentID, LiquidityProviderTypeID) - composite CLUSTERED PK |
| **Partition** | No |
| **Indexes** | 1 (PK clustered composite) |

---

## 1. Business Meaning

LiquidityProviderQuantities maps a combination of instrument and liquidity provider type to a decimal quantity value. The table was designed to configure quantity-related thresholds (maximum order size, lot size, or quantity limit) for each instrument per liquidity provider category - for example, defining that Interactive Brokers (LiquidityProviderTypeID=11) can trade instrument X in quantities up to Y lots, while Goldman Sachs (LiquidityProviderTypeID=9) has a different limit for the same instrument.

The table is currently unused: 0 rows, no stored procedures, and no views reference it. The inclusion of system versioning (temporal table) and the ASM-generated audit trigger suggest it was provisioned as part of a broader pricing infrastructure build-out but has not been populated or integrated into active pricing logic. It may represent a planned feature for quantity-aware feed routing.

System versioning tracks all changes in History.LiquidityProviderQuantities.

---

## 2. Business Logic

### 2.1 Instrument-Provider Quantity Configuration

**What**: Each row defines the quantity value for one instrument-provider type combination.

**Columns/Parameters Involved**: `InstrumentID`, `LiquidityProviderTypeID`, `Quantity`

**Rules**:
- The composite PK (InstrumentID, LiquidityProviderTypeID) ensures one quantity value per instrument-provider combination
- Quantity is decimal(16,4) - supports both whole-unit and fractional quantities with 4 decimal places of precision
- No NOT NULL check constraint - Quantity=0 is technically valid (may indicate "not tradeable with this provider")
- Currently no procedures read or write this table - configuration would need to be done via direct DML or a new management procedure

---

## 3. Data Overview

The table is currently empty (0 rows). No quantity configurations are active.

*When populated, rows would appear as:*

| InstrumentID | LiquidityProviderTypeID | Quantity | Meaning |
|---|---|---|---|
| 1 (EUR/USD) | 11 (IB) | 1000000.0000 | Maximum 1M units of EUR/USD tradeable via IB in a single order |
| 1 (EUR/USD) | 9 (GoldmanSachs) | 500000.0000 | Goldman Sachs has a lower quantity limit for EUR/USD |
| 5 | 5 (XIGNITE) | 100.0000 | Xignite feed for instrument 5 limited to 100 units per order |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | LiquidityProviderTypeID | int | NOT NULL | - | VERIFIED | Part 1 of composite PK. References the category of liquidity provider (Trade.LiquidityProviderType): 0=eToro, 1=BMFN, 2=FXCM, 3=FD, 4=CNX, 5=XIGNITE, 6=MT_GOX, 7=GFT, 8=BitStamp, 9=GoldmanSachs, 10=BTC-e, 11=IB, 12=IG Execution, 13=Exante, 15=Kraken, 16=GDAX, 17=Poloniex, 18=IEX, 19=Bittrex, 20=Gemini. Note: PK is (InstrumentID ASC, LiquidityProviderTypeID ASC) so InstrumentID is the leading key. (Trade.LiquidityProviderType) |
| 2 | InstrumentID | int | NOT NULL | - | VERIFIED | Part 2 of composite PK (leading column in the PK index). References the trading instrument (Trade.Instrument) for which this quantity applies. (Trade.Instrument) |
| 3 | Quantity | decimal(16,4) | NOT NULL | - | NAME-INFERRED | The quantity threshold or limit for this instrument-provider combination. Exact semantics depend on how consuming code would use this value - could represent max order size, lot size, or available liquidity quantity per provider. No procedures currently read this column so the precise business interpretation remains unconfirmed. |
| 4 | DbLoginName | varchar (computed) | NOT NULL | suser_name() | CODE-BACKED | Computed: SQL Server login of last row modifier. Auto-set on DML. |
| 5 | AppLoginName | varchar(500) (computed) | YES | context_info() | CODE-BACKED | Computed: application identity from context_info(). |
| 6 | SysStartTime | datetime2(7) | NOT NULL | getutcdate() | CODE-BACKED | Temporal period start. Auto-managed by SQL Server system versioning. |
| 7 | SysEndTime | datetime2(7) | NOT NULL | '9999-12-31 23:59:59.9999999' | CODE-BACKED | Temporal period end. Historical row versions in History.LiquidityProviderQuantities. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | FK (FK_PriceLiquidityProviderQuantities_InstrumentID) | The instrument for which a quantity is configured |
| LiquidityProviderTypeID | Trade.LiquidityProviderType | FK (FK_PriceLiquidityProviderQuantities_LiquidityProviderTypeID) | The category of liquidity provider for which the quantity applies |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. No stored procedures or views currently reference this table.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.LiquidityProviderQuantities (table)
|- Trade.Instrument (table, FK target - leaf)
|- Trade.LiquidityProviderType (table, FK target - leaf)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Instrument | Table | FK target - InstrumentID must reference a valid instrument |
| Trade.LiquidityProviderType | Table | FK target - LiquidityProviderTypeID must reference a valid LP type |

### 6.2 Objects That Depend On This

No dependents found. The table is currently not referenced by any stored procedures or views.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_PriceLiqudityProviderQuantities | CLUSTERED PK | InstrumentID ASC, LiquidityProviderTypeID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_PriceLiqudityProviderQuantities | PRIMARY KEY | Composite PK - one quantity per (instrument, LP type) combination |
| FK_PriceLiquidityProviderQuantities_InstrumentID | FK | InstrumentID -> Trade.Instrument(InstrumentID) |
| FK_PriceLiquidityProviderQuantities_LiquidityProviderTypeID | FK | LiquidityProviderTypeID -> Trade.LiquidityProviderType(LiquidityProviderTypeID) |
| DF_LiquidityProviderQuantities_SysStart | DEFAULT | SysStartTime = getutcdate() |
| DF_LiquidityProviderQuantities_SysEnd | DEFAULT | SysEndTime = '9999-12-31 23:59:59.9999999' |
| SYSTEM_VERSIONING = ON | Temporal | Full history in History.LiquidityProviderQuantities |
| TRG_T_LiquidityProviderQuantities | TRIGGER (INSERT) | ASM no-op: self-update on InstrumentID after insert |

---

## 8. Sample Queries

### 8.1 View all configured quantities with names

```sql
SELECT
    LPQ.InstrumentID,
    LPQ.LiquidityProviderTypeID,
    LPT.Name AS ProviderTypeName,
    LPQ.Quantity,
    LPQ.SysStartTime AS ConfiguredSince
FROM Price.LiquidityProviderQuantities LPQ WITH (NOLOCK)
JOIN Trade.LiquidityProviderType LPT WITH (NOLOCK)
    ON LPT.LiquidityProviderTypeID = LPQ.LiquidityProviderTypeID
ORDER BY LPQ.InstrumentID, LPQ.LiquidityProviderTypeID;
```

### 8.2 Find all quantity configurations for a specific instrument

```sql
SELECT
    LPQ.LiquidityProviderTypeID,
    LPT.Name AS ProviderTypeName,
    LPQ.Quantity
FROM Price.LiquidityProviderQuantities LPQ WITH (NOLOCK)
JOIN Trade.LiquidityProviderType LPT WITH (NOLOCK)
    ON LPT.LiquidityProviderTypeID = LPQ.LiquidityProviderTypeID
WHERE LPQ.InstrumentID = 1  -- replace with specific InstrumentID
ORDER BY LPQ.Quantity DESC;
```

### 8.3 View change history for quantity configurations

```sql
SELECT
    InstrumentID,
    LiquidityProviderTypeID,
    Quantity,
    DbLoginName,
    SysStartTime,
    SysEndTime
FROM Price.LiquidityProviderQuantities
FOR SYSTEM_TIME ALL
ORDER BY InstrumentID, LiquidityProviderTypeID, SysStartTime;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.5/10 (Elements: 9/10, Logic: 5/10, Relationships: 6/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 1, 2, 4, 7, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.LiquidityProviderQuantities | Type: Table | Source: etoro/etoro/Price/Tables/Price.LiquidityProviderQuantities.sql*
