# Customer.PlayerLevelGetData

> Returns the full PlayerLevel configuration table used by the automatic player-level upgrade/downgrade engine: tier names, realized equity thresholds, and downgrade hysteresis percentages.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns resultset from Dictionary.PlayerLevel |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Customer.PlayerLevelGetData` exposes the PlayerLevel tier configuration to the automated player level upgrade process. The tiers (Bronze through Diamond plus Internal) define eToro's customer loyalty/value segmentation based on realized equity - the total realized profit/loss a customer has accumulated.

This procedure is the data source for the scheduling/automation job that determines which customers should be promoted or demoted between levels. The calling process reads all tier definitions, then compares each customer's realized equity (from `Customer.PlayerLevelGetRealizedEquityData`) against these ranges to determine the correct level.

The ThresholdPercentToCurrentLevel field implements downgrade hysteresis: a customer does not immediately drop a tier when their realized equity dips below the tier's minimum. They must drop below (RealizedEquityFrom - ThresholdPercent% of the range) to be demoted, preventing frequent tier oscillation.

---

## 2. Business Logic

### 2.1 PlayerLevel Tier Configuration

**What**: The tier system maps realized equity ranges to customer value levels, each with hysteresis to prevent oscillation.

**Columns/Parameters Involved**: `PlayerLevelID`, `RealizedEquityFrom`, `RealizedEquityTo`, `ThresholdPercentToCurrentLevel`, `Sort`

**Rules**:
- Tier assignment is based on RealizedEquityFrom/To range.
- PlayerLevelID 4 (Internal) has NULL equity bounds - reserved for internal/test accounts, excluded from automatic level changes.
- All standard tiers use ThresholdPercentToCurrentLevel = 20 (20% hysteresis buffer for downgrades).
- Sort column defines display order: 0=Internal, 1=Bronze, 2=Silver, 3=Gold, 4=Platinum, 5=Platinum Plus, 6=Diamond.

```
Tier ladder (by Sort):
  Internal (4):      NULL range      - Internal/test accounts
  Bronze   (1): -100000 to    5,000  - Entry level
  Silver   (5):   5,000 to   10,000  - Mid-tier I
  Gold     (3):  10,000 to   25,000  - Mid-tier II
  Platinum (2):  25,000 to   50,000  - High-value I
  Plat Plus(6):  50,000 to  250,000  - High-value II
  Diamond  (7): 250,000 to 100M      - Premium
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| (none) | - | - | - | - | - | No input parameters. No output parameters. Returns a single resultset. |

**Returned Columns:**

| # | Column | Source | Description |
|---|--------|--------|-------------|
| 1 | PlayerLevelID | Dictionary.PlayerLevel | Tier identifier: 1=Bronze, 2=Platinum, 3=Gold, 4=Internal, 5=Silver, 6=Platinum Plus, 7=Diamond |
| 2 | Name | Dictionary.PlayerLevel | Display name of the tier |
| 3 | Sort | Dictionary.PlayerLevel | Display/processing order (0=Internal first, then 1-6 ascending) |
| 4 | RealizedEquityFrom | Dictionary.PlayerLevel | Minimum realized equity (USD) for this tier. NULL for Internal. |
| 5 | RealizedEquityTo | Dictionary.PlayerLevel | Maximum realized equity (USD) for this tier. NULL for Internal. |
| 6 | ThresholdPercentToCurrentLevel | Dictionary.PlayerLevel | Hysteresis percentage (20 for all standard tiers) - customer must drop this % below the tier minimum before being downgraded |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (resultset) | Dictionary.PlayerLevel | SELECT source | Returns all rows from the tier configuration table |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.PlayerLevelGetData (procedure)
└── Dictionary.PlayerLevel (table) [SELECT - returns full tier config]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.PlayerLevel | Table | SELECT - returns PlayerLevelID, Name, Sort, RealizedEquityFrom, RealizedEquityTo, ThresholdPercentToCurrentLevel |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (automatic player level job) | External process | Reads tier config to determine upgrade/downgrade thresholds |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 View full tier configuration directly

```sql
SELECT
    PlayerLevelID,
    Name,
    Sort,
    RealizedEquityFrom,
    RealizedEquityTo,
    ThresholdPercentToCurrentLevel
FROM Dictionary.PlayerLevel WITH (NOLOCK)
ORDER BY Sort
```

### 8.2 Determine what tier a customer's realized equity maps to

```sql
DECLARE @RealizedEquity MONEY = 12500

SELECT
    PlayerLevelID,
    Name,
    RealizedEquityFrom,
    RealizedEquityTo
FROM Dictionary.PlayerLevel WITH (NOLOCK)
WHERE @RealizedEquity >= RealizedEquityFrom
  AND @RealizedEquity < RealizedEquityTo
  AND RealizedEquityFrom IS NOT NULL
```

### 8.3 View current tier distribution across customers

```sql
SELECT
    c.PlayerLevelID,
    pl.Name AS TierName,
    COUNT(*) AS CustomerCount
FROM Customer.Customer c WITH (NOLOCK)
JOIN Dictionary.PlayerLevel pl WITH (NOLOCK) ON pl.PlayerLevelID = c.PlayerLevelID
GROUP BY c.PlayerLevelID, pl.Name
ORDER BY pl.Sort
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 9.0/10, Logic: 8.0/10, Relationships: 7.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.PlayerLevelGetData | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.PlayerLevelGetData.sql*
