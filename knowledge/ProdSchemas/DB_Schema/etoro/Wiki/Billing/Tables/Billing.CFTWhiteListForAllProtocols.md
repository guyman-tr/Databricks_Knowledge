# Billing.CFTWhiteListForAllProtocols

> Protocol-specific BIN whitelist for Card-Funded Transfer (CFT) eligibility - maps card BIN prefixes to the payment protocols authorized to process CFT transactions for those card ranges.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | ID (IDENTITY PK) |
| **Partition** | No (PRIMARY filegroup, FILLFACTOR 95) |
| **Indexes** | 3 (PK clustered + NC on BIN + NC on SixDigitsBin) |

---

## 1. Business Meaning

`Billing.CFTWhiteListForAllProtocols` defines which card BIN ranges are eligible for Card-Funded Transfer (CFT) processing on a per-protocol basis. Each row declares: "for BIN prefix X, payment protocol Y is authorized to process CFT transactions." With 269,618 rows, the table covers a large universe of card ranges, overwhelmingly for ProtocolID=23 (WorldPay, 99.99%).

CFT (Card-Funded Transfer) allows a customer's credit or debit card to fund a transfer directly. Not all card issuers support CFT, and not all payment protocols can process CFT for every card range - this table encodes that eligibility matrix. The table supersedes the older `Billing.CFTWhiteList` (which had no protocol dimension) and is the active BIN eligibility source used by BackOffice.GetCashActivities for CFT-enabled determination.

The `SixDigitsBin` computed column normalizes all BIN values to their 6-digit form (LEFT(BIN, 6)), enabling fast lookups regardless of whether a BIN was stored as 3, 6, or 8 digits. Both BIN and SixDigitsBin are indexed to support both full and truncated BIN lookups.

The `NOT FOR REPLICATION` flag on IDENTITY indicates participation in SQL Server replication topology.

---

## 2. Business Logic

### 2.1 Protocol-Aware BIN Lookup

**What**: CFT eligibility is determined by matching a transaction's BIN against this list for the relevant protocol.

**Columns/Parameters Involved**: `BIN`, `ProtocolID`, `SixDigitsBin`

**Rules**:
- A BIN found in this table for the querying protocol = CFT is supported for that card range.
- A BIN NOT found = CFT is not supported (implicit deny).
- `SixDigitsBin` (= `LEFT(BIN,6)`) allows 6-digit lookups even when BINs were stored as 3-digit prefixes (e.g., BIN=340 -> SixDigitsBin=340). BackOffice.GetCashActivities uses LEFT on the transaction BIN for the join.
- 99.99% of entries are for ProtocolID=23 (WorldPay), making WorldPay the dominant CFT processor.

**Diagram**:
```
CFT eligibility check for card BIN in transaction
        |
        v
JOIN CFTWhiteListForAllProtocols ON LEFT(BIN,6) = SixDigitsBin
  AND ProtocolID = @Protocol
        |
        +-- Match found  -> IsCFTEnabled = 1 (CFT allowed)
        +-- No match     -> IsCFTEnabled = 0 (CFT not supported)
```

### 2.2 BIN Normalization via Computed Column

**What**: Variable-length BINs are normalized to 6 digits for consistent lookups.

**Columns/Parameters Involved**: `BIN`, `SixDigitsBin`

**Rules**:
- `SixDigitsBin = CONVERT(int, LEFT(BIN, 6))` - persisted as indexed computed column.
- Supports both legacy 6-digit BINs and modern 8-digit BINs: an 8-digit BIN like 22264700 gets SixDigitsBin=222647.
- Also handles short range prefixes (BIN=340 -> SixDigitsBin=340) representing broad card families.
- The IX_BillingCFTWhiteListForAllProtocols_SixDigitsBin index enables efficient LEFT-join lookups used in GetCashActivities.

---

## 3. Data Overview

| ID | BIN | ProtocolID | SixDigitsBin | Meaning |
|----|-----|-----------|-------------|---------|
| 1 | 340 | 23 (WorldPay) | 340 | Short prefix 340 - covers all Amex cards starting with 340 - authorized for WorldPay CFT processing. |
| 2 | 341 | 23 (WorldPay) | 341 | Amex 341-range - WorldPay CFT eligible. |
| 3 | 342 | 23 (WorldPay) | 342 | Amex 342-range - WorldPay CFT eligible. |
| 4 | 343 | 23 (WorldPay) | 343 | Amex 343-range - WorldPay CFT eligible. |
| 5 | 344 | 23 (WorldPay) | 344 | Amex 344-range - WorldPay CFT eligible. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | IDENTITY(1,1) NOT FOR REPLICATION | CODE-BACKED | Surrogate primary key. NOT FOR REPLICATION prevents identity consumption on replication subscribers. Not a business key. |
| 2 | BIN | bigint | NO | - | CODE-BACKED | Card BIN (Bank Identification Number) - the card range prefix identifying card issuer and product. Can be 3, 6, or 8 digits stored as bigint. Short prefixes (e.g., 340) represent broad card families. Full BINs (e.g., 222300) identify a specific issuer product. Used in LEFT-join lookups alongside SixDigitsBin. Indexed via IX_BillingCFTWhiteListForAllProtocols_BIN. |
| 3 | ProtocolID | int | NO | - | CODE-BACKED | Payment protocol authorized to process CFT for this BIN range. FK to Dictionary.Protocol. Observed values: 23=WorldPay (99.99%, 269,608 rows), 43 (7 rows), 46 (3 rows). WorldPay is the primary CFT protocol. Allows the same BIN to be eligible for CFT on some protocols but not others. |
| 4 | SixDigitsBin | computed int | NO | CONVERT(int, LEFT(BIN,6)) | CODE-BACKED | Computed normalization of BIN to its first 6 digits as an integer. Enables fast 6-digit BIN lookups against variable-length stored BINs. Indexed via IX_BillingCFTWhiteListForAllProtocols_SixDigitsBin. Used by BackOffice.GetCashActivities: `LEFT(BIN,6) = LEFT(CAST(FundingData...,6))`. Not stored persistently - recalculated from BIN. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ProtocolID | Dictionary.Protocol | Implicit FK | Identifies the payment protocol authorized for CFT on this BIN range. Value 23=WorldPay dominates. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.GetCashActivities | BIN column via LEFT join | READER | Joins on SixDigitsBin/BIN to determine IsCFTEnabled for cash activity records. See MIMOPSA-11774 comment in that procedure. |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.GetCashActivities | Stored Procedure | READER - joins on BIN/SixDigitsBin to flag IsCFTEnabled on cash activity rows |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BillingCftWhiteLastForAllDepots | CLUSTERED PK | ID ASC | - | - | Active |
| IX_BillingCFTWhiteListForAllProtocols_BIN | NONCLUSTERED | BIN ASC | - | - | Active |
| IX_BillingCFTWhiteListForAllProtocols_SixDigitsBin | NONCLUSTERED | SixDigitsBin ASC | - | - | Active |

All indexes: FILLFACTOR=95. PRIMARY filegroup.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BillingCftWhiteLastForAllDepots | PRIMARY KEY | ID - unique row identifier |

---

## 8. Sample Queries

### 8.1 Check if a full card BIN is eligible for CFT via WorldPay

```sql
SELECT ID, BIN, ProtocolID, SixDigitsBin
FROM [Billing].[CFTWhiteListForAllProtocols] WITH (NOLOCK)
WHERE SixDigitsBin = LEFT(@CardBIN, 6)
  AND ProtocolID = 23;  -- WorldPay
-- Non-empty = CFT eligible
```

### 8.2 Count BIN entries per protocol

```sql
SELECT p.Name AS ProtocolName, COUNT(*) AS BINCount
FROM [Billing].[CFTWhiteListForAllProtocols] c WITH (NOLOCK)
INNER JOIN [Dictionary].[Protocol] p WITH (NOLOCK) ON c.ProtocolID = p.ProtocolID
GROUP BY p.Name
ORDER BY BINCount DESC;
```

### 8.3 Find all protocols supporting a specific 6-digit BIN

```sql
SELECT c.BIN, c.SixDigitsBin, c.ProtocolID, p.Name AS ProtocolName
FROM [Billing].[CFTWhiteListForAllProtocols] c WITH (NOLOCK)
INNER JOIN [Dictionary].[Protocol] p WITH (NOLOCK) ON c.ProtocolID = p.ProtocolID
WHERE c.SixDigitsBin = 222300;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specifically for Billing.CFTWhiteListForAllProtocols.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.8/10 (Elements: 10/10, Logic: 7/10, Relationships: 5/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.CFTWhiteListForAllProtocols | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.CFTWhiteListForAllProtocols.sql*
