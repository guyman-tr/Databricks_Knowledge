# Billing.CustomerToFunding_UpdateWireRecord

> Removes the wire transfer funding link (`FundingID=1`) for a customer from `Billing.CustomerToFunding` only if the customer has no deposits or withdrawals using that wire funding; archives the deleted row to history.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID (customer), @FundingID (provided but unused - hard-coded to 1 internally) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.CustomerToFunding_UpdateWireRecord` is a conditional cleanup procedure that removes a customer's wire transfer funding registration (always FundingID=1 - the system wire transfer record) if and only if the customer has never actually transacted using that wire funding. It prevents orphaned wire funding registrations from appearing in a customer's saved payment methods list.

Despite accepting `@FundingID` as a parameter, the procedure ignores it internally and always operates on `FundingID = 1`. This is the special system wire transfer FundingID that is linked to customers during wire transfer registration but may have been created without actual use.

Added to history archival: January 2023 (PAYIL-5743, Shay Oren).

---

## 2. Business Logic

### 2.1 Conditional DELETE - Wire Record Cleanup

**What**: Deletes the CustomerToFunding row for FundingID=1 only if the customer has no transactional usage of it.

**Rules**:
- **Guard condition 1**: `NOT EXISTS (SELECT * FROM Billing.Deposit WHERE FundingID = 1 AND CID = @CID)` - customer must have no deposits using the wire funding
- **Guard condition 2**: `NOT EXISTS (SELECT * FROM Billing.WithdrawToFunding WTF JOIN Billing.Withdraw W ON W.WithdrawID = WTF.WithdrawID AND W.CID = @CID WHERE WTF.FundingID = 1)` - customer must have no withdrawals using the wire funding
- If BOTH guards pass (no deposit AND no withdrawal on FundingID=1): DELETE the CTF row where `CID=@CID AND FundingID=1`
- If either guard fails (customer has used FundingID=1): no change; zero rows deleted
- `OUTPUT DELETED.*` -> `History.ActiveCustomerToFunding` archives the deleted row

**Note**: The `@FundingID` parameter is accepted but not used. The procedure always targets `FundingID=1`. This is a documentation artifact - the parameter likely exists for API consistency with other procedures in this family.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | VERIFIED | Customer whose wire funding link is being evaluated for cleanup. |
| 2 | @FundingID | INT | NO | - | CODE-BACKED | Accepted for API consistency but not used internally. The procedure always targets FundingID=1 (system wire transfer record). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Guard 1 | Billing.Deposit | Read | Checks for wire deposits by this customer |
| Guard 2 | Billing.WithdrawToFunding | Read | Checks for wire withdrawals by this customer |
| Guard 2 | Billing.Withdraw | Join | Resolves WithdrawToFunding to CID for the withdrawal check |
| DELETE | Billing.CustomerToFunding | Write (DELETE) | Removes the FundingID=1 link if not transactionally used |
| OUTPUT DELETED | History.ActiveCustomerToFunding | Write | Archives the deleted row |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wire transfer cleanup service | @CID | Caller | Cleans up unused wire funding registrations |

---

## 6. Dependencies

```
Billing.CustomerToFunding_UpdateWireRecord (procedure)
+-- Billing.Deposit (table) [READ: deposit guard check]
+-- Billing.WithdrawToFunding (table) [READ: withdrawal guard check]
+-- Billing.Withdraw (table) [JOIN: CID resolution for withdrawal check]
+-- Billing.CustomerToFunding (table) [DELETE target]
+-- History.ActiveCustomerToFunding (table) [OUTPUT target]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | Guard: does customer have deposits on FundingID=1? |
| Billing.WithdrawToFunding | Table | Guard: does customer have withdrawals on FundingID=1? |
| Billing.Withdraw | Table | CID join for withdrawal guard |
| Billing.CustomerToFunding | Table | DELETE target |
| History.ActiveCustomerToFunding | Table | History OUTPUT |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wire transfer management service | External | Cleanup of unused wire registrations |

---

## 7. Technical Details

**@FundingID is unused**: Despite being declared, the parameter has no effect on the operation. All checks and the DELETE use the literal value `1`. This is a potential source of confusion for callers who might expect passing a different FundingID to clean up a different funding record.

**FundingID=1 significance**: In eToro's billing system, FundingID=1 is a special reserved FundingID representing the wire transfer funding instrument. Unlike card or e-wallet FundingIDs (which are unique per customer account), FundingID=1 is a shared system record.

---

## 8. Sample Queries

### 8.1 Clean up unused wire funding for a customer

```sql
EXEC Billing.CustomerToFunding_UpdateWireRecord
    @CID = 24186018,
    @FundingID = 1   -- or any value; parameter is unused internally
```

### 8.2 Check if a customer has wire transaction history (guard equivalent)

```sql
SELECT
    (SELECT COUNT(*) FROM Billing.Deposit WITH(NOLOCK) WHERE FundingID=1 AND CID=24186018) AS WireDeposits,
    (SELECT COUNT(*) FROM Billing.WithdrawToFunding WTF WITH(NOLOCK)
        JOIN Billing.Withdraw W WITH(NOLOCK) ON W.WithdrawID=WTF.WithdrawID AND W.CID=24186018
     WHERE WTF.FundingID=1) AS WireWithdrawals
-- Both 0 means the record would be deleted by CustomerToFunding_UpdateWireRecord
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,8,9,9B(skip),10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.CustomerToFunding_UpdateWireRecord | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.CustomerToFunding_UpdateWireRecord.sql*
