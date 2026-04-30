# BackOffice.IDs_DUP

> General-purpose table-valued parameter type for passing a set of integer IDs with silent duplicate suppression - used when the caller's source data may contain repeated IDs.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | User Defined Type |
| **Key Identifier** | ID (CLUSTERED PK, IGNORE_DUP_KEY=ON) |
| **Partition** | N/A |
| **Indexes** | 1 (CLUSTERED PK on ID ASC) |

---

## 1. Business Meaning

`BackOffice.IDs_DUP` is a variant of `BackOffice.IDs` designed for scenarios where the caller's source data naturally contains duplicate integer IDs. It has an identical schema (a single `ID INT NOT NULL` column with a CLUSTERED PK) but uses `IGNORE_DUP_KEY=ON`, meaning that inserting a duplicate ID silently skips the duplicate row rather than raising an error. The effective result in the TVT is always a distinct set of IDs.

This type exists for the specific use case where a procedure caller derives IDs from a query that may produce duplicates - for example, deposit IDs appearing in multiple billing join rows. Using `BackOffice.IDs` in that context would require the caller to pre-deduplicate (adding a DISTINCT or GROUP BY), whereas `IDs_DUP` handles deduplication transparently at insert time.

Data flows into this type from application code processing billing or deposit records that may reference the same deposit multiple times. The sole identified consumer is `BackOffice.GetProcessDepositValidationInfo`, which accepts deposit IDs and returns deposit details from `Billing.Deposit`.

---

## 2. Business Logic

### 2.1 IGNORE_DUP_KEY=ON - Silent Deduplication Contract

**What**: Unlike its sibling `BackOffice.IDs`, this type silently discards duplicate IDs on insert rather than raising an error, making it safe to populate from non-deduplicated sources.

**Columns/Parameters Involved**: `ID`

**Rules**:
- Inserting the same ID twice results in one row in the TVT (first insert wins, duplicate is silently dropped).
- The final TVT always contains a distinct set of IDs.
- Use this type when: the source query produces duplicates naturally and pre-deduplication would add complexity.
- Use `BackOffice.IDs` when: duplicates indicate a caller bug that should be surfaced immediately.

**Diagram**:
```
Source data: DepositID=101 (from billing row 1)
             DepositID=101 (from billing row 2, same deposit different funding row)
             DepositID=102

INSERT INTO @depositIds VALUES (101),(101),(102)
                                    ^
                            Second 101 silently skipped (IGNORE_DUP_KEY=ON)

@depositIds now contains: {101, 102}
```

---

## 3. Data Overview

N/A for User Defined Type. This is a transient parameter container, not a persistent table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | CODE-BACKED | Generic integer identifier with silent duplicate suppression. In the sole identified consuming procedure (BackOffice.GetProcessDepositValidationInfo), represents DepositID values from Billing.Deposit. The CLUSTERED PK ensures efficient JOIN and automatic deduplication at insert time. NOT NULL. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. The semantic meaning of ID is context-dependent per consuming procedure.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.GetProcessDepositValidationInfo | @DepositIDs parameter | Schema contract | Receives deposit IDs (possibly with duplicates) and JOINs to Billing.Deposit to return payment status, amount, currency, depot, and protocol settings |

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
| BackOffice.GetProcessDepositValidationInfo | Stored Procedure | READONLY parameter @DepositIDs - JOINs to Billing.Deposit to retrieve validation info (PaymentStatusID, Amount, CurrencyID, DepotID, ProtocolMIDSettingsID) for each unique deposit |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| (unnamed PK) | CLUSTERED PK | ID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| IGNORE_DUP_KEY = ON | Index option | Duplicate ID values are silently ignored on insert - the TVT always contains a distinct set. Contrast with BackOffice.IDs where duplicates raise an error. |

---

## 8. Sample Queries

### 8.1 Get deposit validation info for a batch of deposit IDs (with potential duplicates)

```sql
DECLARE @depositIds BackOffice.IDs_DUP;

-- Source may produce duplicates - IDs_DUP handles them silently
INSERT INTO @depositIds (ID)
SELECT bd.DepositID
FROM Billing.Deposit bd WITH (NOLOCK)
WHERE bd.CID = 12345
  AND bd.PaymentStatusID IN (1, 2); -- pending + approved

EXEC BackOffice.GetProcessDepositValidationInfo @DepositIDs = @depositIds;
```

### 8.2 Verify deduplication behavior

```sql
DECLARE @ids BackOffice.IDs_DUP;

-- Inserting same ID twice - second is silently dropped
INSERT INTO @ids VALUES (101), (101), (102), (103), (102);

-- Result: 3 rows (101, 102, 103) - not 5
SELECT COUNT(*) AS DistinctCount FROM @ids WITH (NOLOCK); -- Returns 3
```

### 8.3 Compare IDs_DUP vs IDs for the same data

```sql
-- IDs_DUP: safe with duplicates
DECLARE @safe BackOffice.IDs_DUP;
INSERT INTO @safe VALUES (1),(1),(2); -- OK, result = {1,2}

-- BackOffice.IDs: would raise PK violation on (1),(1)
-- DECLARE @strict BackOffice.IDs;
-- INSERT INTO @strict VALUES (1),(1),(2); -- ERROR

SELECT * FROM @safe WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11 (DDL, Procedure Ref, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.IDs_DUP | Type: User Defined Type | Source: etoro/etoro/BackOffice/User Defined Types/BackOffice.IDs_DUP.sql*
