# BackOffice.Suitability

> Whitelist table of customer IDs who have passed the regulatory suitability assessment, used to gate access to complex financial instruments.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table |
| **Key Identifier** | PK_Suitability: CID (CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (clustered PK) |

---

## 1. Business Meaning

`BackOffice.Suitability` is a regulatory compliance whitelist. Under MiFID II and equivalent frameworks, brokers must assess whether a customer understands the risks of complex instruments (CFDs, leveraged products) before granting access. A customer who passes the suitability test has their CID added to this table. Downstream systems check membership in this table to determine whether a customer may trade restricted product types.

The table's design is intentionally minimal - it is a set of CIDs with no metadata. The sole question it answers is: "Has this customer been assessed as suitable?" The absence of a row means the customer has not passed (or has had their suitability revoked). Because any non-null CID in this table implies suitability, there is no status column needed - membership equals approval.

Data is written by `BackOffice.SuitabilityAdd` and removed by `BackOffice.SuitabilityDelete`. The `Bulk_UpdateRiskUserInfoRemote` procedure reads `SuitabilityTestStatusID` from a bulk update payload and inserts/removes CIDs from this table accordingly, supporting batch KYC/compliance updates.

---

## 2. Business Logic

### 2.1 Suitability as a Binary Gate

**What**: CID presence in this table is a boolean pass/fail gate for instrument access.

**Columns/Parameters Involved**: `CID`

**Rules**:
- A customer is "suitable" if and only if their CID appears in this table.
- No expiry, no score - suitability is a binary state managed externally.
- Removal (`SuitabilityDelete`) revokes suitability; re-insertion restores it.
- The clustered PK on CID guarantees uniqueness (one row per customer).

**Diagram**:
```
Customer completes suitability questionnaire
    -> Back-office reviews assessment
    -> PASS: SuitabilityAdd(@CID) -> INSERT INTO BackOffice.Suitability (CID)
    -> FAIL: CID not present (or SuitabilityDelete removes existing row)

Trading system: IF CID IN (SELECT CID FROM BackOffice.Suitability) -> ALLOW complex instruments
```

### 2.2 Bulk Risk Update Integration

**What**: Suitability can be set/cleared as part of bulk KYC/risk profile updates.

**Columns/Parameters Involved**: `CID` (via `Bulk_UpdateRiskUserInfoRemote`)

**Rules**:
- `Bulk_UpdateRiskUserInfoRemote` accepts a `SuitabilityTestStatusID` field per customer.
- If `SuitabilityTestStatusID` indicates pass, a row is upserted into this table.
- If it indicates fail/reset, the row is removed.
- This enables mass suitability updates (e.g., after a regulatory rule change affecting a cohort of customers).

---

## 3. Data Overview

Table contains one row per suitable customer. No representative sample can be shown (CIDs are PII). The table is a pure set - exactly one column, one constraint, no metadata.

| Column | Value |
|--------|-------|
| Total distinct customers | (live count - varies) |
| Row structure | CID only - no timestamps, no status flags |
| Write pattern | Individual: SuitabilityAdd/Delete; Bulk: Bulk_UpdateRiskUserInfoRemote |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | CODE-BACKED | Customer ID of a customer who has passed the regulatory suitability assessment. Clustered PK - guarantees uniqueness. References Customer.Customer.CID. Presence = suitable; absence = not suitable. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.Customer.CID | Implicit | The customer assessed as suitable |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.SuitabilityAdd | INSERT | Writer | Adds a CID when a customer passes suitability |
| BackOffice.SuitabilityDelete | DELETE | Writer | Removes a CID when suitability is revoked |
| BackOffice.Bulk_UpdateRiskUserInfoRemote | INSERT/DELETE | Bulk Writer | Mass suitability updates as part of KYC processing |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies (leaf table).

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.SuitabilityAdd | Stored Procedure | Inserts CID into this whitelist |
| BackOffice.SuitabilityDelete | Stored Procedure | Removes CID from this whitelist |
| BackOffice.Bulk_UpdateRiskUserInfoRemote | Stored Procedure | Bulk inserts/removes based on SuitabilityTestStatusID |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Suitability | CLUSTERED PK | CID ASC | - | - | Active |

### 7.2 Constraints

No constraints beyond the PK.

---

## 8. Sample Queries

### 8.1 Check if a specific customer is suitable

```sql
SELECT CASE WHEN EXISTS (
    SELECT 1 FROM BackOffice.Suitability WITH (NOLOCK) WHERE CID = 99999
) THEN 'Suitable' ELSE 'Not Suitable' END AS SuitabilityStatus;
```

### 8.2 Count of suitable customers

```sql
SELECT COUNT(CID) AS SuitableCustomers
FROM BackOffice.Suitability WITH (NOLOCK);
```

### 8.3 Add/remove suitability via stored procedures

```sql
-- Grant suitability
EXEC BackOffice.SuitabilityAdd @CID = 99999;

-- Revoke suitability
EXEC BackOffice.SuitabilityDelete @CID = 99999;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11 (DDL, Procedure Ref, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.Suitability | Type: Table | Source: etoro/etoro/BackOffice/Tables/BackOffice.Suitability.sql*
