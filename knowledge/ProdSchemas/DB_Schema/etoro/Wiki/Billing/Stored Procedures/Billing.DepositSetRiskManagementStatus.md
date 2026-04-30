# Billing.DepositSetRiskManagementStatus

> Single-column updater that sets the RiskManagementStatusID on a specific deposit - used by risk management workflows to flag or clear deposits under review.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | UPDATE Billing.Deposit.RiskManagementStatusID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.DepositSetRiskManagementStatus` is a minimal SP that updates the `RiskManagementStatusID` column on a single deposit. It is called by risk management processes to flag deposits for review, approve them through risk checks, or clear holds. The `RiskManagementStatusID` column in `Billing.Deposit` tracks whether a deposit is under risk review, approved by risk, or in another risk-management state (lookup: `Dictionary.RiskManagementStatus`).

The SP has no transaction management, no audit trail insertion, and no validation - it is a pure single-column UPDATE. Risk status changes are not tracked in `History.DepositAction`. This makes it a lightweight setter used in automated pipelines where the calling system handles audit logging externally.

---

## 2. Business Logic

### 2.1 Risk Status Update

**What**: Sets RiskManagementStatusID to the requested value for the deposit.

**Rules**:
- `UPDATE Billing.Deposit SET RiskManagementStatusID = @RiskManagementStatusID WHERE DepositID = @DepositID`.
- No validation that @RiskManagementStatusID is a valid Dictionary.RiskManagementStatus value.
- No check that @DepositID exists (silent no-op if not found).
- `RETURN @@ERROR` - returns 0 on success, non-zero SQL error code on failure.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DepositID | INTEGER | NO | - | CODE-BACKED | PK of the deposit to update. FK to Billing.Deposit.DepositID. No existence validation - silent no-op if not found. |
| 2 | @RiskManagementStatusID | INTEGER | NO | - | CODE-BACKED | New risk management status. FK to Dictionary.RiskManagementStatus.RiskManagementStatusID (not validated). Common values: 0 or NULL = no hold; other values = specific risk review states. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @DepositID | Billing.Deposit | MODIFIER (UPDATE) | Sets RiskManagementStatusID column. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Risk management service / back-office | @DepositID | EXEC | Called to update risk status as deposits progress through review workflows. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.DepositSetRiskManagementStatus (procedure)
+-- Billing.Deposit (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | UPDATE target - RiskManagementStatusID column. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SSDT repo. | - | - |

---

## 7. Technical Details

**No transaction**: Single UPDATE without explicit transaction management (auto-commit behavior).

**No audit trail**: Unlike most deposit-modifying SPs, this does NOT insert into `History.DepositAction`. Risk status changes are not directly auditable via the deposit action history.

**RETURN @@ERROR**: Returns the raw SQL error code. Callers should check the return value for non-zero to detect failure.

---

## 8. Sample Queries

### 8.1 Set a deposit to under risk review

```sql
EXEC [Billing].[DepositSetRiskManagementStatus]
    @DepositID = 12345678,
    @RiskManagementStatusID = 1;  -- specific value from Dictionary.RiskManagementStatus
```

### 8.2 Clear risk hold on a deposit

```sql
EXEC [Billing].[DepositSetRiskManagementStatus]
    @DepositID = 12345678,
    @RiskManagementStatusID = 0;
```

### 8.3 Check valid RiskManagementStatusID values

```sql
SELECT RiskManagementStatusID, Name
FROM [Dictionary].[RiskManagementStatus] WITH (NOLOCK)
ORDER BY RiskManagementStatusID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.2/10 (Elements: 9/10, Logic: 8/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.DepositSetRiskManagementStatus | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.DepositSetRiskManagementStatus.sql*
