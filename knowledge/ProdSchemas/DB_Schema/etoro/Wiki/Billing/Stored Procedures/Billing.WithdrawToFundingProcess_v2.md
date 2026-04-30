# Billing.WithdrawToFundingProcess_v2

> Identical to Billing.WithdrawToFundingProcess but without the @CalculateFTP / IsFTP output (removed 2025-04-02); the current version used by the Gen 2 payout service pipeline via PayoutProcess_FinalizeRequest_v2.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @WithdrawID + @FundingID + @ID (WithdrawToFunding PK) -> settlement |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.WithdrawToFundingProcess_v2` is the current-generation settlement procedure used by the Gen 2 payout service (`Billing.PayoutProcess_FinalizeRequest_v2`). It performs the same core settlement function as `Billing.WithdrawToFundingProcess` (v1): marks a payment leg as Processed, debits the customer's balance, updates the parent withdrawal status, cancels sibling legs, and triggers completion notifications.

The only functional difference from v1 is the **removal of the `@CalculateFTP` (First Time Payout) calculation** (Lior Tamam, 2025-04-02). The IsFTP flag is no longer computed or returned by this procedure. This was presumably moved to the application layer or retired.

For full business logic documentation, see [Billing.WithdrawToFundingProcess](Billing.WithdrawToFundingProcess.md) - all sections apply identically to this v2 procedure, except for the differences documented in Section 2.

---

## 2. Differences from Billing.WithdrawToFundingProcess (v1)

| Aspect | v1 (WithdrawToFundingProcess) | v2 (WithdrawToFundingProcess_v2) |
|--------|-------------------------------|-----------------------------------|
| `@CalculateFTP BIT = NULL` parameter | Present - computes and returns IsFtp result set | Removed (Lior Tamam 2025-04-02) |
| IsFTP result set | Returns `SELECT IsFtp BIT` when @CalculateFTP=1 | Not present |
| SetBalance failure response | ROLLBACK + RETURN @Answer (no RAISERROR) | ROLLBACK + RAISERROR(60025) + RETURN @Answer |
| Outer CATCH | `THROW 60000, @ErrorMessage, 1` (specific error code) | `THROW` (re-throws original exception unchanged) |
| Caller | PayoutProcess_FinalizeRequest, WithdrawToFundingProcessBatch, WithdrawToFundingProcessForBatch | PayoutProcess_FinalizeRequest_v2 |

All other logic - validation gates, deadlock-avoidance phantom UPDATEs, @CreditAmount calculation, WTF status 3 via UpdateWithdraw2Funding, comprehensive history INSERT, Customer.SetBalance, over-payment guard, completion vs. partial branching, sibling leg cancellation, email notification - is identical to v1.

---

## 3. Business Logic

See [Billing.WithdrawToFundingProcess - Section 2](Billing.WithdrawToFundingProcess.md#2-business-logic) for the full logic. All rules apply identically except:

### 3.1 SetBalance Failure Handling (v2-specific)

In v2, when `Customer.SetBalance` returns a non-zero @Answer:
```sql
Rollback Tran;
RAISERROR(60025,16,1,'SetBalance returned error');
RETURN @Answer;
```
In v1, only `Rollback Tran; RETURN @Answer` - no explicit RAISERROR is raised to the caller.

### 3.2 IsFTP: Removed

The FTP calculation block from v1 (lines 683-706 in v1 DDL) is entirely absent from v2. The `@CalculateFTP` parameter does not exist.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WithdrawID | int | NO | - | CODE-BACKED | See WithdrawToFundingProcess. |
| 2 | @FundingID | int | NO | - | CODE-BACKED | See WithdrawToFundingProcess. |
| 3 | @ManagerID | int | NO | - | CODE-BACKED | See WithdrawToFundingProcess. |
| 4 | @Remark | varchar(255) | YES | NULL | CODE-BACKED | See WithdrawToFundingProcess. |
| 5 | @ID | int | NO | - | CODE-BACKED | See WithdrawToFundingProcess. |
| 6 | @VerificationCode | varchar(50) | YES | NULL | CODE-BACKED | See WithdrawToFundingProcess. |
| 7 | @ProcessorValueDate | datetime | YES | NULL | CODE-BACKED | See WithdrawToFundingProcess. Defaults to GETUTCDATE() if NULL. |
| 8 | @SessionID | bigint | YES | NULL | CODE-BACKED | See WithdrawToFundingProcess. |
| 9 | @VendorCode | nvarchar(250) | YES | NULL | CODE-BACKED | See WithdrawToFundingProcess. |
| 10 | @MID | nvarchar(250) | YES | NULL | CODE-BACKED | See WithdrawToFundingProcess. Resolved to ProtocolMIDSettingsID via ParameterID=52. |
| 11 | @RequestExecuteEntryMethodId | int | YES | NULL | CODE-BACKED | See WithdrawToFundingProcess. |
| 12 | @MoveMoneyReasonID | int | YES | NULL | CODE-BACKED | See WithdrawToFundingProcess. Auto-overridden to 5 (local currency) or 6 (FlowID=3). |

Note: `@CalculateFTP` from v1 is NOT present in v2.

---

## 5. Relationships

### 5.1 References To (this object points to)

Identical to `Billing.WithdrawToFundingProcess` v1. See [Section 5.1](Billing.WithdrawToFundingProcess.md#51-references-to-this-object-points-to).

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.PayoutProcess_FinalizeRequest_v2 | EXEC | Caller | Gen 2 payout finalization pipeline - sole caller in SSDT |

---

## 6. Dependencies

### 6.0 Dependency Chain

Identical to `Billing.WithdrawToFundingProcess` v1. See [Section 6.0](Billing.WithdrawToFundingProcess.md#60-dependency-chain).

### 6.1 Objects This Depends On

Identical to v1. See [Billing.WithdrawToFundingProcess Section 6.1](Billing.WithdrawToFundingProcess.md#61-objects-this-depends-on).

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.PayoutProcess_FinalizeRequest_v2 | Procedure | Sole SSDT caller - Gen 2 payout finalization |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

Identical to v1 except:

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| No @CalculateFTP | Design | IsFTP calculation entirely removed. @CalculateFTP parameter does not exist. |
| SetBalance failure RAISERROR | Design | v2 explicitly raises RAISERROR(60025) "SetBalance returned error" before RETURN - v1 only does ROLLBACK+RETURN |
| Outer CATCH: bare THROW | Design | v2 uses `THROW` (re-throws original exception with original error code) vs. v1's `THROW 60000, @ErrorMessage, 1` |

---

## 8. Sample Queries

### 8.1 Process a settlement in the Gen 2 pipeline

```sql
EXEC Billing.WithdrawToFundingProcess_v2
    @WithdrawID = 1234567,
    @FundingID = 987654,
    @ManagerID = 42,
    @Remark = 'Gen2 provider confirmed settlement',
    @ID = 9876543,
    @VerificationCode = 'AUTH-GEN2-001',
    @MID = 'VISA_MID_001',
    @ProcessorValueDate = '2026-03-18 10:00:00';
-- No IsFtp result set (removed in v2)
```

### 8.2 Check parent withdrawal status after settlement

```sql
SELECT
    w.WithdrawID,
    w.CashoutStatusID,    -- 3=Processed, 5=Partially Processed
    w.Amount,
    w.ModificationDate
FROM Billing.Withdraw w WITH (NOLOCK)
WHERE w.WithdrawID = 1234567;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| Payout Service Gen 2.0 - Changes (Confluence /spaces/MG/pages/1218937110) | Confluence | This SP is the settlement procedure for the Gen 2 payout pipeline. v2 is called by PayoutProcess_FinalizeRequest_v2 which is invoked by the PayoutService via Azure Service Bus (prod-payout-requests queue). |
| Same Jira tickets as v1 | Jira | DBA-648, PAYUS-1560, MIMOPS-4536, PAYIL-4186, MIMOPSA-12732 - all reflected in DDL comments. See WithdrawToFundingProcess documentation. |
| Lior Tamam 2025-04-02 (DDL comment) | Code | @CalculateFTP / IsFTP calculation removed from v2. No Jira ticket referenced in DDL. |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 10/10, Logic: 9.0/10, Relationships: 8.5/10, Sources: 7.5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 1 Confluence + 0 Jira (same tickets as v1 in DDL) | Procedures: 1 caller analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.WithdrawToFundingProcess_v2 | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.WithdrawToFundingProcess_v2.sql*
