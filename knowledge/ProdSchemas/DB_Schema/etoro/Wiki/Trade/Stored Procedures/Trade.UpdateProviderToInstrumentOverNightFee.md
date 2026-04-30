# Trade.UpdateProviderToInstrumentOverNightFee

> Applies overnight (rollover) fee updates to Trade.ProviderToInstrument with built-in rate guards that reject changes exceeding safe thresholds based on day-of-week.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @instrumetFeeUpdtaeList (TVP input); modifies Trade.ProviderToInstrument.BuyOverNightFee / SellOverNightFee |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the gatekeeper for overnight fee (rollover fee) updates on instruments. It receives a set of proposed fee changes via a table-valued parameter and applies them to Trade.ProviderToInstrument only when the changes pass safety validation rules. The core business need is ensuring that overnight fees - which are charged daily to customers who hold leveraged positions - cannot spike or flip sign unexpectedly due to bad data in the fee source file.

Without this procedure, a corrupt or erroneous fee file could apply extreme overnight charges or sign-flipped fees (buy becoming negative, sell becoming positive) to thousands of open positions simultaneously, causing significant financial harm to customers. The threshold guards prevent runaway fees.

The procedure is called by operations/BI admin processes that ingest overnight fee data from external providers (likely a pricing feed or market data vendor). It is executed on a scheduled basis and returns a diagnostic result set identifying every fee that was NOT applied, allowing operators to investigate rejected updates. The commented-out select alias `GodIHateMyJobSometimes` embedded in the source code indicates this is an ops-owned procedure with legacy history.

---

## 2. Business Logic

### 2.1 Day-of-Week Rate Guard (BigChangeFlag)

**What**: Tuesday and Saturday are designated "big change" days that allow larger fee movements.

**Columns/Parameters Involved**: `@BigChangeFlag` (internal), `BuyOverNightFee`, `SellOverNightFee`

**Rules**:
- Tuesday or Saturday: `@BigChangeFlag = 1` - allows fee changes up to 400% in either direction
- All other days: `@BigChangeFlag = 0` - allows only up to 10% change from current value
- This reflects market convention where rollover rates from providers are more likely to have large legitimate swings on certain days (e.g., weekend rollover, mid-week rebalancing)

**Diagram**:
```
GETUTCDATE() day of week
        |
        +-- Tuesday or Saturday? --> @BigChangeFlag = 1 (allows up to 400% change)
        |
        +-- Any other day? -------> @BigChangeFlag = 0 (allows only +-10% change)
```

### 2.2 Fee Update Decision Matrix

**What**: A CASE expression in the UPDATE determines whether each proposed fee is accepted or rejected.

**Columns/Parameters Involved**: `BuyOverNightFee`, `SellOverNightFee`, `BuyCharge`, `SellCharge`

**Rules**:
- **Rule 1 - Zero current fee**: If existing fee is 0, always accept new value (no percentage comparison possible)
- **Rule 2 - Sign conflict**: If proposed and current fees have opposite signs (one positive, one negative), REJECT - keep current value (sign flip is always suspicious)
- **Rule 3 - Non-big-change day >10% delta**: If NOT Tuesday/Saturday and ratio of new/old is outside [0.9, 1.1], REJECT
- **Rule 4 - Big-change day >400% delta**: If IS Tuesday/Saturday and ratio of new/old is outside [0.25, 4.0], REJECT
- **Default**: Accept the new value from the input (or keep current if input is NULL)

**Diagram**:
```
For each InstrumentID in @instrumetFeeUpdtaeList:
  CASE
    WHEN current = 0           -> USE new value (ISNULL(new, 0))
    WHEN signs differ          -> KEEP current
    WHEN !big_day AND |delta| > 10% -> KEEP current
    WHEN big_day AND |delta| > 400% -> KEEP current
    ELSE                       -> USE new value (ISNULL(new, current))
  END
```

### 2.3 Rejection Diagnostic Output

**What**: The procedure returns a result set reporting every fee update that was rejected (where new != old despite input having a different value).

**Columns/Parameters Involved**: `#T.OldSell`, `#T.NewSell`, `#T.OldBuy`, `#T.NewBuy`, `IFL.SellCharge`, `IFL.BuyCharge`

**Rules**:
- UNION of rejected Sell fees and rejected Buy fees
- Output includes InstrumentID, the old value, the value that was NOT used, and which threshold applied (10% or 400%)
- Ordered alphabetically for readability
- This output is consumed by operators to review and manually override if the rejection was incorrect

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @instrumetFeeUpdtaeList | Trade.FeeUpdateList READONLY | NO | - | CODE-BACKED | Table-valued parameter (note: typo in parameter name - "instrume**t**" and "Updtae" are legacy misspellings preserved for backwards compatibility). Contains the proposed fee changes per InstrumentID with columns BuyCharge and SellCharge from the overnight fee data file. The TVP is READONLY, meaning the procedure cannot modify it. See Trade.FeeUpdateList for the type definition. |

**Internal variables and temp tables (not parameters but documented for completeness):**

| # | Element | Type | Description |
|---|---------|------|-------------|
| - | @BigChangeFlag | TINYINT | 1 = Tuesday or Saturday (big-change day, 400% threshold); 0 = all other days (10% threshold). Controls which CASE branch applies in the fee update. |
| - | #T | Temp Table | Captures OUTPUT of the UPDATE via OUTPUT clause. Columns: InstrumentID INT, NewBuy MONEY, OldBuy MONEY, NewSell MONEY, OldSell MONEY. Used to identify rejected updates by comparing old vs new values. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @instrumetFeeUpdtaeList | Trade.FeeUpdateList | User Defined Type (TVP) | Input TVP type defining the fee update structure (InstrumentID, BuyCharge, SellCharge per instrument) |
| UPDATE target | Trade.ProviderToInstrument | Modifier | Updates BuyOverNightFee and SellOverNightFee columns. Joined via InstrumentID. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PROD_BIadmins | EXECUTE permission | Permission grant | BI admin users have execute rights - procedure is called by BI/OPS overnight fee ingestion jobs |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.UpdateProviderToInstrumentOverNightFee (procedure)
├── Trade.FeeUpdateList (type - TVP input)
└── Trade.ProviderToInstrument (table - UPDATE target)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.FeeUpdateList | User Defined Type (TVP) | Input parameter type - carries the proposed fee data |
| Trade.ProviderToInstrument | Table | UPDATE target - BuyOverNightFee and SellOverNightFee columns updated based on safety thresholds |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| PROD_BIadmins role | Permission | Execute permission granted - called by BI admin overnight fee ingestion process |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Sign protection | Business logic | If BuyCharge and BuyOverNightFee have opposite signs, reject the update. Prevents a positive buy fee from becoming negative (which would mean paying customers to hold a long position - clearly erroneous) |
| 10% threshold (non-big-change day) | Business logic | Max allowed daily change outside Tuesday/Saturday: BuyCharge/BuyOverNightFee must be in [0.9, 1.1] |
| 400% threshold (big-change day) | Business logic | Max allowed change on Tuesday or Saturday: ratio must be in [0.25, 4.0] |

---

## 8. Sample Queries

### 8.1 Preview proposed overnight fee changes before applying

```sql
-- Preview what fees would be updated vs rejected for a given input
-- Useful to dry-run before calling the procedure
SELECT
    a.InstrumentID,
    b.BuyOverNightFee AS CurrentBuy,
    a.BuyCharge AS ProposedBuy,
    b.SellOverNightFee AS CurrentSell,
    a.SellCharge AS ProposedSell,
    CASE
        WHEN b.BuyOverNightFee = 0 THEN 'ACCEPT (zero baseline)'
        WHEN (a.BuyCharge < 0 AND b.BuyOverNightFee > 0) OR (a.BuyCharge > 0 AND b.BuyOverNightFee < 0)
            THEN 'REJECT (sign conflict)'
        WHEN ABS(a.BuyCharge / b.BuyOverNightFee - 1) > 0.1
            THEN 'CHECK (>10% delta - accepted only on Tue/Sat)'
        ELSE 'ACCEPT'
    END AS BuyDecision
FROM @FeeInput a
JOIN Trade.ProviderToInstrument b WITH (NOLOCK) ON b.InstrumentID = a.InstrumentID
```

### 8.2 Check current overnight fees for specific instruments

```sql
SELECT
    pti.InstrumentID,
    imd.Symbol,
    pti.BuyOverNightFee,
    pti.SellOverNightFee
FROM Trade.ProviderToInstrument pti WITH (NOLOCK)
JOIN Trade.InstrumentMetaData imd WITH (NOLOCK) ON pti.InstrumentID = imd.InstrumentID
WHERE pti.BuyOverNightFee <> 0 OR pti.SellOverNightFee <> 0
ORDER BY ABS(pti.BuyOverNightFee) DESC
```

### 8.3 Identify instruments with zero overnight fees (those that bypass the threshold check)

```sql
-- Zero-fee instruments always accept the new value regardless of magnitude
-- Useful to audit which instruments could receive any fee without the threshold guard
SELECT
    pti.InstrumentID,
    imd.Symbol,
    imd.InstrumentTypeID,
    pti.BuyOverNightFee,
    pti.SellOverNightFee
FROM Trade.ProviderToInstrument pti WITH (NOLOCK)
JOIN Trade.InstrumentMetaData imd WITH (NOLOCK) ON pti.InstrumentID = imd.InstrumentID
WHERE pti.BuyOverNightFee = 0 AND pti.SellOverNightFee = 0
ORDER BY imd.Symbol
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| "Payments in Non-USD - Overnight Fees, Dividends, Interest" (body inaccessible) | Confluence | Page title confirms overnight fees relate to multi-currency payment processing - body could not be retrieved |

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 5, 8, 10, 11*
*Sources: Atlassian: 0 Confluence (body inaccessible) + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.UpdateProviderToInstrumentOverNightFee | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.UpdateProviderToInstrumentOverNightFee.sql*
