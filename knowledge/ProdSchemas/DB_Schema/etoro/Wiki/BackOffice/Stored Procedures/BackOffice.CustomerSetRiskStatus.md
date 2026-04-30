# BackOffice.CustomerSetRiskStatus

> Upserts a risk flag against a customer group (GCID + RiskStatusID), either creating a new risk alert or updating the event state/manager/remark of an existing one, with automatic history capture via OUTPUT INTO.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @GCID + @RiskStatusID - composite key matching BackOffice.CustomerRisk PK |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.CustomerSetRiskStatus is the primary write procedure for the Risk team's alert registry (`BackOffice.CustomerRisk`). When an automated risk rule fires or a BackOffice agent manually applies a risk flag, this procedure is called to record the alert. It implements a compound UPSERT: if the customer already has a flag of the specified risk type (GCID + RiskStatusID match exists), it updates the flag's current event state, manager, and optionally the remark; if the flag is new, it inserts a fresh row.

The procedure also maintains an automatic audit trail: each UPDATE emits the pre-update state of the row into `History.CustomerRisk` via an `OUTPUT INTO` clause. This means every state change on a risk flag is preserved historically without a separate INSERT. Note that INSERT operations (new flags) do NOT write to History.CustomerRisk - only subsequent updates do.

An inline comment block shows the original implementation targeted `BackOffice.Customer.RiskStatusID` and `History.RiskStatus` - both now replaced by the `BackOffice.CustomerRisk` multi-flag model, enabling customers to hold multiple simultaneous risk alerts instead of a single status.

The procedure is called by `BackOffice.FreazCustomer` (account freeze workflow) and by regional BackOffice permissions grantees. A legacy alias `BackOffice.CusotmerSetRiskStatus` (typo in name) exists as a separate file.

---

## 2. Business Logic

### 2.1 UPSERT Pattern: Update-or-Insert Risk Flag

**What**: Determines whether to update an existing risk record or create a new one based on the GCID + RiskStatusID composite key.

**Columns/Parameters Involved**: `@GCID`, `@RiskStatusID`, `BackOffice.CustomerRisk.*`

**Rules**:
- IF EXISTS (SELECT * FROM BackOffice.CustomerRisk WHERE GCID = @GCID AND RiskStatusID = @RiskStatusID):
  - UPDATE path: modifies `RiskEventStatusID`, `ManagerID`, `ModifiedDate = GETUTCDATE()`, and conditionally `Remark`.
  - History written via `OUTPUT DELETED.* INTO History.CustomerRisk` before the UPDATE applies.
- ELSE:
  - INSERT path: creates a new row with `GCID, RiskStatusID, ModifiedDate=GETUTCDATE(), Remark, RiskEventStatusID, ManagerID`.
  - No history write on INSERT (only the first update of a new flag creates a history record).

**Diagram**:
```
EXEC CustomerSetRiskStatus @GCID, @RiskStatusID, @ManagerID, @RiskEventStatusID, @Remark

EXISTS (CustomerRisk WHERE GCID=@GCID AND RiskStatusID=@RiskStatusID)?
  YES ->
    OUTPUT old row INTO History.CustomerRisk
    UPDATE: RiskEventStatusID, ManagerID, ModifiedDate, Remark (if provided)
  NO ->
    INSERT new row: GCID, RiskStatusID, ModifiedDate, Remark, RiskEventStatusID, ManagerID
```

### 2.2 Conditional Remark Update

**What**: @Remark is optional - passing NULL preserves the existing remark rather than overwriting it.

**Columns/Parameters Involved**: `@Remark`, `BackOffice.CustomerRisk.Remark`

**Rules**:
- `Remark = IIF(@Remark IS NULL, Remark, @Remark)`: if the caller passes NULL for @Remark, the existing Remark value is retained unchanged.
- Only applicable to the UPDATE path. On INSERT, @Remark (even if NULL) is written directly.
- Allows callers to update only RiskEventStatusID/ManagerID without clearing an existing investigator note.

### 2.3 Automatic History Capture via OUTPUT INTO

**What**: Every UPDATE to a risk flag automatically archives the prior state to History.CustomerRisk.

**Columns/Parameters Involved**: `DELETED.GCID, DELETED.RiskStatusID, DELETED.ModifiedDate, DELETED.Remark, DELETED.RiskEventStatusID, DELETED.ManagerID`

**Rules**:
- `OUTPUT DELETED.*` captures the row as it was BEFORE the UPDATE (the "deleted" logical image in SQL Server).
- Columns written to History.CustomerRisk: GCID, RiskStatusID, ModifiedDate, Remark, RiskEventStatusID, ManagerID.
- History records thus represent the timeline of state changes for each GCID + RiskStatusID combination.
- INSERT operations do NOT generate History entries (the INSERTED image is not captured).

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | INT | NO | - | CODE-BACKED | Global Customer ID - the customer group being flagged. Matches BackOffice.CustomerRisk.GCID (part of composite PK). |
| 2 | @RiskStatusID | INT | NO | - | CODE-BACKED | The type of risk alert to apply or update. Matches BackOffice.CustomerRisk.RiskStatusID (part of composite PK). One of 60+ defined risk categories (fraud, velocity, geo-conflict, document quality, etc.) - see BackOffice.CustomerRisk for full category taxonomy. |
| 3 | @ManagerID | INT | NO | - | CODE-BACKED | The BackOffice agent or manager applying/updating this risk flag. Written to BackOffice.CustomerRisk.ManagerID and captured in History.CustomerRisk on each state change. FK to BackOffice.Manager. |
| 4 | @RiskEventStatusID | INT | NO | - | CODE-BACKED | The current lifecycle state of this risk flag: On (active alert), InProcess (under investigation), or Off (resolved). Written to BackOffice.CustomerRisk.RiskEventStatusID. Lookup in Dictionary or application layer. |
| 5 | @Remark | VARCHAR(255) | YES | NULL | CODE-BACKED | Optional free-text investigator note. NULL = preserve existing remark unchanged (UPDATE path only). On INSERT, NULL is written as-is. Allows agents to annotate the risk alert with investigation details. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @GCID + @RiskStatusID | BackOffice.CustomerRisk | Modifier | UPSERT target - creates or updates the risk flag record for this customer/risk-type combination. |
| OUTPUT DELETED | History.CustomerRisk | Writer | Prior state is written to History.CustomerRisk on every UPDATE, maintaining the full change timeline. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.FreazCustomer | EXEC | Caller | Calls CustomerSetRiskStatus as part of the account freeze workflow to record the freeze-triggering risk event. |
| Risk automation / BackOffice tooling | EXEC | Caller | Called by automated risk rules and BackOffice agents when applying or updating risk alerts. Regional BOUser groups are granted EXEC. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CustomerSetRiskStatus (procedure)
├── BackOffice.CustomerRisk (table) - UPSERT target
└── History.CustomerRisk (table) - OUTPUT INTO for prior-state history
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CustomerRisk | Table | EXISTS check + UPDATE or INSERT - the primary risk flag registry |
| History.CustomerRisk | Table | OUTPUT INTO - receives the pre-update row on every state change |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.FreazCustomer | Procedure | EXEC - calls this as part of the customer freeze workflow |
| Risk automation services | External | EXEC - automated risk rule engine writes alerts via this procedure |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Composite key uniqueness | Behavior | One row per (GCID, RiskStatusID) - the EXISTS check enforces UPSERT semantics using the CustomerRisk composite PK. |
| Conditional remark | Logic | IIF(@Remark IS NULL, Remark, @Remark) - NULL @Remark preserves existing value; only UPDATE path affected. |
| THROW on error | Convention | CATCH block re-throws the original exception (preserves original error code/message unlike RAISERROR pattern). Returns -1 after THROW (unreachable in practice, since THROW exits). |
| History INSERT only on UPDATE | Behavior | INSERT of new risk flags does not produce History records. The first history entry appears on the first subsequent UPDATE. |

---

## 8. Sample Queries

### 8.1 Apply a new fraud risk flag to a customer
```sql
EXEC BackOffice.CustomerSetRiskStatus
    @GCID = 123456789,
    @RiskStatusID = 25,   -- e.g., FraudRequestResponseMismatch
    @ManagerID = 42,
    @RiskEventStatusID = 1, -- On (active)
    @Remark = 'Detected mismatched funding request/response pattern'
```

### 8.2 Update an existing risk flag to InProcess
```sql
EXEC BackOffice.CustomerSetRiskStatus
    @GCID = 123456789,
    @RiskStatusID = 25,
    @ManagerID = 42,
    @RiskEventStatusID = 2, -- InProcess
    @Remark = NULL  -- preserve existing remark
```

### 8.3 View risk flag history for a customer
```sql
SELECT
    cr.GCID,
    cr.RiskStatusID,
    cr.RiskEventStatusID,
    cr.ModifiedDate,
    cr.Remark,
    cr.ManagerID
FROM BackOffice.CustomerRisk cr WITH (NOLOCK)
WHERE cr.GCID = 123456789
UNION ALL
SELECT
    hcr.GCID,
    hcr.RiskStatusID,
    hcr.RiskEventStatusID,
    hcr.ModifiedDate,
    hcr.Remark,
    hcr.ManagerID
FROM History.CustomerRisk hcr WITH (NOLOCK)
WHERE hcr.GCID = 123456789
ORDER BY ModifiedDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (FreazCustomer) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.CustomerSetRiskStatus | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.CustomerSetRiskStatus.sql*
