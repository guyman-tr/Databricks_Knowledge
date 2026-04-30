# Trade.GetInvalidDividendsByCorrection

> Validates a batch of dividend correction references and returns the ones whose ExDate or DividendCurrencyID do not match the original dividend record.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: DividendID + CorrectionDividendID (invalid corrections only) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetInvalidDividendsByCorrection is a batch validation procedure used by the Dividends application to identify correction dividends that have become invalid. A "correction dividend" in eToro references an original dividend via CorrectionDividendID - this procedure checks whether the correction's ExDate and DividendCurrencyID still match the original dividend's values, and flags mismatches.

This procedure exists because dividend corrections must reference a valid original dividend. If the original dividend's ExDate or currency was changed after the correction was created, the correction becomes invalid and must be flagged for manual review or reprocessing. Without this validation, incorrect financial adjustments could be applied to customer positions.

The DividendsApp service calls this procedure with a batch of DividendIDs (via TVP). The procedure filters to those with a non-NULL CorrectionDividendID, validates each via CROSS APPLY to Trade.ValidateCorrectionDividendId, and returns only the invalid ones (isValid=0). This supports the broader dividend lifecycle managed by the Dividends microservice.

---

## 2. Business Logic

### 2.1 Correction Validation via Function Delegation

**What**: Each correction dividend is validated by delegating to Trade.ValidateCorrectionDividendId, which checks field-level consistency between the correction and its original.

**Columns/Parameters Involved**: `@DividendIDs`, `CorrectionDividendID`, `ExDate`, `DividendCurrencyID`

**Rules**:
- Only dividends with CorrectionDividendID IS NOT NULL are evaluated - standard dividends are skipped
- Validation checks: the correction's ExDate must match the original's ExDate, AND the correction's DividendCurrencyID must match the original's DividendCurrencyID
- If either field mismatches, the correction is flagged as invalid (isValid=0)
- If the CorrectionDividendID points to a non-existent DividendID, the function returns isValid=0 (NULL comparison fails)

**Diagram**:
```
@DividendIDs (TVP batch)
     |
     v
Trade.IndexDividends (filter: CorrectionDividendID IS NOT NULL)
     |
     v
CROSS APPLY Trade.ValidateCorrectionDividendId(
    CorrectionDividendID, ExDate, DividendCurrencyID)
     |
     +--> isValid=1 --> filtered out (valid correction)
     +--> isValid=0 --> returned to caller (invalid correction)
```

### 2.2 Temp Table Intermediate Storage

**What**: Results are materialized into #temp before filtering, separating the validation step from the output step.

**Columns/Parameters Involved**: `#temp.DividendID`, `#temp.CorrectionDividendID`, `#temp.isValid`

**Rules**:
- All correction dividends (with their validation result) are stored in #temp
- The final SELECT returns only rows where isValid=0
- This two-step pattern allows potential future extension (e.g., returning valid corrections separately)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### 4.1 Parameters

| # | Element | Type | Direction | Default | Confidence | Description |
|---|---------|------|-----------|---------|------------|-------------|
| 1 | @DividendIDs | dbo.IdIntList (TVP) | IN (READONLY) | - | CODE-BACKED | Table-valued parameter containing a batch of DividendID values (INT) to validate. Each ID corresponds to a row in Trade.IndexDividends. Passed by the DividendsApp service for bulk validation. |

### 4.2 Result Set

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 1 | DividendID | int | NO | CODE-BACKED | The DividendID of the correction dividend that failed validation. FK to Trade.IndexDividends.DividendID. |
| 2 | CorrectionDividendID | int | NO | CODE-BACKED | The DividendID of the original dividend that this correction references. The mismatch was detected between this original's ExDate/DividendCurrencyID and the correction's values. |

### 4.3 Temp Table (#temp)

| # | Element | Type | Confidence | Description |
|---|---------|------|------------|-------------|
| 1 | DividendID | int | CODE-BACKED | DividendID of the correction dividend being validated. |
| 2 | CorrectionDividendID | int | CODE-BACKED | The original dividend ID referenced by the correction. |
| 3 | isValid | bit | CODE-BACKED | Validation result from Trade.ValidateCorrectionDividendId: 1=ExDate and DividendCurrencyID match the original, 0=mismatch detected. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @DividendIDs | dbo.IdIntList | TVP Type | User-defined table type for batch integer ID input |
| FROM Trade.IndexDividends | Trade.IndexDividends | SELECT (READER) | Reads dividend records to find those with corrections and extract ExDate/DividendCurrencyID for validation |
| CROSS APPLY | Trade.ValidateCorrectionDividendId | Function Call | Validates each correction by comparing ExDate and DividendCurrencyID against the original dividend |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| DividendsApp | GRANT EXECUTE | Application User | The Dividends microservice calls this procedure for batch correction validation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetInvalidDividendsByCorrection (procedure)
+-- Trade.IndexDividends (table)
+-- Trade.ValidateCorrectionDividendId (function)
|     +-- Trade.IndexDividends (table)
+-- dbo.IdIntList (type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.IndexDividends | Table | JOINed via DividendID to find correction dividends and extract ExDate/DividendCurrencyID |
| Trade.ValidateCorrectionDividendId | Function | CROSS APPLYed per row to validate correction against original |
| dbo.IdIntList | User Defined Type | TVP type for @DividendIDs parameter |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| DividendsApp | Application User | Executes this procedure for dividend correction validation |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Validate a batch of dividend corrections

```sql
DECLARE @ids dbo.IdIntList;
INSERT INTO @ids (ID) VALUES (100), (200), (300);

EXEC Trade.GetInvalidDividendsByCorrection @DividendIDs = @ids;
```

### 8.2 Find all correction dividends and check their validity

```sql
DECLARE @correctionIds dbo.IdIntList;

INSERT INTO @correctionIds (ID)
SELECT  DividendID
FROM    Trade.IndexDividends WITH (NOLOCK)
WHERE   CorrectionDividendID IS NOT NULL
        AND Status IN (0, 4);

EXEC Trade.GetInvalidDividendsByCorrection @DividendIDs = @correctionIds;
```

### 8.3 Review correction dividends with full context

```sql
SELECT  d.DividendID,
        d.CorrectionDividendID,
        d.ExDate            AS CorrectionExDate,
        d.DividendCurrencyID AS CorrectionCurrencyID,
        orig.ExDate         AS OriginalExDate,
        orig.DividendCurrencyID AS OriginalCurrencyID,
        CASE WHEN d.ExDate <> orig.ExDate THEN 'ExDate mismatch'
             WHEN d.DividendCurrencyID <> orig.DividendCurrencyID THEN 'Currency mismatch'
             ELSE 'Valid'
        END AS MismatchReason
FROM    Trade.IndexDividends d WITH (NOLOCK)
        LEFT JOIN Trade.IndexDividends orig WITH (NOLOCK)
            ON orig.DividendID = d.CorrectionDividendID
WHERE   d.CorrectionDividendID IS NOT NULL;
```

---

## 9. Atlassian Knowledge Sources

No dedicated Atlassian page found for this procedure. General dividend-related Confluence pages exist (e.g., "Dividends tax withholding daily reconciliation: Ex-date") but do not reference this specific procedure.

---

*Generated: 2026-03-16 | Quality: 8.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetInvalidDividendsByCorrection | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetInvalidDividendsByCorrection.sql*
