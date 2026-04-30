# Billing.InsertWithdraw2Funding

> The primary writer for Billing.WithdrawToFunding; inserts a new withdrawal payment leg record from a table-valued parameter, applies ISNULL defaults for optional fields, captures the generated ID via OUTPUT, and simultaneously logs the action to History.WithdrawToFundingAction. Returns the new WTF ID.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns new Billing.WithdrawToFunding.ID via RETURN |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.InsertWithdraw2Funding` is the authoritative write procedure for creating withdrawal payment legs in the eToro withdrawal pipeline. A "WithdrawToFunding" (WTF) record represents the execution leg connecting a withdrawal request (`Billing.Withdraw`) to a specific payment instrument (`Billing.Funding`) - it tracks the actual payment processing status, routing decisions, exchange rates, and provider responses for that leg.

This procedure is the single entry point for creating new WTF records (as part of the DBA-648 TVP refactoring pattern). Instead of direct INSERT calls, all callers populate a `Billing.TBL_Withdraw2Funding` table-valued parameter and call this procedure. This design centralizes the dual-write logic that ensures every WTF creation is simultaneously recorded in `History.WithdrawToFundingAction` for a complete audit trail.

Data flows: the payment processing service determines how to route a withdrawal (which depot, which MID, which currency, what exchange rate), populates the TVP, and calls this procedure. The procedure returns the new WTF ID so the caller can track the created record. The history entry is written atomically with the main record using the OUTPUT-captured data plus additional action context (Remark, CashoutActionStatusID) from the input TVP. History was added: SchemeId (PAYUS-3900, Oct 2021) and ResponseID (PAYUA-2822, Oct 2021).

---

## 2. Business Logic

### 2.1 TVP-Driven Insert with Selective ISNULL Defaulting

**What**: The procedure reads from the input TVP and applies ISNULL defaults for 5 optional fields before inserting into Billing.WithdrawToFunding.

**Columns/Parameters Involved**: `@Widraw2F`, `MatchStatusID`, `AutoPaymentStartDate`, `ProtocolMIDSettingsID`, `CreationDate`, `MerchantAccountID`

**Rules**:
- `MatchStatusID`: ISNULL(Src.MatchStatusID, 0) - defaults to 0 (unmatched) if not provided
- `AutoPaymentStartDate`: ISNULL(Src.AutoPaymentStartDate, GETUTCDATE()) - defaults to now
- `ProtocolMIDSettingsID`: ISNULL(Src.ProtocolMIDSettingsID, 0) - defaults to 0 (no specific MID)
- `CreationDate`: ISNULL(Src.CreationDate, GETUTCDATE()) - defaults to now; NULL for older records
- `MerchantAccountID`: ISNULL(Src.MerchantAccountID, 0) - defaults to 0 (no specific merchant account)
- All other columns are taken as-is from the TVP (no transformation)
- The INSERT uses a SELECT from the TVP, supporting batch inserts (multiple rows in one call)

### 2.2 Three-Phase Write: Live Table + OUTPUT Capture + History

**What**: The procedure performs three sequential data operations, using an intermediate OUTPUT variable to bridge the INSERT into the history write.

**Columns/Parameters Involved**: All WTF columns + `Remark`, `CashoutActionStatusID` (from TVP for history)

**Rules**:
- Phase 1: INSERT INTO Billing.WithdrawToFunding from @Widraw2F SELECT - creates the live record
- Phase 2: OUTPUT INSERTED.* INTO @out - captures all inserted columns including the IDENTITY-generated ID into a local TBL_Withdraw2Funding variable
- Phase 3: INSERT INTO History.WithdrawToFundingAction from JOIN of @out (has the new ID) with @Widraw2F (has Remark and CashoutActionStatusID not captured in OUTPUT) - writes the initial action history entry
- The JOIN is ON O.WithdrawID = W.WithdrawID AND O.FundingID = W.FundingID (composite key)
- History captures: the new WTF ID (as BW2F_ID), all financial fields, CashoutActionStatusID and Remark from the input TVP

**Diagram**:
```
@Widraw2F (TVP input, 31 columns)
        |
        v
Phase 1: INSERT INTO Billing.WithdrawToFunding
         (ISNULL defaults for 5 fields)
                |
                | OUTPUT INSERTED.*
                v
        @out (local TBL_Withdraw2Funding - captures new ID)
                |
                | JOIN with @Widraw2F (to get Remark, CashoutActionStatusID)
                v
Phase 3: INSERT INTO History.WithdrawToFundingAction
         (full WTF fields + Remark + CashoutActionStatusID)
                |
                v
RETURN: SELECT TOP(1) ID FROM @out  -> new WTF ID returned to caller
```

### 2.3 ID Return Pattern

**What**: The procedure returns the newly created WTF ID via RETURN so callers can track and reference the new record.

**Columns/Parameters Involved**: `ID` (Billing.WithdrawToFunding IDENTITY column)

**Rules**:
- `RETURN (SELECT TOP(1) ID FROM @out)` - returns the ID of the first (typically only) inserted row
- For single-row inserts (the common case), this is the definitive WTF ID
- For multi-row inserts (rare batch scenarios), only the first ID is returned; callers needing all IDs must query the table after the call
- Callers use the returned ID to link subsequent operations (status updates, notifications) back to the WTF record

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Widraw2F | Billing.TBL_Withdraw2Funding | NO | - | CODE-BACKED | Table-valued parameter containing one or more WithdrawToFunding records to insert. Each row provides the full payment leg specification: routing (DepotID, ProtocolMIDSettingsID), amounts (Amount, ExchangeRate, BaseExchangeRate, ExchangeFee), status (CashoutStatusID), provider data (VerificationCode, VendorCode, SchemeId, ResponseID), and audit context (Remark, CashoutActionStatusID). See [Billing.TBL_Withdraw2Funding](../User%20Defined%20Types/Billing.TBL_Withdraw2Funding.md) for full column documentation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Widraw2F parameter | Billing.TBL_Withdraw2Funding | TVP Type | Input type that carries all WTF record data for the INSERT |
| Primary INSERT target | Billing.WithdrawToFunding | INSERT | Creates new withdrawal payment leg records; IDENTITY generates the WTF ID |
| History INSERT | History.WithdrawToFundingAction | INSERT | Writes the initial action audit entry for the new WTF record using OUTPUT-captured data |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Payment processing services) | - | Caller | Called by payment routing/processing procedures that create new withdrawal-to-funding legs |
| Billing.WithdrawToFundingProcess | (internally) | Caller | Processing procedure that may create new WTF legs during routing |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.InsertWithdraw2Funding (procedure)
├── Billing.TBL_Withdraw2Funding (type - TVP parameter type)
├── Billing.WithdrawToFunding (table - INSERT target)
└── History.WithdrawToFundingAction (table - audit history INSERT)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.TBL_Withdraw2Funding | User Defined Type | Input TVP type for @Widraw2F and @out local variable |
| Billing.WithdrawToFunding | Table | Primary INSERT target for the new WTF payment leg record |
| History.WithdrawToFundingAction | Table | Audit history target; receives the new WTF record data + action context |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| UpdateWithdraw2Funding | Stored Procedure | Sibling procedure - updates existing WTF records using the same TVP pattern |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

**Implementation notes**:
- `SET NOCOUNT ON` suppresses row-count messages
- Uses a local `@out [Billing].[TBL_Withdraw2Funding]` table variable to capture OUTPUT data and bridge it to the history INSERT
- Note: `@Widraw2F` (typo in original - "Widraw" missing the 'd') is the parameter name in the DDL; calling code must match this spelling
- History.WithdrawToFundingAction JOIN uses composite key (WithdrawID + FundingID), which means for multi-row TVPs, each WTF leg is correctly matched to its TVP input row for Remark/CashoutActionStatusID retrieval
- Change log: SchemeId added 24/10/2021 (PAYUS-3900), ResponseID added 31/10/2021 (PAYUA-2822)

---

## 8. Sample Queries

### 8.1 Verify a newly created WTF record by ID
```sql
-- After calling InsertWithdraw2Funding and capturing the RETURN value (@WtfId):
SELECT w.ID, w.WithdrawID, w.FundingID, w.CashoutStatusID,
       w.Amount, w.ProcessCurrencyID, w.ExchangeRate,
       w.DepotID, w.ProtocolMIDSettingsID, w.CreationDate
FROM Billing.WithdrawToFunding w WITH (NOLOCK)
WHERE w.ID = @WtfId  -- ID returned by InsertWithdraw2Funding
```

### 8.2 View the history entry created alongside a WTF record
```sql
SELECT ha.BW2F_ID, ha.WithdrawID, ha.FundingID, ha.CashoutStatusID,
       ha.CashoutActionStatusID, ha.Amount, ha.Remark, ha.ModificationDate
FROM History.WithdrawToFundingAction ha WITH (NOLOCK)
WHERE ha.BW2F_ID = @WtfId
ORDER BY ha.ModificationDate ASC
```

### 8.3 Find all WTF records created for a specific withdrawal
```sql
SELECT w.ID, w.FundingID, w.CashoutStatusID, w.Amount,
       w.ProcessCurrencyID, w.DepotID, w.VerificationCode,
       w.CreationDate, w.ModificationDate
FROM Billing.WithdrawToFunding w WITH (NOLOCK)
WHERE w.WithdrawID = @WithdrawID
ORDER BY w.CreationDate ASC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found directly for this procedure. Related pages (Merchant Account, AML pipeline) did not contain specific references to InsertWithdraw2Funding.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 related analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.InsertWithdraw2Funding | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.InsertWithdraw2Funding.sql*
