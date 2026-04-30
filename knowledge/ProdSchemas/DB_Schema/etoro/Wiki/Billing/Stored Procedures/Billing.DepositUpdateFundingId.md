# Billing.DepositUpdateFundingId

> Sets the FundingID on a specific deposit - a corrective/migration utility for re-linking a deposit to the correct funding instrument.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | UPDATE Billing.Deposit.FundingID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.DepositUpdateFundingId` (created PAYIL-1371, 10/09/2020, Elrom Behar) is a minimal SP that updates the `FundingID` column on a specific deposit. This is used for corrective operations when a deposit was linked to the wrong funding instrument (e.g., wrong card or bank account), or during data migration when funding records are reorganized.

No audit trail is created, no validation is performed, and no transaction is used. It is a simple corrective utility.

---

## 2. Business Logic

### 2.1 FundingID Update

**Rules**:
- `UPDATE Billing.Deposit SET FundingID = @FundingID WHERE DepositID = @DepositID`.
- No existence validation. No FundingID FK validation. RETURN 0.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FundingID | INTEGER | NO | - | CODE-BACKED | New FundingID to assign. FK to Billing.Funding.FundingID (not validated). The funding instrument (card/bank account) to link this deposit to. |
| 2 | @DepositID | INTEGER | NO | - | CODE-BACKED | PK of the deposit to update. FK to Billing.Deposit.DepositID. No existence check - silent no-op if not found. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @DepositID | Billing.Deposit | MODIFIER (UPDATE) | Sets FundingID column. |

---

## 6. Dependencies

```
Billing.DepositUpdateFundingId (procedure)
+-- Billing.Deposit (table)
```

---

## 7. Technical Details

No transaction, no audit trail. Created PAYIL-1371 (10/09/2020).

---

## 8. Sample Queries

```sql
EXEC [Billing].[DepositUpdateFundingId]
    @FundingID = 67890,
    @DepositID = 12345678;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.0/10 (Elements: 9/10, Logic: 8/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.DepositUpdateFundingId | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.DepositUpdateFundingId.sql*
