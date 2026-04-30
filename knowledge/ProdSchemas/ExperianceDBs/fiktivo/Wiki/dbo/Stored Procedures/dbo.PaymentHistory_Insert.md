# dbo.PaymentHistory_Insert

## 1. Overview

Inserts a new affiliate payment history record into `tblaff_PaymentHistory`, capturing the full multi-tier commission breakdown across CPA, Sales, Leads, Registrations, Clicks, Copy Traders, First Positions, and eCost categories. Returns the new payment ID as a scalar result set and the row version via an OUTPUT parameter. This is the primary write entry point for the affiliate payment approval workflow.

## 2. Classification

| Property | Value |
|---|---|
| Schema | dbo |
| Type | Stored Procedure |
| Database | fiktivo |
| Primary Table | dbo.tblaff_PaymentHistory |
| Secondary Tables | None |
| Operation | INSERT |
| Transaction | Implicit (single statement) |

## 3. Return / Result Set

N/A for stored procedure.

Returns a single-column, single-row result set containing the new `PaymentID` integer. The `@RowVersion` OUTPUT parameter is also populated with the binary(8) row version of the inserted row.

## 4. Parameters

The procedure accepts 88 parameters covering the complete payment record. Key groupings are listed below.

| Parameter | Direction | Type | Default | Description |
|---|---|---|---|---|
| @RowVersion | OUT | binary(8) | NULL | Row version of the inserted row, returned to caller. |
| @AffiliateID | IN | int | required | Affiliate receiving the payment. |
| @PaymentDate | IN | datetime | NULL | Date the payment was issued. |
| @PaymentAmount | IN | float | NULL | Total payment amount in USD. |
| @PaymentAdjustment | IN | float | NULL | Manual adjustment applied to the payment. |
| @PaymentDescription | IN | nvarchar(20) | NULL | Short description of the payment. |
| @Tier1CPA ... @Tier5CPA | IN | int | 0 | Count of CPA events per tier (1 through 5). |
| @Tier1CPACommission ... @Tier5CPACommission | IN | float | 0 | CPA commission amounts per tier. |
| @Tier1Sales ... @Tier5Sales | IN | int | 0 | Sales counts per tier. |
| @Tier1SalesCommission ... @Tier5SalesCommission | IN | float | 0 | Sales commission amounts per tier. |
| @Tier1Registrations ... @Tier5Registrations | IN | int | 0 | Registration counts per tier. |
| @Tier1RegistrationsCommission ... @Tier5RegistrationsCommission | IN | float | 0 | Registration commission amounts per tier. |
| @Tier1Leads ... @Tier5Leads | IN | int | 0 | Lead counts per tier. |
| @Tier1LeadsCommission ... @Tier5LeadsCommission | IN | float | 0 | Lead commission amounts per tier. |
| @Tier1Clicks ... @Tier5Clicks | IN | int | 0 | Click counts per tier. |
| @Tier1ClicksCommission ... @Tier5ClicksCommission | IN | float | 0 | Click commission amounts per tier. |
| @PaymentRange | IN | nvarchar(25) | NULL | Date range label for the payment period. |
| @Comment | IN | nvarchar(max) | NULL | Free-text comment on the payment. |
| @ManagerApproved | IN | bit | FALSE | Whether the manager has approved the payment. |
| @Approved | IN | bit | FALSE | Whether the payment is fully approved. |
| @ApprovalDate | IN | datetime | NULL | Date of approval. |
| @RequestedBy | IN | int | 0 | UserID who requested the payment. |
| @ApprovedBy | IN | int | 0 | UserID who approved the payment. |
| @VPMarketingApproved | IN | bit | FALSE | VP Marketing approval flag. |
| @CurrencyID | IN | int | 0 | Currency for the payment. |
| @LastApprovalDate | IN | datetime | NULL | Date of the most recent approval action. |
| @Tier1eCostCommission | IN | float | 0 | eCost commission for tier 1. |
| @PaymentDetailsID | IN | bigint | 0 | Reference to payment details record. |
| @PaymentDetailsOnApprove | IN | varchar(max) | NULL | Snapshot of payment details at approval time. |
| @PaymentMethodOnApprove | IN | int | NULL | Payment method used at approval. |
| @Tier1CopyTraders ... @Tier5CopyTraders | IN | int | 0 | Copy Trader counts per tier. |
| @Tier1CopyTradersCommission ... @Tier5CopyTradersCommission | IN | float | 0 | Copy Trader commission per tier. |
| @Tier1FirstPositions ... @Tier5FirstPositions | IN | int | 0 | First Position event counts per tier. |
| @Tier1FirstPositionsCommission ... @Tier5FirstPositionsCommission | IN | float | 0 | First Position commission per tier. |
| @PaymentRowStatusID | IN | int | NULL | Status code for the payment row in the workflow. |
| @eCostHistoryID | IN | int | NULL | Reference to the eCost history batch this payment belongs to. |
| @FinanceApproved | IN | bit | FALSE | Finance team approval flag. |
| @FinanceManagerApproved | IN | bit | FALSE | Finance manager approval flag. |
| @PaymentPeriod | IN | date | NULL | Accounting period for the payment. |
| @PaymentGroupCode | IN | uniqueidentifier | NULL | GUID grouping related payment rows in a batch. |
| @AmountInCurrency | IN | decimal(18,2) | NULL | Payment amount in the affiliate's preferred currency. |

## 5. Business Logic

1. Declares a table variable `@INSERTED` to capture the OUTPUT clause from the INSERT.
2. Inserts one row into `tblaff_PaymentHistory` with all 88 column values supplied by the parameters, using `OUTPUT [inserted].PaymentID, [inserted].RowVersion INTO @INSERTED`.
3. Reads the new `PaymentID` and `RowVersion` from `@INSERTED` and assigns `RowVersion` to the `@RowVersion` OUTPUT parameter.
4. Returns the new `PaymentID` as a scalar result set (`SELECT @ID`).
5. `SET NOCOUNT ON` prevents the INSERT row-count message from being returned as an extra result set.

## 6. Dependencies

| Object | Type | Schema | Purpose |
|---|---|---|---|
| dbo.tblaff_PaymentHistory | Table | dbo | Target table for the new payment record |

## 7. Indexes and Performance

### 7.1 Recommendations

N/A for stored procedure.

### 7.2 Notes

- Single-row INSERT; performance is not a concern at typical invocation rates.
- The OUTPUT clause safely captures the identity and row version even when triggers are present on `tblaff_PaymentHistory`.
- The large number of parameters (88) reflects the wide schema of `tblaff_PaymentHistory`; all tier columns default to 0, so callers only need to supply the tiers relevant to the affiliate's commission plan.

## 8. Usage Examples

```sql
DECLARE @RV binary(8);

EXEC dbo.PaymentHistory_Insert
    @RowVersion           = @RV OUTPUT,
    @AffiliateID          = 1001,
    @PaymentDate          = '2024-06-30',
    @PaymentAmount        = 5000.00,
    @PaymentDescription   = N'June 2024',
    @Tier1CPA             = 10,
    @Tier1CPACommission   = 2500.00,
    @Tier1Sales           = 5,
    @Tier1SalesCommission = 2500.00,
    @RequestedBy          = 42,
    @PaymentPeriod        = '2024-06-01',
    @PaymentGroupCode     = NEWID();

SELECT @RV AS RowVersion;
```

## 9. Change History

| Date | Author | Jira / Note | Description |
|---|---|---|---|
| Unknown | Unknown | N/A | Initial creation |

---
*Object: dbo.PaymentHistory_Insert | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.PaymentHistory_Insert.sql*
