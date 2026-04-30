# BackOffice.ChangeCustomerVerificationLevel

> Transitions a customer's KYC verification level and synchronizes the boolean Verified flag: Level 3 sets Verified=1 (full KYC), all other levels set Verified=0.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID (Customer ID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure manages KYC (Know Your Customer) verification level transitions for BackOffice operators. The verification level is one of the most consequential customer attributes: it gates withdrawal amounts, instrument access, leverage limits, and compliance reporting. Moving a customer to a higher or lower level changes what they can and cannot do on the platform.

The critical business rule is the Level 3 / Verified flag coupling: `VerificationLevelID=3` is full KYC (proof of identity + proof of address confirmed) and is the ONLY level that sets `Verified=1`. All other levels (0, 1, 2) set `Verified=0`. This means the `Verified` column in BackOffice.Customer is not an independent flag - it is always derived from and synchronized with `VerificationLevelID`. BackOffice operators changing a customer to Level 3 automatically marks them as fully verified; any downgrade (3->2, 3->1, etc.) immediately sets Verified=0.

As documented in Dictionary.VerificationLevel: Level 0 = unverified (registration only), Level 1 = basic (email confirmed), Level 2 = intermediate (POI submitted), Level 3 = full KYC (POI + POA confirmed).

The procedure uses the same dual-existence guard as BackOffice.ChangeCustomerRegulation: both customer and target level must exist before any update is applied.

---

## 2. Business Logic

### 2.1 Dual-Existence Guard

**What**: Both the customer and the target verification level must exist in their respective tables.

**Columns/Parameters Involved**: `@CID`, `@VerificationLevelID`, `BackOffice.Customer.CID`, `Dictionary.VerificationLevel.ID`

**Rules**:
- Guard 1: `EXISTS (SELECT 1 FROM BackOffice.Customer WHERE CID=@CID)` - customer must exist
- Guard 2: `EXISTS (SELECT 1 FROM Dictionary.VerificationLevel WHERE ID=@VerificationLevelID)` - level must be valid (0-3)
- If EITHER fails -> silent no-op (no update, no error)

### 2.2 Level 3 = Verified Flag Coupling (Critical Business Rule)

**What**: VerificationLevelID=3 is the exclusive trigger for Verified=1; all other levels reset Verified=0.

**Columns/Parameters Involved**: `@VerificationLevelID`, `BackOffice.Customer.VerificationLevelID`, `BackOffice.Customer.Verified`

**Rules**:
- If `@VerificationLevelID = 3`:
  - `UPDATE BackOffice.Customer SET VerificationLevelID=3, Verified=1 WHERE CID=@CID`
  - Customer gains full KYC status; all withdrawal and trading restrictions lifted
- If `@VerificationLevelID != 3` (i.e., 0, 1, or 2):
  - `UPDATE BackOffice.Customer SET VerificationLevelID=@VerificationLevelID, Verified=0 WHERE CID=@CID`
  - Customer is not fully KYC verified; platform restrictions apply

**Diagram**:
```
@VerificationLevelID = 3?
  YES -> SET VerificationLevelID=3, Verified=1   (full KYC - all privileges unlocked)
  NO  -> SET VerificationLevelID=@VerificationLevelID, Verified=0  (restricted access)

Verification Level Values:
  0 = Unverified (registration only)
  1 = Basic (email confirmed)
  2 = Intermediate (POI submitted, not yet confirmed)
  3 = Full KYC (POI + POA confirmed) -> ONLY level with Verified=1
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. The customer whose verification level is being changed. Validated against BackOffice.Customer.CID before the update. |
| 2 | @VerificationLevelID | INT | NO | - | CODE-BACKED | Target verification level ID. Validated against Dictionary.VerificationLevel.ID. Values: 0=Unverified, 1=Basic, 2=Intermediate, 3=Full KYC. Only Level 3 sets Verified=1; all others set Verified=0. |

**Return Value:**

| # | Element | Type | Description |
|---|---------|------|-------------|
| 3 | RETURN | (none) | No RETURN statement. Procedure always returns NULL. Caller cannot determine success vs. validation failure from the return value alone. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | BackOffice.Customer | MODIFIER | Updates VerificationLevelID and Verified WHERE CID=@CID (conditional on both guards passing) |
| @CID | BackOffice.Customer | Lookup (EXISTS) | Validates that the customer exists before applying the update |
| @VerificationLevelID | Dictionary.VerificationLevel | Lookup (EXISTS) | Validates that the target level ID is valid (cross-schema) |

### 5.2 Referenced By (other objects point to this)

No SP-to-SP callers found in SSDT. Referenced in Dictionary.VerificationLevel documentation as the primary level transition mechanism. Called from BackOffice KYC management UI and potentially by the KYC processing pipeline.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.ChangeCustomerVerificationLevel (procedure)
|- BackOffice.Customer (table) [EXISTS check + UPDATE target - VerificationLevelID, Verified]
+-- Dictionary.VerificationLevel (table) [EXISTS validation - cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Customer | Table | EXISTS guard: verifies CID exists; UPDATE: sets VerificationLevelID AND Verified WHERE CID=@CID |
| Dictionary.VerificationLevel | Table | EXISTS guard: verifies @VerificationLevelID is a valid tier (cross-schema) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice KYC management UI | External | Calls this when an operator approves or changes a customer's KYC status |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Dual-existence guard | Application | Both CID in BackOffice.Customer AND VerificationLevelID in Dictionary.VerificationLevel must exist; either missing -> silent no-op |
| Level 3 exclusive Verified flag | Business | ONLY @VerificationLevelID=3 sets Verified=1; any other level explicitly sets Verified=0; the Verified flag is always coupled to the level |
| No RETURN code | Design | No RETURN statement; callers must re-read BackOffice.Customer to confirm the update was applied |
| High-impact operation | Business | Verification level changes affect withdrawal limits, instrument access, leverage caps, and regulatory reporting; should be tracked in audit logs |

---

## 8. Sample Queries

### 8.1 Approve a customer for full KYC (Level 3)

```sql
EXEC BackOffice.ChangeCustomerVerificationLevel
    @CID = 12345,
    @VerificationLevelID = 3  -- Full KYC - also sets Verified=1
-- Verify: SELECT VerificationLevelID, Verified FROM BackOffice.Customer WITH (NOLOCK) WHERE CID = 12345
-- Expected: VerificationLevelID=3, Verified=1
```

### 8.2 Downgrade a customer from Level 3 to Level 2 (document expired)

```sql
EXEC BackOffice.ChangeCustomerVerificationLevel
    @CID = 12345,
    @VerificationLevelID = 2  -- Sets Verified=0 automatically
-- Expected: VerificationLevelID=2, Verified=0
```

### 8.3 Check current verification status

```sql
SELECT BC.CID, BC.VerificationLevelID, BC.Verified,
    VL.Name AS VerificationLevelName
FROM BackOffice.Customer BC WITH (NOLOCK)
JOIN Dictionary.VerificationLevel VL WITH (NOLOCK) ON BC.VerificationLevelID = VL.ID
WHERE BC.CID = 12345
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.1/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.ChangeCustomerVerificationLevel | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.ChangeCustomerVerificationLevel.sql*
