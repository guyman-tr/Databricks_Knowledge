# Billing.UpsertFundingStatus

> MERGE upsert that sets or updates the validation status of a Billing.Funding record in Billing.FundingStatus, indicating whether the funding data is valid (complete) or partial for use in new money payouts.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @FundingID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.UpsertFundingStatus` is the write path for `Billing.FundingStatus`, a table created as part of the "Funding Data wrong association fix" (PAYIL-2611). The problem it addresses: when payment provider postbacks arrive with empty funding data, deposits can be incorrectly associated with funding records belonging to other customers, causing wrong new-money payouts.

The solution (Confluence: "Funding Data wrong association fix") adds a status flag to each funding record indicating whether its data is complete enough to be trusted for payout. `Billing.FundingStatus` holds this status keyed by `FundingID`, and `Billing.UpsertFundingStatus` is the SP that sets it.

The procedure performs a MERGE: if a status record already exists for the `@FundingID`, it updates the `FundingStatusID`; if no record exists, it inserts one. The return value (`@FundingID` via SELECT) is only populated on INSERT - on UPDATE it returns NULL - allowing the caller to distinguish new vs. existing funding status records.

Called by the Funding Service when the `ENABLE_FUNDING_UPDATE_STATUS` CCM feature flag is enabled (default: false). Created by elrom behar, 14/05/2021.

---

## 2. Business Logic

### 2.1 MERGE Upsert on FundingID

**What**: Atomically inserts or updates the funding status record for a given FundingID.

**Columns/Parameters Involved**: `@FundingID`, `@FundingStatusID`, `Billing.FundingStatus`

**Rules**:
- MERGE target: `Billing.FundingStatus` (aliased PRM)
- MERGE source: single-row inline `VALUES (@FundingID)` as `newFunding(FundingID)`
- Match condition: `PRM.FundingID = newFunding.FundingID`
- WHEN MATCHED (record exists): `UPDATE SET FundingStatusID = @FundingStatusID` - replaces the existing status
- WHEN NOT MATCHED (no record): `INSERT (FundingID, FundingStatusID) VALUES (@FundingID, @FundingStatusID)` - creates the first status record for this funding

**Diagram**:
```
@FundingID, @FundingStatusID
  -> MERGE Billing.FundingStatus ON FundingID

  MATCHED (exists)  -> UPDATE FundingStatusID = @FundingStatusID
                       @out = NULL (no INSERT output)

  NOT MATCHED       -> INSERT (FundingID, FundingStatusID)
                       @out = Inserted.FundingID (the new row's FundingID)

  -> SELECT TOP 1 @FundingID = id FROM @out
     (returns @FundingID on INSERT, NULL on UPDATE)
```

### 2.2 Return Value: INSERT vs. UPDATE Detection

**What**: The OUTPUT clause captures the FundingID only on INSERT; the SELECT sets the return variable to allow the caller to detect whether a new record was created.

**Rules**:
- OUTPUT: `CASE $action WHEN 'INSERT' THEN Inserted.FundingID END INTO @out` - only emits a row when the action was INSERT; on UPDATE, the CASE evaluates to NULL and emits nothing
- `SELECT TOP 1 @FundingID = id FROM @out` - after the MERGE, if the @out table is populated (INSERT happened), `@FundingID` will hold the new row's FundingID; if empty (UPDATE happened), `@FundingID` remains unchanged from its input value
- This pattern allows callers to check whether the status was newly created (INSERT) vs. already existed and was updated (UPDATE)

### 2.3 FundingStatusID Values

**What**: The `@FundingStatusID` parameter references `Dictionary.FundingStatus` which has two values.

**Rules** (Source: Confluence PAYIL-2611 - "Funding Data wrong association fix"):

| FundingStatusID | FundingStatusName | Meaning |
|----------------|------------------|---------|
| 0 | Partial | Funding data is incomplete - not safe for new money payout |
| 1 | Valid | Funding data is complete (has mandatory fields) - approved for payout |

- Back Office (BO) uses this status when displaying payout options; only fundings with status 1 (Valid) are eligible for new money payouts
- The Funding Service validates mandatory fields (e.g., SwiftCodeAsString+IBANCodeAsString+CountryIDAsInteger for wire) before setting status to 1

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FundingID | INT | NO | - | CODE-BACKED | FK to `Billing.Funding.FundingID`. The funding record whose status will be set or updated. Used as the MERGE key. |
| 2 | @FundingStatusID | INT | NO | - | VERIFIED | The new funding status: 0=Partial (incomplete data, not eligible for payout), 1=Valid (complete data, eligible for payout). FK to `Dictionary.FundingStatus`. (Source: Confluence PAYIL-2611) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @FundingID | Billing.FundingStatus | MERGE (UPDATE or INSERT) | Upserts the status record for this funding |
| @FundingStatusID | Dictionary.FundingStatus | FK reference | Status value must exist in Dictionary.FundingStatus (0=Partial, 1=Valid) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Funding Service (application) | UpdateFundingStatus flow | Application call | Called when ENABLE_FUNDING_UPDATE_STATUS CCM flag is true; sets status after validating funding data completeness |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.UpsertFundingStatus (procedure)
+-- Billing.FundingStatus (table) [MERGE - UPDATE or INSERT]
    +-- Dictionary.FundingStatus (table) [FK - status values: 0=Partial, 1=Valid]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.FundingStatus | Table | MERGE target: upserts funding status record by FundingID |
| Dictionary.FundingStatus | Table | FK reference for @FundingStatusID (0=Partial, 1=Valid) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Funding Service (application) | Application | Sets funding validation status after postback data received; controlled by ENABLE_FUNDING_UPDATE_STATUS CCM flag |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| No transaction wrapper | Design | MERGE runs in auto-commit mode; no explicit TRY/CATCH. On failure, MERGE is atomic by itself (no partial state). |
| Return value is INSERT-only | Design | @FundingID is only populated in @out on INSERT; on UPDATE the return is unchanged input value - callers must understand this contract. |
| No existence validation on @FundingID | Design | If @FundingID does not exist in Billing.Funding, the FK constraint on Billing.FundingStatus.FundingID will raise a constraint error. |
| SET NOCOUNT ON | Performance | Suppresses row count messages from MERGE. |

---

## 8. Sample Queries

### 8.1 Mark a funding as Valid after successful postback validation
```sql
EXEC Billing.UpsertFundingStatus
    @FundingID       = 987654,
    @FundingStatusID = 1;  -- Valid
```

### 8.2 Mark a funding as Partial when postback arrives with incomplete data
```sql
EXEC Billing.UpsertFundingStatus
    @FundingID       = 987654,
    @FundingStatusID = 0;  -- Partial
```

### 8.3 Check current funding statuses for a customer's deposits
```sql
SELECT
    f.FundingID,
    f.FundingTypeID,
    fs.FundingStatusID,
    CASE fs.FundingStatusID
        WHEN 0 THEN 'Partial'
        WHEN 1 THEN 'Valid'
        ELSE 'Unknown'
    END AS StatusLabel
FROM Billing.Funding f WITH (NOLOCK)
LEFT JOIN Billing.FundingStatus fs WITH (NOLOCK)
    ON fs.FundingID = f.FundingID
WHERE f.CustomerID = 123456
ORDER BY f.FundingID DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Funding Data wrong association fix](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/2250375192) | Confluence | Full context: PAYIL-2611; Dictionary.FundingStatus values (0=Partial, 1=Valid); Billing.FundingStatus table design; CCM flag ENABLE_FUNDING_UPDATE_STATUS; created by elrom behar 14/05/2021; Back Office uses this status to determine payout eligibility |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.5/10 (Elements: 10/10, Logic: 10/10, Relationships: 9.0/10, Sources: 9.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 5, 8, 10)*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: skipped (no Billing repos) | Corrections: 0 applied*
*Object: Billing.UpsertFundingStatus | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.UpsertFundingStatus.sql*
