# BackOffice.CustomerSetRiskClassification

> Sets the risk classification level for a customer account, used by regional BackOffice teams to categorize customers by AML/compliance risk tier.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID - internal customer identifier |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.CustomerSetRiskClassification assigns a risk classification level to a customer account in `BackOffice.Customer.RiskClassificationID`. Risk classification is a compliance-driven categorization that groups customers by their AML (Anti-Money Laundering) or general financial risk profile - for example, whether enhanced scrutiny is required, whether the customer matches high-risk country profiles, or what review frequency the compliance team should apply.

The procedure is granted to regional BackOffice user groups across multiple geographies (China, Russia, Eastern Europe, UK, US), indicating it is a standard BackOffice operation performed by compliance agents in every region during customer review workflows.

The procedure wraps the UPDATE in an explicit transaction with full rollback on failure, ensuring the classification change is atomic. The change is audit-trailed by the existing UPDATE trigger on `BackOffice.Customer` which writes to `History.BackOfficeCustomer`.

---

## 2. Business Logic

### 2.1 Transactional Risk Classification Update

**What**: Single-column UPDATE wrapped in explicit transaction with error check and rollback.

**Columns/Parameters Involved**: `@CID`, `@RiskClassificationID`, `BackOffice.Customer.RiskClassificationID`

**Rules**:
- UPDATE fires unconditionally (no change-guard) - even if new value equals current value, the UPDATE executes.
- Wrapped in explicit BEGIN TRAN / COMMIT TRANSACTION - if @@ERROR != 0 after UPDATE, a RAISERROR(60000) is issued within the TRY block before COMMIT.
- CATCH block: rolls back transaction, re-raises error as RAISERROR(60000), returns 60000.
- Returns 0 on success.
- History recorded by BackOffice.Customer trigger (CustomerHistoryUpdate -> History.BackOfficeCustomer).

**Diagram**:
```
BEGIN TRAN
  UPDATE BackOffice.Customer SET RiskClassificationID = @RiskClassificationID WHERE CID = @CID
  IF @@ERROR != 0 -> RAISERROR(60000)
COMMIT
  -> RETURN 0

On any error:
ROLLBACK
  -> RAISERROR(60000) + RETURN 60000
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Internal Customer ID. Identifies the customer row in BackOffice.Customer to update. |
| 2 | @RiskClassificationID | INT | NO | - | CODE-BACKED | The new risk classification level to assign. Mapped to BackOffice.Customer.RiskClassificationID. Values represent AML/compliance risk tiers (e.g., standard, elevated, high-risk). Lookup table not identified in code; values defined by compliance configuration. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | BackOffice.Customer | Modifier | UPDATE target - sets RiskClassificationID for the customer's compliance profile row. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice regional agents (BOUserChina, BOUserChinaWrite, BOUserEastEU, BOUserRussia, BOUserUK, BOUserUSReadWrite) | EXEC | Permissions grantee | Regional BackOffice teams are explicitly granted EXEC rights - used during compliance review workflows across all active regions. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CustomerSetRiskClassification (procedure)
└── BackOffice.Customer (table) - UPDATE RiskClassificationID
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Customer | Table | UPDATE - sets RiskClassificationID = @RiskClassificationID WHERE CID = @CID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Regional BackOffice tooling (China, Russia, EastEU, UK, US) | External | EXEC - called during compliance risk assessment workflows |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Explicit transaction | Pattern | BEGIN TRAN / COMMIT / ROLLBACK ensures the UPDATE is atomic. Failure rolls back cleanly. |
| @@ERROR mid-TRY check | Pattern | Checks @@ERROR immediately after UPDATE within TRY block before COMMIT - catches deferred errors before they reach CATCH. |
| RAISERROR(60000) | Convention | Standard BackOffice error code 60000 used for all failure paths, consistent with other BackOffice procedures. |

---

## 8. Sample Queries

### 8.1 Assign a risk classification to a customer
```sql
EXEC BackOffice.CustomerSetRiskClassification @CID = 12345678, @RiskClassificationID = 3
```

### 8.2 Check current risk classification for a customer
```sql
SELECT
    bc.CID,
    cs.GCID,
    cs.UserName,
    bc.RiskClassificationID
FROM BackOffice.Customer bc WITH (NOLOCK)
JOIN Customer.CustomerStatic cs WITH (NOLOCK) ON cs.CID = bc.CID
WHERE bc.CID = 12345678
```

### 8.3 List customers by risk classification level
```sql
SELECT
    bc.RiskClassificationID,
    COUNT(*) AS CustomerCount
FROM BackOffice.Customer bc WITH (NOLOCK)
WHERE bc.RiskClassificationID IS NOT NULL
GROUP BY bc.RiskClassificationID
ORDER BY bc.RiskClassificationID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.1/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.CustomerSetRiskClassification | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.CustomerSetRiskClassification.sql*
