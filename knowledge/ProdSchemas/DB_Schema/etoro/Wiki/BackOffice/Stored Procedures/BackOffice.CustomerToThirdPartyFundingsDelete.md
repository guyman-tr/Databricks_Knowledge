# BackOffice.CustomerToThirdPartyFundingsDelete

> Removes a specific third-party funding relationship from the AML/fraud review registry by CID + FundingID.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @FundingID - composite key matching BackOffice.CustomerToThirdPartyFundings PK |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.CustomerToThirdPartyFundingsDelete removes a previously approved third-party funding relationship from `BackOffice.CustomerToThirdPartyFundings`. This is called when a documented relationship is no longer valid - for example, if the funding link was added in error, the relationship was resolved (e.g., funds returned), or the compliance team has determined the pair no longer requires special tracking.

Removing the pair restores the system's ability to flag the (FundingID, CID) combination as a new third-party relationship if it occurs again in the future. The delete is by both CID and FundingID, targeting the exact composite PK - unlike CustomerToPayoneerFundingDelete which deletes by CID alone, this procedure requires both keys to prevent accidentally removing all of a customer's third-party relationships.

---

## 2. Business Logic

### 2.1 Exact Pair Delete by Composite Key

**What**: Removes a specific (CID, FundingID) combination from the third-party registry.

**Columns/Parameters Involved**: `@CID`, `@FundingID`, `BackOffice.CustomerToThirdPartyFundings.CID`, `BackOffice.CustomerToThirdPartyFundings.FundingID`

**Rules**:
- DELETE WHERE CID = @CID AND FundingID = @FundingID. Targets exactly one row (composite PK).
- If the pair does not exist, 0 rows deleted - silent no-op, no error.
- Counterpart to CustomerToThirdPartyFundingsAdd.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Internal Customer ID. First part of the composite key identifying which customer's relationship to remove. |
| 2 | @FundingID | INT | NO | - | CODE-BACKED | The funding instrument ID. Second part of the composite key - narrows the delete to the specific funding relationship, preserving other third-party relationships this customer may have. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID + @FundingID | BackOffice.CustomerToThirdPartyFundings | Deleter | DELETE target - removes the specific (CID, FundingID) pair by composite PK. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice AML workflow | EXEC | Caller | Called when a third-party funding relationship is revoked or corrected. No SQL-layer callers found. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CustomerToThirdPartyFundingsDelete (procedure)
└── BackOffice.CustomerToThirdPartyFundings (table) - DELETE target
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CustomerToThirdPartyFundings | Table | DELETE WHERE CID = @CID AND FundingID = @FundingID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice AML workflow | External | EXEC - removes third-party funding registration |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Composite key delete | Safety | Both CID AND FundingID required - prevents accidental deletion of all third-party relationships for a customer. |
| Silent no-op | Behavior | Missing pair returns 0 rows affected without error. |

---

## 8. Sample Queries

### 8.1 Remove a specific third-party funding relationship
```sql
EXEC BackOffice.CustomerToThirdPartyFundingsDelete @CID = 12345678, @FundingID = 98765
```

### 8.2 Verify the pair was removed
```sql
SELECT COUNT(*) AS Remaining
FROM BackOffice.CustomerToThirdPartyFundings WITH (NOLOCK)
WHERE CID = 12345678 AND FundingID = 98765
```

### 8.3 List remaining third-party relationships for a customer after delete
```sql
SELECT tpf.FundingID
FROM BackOffice.CustomerToThirdPartyFundings tpf WITH (NOLOCK)
WHERE tpf.CID = 12345678
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.2/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.CustomerToThirdPartyFundingsDelete | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.CustomerToThirdPartyFundingsDelete.sql*
