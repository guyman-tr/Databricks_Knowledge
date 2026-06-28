# Billing.BadBin

> BIN (Bank Identification Number) range blocklist used to check whether a card prefix corresponds to a blocked card range; queried by `Billing.CheckBadBin` and `Billing.CheckInBadBins` during card payment validation.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | (BinFrom, BinTo) - PRIMARY KEY NONCLUSTERED composite |
| **Row Count** | ~4.95M rows |
| **Partition** | N/A - filegroup MAIN |
| **Indexes** | 1 - PK NONCLUSTERED on (BinFrom, BinTo) |

---

## 1. Business Meaning

`Billing.BadBin` stores BIN (Bank Identification Number) ranges that should be blocked or flagged during credit card payment processing. A BIN is the first 6-8 digits of a card number; it identifies the issuing bank and card type. When a customer attempts to make a card payment, the system checks whether their card's BIN falls within any range in this table.

The table contains ~4.95M rows representing individual BIN codes or ranges. The vast majority (~4.95M rows) have `BlockReasonID=NULL`, while only 2 rows have an explicit `BlockReasonID=1`. BINs span from 104001 to 99985099, covering both 6-digit (standard) and 8-digit (expanded ISO 8583:2003) BIN formats.

The range design (`BinFrom`/`BinTo`) allows blocking an entire contiguous block of BINs (e.g., all BINs from a specific issuer) with a single row, while single-point blocks (`BinFrom=BinTo`) target individual BINs precisely.

---

## 2. Business Logic

### 2.1 BIN Blocking Check

**What**: Before accepting a card payment, the BIN prefix of the card is checked against this table. If found, the transaction may be blocked or flagged depending on the calling context.

**Columns Involved**: `BinFrom`, `BinTo`, `BlockReasonID`

**Rules**:
- `Billing.CheckBadBin @CardPrefix INT` -> returns 1 if `@CardPrefix BETWEEN BinFrom AND BinTo` for any row, else 0
- `Billing.CheckInBadBins @CardBinNumber INT OUTPUT @CheckResult` -> same range check, output parameter variant
- `BlockReasonID=NULL` (4,949,121 rows): BIN is in the blocklist without an explicit reason code - treated as blocked
- `BlockReasonID=1` (2 rows): BIN has an explicit block reason (40380600-40380601, a specific Visa BIN pair)
- `Billing.BadBinAdd` / `Billing.BadBinRemove`: manage the blocklist (add/remove BIN ranges)

### 2.2 Range vs. Single-Point Blocks

Most rows are single-point entries (`BinFrom = BinTo`, RangeSize=0). A small number of rows cover large contiguous ranges (observed ranges of 90,000-111,000 BINs), likely used to block entire issuer families or test/invalid BIN blocks.

---

## 3. Data Overview

| Metric | Value |
|--------|-------|
| Total rows | ~4,949,123 |
| BinFrom range | 104001 to 99985099 |
| Rows with BlockReasonID=NULL | 4,949,121 (99.99%) |
| Rows with BlockReasonID=1 | 2 (BINs 40380600-40380601) |
| Single-point entries (BinFrom=BinTo) | Majority |
| Largest observed range | ~111,823 BINs wide (234523-346346) |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | BinFrom | int | NO | - | CODE-BACKED | Start of the blocked BIN range (inclusive). Part of the composite PK. For single-BIN blocks, equals BinTo. Represents the first 6 or 8 digits of the card number. |
| 2 | BinTo | int | NO | - | CODE-BACKED | End of the blocked BIN range (inclusive). Part of the composite PK. For single-BIN blocks, equals BinFrom. Any card whose BIN prefix falls in [BinFrom, BinTo] is considered blocked. |
| 3 | BlockReasonID | int | YES | NULL | NAME-INFERRED | Optional block reason code. NULL = blocked without a specific coded reason (the overwhelming majority of rows). Non-NULL values reference a reason catalog (only BlockReasonID=1 observed in live data, applied to 2 rows at BIN 40380600-40380601). No FK constraint defined. |

---

## 5. Relationships

### 5.1 References To (this object points to)

No FK constraints defined. `BlockReasonID` semantically references an unnamed block reason catalog.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.CheckBadBin | BinFrom, BinTo | Read | Returns 1 if @CardPrefix matches any BadBin range |
| Billing.CheckInBadBins | BinFrom, BinTo | Read | Output-parameter variant of the same range check |
| Billing.BadBinAdd | BinFrom, BinTo | Write | Inserts new BIN ranges into the blocklist |
| Billing.BadBinRemove | BinFrom, BinTo | Delete | Removes BIN ranges from the blocklist |

---

## 6. Dependencies

### 6.0 Dependency Chain

No dependencies - standalone fraud/risk table.

---

### 6.1 Objects This Depends On

None.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.CheckBadBin | Stored Procedure | Primary consumer - range check against incoming card BIN prefix |
| Billing.CheckInBadBins | Stored Procedure | Output-parameter variant of BIN check |
| Billing.BadBinAdd | Stored Procedure | Inserts new blocked BIN ranges |
| Billing.BadBinRemove | Stored Procedure | Removes BIN ranges from blocklist |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Notes |
|-----------|------|-------------|-----------------|--------|-------|
| PK_BBDB | NONCLUSTERED PK | BinFrom ASC, BinTo ASC | - | - | Active; FILLFACTOR=90; no CLUSTERED index defined - heap table |

**Note**: The table is a heap (no clustered index). With 4.95M rows and a range-based query (`BETWEEN BinFrom AND BinTo`), the NONCLUSTERED PK on (BinFrom, BinTo) allows efficient range lookups by scanning forward from the matching BinFrom.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BBDB | PRIMARY KEY NONCLUSTERED (BinFrom, BinTo) | One row per unique BIN range; prevents duplicate range entries |

---

## 8. Sample Queries

### 8.1 Check if a specific BIN is blocked

```sql
DECLARE @CardBin INT = 403806  -- Example BIN

SELECT CASE WHEN EXISTS (
    SELECT 1 FROM Billing.BadBin WITH (NOLOCK)
    WHERE @CardBin BETWEEN BinFrom AND BinTo
) THEN 'BLOCKED' ELSE 'OK' END AS BinStatus
```

### 8.2 View rows with explicit block reasons

```sql
SELECT BinFrom, BinTo, BlockReasonID, (BinTo - BinFrom) AS RangeWidth
FROM Billing.BadBin WITH (NOLOCK)
WHERE BlockReasonID IS NOT NULL
ORDER BY BinFrom
```

### 8.3 Summarize blocklist by range size

```sql
SELECT
    CASE
        WHEN (BinTo - BinFrom) = 0 THEN 'Single BIN'
        WHEN (BinTo - BinFrom) <= 99 THEN 'Small range (1-99)'
        WHEN (BinTo - BinFrom) <= 9999 THEN 'Medium range (100-9999)'
        ELSE 'Large range (10000+)'
    END AS RangeCategory,
    COUNT(*) AS RowCount
FROM Billing.BadBin WITH (NOLOCK)
GROUP BY
    CASE
        WHEN (BinTo - BinFrom) = 0 THEN 'Single BIN'
        WHEN (BinTo - BinFrom) <= 99 THEN 'Small range (1-99)'
        WHEN (BinTo - BinFrom) <= 9999 THEN 'Medium range (100-9999)'
        ELSE 'Large range (10000+)'
    END
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 8/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 1,2,5,7,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.BadBin | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.BadBin.sql*
