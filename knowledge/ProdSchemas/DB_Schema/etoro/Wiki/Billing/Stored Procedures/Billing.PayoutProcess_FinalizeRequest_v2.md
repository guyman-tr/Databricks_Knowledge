# Billing.PayoutProcess_FinalizeRequest_v2

> V2 variant of PayoutProcess_FinalizeRequest for the new payout service that excludes fee-to-provider (FTP) calculation; identical logic to v1 but delegates to WithdrawToFundingProcess_v2 instead.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @WithdrawToFundingID - the payout record being finalized |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.PayoutProcess_FinalizeRequest_v2` is a 2025 variant of `Billing.PayoutProcess_FinalizeRequest` created specifically for the new payout service that does not perform fee-to-provider (FTP) calculations during payment processing. It is functionally identical to v1 except for two differences: it does not accept a `@CalculateFTP` parameter, and it calls `Billing.WithdrawToFundingProcess_v2` (which skips FTP logic) instead of `Billing.WithdrawToFundingProcess`.

The procedure finalizes a payout record the same way: marks the `Billing.PayoutProcess` entry as Processed (CashoutStatusID=3), resolves a VerificationCode, determines if the execution is system-driven or manager-driven, and delegates the actual payment disbursement to the v2 processing procedure - all within a deadlock-safe transactional wrapper.

Both payout service roles (`PayoutUser`) are granted EXECUTE on this procedure. The choice between v1 and v2 is made by the calling service based on which FTP calculation behaviour is needed: v2 is for payment flows where FTP is handled separately or not at all. Created April 2025 by Lior Tamam.

---

## 2. Business Logic

### 2.1 Differences from v1 (PayoutProcess_FinalizeRequest)

**What**: V2 skips FTP calculation and targets the updated payment processing procedure.

**Rules**:
- v2 does NOT have the `@CalculateFTP BIT` parameter. FTP (fee-to-provider) is never computed in this flow.
- v2 calls `Billing.WithdrawToFundingProcess_v2` instead of `Billing.WithdrawToFundingProcess`. The v2 processing procedure excludes FTP calculation per its design.
- All other logic is identical to v1: PayoutProcess UPDATE, ManagerID->RequestExecuteEntryMethodId derivation, VerificationCode fallback, transaction handling.

**Diagram**:
```
v1: PayoutProcess_FinalizeRequest      v2: PayoutProcess_FinalizeRequest_v2
  Has @CalculateFTP parameter    vs.     No @CalculateFTP parameter
  Calls WithdrawToFundingProcess         Calls WithdrawToFundingProcess_v2
  (includes FTP if @CalculateFTP=1)      (always skips FTP)
```

### 2.2 PayoutProcess Status Update (identical to v1)

**What**: Marks the payout record as successfully finalized.

**Rules**:
- Updates `Billing.PayoutProcess` SET CashoutStatusID=3, ExtReferenceCode=@ExtReferenceCode, InProcess=0 WHERE WithdrawToFundingID=@WithdrawToFundingID AND CashoutStatusID NOT IN (3).
- Guard `NOT IN (3)` prevents double-processing.
- See [Billing.PayoutProcess_FinalizeRequest](Billing.PayoutProcess_FinalizeRequest.md) Section 2 for the full logic description (shared with v2).

### 2.3 Execution Actor Classification (identical to v1)

**Rules**:
- @ManagerID = 0 -> @RequestExecuteEntryMethodId = 1 (system).
- @ManagerID > 0 -> @RequestExecuteEntryMethodId = 2 (human manager).

### 2.4 VerificationCode Fallback (identical to v1)

**Rules**:
- `@VerificationCode = ISNULL(@VerificationCode, @ExtReferenceCode)` - falls back to ExtReferenceCode if not provided.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WithdrawToFundingID | int | NO | - | CODE-BACKED | The payout record identifier. References `Billing.WithdrawToFunding.ID` and `Billing.PayoutProcess.WithdrawToFundingID`. Identical to v1. |
| 2 | @Remark | varchar(255) | YES | NULL | CODE-BACKED | Free-text remark passed through to `Billing.WithdrawToFundingProcess_v2`. Identical to v1. |
| 3 | @ManagerID | int | NO | - | VERIFIED | Actor initiating finalization. 0=system (RequestExecuteEntryMethodId=1), >0=manager (RequestExecuteEntryMethodId=2). Identical to v1. |
| 4 | @ExtReferenceCode | varchar(50) | NO | - | CODE-BACKED | External payment provider reference code. Stored in PayoutProcess.ExtReferenceCode. Doubles as @VerificationCode fallback. Identical to v1. |
| 5 | @VerificationCode | varchar(50) | YES | NULL | VERIFIED | Verification token. Falls back to @ExtReferenceCode if NULL (`ISNULL(@VerificationCode, @ExtReferenceCode)`). Identical to v1. Added PAYI-6071. |

*Note: v2 does NOT have @CalculateFTP - this is the key structural difference from v1.*

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @WithdrawToFundingID | [Billing.WithdrawToFunding](../Tables/Billing.WithdrawToFunding.md) | Read (SELECT) | Looks up WithdrawID and FundingID. Identical to v1. |
| @WithdrawToFundingID | [Billing.PayoutProcess](../Tables/Billing.PayoutProcess.md) | Write (UPDATE) | Sets CashoutStatusID=3, ExtReferenceCode, InProcess=0. Identical to v1. |
| @WithdrawID, @FundingID, ... | Billing.WithdrawToFundingProcess_v2 | EXEC (callee) | V2 of payment disbursement (no FTP). Pending documentation (future batch). |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PayoutUser (db role) | - | EXEC | Payout service application user - calls this for flows that skip FTP calculation. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.PayoutProcess_FinalizeRequest_v2 (procedure)
├── Billing.WithdrawToFunding (table) - lookup for WithdrawID/FundingID
├── Billing.PayoutProcess (table) - update to CashoutStatusID=3
└── Billing.WithdrawToFundingProcess_v2 (procedure) - payment processing (no FTP)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [Billing.WithdrawToFunding](../Tables/Billing.WithdrawToFunding.md) | Table | SELECT - looks up WithdrawID and FundingID by ID=@WithdrawToFundingID. |
| [Billing.PayoutProcess](../Tables/Billing.PayoutProcess.md) | Table | UPDATE - sets CashoutStatusID=3, ExtReferenceCode, InProcess=0. |
| Billing.WithdrawToFundingProcess_v2 | Stored Procedure | EXEC - full payment execution without FTP. Pending documentation (future batch). |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| PayoutUser application role | Application | New payout service calls this for FTP-excluded payment flows. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. Same index usage pattern as v1. See [Billing.PayoutProcess_FinalizeRequest](Billing.PayoutProcess_FinalizeRequest.md) Section 7.1.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Finalize a payout via v2 (no FTP calculation)

```sql
-- Automated payout service (ManagerID=0), no FTP
EXEC Billing.PayoutProcess_FinalizeRequest_v2
    @WithdrawToFundingID = 12345678,
    @ManagerID           = 0,
    @ExtReferenceCode    = 'PROVREF-ABC123',
    @Remark              = NULL,
    @VerificationCode    = NULL;
```

### 8.2 Finalize by manager via v2

```sql
EXEC Billing.PayoutProcess_FinalizeRequest_v2
    @WithdrawToFundingID = 12345678,
    @ManagerID           = 999,
    @ExtReferenceCode    = 'PROVREF-DEF456',
    @Remark              = 'Manual approval - FTP handled separately',
    @VerificationCode    = 'VERIF-XYZ789';
```

### 8.3 Find payout records processed via v2 (no FTP indicator)

```sql
-- Records processed by the new payout service (PayoutGeneration=1)
SELECT
    pp.ProcessID,
    pp.WithdrawToFundingID,
    pp.CashoutStatusID,
    pp.ExtReferenceCode,
    pp.PayoutGeneration
FROM Billing.PayoutProcess pp WITH (NOLOCK)
WHERE pp.CashoutStatusID = 3
  AND pp.PayoutGeneration = 1  -- new payout service
ORDER BY pp.ProcessID DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| Payout Service Recovery Design | Confluence | Referenced in search - payout service architecture context. Page content not retrievable via API. |
| Payout Design | Confluence | Referenced in search - payout service flow design. Page content not retrievable via API. |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 applicable*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 1 callee (WithdrawToFundingProcess_v2) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.PayoutProcess_FinalizeRequest_v2 | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.PayoutProcess_FinalizeRequest_v2.sql*
