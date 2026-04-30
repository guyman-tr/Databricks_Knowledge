# Billing.FundingCustomerRisk_Add

> Idempotent insert of a customer-funding risk status record - adds a (CID, FundingID, RiskStatusID) row to Billing.FundingCustomerRisk only if the exact combination does not already exist.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | INSERT INTO Billing.FundingCustomerRisk ... EXCEPT (duplicate guard) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.FundingCustomerRisk_Add` records a risk status association between a customer, a funding instrument, and a specific risk classification. It is the base writer for `Billing.FundingCustomerRisk` and is called by `FundingCustomerRisk_AddByDeposit` (resolves FundingID from deposit) and `FundingCustomerRisk_AddByWithdraw` (resolves FundingID from withdrawal).

The EXCEPT-based pattern makes the insert idempotent: if the exact (CID, FundingID, RiskStatusID) triple already exists, the INSERT is a no-op. This prevents duplicate risk classification records when risk events fire multiple times.

---

## 2. Business Logic

**Rules**:
- `INSERT INTO Billing.FundingCustomerRisk (CID, FundingID, RiskStatusID) SELECT @CID, @FundingID, @RiskStatusID EXCEPT SELECT CID, FundingID, RiskStatusID FROM Billing.FundingCustomerRisk WHERE CID=@CID AND FundingID=@FundingID AND RiskStatusID=@RiskStatusID`.
- No transaction, no audit trail, no error handling beyond SQL auto-rollback.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. FK to Billing.FundingCustomerRisk.CID. Part of the unique risk classification key. |
| 2 | @FundingID | INT | NO | - | CODE-BACKED | Funding instrument ID. FK to Billing.Funding.FundingID. Part of the unique risk classification key. |
| 3 | @RiskStatusID | INT | NO | - | CODE-BACKED | Risk status to associate with this customer-funding pair. FK to a risk status lookup. Part of the unique triple for the EXCEPT guard. |

---

## 5. Relationships

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (CID, FundingID, RiskStatusID) | Billing.FundingCustomerRisk | WRITER (INSERT, idempotent) | Inserts new risk classification if not already present. |

---

## 6. Dependencies

```
Billing.FundingCustomerRisk_Add (procedure)
+-- Billing.FundingCustomerRisk (table)
```

---

## 7. Technical Details

**EXCEPT-based idempotency**: The `INSERT ... EXCEPT SELECT` pattern is SQL Server's clean way to do "insert if not exists" without race conditions for a pure INSERT. Simpler than `IF NOT EXISTS` and avoids the UPSERT overhead for this pattern.

---

## 8. Sample Queries

```sql
EXEC [Billing].[FundingCustomerRisk_Add]
    @CID = 12345,
    @FundingID = 67890,
    @RiskStatusID = 2;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.2/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.FundingCustomerRisk_Add | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.FundingCustomerRisk_Add.sql*
