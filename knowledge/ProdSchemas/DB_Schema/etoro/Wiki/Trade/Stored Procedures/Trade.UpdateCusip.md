# Trade.UpdateCusip

> Batch-updates security identifier codes (CUSIP, ISIN, ISINCountryCode, SEDOL) across two instrument tables atomically for a supplied set of instruments; uses null-safe ISNULL to preserve existing values when not provided.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CusipConfig (TVP - Trade.CusipConfigTbl) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.UpdateCusip is the primary write path for financial security identifiers on eToro's tradeable instruments. Financial instruments are identified by multiple international standards simultaneously: CUSIP (US clearing standard, 9 characters, used by Apex), ISIN (global 12-character identifier), ISINCountryCode (2-letter country prefix), and SEDOL (UK/Irish market identifier). These codes are required for order routing to clearing brokers, regulatory reporting, and cross-market reconciliation.

Without accurate security identifiers, US stock orders cannot be routed to Apex, dividend matching against external feeds (CUSIP-based) fails, and regulatory reporting to international bodies is incomplete. The procedure ensures both the compact identifier store (`Trade.InstrumentCusip`, holding CUSIP + ISIN) and the full metadata record (`Trade.InstrumentMetaData`, holding ISIN + ISINCountryCode + SEDOL) stay synchronized in a single atomic transaction.

The procedure accepts a batch of instruments via a table-valued parameter (`Trade.CusipConfigTbl`), making it suitable for bulk operations such as onboarding a new batch of US equities, reconciling with a broker feed, or correcting identifiers after a corporate action reclassification. The null-safe ISNULL update pattern means a caller can pass a partial record (e.g., only CUSIP, leaving ISINCode null) without overwriting existing values.

---

## 2. Business Logic

### 2.1 Null-Safe Partial Update Pattern

**What**: Both UPDATE statements use `ISNULL(new_value, existing_value)` to perform a partial update - only non-null values in the TVP overwrite the existing database values.

**Columns/Parameters Involved**: `CUSIP`, `ISINCode`, `ISINCountryCode`, `SEDOL`

**Rules**:
- `SET a.CUSIP = ISNULL(b.CUSIP, a.CUSIP)` - if TVP row has CUSIP=null, the existing CUSIP is retained
- Same logic for ISINCode, ISINCountryCode, SEDOL
- A caller can pass a partial TVP (e.g., only CUSIP populated) without clearing the other identifiers
- To explicitly clear an identifier, the caller must pass an empty string or a sentinel value (NULL alone won't clear it)
- This makes the procedure idempotent for partial updates: re-running with the same data leaves the state unchanged

**Diagram**:
```
TVP row: InstrumentID=5, CUSIP='037833100', ISINCode=null, ISINCountryCode=null, SEDOL=null
                                |
                                v
InstrumentCusip row for ID=5:
  CUSIP = ISNULL('037833100', existing) = '037833100'   (updated)
  ISINCode = ISNULL(null, existing)    = existing value (preserved)

InstrumentMetaData row for ID=5:
  ISINCode      = ISNULL(null, existing) = existing  (preserved)
  ISINCountryCode = ISNULL(null, existing) = existing  (preserved)
  SEDOL         = ISNULL(null, existing) = existing  (preserved)
```

### 2.2 Split Storage Across Two Tables

**What**: Security identifiers are stored in two tables with overlapping fields - Trade.InstrumentCusip (compact CUSIP+ISIN store) and Trade.InstrumentMetaData (full metadata including ISIN+ISINCountryCode+SEDOL). Both are updated atomically.

**Columns/Parameters Involved**: All identifier columns in both tables, `InstrumentID` JOIN key

**Rules**:
- `Trade.InstrumentCusip` receives: CUSIP, ISINCode
- `Trade.InstrumentMetaData` receives: ISINCode, ISINCountryCode, SEDOL
- ISINCode is maintained in BOTH tables - they must stay in sync; this procedure keeps them synchronized
- JOIN condition: `a.InstrumentID = b.InstrumentID` in both UPDATEs
- If an InstrumentID in the TVP has no corresponding row in one of the target tables, the UPDATE silently skips it (no INSERT)
- Wrapped in `BEGIN TRAN ... COMMIT` to ensure both tables update atomically

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CusipConfig | Trade.CusipConfigTbl READONLY | NO | - | CODE-BACKED | Table-valued parameter containing the batch of instruments and their security identifiers to update. Each row: InstrumentID (PK, required), CUSIP (nullable, US 9-char clearing identifier), ISINCode (nullable, global 12-char identifier), ISINCountryCode (nullable, 2-letter country prefix), SEDOL (nullable, UK/Irish 7-char identifier). Only non-null values overwrite existing data. See Trade.CusipConfigTbl for full structure. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CusipConfig | Trade.CusipConfigTbl | TVP | Input parameter type; defines the shape of the instrument-identifier batch |
| UPDATE target | Trade.InstrumentCusip | Modifier | Updates CUSIP and ISINCode columns; JOIN on InstrumentID |
| UPDATE target | Trade.InstrumentMetaData | Modifier | Updates ISINCode, ISINCountryCode, SEDOL columns; JOIN on InstrumentID |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase - no callers found in SSDT. Invoked by external operations tooling or admin scripts.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.UpdateCusip (procedure)
+-- Trade.CusipConfigTbl (TVP type)
+-- Trade.InstrumentCusip (table)
+-- Trade.InstrumentMetaData (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.CusipConfigTbl | User Defined Type (TVP) | Input parameter type: batch of InstrumentID -> identifier rows |
| Trade.InstrumentCusip | Table | UPDATE target for CUSIP and ISINCode via InstrumentID JOIN |
| Trade.InstrumentMetaData | Table | UPDATE target for ISINCode, ISINCountryCode, SEDOL via InstrumentID JOIN |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (external operations tooling) | - | Called by admin/ops scripts when updating security identifiers from broker feeds or corporate actions |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. The procedure executes inside `BEGIN TRAN ... COMMIT` to ensure atomicity across the two target tables.

---

## 8. Sample Queries

### 8.1 Update CUSIP and ISIN for a batch of instruments
```sql
DECLARE @Config Trade.CusipConfigTbl;

INSERT INTO @Config (InstrumentID, CUSIP, ISINCode, ISINCountryCode, SEDOL)
VALUES
  (1001, '037833100', 'US0378331005', 'US', NULL),
  (1002, '594918104', 'US5949181045', 'US', NULL),
  (1003, NULL,        'GB0002634946', 'GB', '0263494');

EXEC Trade.UpdateCusip @CusipConfig = @Config;
```

### 8.2 Verify current identifiers for specific instruments
```sql
SELECT ic.InstrumentID,
       ic.CUSIP,
       ic.ISINCode AS ISINCode_Cusip,
       im.ISINCode AS ISINCode_MetaData,
       im.ISINCountryCode,
       im.SEDOL
FROM   Trade.InstrumentCusip ic WITH (NOLOCK)
JOIN   Trade.InstrumentMetaData im WITH (NOLOCK) ON im.InstrumentID = ic.InstrumentID
WHERE  ic.InstrumentID IN (1001, 1002, 1003);
```

### 8.3 Find instruments with mismatched ISIN between the two tables
```sql
SELECT ic.InstrumentID,
       ic.ISINCode AS ISINCode_InstrumentCusip,
       im.ISINCode AS ISINCode_InstrumentMetaData
FROM   Trade.InstrumentCusip ic WITH (NOLOCK)
JOIN   Trade.InstrumentMetaData im WITH (NOLOCK) ON im.InstrumentID = ic.InstrumentID
WHERE  ic.ISINCode <> im.ISINCode
   OR  (ic.ISINCode IS NULL AND im.ISINCode IS NOT NULL)
   OR  (ic.ISINCode IS NOT NULL AND im.ISINCode IS NULL);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers found | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.UpdateCusip | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.UpdateCusip.sql*
