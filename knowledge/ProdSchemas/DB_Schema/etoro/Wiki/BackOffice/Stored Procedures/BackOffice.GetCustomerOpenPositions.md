# BackOffice.GetCustomerOpenPositions

> Returns all currently open positions for a customer from Trade.PositionForExternalUseWithPnL, with live P&L, instrument details, SL/TP rates, copy/mirror linkage, and position type flags.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID - single customer lookup |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure populates the Open Positions tab in the BackOffice customer profile. It returns every currently open trade for a customer: what instrument they are in, which direction (buy/sell), the current size and unrealized P&L, the entry rate and current stop/limit rates, whether it is part of a copy mirror, and various type flags (CFD vs Real, discounted rate, recurring, over-weekend).

`Trade.PositionForExternalUseWithPnL` is a view that enriches the base position table with live (or recently calculated) unrealized PnL (`PnLInDollars`), making this procedure suitable for real-time display without a separate PnL call.

The procedure has been updated multiple times:
- 25/04/2016 (case 36204): original update
- 05/01/2016 (case 42916): `UseAmountInUnitsDecimalInsteadOfLots` - added `AmountInUnitsDecimal` column ([Units])
- 08/03/2017 (case 44218): further update
- 07/01/2019 (RD-1942): added `[Is Real]` column (CFD vs settled/real stock)
- 13/09/2020 (MIMOPS-2247): changed `[Is Discounted]` calculation (same ticket as GetCurrentRates - discounted close rate feature)
- 05/01/2021 (Ran Ovadia): eliminated partition filters on PositionID in the OrdersExit JOIN

**`[HBC]` column**: `CAST(TGEP.IsSettled AS Decimal(16,6))` - numerically the same data as `[Is Real]` (IsSettled=0 for CFD, 1 for Real). The alias "HBC" and trailing comment `--,` suggest this was a temporary or test column that was never cleaned up. The comma comment indicates additional columns were once planned after this line.

**`[SpreadGroup]` = '0'**: hardcoded legacy field; the actual spread group assignment has moved to other mechanisms.

**`[OpenMinusCloseRateMultiplier]`**: -1 for Buy positions, +1 for Sell positions. Used in PnL calculation: `(CloseRate - OpenRate) * Multiplier * Units` gives the position profit direction. Buy profits when CloseRate > OpenRate (negative multiplier makes this additive), Sell profits when CloseRate < OpenRate.

**Close Requested detection**: LEFT JOIN to `Trade.OrdersExit` on PositionID with partition columns. If a matching exit order exists, `[Close Requested]` = 'Yes', alerting the agent that a close request is pending processing.

---

## 2. Business Logic

### 2.1 CFD vs Real (IsSettled)

**What**: Distinguishes between leveraged CFD positions and settled real-stock ownership.

**Rules**:
- `IsSettled = 0` -> 'CFD' (leveraged derivative)
- `IsSettled = 1` -> 'Real' (underlying stock ownership / settled position)
- `ELSE` -> '' (unknown/legacy)
- Also exposed as `[HBC]` = `CAST(IsSettled AS Decimal(16,6))` (numeric form, legacy artifact)

### 2.2 Over Weekend (Inverted Logic)

**What**: `CloseOnEndOfWeek` = 0 means the position stays open over the weekend.

**Rules**:
- `CASE TGEP.CloseOnEndOfWeek WHEN 0 THEN 'Yes' ELSE '' END`
- Inverted flag: 0 = keep open (display 'Yes' for Over Weekend), 1 = close at week end

### 2.3 Is Open Open

**What**: Indicates whether the position's open order is in an "open-open" state (pending processing).

**Rules**:
- `NULL` or `0` -> 'No'
- Any other value -> 'Yes'
- Edge case: uses `CASE WHEN IsOpenOpen IS NULL THEN 'No' WHEN IsOpenOpen=0 THEN 'No' ELSE 'Yes' END`

### 2.4 Recurring Detection

**What**: Identifies positions opened via recurring deposit automation.

**Rules**:
- `OpenActionType = 17` -> 'Yes' (position was opened as part of a recurring investment order)
- All other values -> 'No'
- Added via MIMOPSA-14289 (comment marker in DDL)

### 2.5 OrdersExit Partition JOIN

**What**: Efficient close-request detection using partition columns.

**Rules**:
- `TOE.PartitionCol = @CID % 50` - CID-based partition for OrdersExit
- `TGEP.PartitionCol = TOE.PositionID % 50` - PositionID-based partition for the position
- This two-column partition avoids full table scans on large OrdersExit tables

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| **Input Parameters** | | | | | | |
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. Matched against Trade.PositionForExternalUseWithPnL.CID. |
| **Output Columns** | | | | | | |
| 2 | PositionID | BIGINT | NO | - | CODE-BACKED | Unique position identifier. |
| 3 | [Instrument] | NVARCHAR | YES | - | CODE-BACKED | Instrument display name. From Trade.InstrumentMetaData.InstrumentDisplayName. NULL if no InstrumentMetaData entry. |
| 4 | [Instrument ID] | INT | NO | - | CODE-BACKED | Numeric instrument identifier. From Trade.InstrumentMetaData.InstrumentID. |
| 5 | [Initial Amount] | DECIMAL(16,2) | YES | - | CODE-BACKED | Original investment amount in dollars at position open. TGEP.InitialAmountCents / 100. |
| 6 | [Amount] | DECIMAL(16,2) | YES | - | CODE-BACKED | Current position amount in dollars (may change if copy mirror amount is adjusted). From TGEP.Amount. |
| 7 | [Leverage] | INT | YES | - | CODE-BACKED | Leverage multiplier applied to this position. |
| 8 | [Units] | DECIMAL | YES | - | CODE-BACKED | Position size in instrument units (e.g., shares, lots). From TGEP.AmountInUnitsDecimal. Added case 42916. |
| 9 | [Current Net Profit] | DECIMAL(16,2) | YES | - | CODE-BACKED | Live unrealized P&L in dollars. From TGEP.PnLInDollars (pre-calculated in PositionForExternalUseWithPnL view). |
| 10 | [Init Date Time] | DATETIME | NO | - | CODE-BACKED | Timestamp when the position was opened. From TGEP.InitDateTime. |
| 11 | [Buy/Sell] | VARCHAR | NO | - | CODE-BACKED | Trade direction. 'Buy' (IsBuy=1), 'Sell' (IsBuy=0), 'Unknown' (other). |
| 12 | [Init Rate] | DECIMAL(16,6) | YES | - | CODE-BACKED | Forex rate at position open. From TGEP.InitForexRate. |
| 13 | [Stop Rate] | DECIMAL(16,6) | YES | - | CODE-BACKED | Current stop-loss rate. From TGEP.StopRate. |
| 14 | [Limit Rate] | DECIMAL(16,6) | YES | - | CODE-BACKED | Current take-profit rate. From TGEP.LimitRate. |
| 15 | [TSL Enabled] | VARCHAR | NO | - | CODE-BACKED | Whether Trailing Stop Loss is active. 'Yes' if IsTslEnabled=1, 'No' otherwise. |
| 16 | [CommissionOnOpen] | DECIMAL(16,2) | YES | - | CODE-BACKED | Commission charged when the position was opened. From TGEP.Commission. |
| 17 | [SpreadGroup] | CHAR(1) | NO | '0' | CODE-BACKED | Legacy hardcoded constant '0'. Spread group assignment has moved to other mechanisms. |
| 18 | [OpenMinusCloseRateMultiplier] | INT | NO | - | CODE-BACKED | PnL direction multiplier. -1 for Buy (profits when rate rises), +1 for Sell (profits when rate falls). |
| 19 | [InitForexPriceRateID] | BIGINT | YES | - | CODE-BACKED | Reference to the price rate record used at position open. From TGEP.InitForexPriceRateID. |
| 20 | [Mirror ID] | INT | YES | - | CODE-BACKED | Copy relationship ID if this is a copy position. 0 or NULL for manual positions. From TGEP.MirrorID. |
| 21 | [Parent PosID] | BIGINT | YES | - | CODE-BACKED | Position ID of the master trader's position being copied. 0 for manual positions. From TGEP.ParentPositionID. |
| 22 | [Original Parent PosID] | BIGINT | YES | - | CODE-BACKED | Original parent position ID before any reopen operations. Used to trace reopen chains. From TGEP.OrigParentPositionID. |
| 23 | [Over Weekend] | VARCHAR | NO | - | CODE-BACKED | Whether the position stays open over the weekend. 'Yes' when CloseOnEndOfWeek=0 (inverted flag). |
| 24 | [Is Open Open] | VARCHAR | NO | 'No' | CODE-BACKED | Whether the position's open order is still being processed. 'Yes' if IsOpenOpen is non-null and non-zero. |
| 25 | [Close Requested] | VARCHAR | NO | - | CODE-BACKED | Whether a close request is pending for this position. 'Yes' if a matching Trade.OrdersExit row exists; '' otherwise. |
| 26 | [Is Real] | VARCHAR | NO | '' | CODE-BACKED | Position settlement type. 'CFD' (IsSettled=0) or 'Real' (IsSettled=1). Added RD-1942 Jan 2019. |
| 27 | [Is Discounted] | VARCHAR | NO | 'No' | CODE-BACKED | Whether this position has a discounted rate applied. 'Yes' if IsDiscounted is non-null and non-zero. Calculation updated MIMOPS-2247 Sep 2020. |
| 28 | [Init Conversion Rate] | DECIMAL(16,6) | YES | - | CODE-BACKED | Currency conversion rate used at position open (for non-USD instruments). From TGEP.InitConversionRate. |
| 29 | [End Conversion Rate] | DECIMAL(16,6) | YES | - | CODE-BACKED | Most recent conversion rate used for PnL calculation. From TGEP.LastOpConversionRate. |
| 30 | [HBC] | DECIMAL(16,6) | YES | - | CODE-BACKED | Numeric form of IsSettled (same data as [Is Real]). Legacy artifact - cast as DECIMAL(16,6). Trailing comment "--," indicates planned but unrealized columns after this line. |
| 31 | [Open Total Fees] | DECIMAL(16,2) | YES | - | CODE-BACKED | Total fees charged at position open (beyond commission). From TGEP.OpenTotalFees. Added MIMOPSA-11865. |
| 32 | [Recurring] | VARCHAR | NO | 'No' | CODE-BACKED | Whether the position was opened via recurring investment automation. 'Yes' if OpenActionType=17. Added MIMOPSA-14289. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Trade.PositionForExternalUseWithPnL | Primary Source | All open positions with live PnL for the customer |
| PositionID | Trade.OrdersExit | LEFT JOIN | Detects pending close requests; partition-aware join |
| InstrumentID | Trade.InstrumentMetaData | LEFT JOIN | Instrument display name |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice application (BO) | N/A | Application call | Open Positions tab in customer profile |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetCustomerOpenPositions (procedure)
|- Trade.PositionForExternalUseWithPnL (open positions + live PnL)
|- Trade.OrdersExit (close request detection, partition-aware)
+-- Trade.InstrumentMetaData (instrument display name)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionForExternalUseWithPnL | View | Primary source - open positions enriched with PnLInDollars |
| Trade.OrdersExit | Table | LEFT JOINed on PositionID with partition columns to detect pending close requests |
| Trade.InstrumentMetaData | Table | LEFT JOINed for InstrumentDisplayName |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice application (BO) | External application | Open Positions tab - live position list with P&L for customer review |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- `WITH(NOLOCK)` on all tables.
- `ORDER BY TGEP.InitDateTime DESC` - most recently opened positions first.
- Partition-aware JOIN on OrdersExit: `TOE.PartitionCol = @CID % 50 AND TGEP.PartitionCol = TOE.PositionID % 50`. Partition pruning was improved in Jan 2021 (Ran Ovadia - "Eliminate partitions on PositionID").
- [HBC] duplicate of [Is Real]: `CAST(IsSettled AS DECIMAL(16,6))` - same source column, different format. Likely a leftover development artifact.

---

## 8. Sample Queries

### 8.1 Get open positions for a customer

```sql
EXEC BackOffice.GetCustomerOpenPositions @CID = 12345678;
```

### 8.2 Direct base-table query (key fields)

```sql
SELECT
    TGEP.PositionID,
    TIMD.InstrumentDisplayName AS [Instrument],
    CAST(TGEP.InitialAmountCents / 100 AS DECIMAL(16,2)) AS [Initial Amount],
    CAST(TGEP.PnLInDollars AS DECIMAL(16,2)) AS [Current Net Profit],
    CASE TGEP.IsSettled WHEN 0 THEN 'CFD' WHEN 1 THEN 'Real' ELSE '' END AS [Is Real],
    CASE TGEP.OpenActionType WHEN 17 THEN 'Yes' ELSE 'No' END AS [Recurring]
FROM Trade.PositionForExternalUseWithPnL TGEP WITH(NOLOCK)
LEFT JOIN Trade.InstrumentMetaData TIMD WITH(NOLOCK) ON TIMD.InstrumentID = TGEP.InstrumentID
WHERE TGEP.CID = 12345678
ORDER BY TGEP.InitDateTime DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| MIMOPS-2247 (inferred from comment) | Jira | Sep 2020 - Changed [Is Discounted] calculation. Same ticket as GetCurrentRates - discounted close rate feature for BackOffice. |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 30 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10, 11 executed; 9B skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetCustomerOpenPositions | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetCustomerOpenPositions.sql*
