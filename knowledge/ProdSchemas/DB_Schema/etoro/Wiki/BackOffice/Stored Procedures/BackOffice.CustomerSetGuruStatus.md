# BackOffice.CustomerSetGuruStatus

> Updates GuruStatusID on BackOffice.Customer for a given CID within an explicit transaction. Returns 0 on success, 60000 on failure. GuruStatus controls Popular Investor tier and affects cashout fee group eligibility.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure sets the Guru (Popular Investor) status for a customer - one of the most commercially significant fields in the BackOffice schema. `GuruStatusID` controls the customer's Popular Investor tier, which determines:

1. **Cashout fee group**: Higher Guru Status tiers qualify for Exempt (no-fee) or reduced-fee cashout groups. Changes to GuruStatusID trigger cashout fee group recalculation (via the assignment service that calls `BackOffice.CashoutFeeGroupBulkUpdate`).
2. **Popular Investor programme**: Customers at sufficient Guru Status are listed as Popular Investors - other users can copy their trades, and they earn a share of copier profits.
3. **Platform visibility and benefits**: Higher tiers unlock bonuses, reduced fees, and account manager assignment.

The procedure wraps the UPDATE in an explicit transaction (BEGIN TRAN/COMMIT) for safety. No validation of @GuruStatusID against a dictionary - callers are responsible for valid values.

Note: `@LocalError INT` is declared but never assigned - it remains NULL throughout and is passed as the last argument to RAISERROR in the CATCH block, where it has no practical effect.

---

## 2. Business Logic

### 2.1 Transactional GuruStatusID Update

**What**: Updates GuruStatusID with TRY/CATCH and explicit transaction.

**Rules**:
- BEGIN TRY -> BEGIN TRAN
- UPDATE BackOffice.Customer SET GuruStatusID=@GuruStatusID WHERE CID=@CID
- COMMIT TRANSACTION; RETURN 0
- CATCH: SET @Err=ERROR_MESSAGE(); ROLLBACK TRANSACTION; RAISERROR(60000, 16, 1, @Err, @LocalError); RETURN 60000
- No validation of @GuruStatusID or @CID existence - UPDATE silently 0 rows if CID not found, COMMIT, RETURN 0
- @LocalError is always NULL (declared but never set): passed to RAISERROR as the last argument but has no practical effect

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. No existence check - if not found, UPDATE affects 0 rows, COMMIT, RETURN 0 (silent success). |
| 2 | @GuruStatusID | INT | NO | - | CODE-BACKED | New Guru (Popular Investor) status tier ID. No validation against a dictionary. Controls PI tier membership, cashout fee eligibility, and platform benefits. |

**Return Values:**

| # | Element | Type | Description |
|---|---------|------|-------------|
| 3 | RETURN 0 | INT | Success: transaction committed (including CID-not-found silent no-op case). |
| 4 | RETURN 60000 | INT | CATCH path: transaction rolled back. SQL error occurred during UPDATE. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | BackOffice.Customer | UPDATE | Sets GuruStatusID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Popular Investor programme workflows | External | Direct call | Set/change a customer's PI tier status |
| Cashout fee group assignment service | Indirect | Triggered downstream | GuruStatus changes drive cashout fee group recalculation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CustomerSetGuruStatus (procedure)
|- BackOffice.Customer (table) [UPDATE: GuruStatusID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Customer | Table | UPDATE: GuruStatusID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Popular Investor management | External | Set PI tier for customers |
| Cashout fee group assignment | External (indirect) | GuruStatus change events trigger fee group recalculation |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Explicit transaction | Design | BEGIN TRAN/COMMIT for safety around the UPDATE |
| TRY/CATCH + ROLLBACK | Design | SQL errors cause rollback + re-raise as 60000 |
| No validation | Design | No GuruStatusID dictionary check; silent no-op if CID not found |
| @LocalError unused | Code quality | Declared but never set; always NULL in RAISERROR call |

---

## 8. Sample Queries

### 8.1 Set Guru Status for a customer

```sql
EXEC BackOffice.CustomerSetGuruStatus
    @CID = 12345,
    @GuruStatusID = 3;
-- RETURN 0 = success (or silent no-op if CID not found)
-- RETURN 60000 = SQL error during update
```

### 8.2 Check current Guru Status

```sql
SELECT CID, GuruStatusID, CashoutFeeGroupID
FROM BackOffice.Customer WITH (NOLOCK)
WHERE CID = 12345;
-- Note: CashoutFeeGroupID may not update immediately - driven by separate assignment service
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Cashout Fee Groups Auto Assignment Design](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/1242726429) | Confluence | GuruStatus is one of two factors (with Club Group) that determine cashout fee group; higher status = more fee-exempt group wins |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 5, 8, 10)*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 callers found | App Code: not searched (BackOffice schema) | Corrections: 0 applied*
*Object: BackOffice.CustomerSetGuruStatus | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.CustomerSetGuruStatus.sql*
