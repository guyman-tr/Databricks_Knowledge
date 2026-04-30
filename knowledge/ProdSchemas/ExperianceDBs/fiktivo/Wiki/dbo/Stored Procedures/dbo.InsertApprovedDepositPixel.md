# dbo.InsertApprovedDepositPixel

## 1. Overview

Inserts a new durable message record into `tblaff_DurableMessages` for an approved deposit pixel event and returns the generated `ReferenceID` to the caller via an OUTPUT parameter. This procedure is the entry point for the pixel-delivery queuing mechanism triggered when a deposit is approved, ensuring the pixel is sent exactly once even when billing retries occur.

## 2. Classification

| Property | Value |
|---|---|
| Schema | dbo |
| Type | Stored Procedure |
| Database | fiktivo |
| Primary Table | dbo.tblaff_DurableMessages |
| Secondary Tables | None |
| Operation | INSERT |
| Transaction | Implicit (single statement) |

## 3. Return / Result Set

N/A for stored procedure.

Returns nothing via result set. The newly created `ReferenceID` (identity value) is returned through the `@ReferenceID OUTPUT` parameter.

## 4. Parameters

| Parameter | Direction | Type | Default | Description |
|---|---|---|---|---|
| @AffiliateID | IN | int | required | ID of the affiliate associated with the deposit pixel. |
| @CID | IN | int | required | Customer ID for whom the deposit was approved. |
| @PixelIDs | IN | nvarchar(max) | NULL | Comma-separated or serialized list of pixel IDs to fire. |
| @AppsFlyerID | IN | varchar(255) | NULL | AppsFlyer attribution ID if applicable. |
| @CorrelationID | IN | varchar(255) | required | Correlation identifier used to track the end-to-end message. |
| @TransactionID | IN | varchar(255) | required | Billing transaction ID for the approved deposit. |
| @MessageData | IN | nvarchar(max) | NULL | Serialized message payload for delivery processing. |
| @IsDelivered | IN | bit | 0 | Whether the message has already been delivered; defaults to undelivered. |
| @CreateTime | IN | datetime | NULL | Timestamp for the message creation; NULL lets the application layer supply it. |
| @ReferenceID | OUT | bigint | NULL | OUTPUT: the identity value assigned to the new row in `tblaff_DurableMessages`. |

## 5. Business Logic

1. Declares an in-memory table variable `@T` to capture the OUTPUT clause result.
2. Inserts one row into `tblaff_DurableMessages` with all supplied values.
3. Uses the `OUTPUT Inserted.ReferenceID INTO @T` clause to capture the new identity without a separate `SCOPE_IDENTITY()` call.
4. Reads `@ReferenceID` from `@T` and returns it to the caller.
5. `SET NOCOUNT ON` suppresses the row-count message.
6. The procedure has no explicit transaction; the single INSERT is atomic by default.

## 6. Dependencies

| Object | Type | Schema | Purpose |
|---|---|---|---|
| tblaff_DurableMessages | Table | dbo | Stores queued pixel delivery messages for approved deposits |

## 7. Indexes and Performance

### 7.1 Recommendations

N/A for stored procedure.

### 7.2 Notes

- Single-row INSERT; no performance concerns at typical call rates.
- The OUTPUT clause approach is preferred over `SCOPE_IDENTITY()` as it is safe in the presence of triggers.
- `@ReferenceID` is declared as `bigint` in the OUTPUT parameter but the column comment uses `Int`; verify the actual column type in `tblaff_DurableMessages.ReferenceID`.

## 8. Usage Examples

```sql
DECLARE @RefID BIGINT;
EXEC dbo.InsertApprovedDepositPixel
    @AffiliateID    = 1001,
    @CID            = 500000,
    @PixelIDs       = N'42,87',
    @AppsFlyerID    = NULL,
    @CorrelationID  = 'corr-abc-123',
    @TransactionID  = 'txn-xyz-456',
    @MessageData    = NULL,
    @IsDelivered    = 0,
    @CreateTime     = '2024-06-01 10:00:00',
    @ReferenceID    = @RefID OUTPUT;

SELECT @RefID AS NewReferenceID;
```

## 9. Change History

| Date | Author | Jira / Note | Description |
|---|---|---|---|
| 2017-05-08 | Geri Reshef | 45013 | Approved Deposit Pixel - DB Changes |
| 2018-01-03 | Geri Reshef | 50079 | Prevent Insert Same Pixels to Durable Message Multiple Time on Billing Retry - DB Changes |

---
*Object: dbo.InsertApprovedDepositPixel | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.InsertApprovedDepositPixel.sql*
