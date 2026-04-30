# BackOffice.DepositRollbackTracking

> Synonym that provides a BackOffice-schema alias for the Billing.DepositRollbackTracking table, allowing BackOffice stored procedures to query deposit rollback audit records without cross-schema qualification.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Synonym |
| **Key Identifier** | N/A (synonym - see target) |
| **Partition** | N/A |
| **Indexes** | N/A (defined on target table) |

---

## 1. Business Meaning

`BackOffice.DepositRollbackTracking` is a synonym that transparently redirects all reads to `[Billing].[DepositRollbackTracking]` - the authoritative audit log for deposit rollback operations (chargebacks, refunds, reversals, and cancellations). This alias allows BackOffice stored procedures to reference the table as `BackOffice.DepositRollbackTracking` without needing to qualify it as `Billing.DepositRollbackTracking`, keeping procedure logic schema-neutral.

The underlying `Billing.DepositRollbackTracking` table records every rollback event applied to a deposit: which deposit was affected, the new payment status, rollback amounts in both customer currency and USD, the responsible manager, the reason, and whether the rollback was subsequently canceled.

This synonym was introduced after the table was migrated from the BackOffice schema to the Billing schema in January 2022 (PAYIL-3480). The synonym preserves backward compatibility for BackOffice procedures that predated the migration without requiring all referencing code to be updated.

---

## 2. Business Logic

### 2.1 Cross-Schema Deposit Rollback Read Access

**What**: Transparently routes all BackOffice reads of deposit rollback records to the Billing schema table.

**Columns/Parameters Involved**: N/A (synonym - see Billing.DepositRollbackTracking)

**Rules**:
- Any `SELECT` against `BackOffice.DepositRollbackTracking` is transparently executed against `Billing.DepositRollbackTracking`.
- Consuming BackOffice procedures primarily filter by `DepositID` and `IsCanceled = 0` to find the active (non-canceled) rollback for a deposit.
- `RollbackID DESC` ordering retrieves the most recent rollback action for a deposit.
- The synonym is read-only in practice: deposit rollback writes are performed via `Billing.DepositRollback` (SP) which writes directly to `Billing.DepositRollbackTracking`.
- Prior to Jan 2022 (PAYIL-3480), `DepositRollbackTracking` lived in the BackOffice schema. The synonym preserves compatibility for procedures written before the migration.

**Diagram**:
```
BackOffice.BillingDepositsPCIVersion / GetRiskExposureReportPCIVersion
  |
  +-- SELECT BackOffice.DepositRollbackTracking WHERE IsCanceled = 0
        |
        v (resolved via synonym)
  SELECT Billing.DepositRollbackTracking WHERE IsCanceled = 0
        |
        v
  Returns rollback reason, amounts, and status for deposits in report
```

---

## 3. Data Overview

N/A for Synonym. Data lives in Billing.DepositRollbackTracking. Per the target table's wiki: 18,037 rows as of March 2026, active since January 2023.

---

## 4. Elements

N/A for Synonym. The column structure is defined on the target table `Billing.DepositRollbackTracking`. Key columns referenced by consuming BackOffice procedures:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RollbackID | bigint | NO | IDENTITY | CODE-BACKED | Primary key of the rollback record. Used for DESC ordering to find the latest rollback per deposit. References History.Credit.DepositRollbackID. |
| 2 | DepositID | int | NO | - | CODE-BACKED | The deposit this rollback action was applied to. FK to Billing.Deposit.DepositID. Used as the primary join key in consuming procedures. |
| 3 | IsCanceled | bit | NO | 0 | CODE-BACKED | Whether this rollback was subsequently canceled. All consuming procedures filter `IsCanceled = 0` to exclude canceled rollbacks. Set to 1 when a Cancel Rollback (PaymentStatusID=2) action is applied. |
| 4 | RollbackReasonID | int | YES | - | CODE-BACKED | Reason for the rollback. FK to Dictionary.DepositRollbackTypeReason.DepositRollbackTypeReasonID. Joined by consuming procedures to get the reason name string. |
| 5 | TotalRollbackAmountInCurrency | decimal | YES | - | CODE-BACKED | Cumulative rollback amount in the customer's deposit currency across all rollback actions for this deposit. Used in BackOffice.BillingDepositsPCIVersion report output. |
| 6 | TotalRollbackAmountInUSD | decimal | YES | - | CODE-BACKED | Cumulative rollback amount in USD. Used alongside TotalRollbackAmountInCurrency in report calculations. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (synonym target) | Billing.DepositRollbackTracking | Synonym | All DML against BackOffice.DepositRollbackTracking is redirected to this table. Table was originally in BackOffice schema before PAYIL-3480 migration (Jan 2022). |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.BillingDepositsPCIVersion | SELECT BackOffice.DepositRollbackTracking | Reader | Retrieves latest rollback reason and cumulative rollback amounts for deposits in billing report |
| BackOffice.BillingDepositsPCIVersion_Old | SELECT BackOffice.DepositRollbackTracking | Reader | Older version of billing deposits report - same rollback lookup pattern |
| BackOffice.GetRiskExposureReportPCIVersion | LEFT JOIN BackOffice.DepositRollbackTracking | Reader | Joins on History.Credit.DepositRollbackID to enrich risk exposure rows with rollback reason |
| BackOffice.GetRiskExposureReportPCIVersion_Old | LEFT JOIN BackOffice.DepositRollbackTracking | Reader | Older version of risk exposure report |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.DepositRollbackTracking (synonym)
+-- Billing.DepositRollbackTracking (table - same SQL Server instance, different schema)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.DepositRollbackTracking | Table (cross-schema) | Synonym target - all reads are redirected here |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.BillingDepositsPCIVersion | Stored Procedure | READER - retrieves rollback reasons and cumulative amounts for deposit report |
| BackOffice.BillingDepositsPCIVersion_Old | Stored Procedure | READER - older version, same pattern |
| BackOffice.GetRiskExposureReportPCIVersion | Stored Procedure | READER - left joins to get rollback reason for risk exposure rows |
| BackOffice.GetRiskExposureReportPCIVersion_Old | Stored Procedure | READER - older version of risk exposure report |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Synonym. Indexes exist on the target table in Billing schema.

### 7.2 Constraints

N/A for Synonym. Constraints are defined on the target table.

---

## 8. Sample Queries

### 8.1 Get the latest active rollback for a deposit

```sql
SELECT TOP 1
    bdrt.RollbackID,
    bdrt.DepositID,
    bdrt.TotalRollbackAmountInCurrency,
    bdrt.TotalRollbackAmountInUSD,
    ddrtr.Name AS RollbackReason
FROM BackOffice.DepositRollbackTracking bdrt WITH (NOLOCK)
LEFT JOIN Dictionary.DepositRollbackTypeReason ddrtr WITH (NOLOCK)
    ON ddrtr.DepositRollbackTypeReasonID = bdrt.RollbackReasonID
WHERE bdrt.DepositID = 12345
  AND bdrt.IsCanceled = 0
ORDER BY bdrt.RollbackID DESC;
```

### 8.2 Join rollback data to a risk exposure row via History.Credit

```sql
SELECT
    hcrd.DepositID,
    hcrd.DepositRollbackID,
    bodrt.RollbackReasonID,
    ddrtr.Name AS RollbackReason
FROM History.Credit hcrd WITH (NOLOCK)
LEFT JOIN BackOffice.DepositRollbackTracking bodrt WITH (NOLOCK)
    ON bodrt.RollbackID = hcrd.DepositRollbackID
LEFT JOIN Dictionary.DepositRollbackTypeReason ddrtr WITH (NOLOCK)
    ON ddrtr.DepositRollbackTypeReasonID = bodrt.RollbackReasonID
WHERE hcrd.CreditTypeID IN (11, 12, 16, 32);
```

### 8.3 Access via the target table directly (equivalent)

```sql
-- These two queries return identical results:
SELECT * FROM BackOffice.DepositRollbackTracking WITH (NOLOCK) WHERE DepositID = 99999;
SELECT * FROM Billing.DepositRollbackTracking WITH (NOLOCK) WHERE DepositID = 99999;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| PAYIL-3480 (Jira - inferred from code comments) | Jira | Migration of DepositRollbackTracking from BackOffice schema to Billing schema in January 2022. Synonym created to preserve backward compatibility for existing BackOffice procedures. |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 8/10, Logic: 9/10, Relationships: 9/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11 (DDL, Procedure Ref, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.DepositRollbackTracking | Type: Synonym | Source: etoro/etoro/BackOffice/Synonyms/BackOffice.DepositRollbackTracking.sql*
