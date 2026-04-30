# Billing.FundingCustomerRisk_AddByWithdraw

> Convenience wrapper around FundingCustomerRisk_Add that resolves the FundingID from a withdrawal ID before inserting the customer risk classification - called when the risk event is triggered by a withdrawal.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @WithdrawID -> FundingID -> EXEC Billing.FundingCustomerRisk_Add |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.FundingCustomerRisk_AddByWithdraw` mirrors `FundingCustomerRisk_AddByDeposit` but resolves the FundingID from a withdrawal record. Used when a risk event fires in the context of a withdrawal operation.

---

## 2. Business Logic

**Rules**:
- `SELECT @FundingID = FundingID FROM Billing.Withdraw WHERE WithdrawID = @WithdrawID`.
- If @FundingID IS NULL -> RAISERROR('Could not find FundingID for Withdraw that was passed', 16, 1).
- `EXEC Billing.FundingCustomerRisk_Add @CID, @FundingID, @RiskStatusID`.
- TRY/CATCH with THROW re-raise.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. Passed directly to FundingCustomerRisk_Add. |
| 2 | @WithdrawID | INT | NO | - | CODE-BACKED | Withdrawal ID. Used to look up FundingID from Billing.Withdraw. Error if not found or FundingID is NULL. |
| 3 | @RiskStatusID | INT | NO | - | CODE-BACKED | Risk status. Passed directly to FundingCustomerRisk_Add. |

---

## 5. Relationships

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @WithdrawID | Billing.Withdraw | READ | Resolves FundingID from the withdrawal record. |
| @CID, FundingID, @RiskStatusID | Billing.FundingCustomerRisk_Add | EXEC (callee) | Delegates to the base SP for idempotent insert. |

---

## 6. Dependencies

```
Billing.FundingCustomerRisk_AddByWithdraw (procedure)
+-- Billing.Withdraw (table) [FundingID lookup]
+-- Billing.FundingCustomerRisk_Add (procedure) [EXEC]
  +-- Billing.FundingCustomerRisk (table)
```

---

## 8. Sample Queries

```sql
EXEC [Billing].[FundingCustomerRisk_AddByWithdraw]
    @CID = 12345,
    @WithdrawID = 55443322,
    @RiskStatusID = 2;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.3/10 (Elements: 9/10, Logic: 8/10, Relationships: 9/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.FundingCustomerRisk_AddByWithdraw | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.FundingCustomerRisk_AddByWithdraw.sql*
