# BackOffice.IsLinkedAccountsVerified

> Returns 1 (as VerifiedCount) if ANY customer in the input list has VerificationLevelID=3 (fully verified), 0 otherwise.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CIDs TVP (dbo.IDIntList); returns VerifiedCount = 1 or 0 |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`IsLinkedAccountsVerified` checks whether any of a given set of customers (passed as a TVP) has reached full KYC verification (VerificationLevelID = 3). It is designed to answer the question: "Among all these linked accounts, has at least one been fully verified?"

The use case is **linked accounts**: eToro's compliance model allows customers to have multiple linked accounts (e.g., demo + real, or family accounts). For certain operations - account activation, withdrawal eligibility, or compliance gating - the rule is satisfied if ANY linked account is verified, not necessarily all of them. This procedure encodes that "any-verified" check.

VerificationLevelID = 3 represents the highest standard verification tier (full KYC: identity document + proof of address + possibly enhanced due diligence). Levels 1 and 2 represent partial verification stages.

The TVP type `dbo.IDIntList` is a table of INT IDs, similar in function to `BackOffice.IDs` but defined in the `dbo` schema, suggesting this SP predates or was written independently of the BackOffice TVP type standardization.

No SSDT callers found - called by external Back Office or compliance services that evaluate linked account verification status.

---

## 2. Business Logic

### 2.1 Any-Verified Check Across Linked Accounts

**What**: Determines if at least one customer in the input set is fully KYC verified.

**Columns/Parameters Involved**: `@CIDs`, `BackOffice.Customer.VerificationLevelID`

**Rules**:
- Uses `IF EXISTS (SELECT 1 FROM BackOffice.Customer WITH (NOLOCK) WHERE CID IN (SELECT ID FROM @CIDs) AND VerificationLevelID = 3)`
- If any CID in @CIDs has VerificationLevelID = 3: returns result set with `VerifiedCount = 1`
- If no CID in @CIDs has VerificationLevelID = 3 (all lower levels, or @CIDs is empty): returns `VerifiedCount = 0`
- The check is "any" (EXISTS), not "all" - a single verified account satisfies the check
- WITH (NOLOCK): dirty read, verification status changes in-flight may not be visible

**Diagram**:
```
@CIDs (TVP of linked account CIDs)
  |
  v
EXISTS: any CID WHERE VerificationLevelID = 3?
  YES -> SELECT 1 AS VerifiedCount
  NO  -> SELECT 0 AS VerifiedCount
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CIDs | dbo.IDIntList READONLY | NO | - | CODE-BACKED | TVP of customer IDs to check. Typically the full set of linked accounts for a customer group. The check passes if ANY of these CIDs has VerificationLevelID = 3. Note: uses `dbo.IDIntList` type (not `BackOffice.IDs`). |

**Output (result set):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | VerifiedCount | INT (literal 1 or 0) | NO | - | CODE-BACKED | 1 = at least one customer in @CIDs has VerificationLevelID = 3 (fully verified). 0 = no customer in @CIDs is at VerificationLevelID = 3. Despite the column name "Count", this is a boolean flag (only values 1 or 0 are possible). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CIDs | BackOffice.Customer | Lookup | EXISTS check on CID IN @CIDs AND VerificationLevelID = 3 |
| VerificationLevelID = 3 | BackOffice.VerificationLevel (implicit) | Lookup (implicit) | Level 3 = full KYC verification |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.IsLinkedAccountsVerified (procedure)
└── BackOffice.Customer (table) [EXISTS check on VerificationLevelID]
    └── dbo.IDIntList (user defined type) [TVP for @CIDs]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Customer | Table | EXISTS lookup: CID IN @CIDs AND VerificationLevelID = 3 |
| dbo.IDIntList | User Defined Type | TVP type for @CIDs parameter |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SSDT dependents found. | - | Called by external compliance/account services for linked-account verification gating |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| dbo.IDIntList TVP | Design | Uses the `dbo` schema TVP type rather than `BackOffice.IDs`; may reflect an older convention or cross-schema TVP sharing |
| WITH (NOLOCK) | Query hint | Dirty read - in-flight verification level updates may not be reflected |
| No SET NOCOUNT | Omission | Row count for the single-row SELECT will be sent to caller |
| No TRY/CATCH | Design | Errors propagate to caller |
| EXISTS (not COUNT) | Optimization | Short-circuits on first match - efficient for large linked-account sets |

---

## 8. Sample Queries

### 8.1 Check if any linked account is verified

```sql
DECLARE @CIDs dbo.IDIntList;
INSERT INTO @CIDs VALUES (11111), (22222), (33333); -- linked account CIDs

EXEC [BackOffice].[IsLinkedAccountsVerified] @CIDs = @CIDs;
-- Returns: VerifiedCount = 1 (at least one verified) or 0 (none verified)
```

### 8.2 Check verification level for specific customers

```sql
SELECT
    CID,
    VerificationLevelID,
    CASE VerificationLevelID
        WHEN 1 THEN 'Basic'
        WHEN 2 THEN 'Intermediate'
        WHEN 3 THEN 'Full KYC'
        ELSE 'Unknown'
    END AS VerificationLabel
FROM BackOffice.Customer WITH (NOLOCK)
WHERE CID IN (11111, 22222, 33333);
```

### 8.3 Count fully verified customers in a batch

```sql
SELECT COUNT(*) AS FullyVerifiedCount
FROM BackOffice.Customer WITH (NOLOCK)
WHERE CID IN (11111, 22222, 33333)
  AND VerificationLevelID = 3;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.8/10 (Elements: 8.5/10, Logic: 8.0/10, Relationships: 6.5/10, Sources: 5.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/5 (1, 8, 9B-skipped, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers in SSDT | App Code: 2 repos searched / 0 files | Corrections: 0 applied*
*Object: BackOffice.IsLinkedAccountsVerified | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.IsLinkedAccountsVerified.sql*
