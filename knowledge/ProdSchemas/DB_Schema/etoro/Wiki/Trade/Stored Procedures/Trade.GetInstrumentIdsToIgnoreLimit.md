# Trade.GetInstrumentIdsToIgnoreLimit

> Returns per-instrument SL/TP limit override flags - controls which direction/leverage combinations bypass standard SL/TP limits.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | InstrumentID (result set) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure returns eight boolean flags per instrument that control whether standard Stop-Loss/Take-Profit limits can be bypassed for specific direction (long/short) and leverage (leveraged/non-leveraged) combinations. The naming "IgnoreLimit" is from the consumer's perspective - "Allow" means the consumer CAN set SL/TP for this combination.

The procedure exists to provide fine-grained SL/TP control to the trading engine. Some instruments may allow SL on leveraged longs but not on non-leveraged shorts, for example. This configuration supports regulatory and risk management requirements that vary by instrument and trading mode.

Data flow: no parameters. Returns all instruments from Trade.ProviderToInstrument with their 8 SL/TP allow flags.

---

## 2. Business Logic

### 2.1 SL/TP Permission Matrix

**What**: 8-flag matrix controlling SL/TP availability by direction and leverage.

**Columns/Parameters Involved**: All 8 Allow* columns

**Rules**:
- 4 flags for Stop Loss: Leveraged Long, Non-Leveraged Long, Leveraged Short, Non-Leveraged Short
- 4 flags for Take Profit: same combinations
- 1 = SL/TP is allowed for this combination
- 0 = SL/TP is NOT allowed (limit enforcement applies)

**Diagram**:
```
                    Stop Loss           Take Profit
                Long    Short       Long    Short
Leveraged       Flag1   Flag3       Flag5   Flag7
Non-Leveraged   Flag2   Flag4       Flag6   Flag8
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID (output) | INT | NO | - | CODE-BACKED | Financial instrument identifier. |
| 2 | AllowLeveragedLongSL (output) | BIT | - | - | CODE-BACKED | Allow Stop Loss on leveraged Buy/Long positions. |
| 3 | AllowNonLeveragedLongSL (output) | BIT | - | - | CODE-BACKED | Allow Stop Loss on non-leveraged (real stock) Buy/Long positions. |
| 4 | AllowLeveragedShortSL (output) | BIT | - | - | CODE-BACKED | Allow Stop Loss on leveraged Sell/Short positions. |
| 5 | AllowNonLeveragedShortSL (output) | BIT | - | - | CODE-BACKED | Allow Stop Loss on non-leveraged Sell/Short positions. |
| 6 | AllowLeveragedLongTP (output) | BIT | - | - | CODE-BACKED | Allow Take Profit on leveraged Buy/Long positions. |
| 7 | AllowNonLeveragedLongTP (output) | BIT | - | - | CODE-BACKED | Allow Take Profit on non-leveraged Buy/Long positions. |
| 8 | AllowLeveragedShortTP (output) | BIT | - | - | CODE-BACKED | Allow Take Profit on leveraged Sell/Short positions. |
| 9 | AllowNonLeveragedShortTP (output) | BIT | - | - | CODE-BACKED | Allow Take Profit on non-leveraged Sell/Short positions. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | Trade.ProviderToInstrument | FROM | Source of SL/TP allow flags |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetInstrumentIdsToIgnoreLimit (procedure)
+-- Trade.ProviderToInstrument (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ProviderToInstrument | Table | FROM - reads 8 SL/TP allow flags per instrument |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None. Note: no NOLOCK hint is used.

---

## 8. Sample Queries

### 8.1 Execute to get all flags

```sql
EXEC Trade.GetInstrumentIdsToIgnoreLimit;
```

### 8.2 Find instruments with restricted SL

```sql
SELECT  InstrumentID
FROM    Trade.ProviderToInstrument WITH (NOLOCK)
WHERE   AllowLeveragedLongSL = 0
OR      AllowNonLeveragedLongSL = 0;
```

### 8.3 Check specific instrument SL/TP matrix

```sql
SELECT  InstrumentID,
        AllowLeveragedLongSL, AllowNonLeveragedLongSL,
        AllowLeveragedShortSL, AllowNonLeveragedShortSL,
        AllowLeveragedLongTP, AllowNonLeveragedLongTP,
        AllowLeveragedShortTP, AllowNonLeveragedShortTP
FROM    Trade.ProviderToInstrument WITH (NOLOCK)
WHERE   InstrumentID = 1001;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 8.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetInstrumentIdsToIgnoreLimit | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetInstrumentIdsToIgnoreLimit.sql*
