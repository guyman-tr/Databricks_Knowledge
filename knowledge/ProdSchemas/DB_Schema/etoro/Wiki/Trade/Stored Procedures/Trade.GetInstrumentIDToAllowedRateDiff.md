# Trade.GetInstrumentIDToAllowedRateDiff

> Returns the allowed rate difference percentage for every instrument - used for price deviation tolerance in order execution.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | InstrumentID (result set) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure returns the AllowedRateDiffPercentage for all instruments. This percentage controls how much the execution price can deviate from the requested price before an order is rejected. It is a key parameter for market range validation and slippage control.

The procedure exists to provide the trading engine with per-instrument rate tolerance thresholds. Different instruments have different acceptable deviations based on liquidity and volatility (e.g., major forex pairs have tight tolerances, crypto has wider).

Data flow: no parameters. Reads Trade.GetProviderToInstrument (a view) with NOLOCK. Returns InstrumentID and AllowedRateDiffPercentage for all instruments.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Simple full-table read. See individual element descriptions in Section 4.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID (output) | INT | NO | - | CODE-BACKED | Financial instrument identifier. |
| 2 | AllowedRateDiffPercentage (output) | DECIMAL | YES | - | CODE-BACKED | Maximum allowed percentage deviation between requested and execution price. Used for market range validation and slippage control. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | Trade.GetProviderToInstrument | FROM (view) | Source of rate diff configuration |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetInstrumentIDToAllowedRateDiff (procedure)
+-- Trade.GetProviderToInstrument (view)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetProviderToInstrument | View | FROM - reads InstrumentID and AllowedRateDiffPercentage |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Execute to get all rate diff thresholds

```sql
EXEC Trade.GetInstrumentIDToAllowedRateDiff;
```

### 8.2 Find instruments with wide tolerances

```sql
SELECT  InstrumentID, AllowedRateDiffPercentage
FROM    Trade.GetProviderToInstrument WITH (NOLOCK)
WHERE   AllowedRateDiffPercentage > 5.0
ORDER BY AllowedRateDiffPercentage DESC;
```

### 8.3 Check a specific instrument

```sql
SELECT  InstrumentID, AllowedRateDiffPercentage
FROM    Trade.GetProviderToInstrument WITH (NOLOCK)
WHERE   InstrumentID = 1001;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 7.0/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetInstrumentIDToAllowedRateDiff | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetInstrumentIDToAllowedRateDiff.sql*
