# Billing.Paypal_IsFundingBlockedAndUpdateDeposit

> Resolves and if necessary creates the PayPal funding instrument for a given PayPal account parameter, repairs any FundingID mismatch on the deposit record, and returns whether the funding instrument is blocked - used during PayPal deposit processing.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @Parameter (PayPal account identifier) + @DepositID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.Paypal_IsFundingBlockedAndUpdateDeposit` is an early-stage PayPal deposit processing helper. When a PayPal payment callback arrives, the billing pipeline needs to: (1) find or create the PayPal `Billing.Funding` record for the payer's account, (2) ensure the deposit record's FundingID correctly points to that funding instrument, and (3) report whether the funding instrument is blocked so the caller can decide whether to proceed.

The `@Parameter` input is the PayPal-specific account identifier stored in `Billing.Funding.Parameter`. If no Funding record exists for this parameter and FundingTypeID=3 (PayPal), the procedure creates one. If the Deposit's FundingID doesn't match the resolved Funding record, it is corrected. The caller receives the resolved `@FundingID` and the `@IsBlocked` flag from the Funding row.

This procedure is the older PayPal funding resolution path. Its companion `Billing.Paypal_UpdateFundingAndCheckIsBlocked` is a newer variant that uses `FundingHash` for lookup instead of `Parameter` and additionally upserts the CustomerToFunding relationship.

Created January 2017 (ticket 44765). Ticket 50113 references a fix related to this procedure.

---

## 2. Business Logic

### 2.1 Funding Record Resolution (Find or Create)

**What**: Ensures a Billing.Funding record exists for the PayPal parameter.

**Columns Involved**: `Billing.Funding.Parameter`, `Billing.Funding.FundingTypeID`, `Billing.Funding.IsBlocked`

**Rules**:
- SELECT FundingID, IsBlocked FROM Billing.Funding WHERE Parameter=@Parameter AND FundingTypeID=3.
- FundingTypeID=3 is the implicit PayPal constant - only PayPal funding rows are considered.
- If no row found (new PayPal account): INSERT INTO Billing.Funding (FundingTypeID=3, Parameter=@Parameter, IsBlocked=0). @FundingID is set to SCOPE_IDENTITY().
- If row found: @FundingID and @IsBlocked are set from the existing row.

### 2.2 Deposit FundingID Repair

**What**: Corrects the FundingID on the deposit if it doesn't match the resolved funding record.

**Columns Involved**: `Billing.Deposit.FundingID`, `Billing.Deposit.DepositID`

**Rules**:
- UPDATE Billing.Deposit SET FundingID=@FundingID WHERE DepositID=@DepositID AND FundingID<>@FundingID.
- The conditional UPDATE (FundingID<>@FundingID) is a no-op if the deposit already has the correct FundingID.
- This repair handles cases where the deposit was initially created with a default or incorrect FundingID before the PayPal account was resolved.
- Note: This procedure contains a COMMIT statement in its TRY block without an explicit BEGIN TRAN. This relies on caller-managed transaction context (autocommit behavior if called outside a transaction).

### 2.3 IsBlocked Return

**What**: Returns whether the resolved funding instrument is blocked from processing.

**Columns Involved**: `Billing.Funding.IsBlocked`

**Rules**:
- @IsBlocked OUTPUT: 0=not blocked (processing allowed), 1=blocked (payment should be rejected/held).
- IsBlocked is read from Billing.Funding on the resolved (or newly-created) row.
- New funding records are always created with IsBlocked=0.

**Diagram**:
```
@Parameter (PayPal account ID) + @DepositID
  |
  SELECT FundingID, IsBlocked FROM Billing.Funding
    WHERE Parameter=@Parameter AND FundingTypeID=3
  |
  Found?      Not Found?
   YES          NO
   |             |
   Set           INSERT Billing.Funding
   @FundingID    (FundingTypeID=3, Parameter=@Parameter, IsBlocked=0)
   @IsBlocked    Set @FundingID=SCOPE_IDENTITY(), @IsBlocked=0
   |
  UPDATE Billing.Deposit SET FundingID=@FundingID
    WHERE DepositID=@DepositID AND FundingID<>@FundingID
  |
  RETURN @IsBlocked
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Parameter | nvarchar(255) | NO | - | CODE-BACKED | The PayPal account identifier used to look up the Billing.Funding record. Matched against `Billing.Funding.Parameter` WHERE FundingTypeID=3. This is typically the PayPal email or account token. |
| 2 | @DepositID | int | NO | - | CODE-BACKED | The deposit record to update. Used in the FundingID repair UPDATE on `Billing.Deposit`. |
| 3 | @FundingID | int | YES | OUTPUT | CODE-BACKED | OUTPUT: the resolved Billing.Funding.FundingID for the PayPal account. Either the existing FundingID or the newly inserted identity value. |
| 4 | @IsBlocked | bit | YES | OUTPUT | CODE-BACKED | OUTPUT: whether the resolved funding instrument is currently blocked (1=blocked, 0=allowed). Read from Billing.Funding.IsBlocked. New instruments default to 0. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Parameter + FundingTypeID=3 | Billing.Funding | Read/Write (SELECT + INSERT) | Resolves or creates the PayPal funding record. |
| @DepositID | [Billing.Deposit](../Tables/Billing.Deposit.md) | Write (UPDATE) | Repairs FundingID on deposit record if mismatched. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Payout / billing application | - | EXEC | Called during PayPal deposit callback processing. No SQL-layer callers found (VIEW DEFINITION only to BIadmins). |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.Paypal_IsFundingBlockedAndUpdateDeposit (procedure)
├── Billing.Funding (table) - SELECT + conditional INSERT
└── Billing.Deposit (table) - conditional UPDATE
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Funding | Table | SELECT to resolve PayPal funding record; INSERT if not found. |
| [Billing.Deposit](../Tables/Billing.Deposit.md) | Table | UPDATE to repair FundingID if mismatched. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| PayPal billing application | Application | Called during PayPal payment callback to resolve funding and validate block status. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

The Parameter lookup on Billing.Funding uses the Parameter column with FundingTypeID=3 filter. An index on (FundingTypeID, Parameter) would make this efficient. The Deposit UPDATE targets DepositID (PK) for a single-row update.

**Transaction anomaly**: The procedure contains COMMIT in its TRY block without an explicit BEGIN TRANSACTION. When called from within a caller's transaction, this will commit the caller's entire transaction. When called outside a transaction (autocommit), COMMIT is a no-op. Callers should be aware of this behavior.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Resolve PayPal funding and check block status

```sql
DECLARE @FundingID INT, @IsBlocked BIT;
EXEC Billing.Paypal_IsFundingBlockedAndUpdateDeposit
    @Parameter = 'paypal_user@example.com',
    @DepositID = 987654,
    @FundingID = @FundingID OUTPUT,
    @IsBlocked = @IsBlocked OUTPUT;
SELECT @FundingID AS FundingID, @IsBlocked AS IsBlocked;
-- @IsBlocked=0: proceed with deposit; 1: block payment
```

### 8.2 Check if a PayPal parameter has an existing Funding record

```sql
SELECT FundingID, Parameter, IsBlocked, FundingTypeID
FROM Billing.Funding WITH (NOLOCK)
WHERE Parameter = 'paypal_user@example.com'
  AND FundingTypeID = 3;
```

### 8.3 Find deposits with FundingID mismatches (pre-repair diagnostic)

```sql
SELECT d.DepositID, d.FundingID AS CurrentFundingID, f.FundingID AS ResolvedFundingID
FROM Billing.Deposit d WITH (NOLOCK)
JOIN Billing.Funding f WITH (NOLOCK)
    ON f.Parameter = '<paypal_account>'
    AND f.FundingTypeID = 3
WHERE d.DepositID = 987654
  AND d.FundingID <> f.FundingID;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| Ticket 44765 | Jira (referenced in code comment) | Original creation context for this PayPal funding resolution procedure |
| Ticket 50113 | Jira (referenced in code comment) | Fix applied to this procedure |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.9/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 2 Jira (code comments) | Procedures: 0 SQL callers found | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.Paypal_IsFundingBlockedAndUpdateDeposit | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.Paypal_IsFundingBlockedAndUpdateDeposit.sql*
