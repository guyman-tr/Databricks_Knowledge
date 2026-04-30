# Trade.GetFirmAggregationHWM

> Returns High Water Mark (HWM) exposure data for Apex-linked customers, showing maximum exposure per customer for a given date.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | CID with HWM > 0 per date |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure returns High Water Mark exposure data for customers linked to Apex clearing. The HWM represents the maximum exposure recorded per customer for a given date. It is used for risk monitoring, margin calculations, and regulatory reporting.

The procedure exists to support exposure-based compliance and risk management. Without it, HWM exposure would need to be computed from raw allocation data.

Data is read from dbo.SyneToroAllocationDailyExposure. For each CID and date, the procedure takes MAX(Exposure), filters to HWM > 0, and joins Customer.CustomerStatic for ApexAccountID. Optional filters by @CID and @ApexAccountID narrow results.

---

## 2. Business Logic

### 2.1 HWM Calculation as Maximum Exposure

**What**: HWM is the maximum exposure value per CID for a given date.

**Columns/Parameters Involved**: `Exposure`, `CurrentTradeDay`, `CID`

**Rules**:
- Reads from dbo.SyneToroAllocationDailyExposure
- Groups by CID (and date when specified)
- MAX(Exposure) per group yields the High Water Mark
- Only rows with HWM > 0 are returned - zero exposure is excluded

### 2.2 Optional Filtering by CID or ApexAccountID

**What**: Results can be filtered by customer or Apex account.

**Columns/Parameters Involved**: `@CID`, `@ApexAccountID`

**Rules**:
- When both NULL: returns all Apex-linked customers with HWM > 0
- When @CID provided: filters to that customer
- When @ApexAccountID provided: filters via Customer.CustomerStatic join

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | YES | NULL | CODE-BACKED | Optional filter. When provided, returns HWM only for this customer. |
| 2 | @ApexAccountID | VARCHAR(50) | YES | NULL | CODE-BACKED | Optional filter. When provided, returns HWM only for this Apex account. |
| 3 | @CurrentTradeDay | DATE | YES | NULL | CODE-BACKED | Date for which to compute HWM. NULL typically uses current date. |
| 4 | CID | INT | NO | - | CODE-BACKED | Customer ID. Output column. |
| 5 | ApexAccountID | VARCHAR(50) | NO | - | CODE-BACKED | Apex clearing account ID from Customer.CustomerStatic. |
| 6 | HWM | DECIMAL/MONEY | NO | - | CODE-BACKED | High Water Mark - maximum exposure for this CID on the date. Only rows with HWM > 0 returned. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | dbo.SyneToroAllocationDailyExposure | FROM | Source of daily exposure data |
| (body) | Customer.CustomerStatic | JOIN | ApexAccountID lookup by CID |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetFirmAggregationHWM (procedure)
+-- dbo.SyneToroAllocationDailyExposure (table)
+-- Customer.CustomerStatic (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.SyneToroAllocationDailyExposure | Table | FROM - exposure data per CID per date |
| Customer.CustomerStatic | Table | JOIN - ApexAccountID for Apex-linked customers |

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

### 8.1 Execute for all Apex customers with HWM on today

```sql
EXEC Trade.GetFirmAggregationHWM
    @CID = NULL,
    @ApexAccountID = NULL,
    @CurrentTradeDay = NULL;
```

### 8.2 Get HWM for a specific customer

```sql
EXEC Trade.GetFirmAggregationHWM
    @CID = 12345,
    @ApexAccountID = NULL,
    @CurrentTradeDay = '2026-03-15';
```

### 8.3 Filter by Apex account

```sql
EXEC Trade.GetFirmAggregationHWM
    @CID = NULL,
    @ApexAccountID = 'APEX-ABC123',
    @CurrentTradeDay = '2026-03-15';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 7.8/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetFirmAggregationHWM | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetFirmAggregationHWM.sql*
