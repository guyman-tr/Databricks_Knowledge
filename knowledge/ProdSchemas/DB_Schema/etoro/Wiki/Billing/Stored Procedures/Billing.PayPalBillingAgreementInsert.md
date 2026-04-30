# Billing.PayPalBillingAgreementInsert

> Upserts a PayPal Billing Agreement record by (CID, FundingID) - creating or replacing the agreement token for a customer's PayPal funding instrument - and returns the inserted row including the generated surrogate key.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @FundingID (resolved from @DepositID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.PayPalBillingAgreementInsert` is the write procedure for `Billing.PayPalBillingAgreement`. When a customer authorizes a new PayPal billing agreement (a recurring payment authorization token), this procedure stores it - or replaces the existing one if this customer already has an agreement on the same funding instrument.

The procedure derives the FundingID from @DepositID (looking up `Billing.Deposit.FundingID`), then uses a MERGE statement to upsert on the (CID, FundingID) composite key. If the pair already exists, the existing agreement token is replaced with the new one. If it does not exist, a new row is inserted. The OUTPUT clause returns the full inserted/updated row to the caller, including the generated or existing `PayPalBillingAgreementID`.

This is part of the PAYUSOLA-4629 PayPal Billing Agreement feature, which also includes the companion `Billing.PayPalBillingAgreementGet` and `Billing.PayPalBillingAgreementDelete` procedures.

---

## 2. Business Logic

### 2.1 FundingID Resolution from DepositID

**What**: Resolves the FundingID for the MERGE key by looking up the originating deposit.

**Columns Involved**: `Billing.Deposit.FundingID`, `Billing.Deposit.DepositID`

**Rules**:
- SELECT @FundingID = FundingID FROM Billing.Deposit WHERE DepositID = @DepositID.
- The FundingID on the deposit identifies which PayPal funding instrument was used for the original deposit.
- This FundingID becomes part of the (CID, FundingID) composite merge key.

### 2.2 Upsert by (CID, FundingID)

**What**: Creates or replaces the billing agreement record.

**Columns Involved**: `Billing.PayPalBillingAgreement.CID`, `Billing.PayPalBillingAgreement.FundingID`, `Billing.PayPalBillingAgreement.BillingAgreementID`, `Billing.PayPalBillingAgreement.DepositID`

**Rules**:
- MERGE ON (CID=@CID AND FundingID=@FundingID):
  - WHEN MATCHED: UPDATE SET BillingAgreementID=@BillingAgreementId, DepositID=@DepositID. Replaces the agreement token and updates the source deposit reference.
  - WHEN NOT MATCHED: INSERT (CID, FundingID, BillingAgreementID, DepositID) VALUES (@CID, @FundingID, @BillingAgreementId, @DepositID). Creates a new record.
- OUTPUT Inserted.* returns all columns of the inserted/updated row.
- One customer can have at most one billing agreement per FundingID (enforced by the MERGE ON clause uniqueness assumption).

**Diagram**:
```
@CID + @BillingAgreementId + @DepositID
  |
  SELECT @FundingID = FundingID FROM Billing.Deposit WHERE DepositID=@DepositID
  |
  MERGE Billing.PayPalBillingAgreement
    ON (CID=@CID AND FundingID=@FundingID)
    |
  MATCHED?           NOT MATCHED?
    YES                  NO
    |                    |
    UPDATE               INSERT
    BillingAgreementID   (CID, FundingID,
    DepositID            BillingAgreementID,
                         DepositID)
    |
  OUTPUT Inserted.*
  (returns full row with PayPalBillingAgreementID)
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | int | NO | - | CODE-BACKED | Customer ID. Part of the (CID, FundingID) merge key. Stored in `Billing.PayPalBillingAgreement.CID`. |
| 2 | @BillingAgreementId | nvarchar(255) | NO | - | CODE-BACKED | The PayPal billing agreement token provided by PayPal after customer authorization (e.g., 'B-1AB23456CD789012E'). Stored in `Billing.PayPalBillingAgreement.BillingAgreementID`. Replaced on re-authorization. |
| 3 | @DepositID | int | NO | - | CODE-BACKED | The deposit record that established or renewed this agreement. Used to: (1) resolve @FundingID via Billing.Deposit lookup; (2) stored in `Billing.PayPalBillingAgreement.DepositID` as the agreement's source deposit reference. |

**Result Set**: All columns from the inserted/updated row via `OUTPUT Inserted.*`. See `Billing.PayPalBillingAgreement` for column definitions (PayPalBillingAgreementID, CID, FundingID, BillingAgreementID, DepositID).

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @DepositID | [Billing.Deposit](../Tables/Billing.Deposit.md) | Read (SELECT) | Resolves FundingID from the deposit to use as the MERGE key. |
| @CID + @FundingID | [Billing.PayPalBillingAgreement](../Tables/Billing.PayPalBillingAgreement.md) | Write (MERGE + OUTPUT) | Upserts the billing agreement record. Temporal table preserves history of replaced agreements. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PayPal billing application | - | EXEC | Called when a customer authorizes or re-authorizes a PayPal billing agreement. No SQL-layer callers found. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.PayPalBillingAgreementInsert (procedure)
├── Billing.Deposit (table) - SELECT FundingID
└── Billing.PayPalBillingAgreement (system-versioned temporal table) - MERGE
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [Billing.Deposit](../Tables/Billing.Deposit.md) | Table | SELECT - resolves FundingID from the deposit record. |
| [Billing.PayPalBillingAgreement](../Tables/Billing.PayPalBillingAgreement.md) | Table | MERGE - upserts the billing agreement by (CID, FundingID). Temporal versioning preserves replaced agreements. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| PayPal application | Application | Called when customer authorizes a PayPal billing agreement during deposit flow. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

The MERGE uses (CID, FundingID) as the match condition - an index on these columns in `Billing.PayPalBillingAgreement` is required for efficient upsert performance. The Deposit lookup uses DepositID (PK) for a single-row seek.

**Temporal table behavior**: Since `Billing.PayPalBillingAgreement` is SYSTEM_VERSIONING=ON, the MERGE UPDATE (agreement replacement) automatically moves the previous row into the history table, preserving the full history of agreement token changes per customer-funding pair.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Register or renew a PayPal billing agreement

```sql
EXEC Billing.PayPalBillingAgreementInsert
    @CID                = 12345,
    @BillingAgreementId = 'B-1AB23456CD789012E',
    @DepositID          = 987654;
-- Returns: PayPalBillingAgreementID, CID, FundingID, BillingAgreementID, DepositID
```

### 8.2 Verify the upserted agreement

```sql
SELECT
    PayPalBillingAgreementID,
    CID,
    FundingID,
    BillingAgreementID,
    DepositID
FROM Billing.PayPalBillingAgreement WITH (NOLOCK)
WHERE CID = 12345;
```

### 8.3 View agreement history (after replacement)

```sql
-- Show all historical agreements for a customer (temporal history)
SELECT *
FROM Billing.PayPalBillingAgreementHistory WITH (NOLOCK)
WHERE CID = 12345
ORDER BY SysEndTime DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| PAYUSOLA-4629 | Jira (referenced in code comment) | PayPal Billing Agreement feature - this procedure is the upsert writer for agreement records |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.1/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 1 Jira (code comment) | Procedures: 0 SQL callers found | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.PayPalBillingAgreementInsert | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.PayPalBillingAgreementInsert.sql*
