# History.BillingFunding

> Trigger-based SCD2 (Slowly Changing Dimension Type 2) history table for Billing.Funding: records every version of every customer payment method (credit card, wire, PayPal, etc.) with ValidFrom/ValidTo timestamps. Active rows have ValidTo='3000-01-01'. Sensitive card data is stripped before storing. Very high volume - 226+ million rows growing continuously.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | HistoryFundingID (PK, INT IDENTITY, CLUSTERED) |
| **Partition** | No |
| **Indexes** | 2 active (CLUSTERED PK, FILTERED NONCLUSTERED on FundingID/ValidTo for active rows) |

---

## 1. Business Meaning

History.BillingFunding is the complete version history of all customer payment methods (funding instruments) registered on eToro. When a customer adds, modifies, or removes a payment method in `Billing.Funding` (credit card, wire transfer, PayPal, Skrill, etc.), three triggers on Billing.Funding automatically maintain this history table using an SCD2 pattern:

- **FundingInsertTrigger**: On new payment method registration, creates a history row with ValidFrom=NOW (UTC), ValidTo='3000-01-01' (= active)
- **FundingUpdateTrigger**: On modification, closes the old active row (ValidTo=NOW) and creates a new active row (ValidTo='3000-01-01')
- **FundingDeleteTrigger**: On deletion, closes the active row (ValidTo=NOW)

This means History.BillingFunding serves dual purpose:
1. **Current state**: Rows with ValidTo='3000-01-01' represent the current payment method data (filtered index makes this fast)
2. **Change history**: Rows with specific ValidTo values represent prior states, enabling point-in-time reconstruction

**PCI DSS compliance**: For credit card funding methods (FundingTypeID=1), the triggers explicitly strip `CardNumberAsString` and `SecuredCardDataAsString` nodes from the `FundingData` XML before inserting into history. Raw card numbers never persist in the history table. Additionally, `FundingData` is MASKED with `FUNCTION='default()'` - non-privileged users see NULL for this column.

**Scale**: HistoryFundingID exceeds 226 million (as of March 2026). New funding rows arrive continuously (several per second observed). FundingID starts at 1000 (Billing.Funding IDENTITY starts at 1000), with the most recent FundingID around 4.15 million - approximately 4 million distinct payment methods ever registered, each with an average of 55+ history versions.

**MIMO integration**: `MIMOAlerts.GetSupportedCountryMOPConfigurationChanges` reads this table as part of payment method configuration change detection.

---

## 2. Business Logic

### 2.1 SCD2 Trigger Write Pattern

**What**: Three triggers on Billing.Funding maintain the SCD2 history in this table.

**Columns/Parameters Involved**: All 12 columns (FundingID, FundingTypeID, ManagerID, IsBlocked, BlockedDescription, BlockedAt, FundingData, IsRefundExcluded, DocumentRequired, DateCreated, ValidFrom, ValidTo)

**Rules**:
- **INSERT** (new payment method registered):
  1. Copy all columns from INSERTED row to @tbl
  2. For FundingTypeID=1 (CreditCard): modify FundingData XML to delete `/Funding/CardNumberAsString` and `/Funding/SecuredCardDataAsString` (PCI safety)
  3. INSERT into History.BillingFunding with ValidFrom=GETUTCDATE(), ValidTo='30000101'
- **UPDATE** (payment method modified):
  1. UPDATE History.BillingFunding SET ValidTo=GETUTCDATE() WHERE ValidTo='3000-01-01' AND FundingID IN (DELETED)
  2. Then INSERT new row (same PCI-safe logic as INSERT trigger)
- **DELETE** (payment method removed):
  1. UPDATE History.BillingFunding SET ValidTo=GETUTCDATE() WHERE ValidTo='3000-01-01' AND FundingID IN (DELETED)
- Trace column: populated by DEFAULT constraint (JSON context) when row is inserted
- `TR_FundingPaymentDetails` trigger also fires on Insert/Update: populates Billing.Funding.PaymentDetails (does NOT affect history)

**Diagram**:
```
Customer adds CreditCard -> Billing.Funding INSERT
   FundingInsertTrigger fires
   Strip CardNumberAsString from FundingData XML
   INSERT History.BillingFunding (ValidFrom=NOW, ValidTo='3000-01-01', ...)

Customer updates card expiry -> Billing.Funding UPDATE
   FundingUpdateTrigger fires
   UPDATE old history row: ValidTo=NOW
   INSERT new history row: (ValidFrom=NOW, ValidTo='3000-01-01', updated data)

Customer removes card -> Billing.Funding DELETE
   FundingDeleteTrigger fires
   UPDATE history row: ValidTo=NOW (card deregistered)
```

### 2.2 Current State vs. History Separation

**What**: The filtered index enables fast querying of only active (current) payment methods.

**Rules**:
- Active rows: ValidTo='3000-01-01 00:00:00.000' - uses filtered index IDX_Filtered_HistoryBillingFunding_ValidTo (FundingID, ValidTo)
- Historical rows: ValidTo < '3000-01-01' - requires clustered PK scan
- To get the current state of a funding: WHERE FundingID=@ID AND ValidTo='3000-01-01'
- To get the full history: WHERE FundingID=@ID ORDER BY ValidFrom ASC

### 2.3 ValidFrom/ValidTo Timestamp Behavior

**What**: Some funding records show ValidFrom = ValidTo (zero-duration rows).

**Rules**:
- Zero-duration rows (ValidFrom = ValidTo to millisecond precision) occur when a Billing.Funding INSERT is immediately followed by an UPDATE within the same millisecond
- This happens when TR_FundingPaymentDetails fires immediately after FundingInsertTrigger, updating Billing.Funding which triggers FundingUpdateTrigger
- Zero-duration history rows are valid and expected in high-throughput scenarios
- The active row (ValidTo='3000-01-01') is always the definitive current state

---

## 3. Data Overview

226+ million rows growing continuously. ~4.15 million distinct FundingIDs. HistoryFundingID starts at 1 (legacy). FundingID starts at 1000 (per source table IDENTITY). FundingTypeID=33 and FundingTypeID=2 (WireTransfer) observed as most recent. FundingData is MASKED for non-privileged users.

| HistoryFundingID | FundingID | FundingTypeID | IsBlocked | ValidFrom | ValidTo | Meaning |
|---|---|---|---|---|---|---|
| 226970411 | 4155477 | 33 | 0 | 2026-03-19 07:42:18 | 3000-01-01 | Active (current) state of FundingID=4155477, FundingType=33. |
| 226970410 | 4155477 | 33 | 0 | 2026-03-19 07:42:18 | 2026-03-19 07:42:18 | Zero-duration prior state - superseded immediately (sub-millisecond update sequence). |
| (any) | (any) | 1 (CC) | 0/1 | (date) | (date) | CreditCard row. FundingData XML has CardNumberAsString stripped (PCI compliance). |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | HistoryFundingID | int | NO | IDENTITY(1,1) | CODE-BACKED | Surrogate PK. Auto-generated IDENTITY, NOT FOR REPLICATION (independent sequence per replica). Clustered PK on HISTORY filegroup. Exceeds 226 million as of March 2026. |
| 2 | ValidFrom | datetime | NO | - | CODE-BACKED | UTC timestamp when this version of the funding record became active. Set to GETUTCDATE() at time of INSERT or UPDATE in Billing.Funding triggers. NOT datetime2 - lower precision than temporal tables. |
| 3 | ValidTo | datetime | NO | - | CODE-BACKED | UTC timestamp when this version was superseded. '3000-01-01 00:00:00.000' = currently active. Specific datetime = historical/closed. Filtered index optimizes queries for active rows. |
| 4 | FundingID | int | NO | - | CODE-BACKED | The funding instrument's ID from Billing.Funding (IDENTITY starting at 1000). Links all history versions for a single payment method. ~4.15 million distinct values. Used in filtered index for active-row lookups. |
| 5 | FundingTypeID | int | NO | - | CODE-BACKED | Payment method type. References Dictionary.FundingType. Recent data: 33 (newer type), 2=WireTransfer frequently observed. 1=CreditCard (PCI-cleaned FundingData). |
| 6 | ManagerID | int | YES | - | CODE-BACKED | BackOffice manager who modified the funding record. NULL or 0 for customer-initiated changes (system/application), positive value for BackOffice-initiated changes. References BackOffice.Manager. |
| 7 | IsBlocked | bit | NO | - | CODE-BACKED | 1=this payment method is blocked from use. 0=active/unblocked. When BlockedAt/BlockedDescription are set, this should be 1. |
| 8 | BlockedDescription | varchar(255) | YES | - | CODE-BACKED | Free-text reason for blocking this payment method (e.g., fraud flag, compliance issue). NULL when IsBlocked=0. |
| 9 | BlockedAt | datetime | YES | - | CODE-BACKED | UTC timestamp when this payment method was blocked. NULL when never blocked or unblocked. |
| 10 | FundingData | xml | YES | - | CODE-BACKED | XML containing payment method details (card numbers, account numbers, etc.). MASKED WITH (FUNCTION='default()') - non-privileged users see NULL. For CreditCard rows, CardNumberAsString and SecuredCardDataAsString nodes are deleted before insert (PCI DSS compliance). |
| 11 | IsRefundExcluded | bit | NO | - | CODE-BACKED | 1=this payment method is excluded from receiving refunds. DEFAULT=0. Used to prevent refunds to certain payment methods. |
| 12 | DocumentRequired | bit | NO | - | CODE-BACKED | 1=documentation required for this funding method before use. DEFAULT=0. Compliance/KYC control flag. |
| 13 | DateCreated | datetime | YES | - | CODE-BACKED | UTC timestamp when the funding record was originally created in Billing.Funding (not the history row's creation time). Copied from the source row. GETUTCDATE() default in source. |
| 14 | Trace | varchar(max) | YES | - | CODE-BACKED | JSON connection context captured at history row creation. Format: {"HostName": "...", "AppName": "...", "SUserName": "...", "OriginalLogin": "...", "SPID": "...", "DBName": "...", "ObjectName": "..."}. Includes original_login() in addition to suser_name() - distinguishes impersonated from actual login. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FundingID | Billing.Funding | Implicit | All history rows reference the source funding record. No FK constraint (SCD2 tables typically avoid FK back to source). |
| FundingTypeID | Dictionary.FundingType | Implicit FK | Payment method type lookup. |
| ManagerID | BackOffice.Manager | Implicit FK | Manager who modified the record (when not system-initiated). |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.FundingInsertTrigger | INSERT | Writer | Creates initial active history row on new funding registration |
| Billing.FundingUpdateTrigger | INSERT + UPDATE | Writer | Closes prior active row and creates new active row on each update |
| Billing.FundingDeleteTrigger | UPDATE | Writer | Closes active row on funding deletion |
| MIMOAlerts.GetSupportedCountryMOPConfigurationChanges | SELECT | Reader | Monitors payment method configuration changes |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.BillingFunding (table)
  - written by: Billing.FundingInsertTrigger
  - written by: Billing.FundingUpdateTrigger
  - written by: Billing.FundingDeleteTrigger
  - read by: MIMOAlerts.GetSupportedCountryMOPConfigurationChanges
```

### 6.1 Objects This Depends On

None.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.FundingInsertTrigger | Trigger | Writer - creates SCD2 history row on INSERT to Billing.Funding |
| Billing.FundingUpdateTrigger | Trigger | Writer - close prior row + create new row on UPDATE to Billing.Funding |
| Billing.FundingDeleteTrigger | Trigger | Writer - closes active row on DELETE from Billing.Funding |
| MIMOAlerts.GetSupportedCountryMOPConfigurationChanges | Stored Procedure | Reader - change detection for payment method configuration |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HistoryBillingFunding | CLUSTERED PK | HistoryFundingID ASC | - | - | Active |
| IDX_Filtered_HistoryBillingFunding_ValidTo | NONCLUSTERED | FundingID ASC, ValidTo ASC | - | WHERE ValidTo='3000-01-01 00:00:00.000' | Active |

**Filtered index**: The nonclustered filtered index on (FundingID, ValidTo) WHERE ValidTo='3000-01-01' covers only active rows (~4.15M of 226M total). This makes active-row lookups like `WHERE FundingID=@ID AND ValidTo='3000-01-01'` extremely fast without scanning the full history. FILLFACTOR=95, PAGE compressed. On HISTORY filegroup.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HistoryBillingFunding | PRIMARY KEY CLUSTERED | HistoryFundingID |
| Df_History_Billing_Funding_Trace | DEFAULT | JSON context including host_name(), app_name(), suser_name(), original_login(), @@spid, db_name(), object_name(@@procid) |
| NOT FOR REPLICATION on HistoryFundingID | Identity option | Independent IDENTITY per replica |

---

## 8. Sample Queries

### 8.1 Current state of a specific funding method
```sql
SELECT
    HistoryFundingID,
    FundingID,
    FundingTypeID,
    ManagerID,
    IsBlocked,
    BlockedDescription,
    BlockedAt,
    IsRefundExcluded,
    DocumentRequired,
    ValidFrom AS ActiveSince,
    DateCreated
FROM History.BillingFunding WITH (NOLOCK)
WHERE FundingID = @FundingID
  AND ValidTo = '3000-01-01 00:00:00.000';
-- Uses IDX_Filtered_HistoryBillingFunding_ValidTo
```

### 8.2 Full change history for a funding method
```sql
SELECT
    HistoryFundingID,
    IsBlocked,
    BlockedDescription,
    ManagerID,
    ValidFrom,
    ValidTo,
    DATEDIFF(SECOND, ValidFrom, ValidTo) AS ActiveSeconds,
    JSON_VALUE(Trace, '$.SUserName') AS ChangedBy
FROM History.BillingFunding WITH (NOLOCK)
WHERE FundingID = @FundingID
ORDER BY ValidFrom ASC;
```

### 8.3 Recently blocked payment methods
```sql
SELECT TOP 100
    FundingID,
    FundingTypeID,
    BlockedDescription,
    BlockedAt,
    ValidFrom AS BlockedRecordedAt,
    JSON_VALUE(Trace, '$.SUserName') AS BlockedBy
FROM History.BillingFunding WITH (NOLOCK)
WHERE IsBlocked = 1
  AND ValidTo = '3000-01-01 00:00:00.000'
  AND BlockedAt >= DATEADD(day, -7, GETUTCDATE())
ORDER BY BlockedAt DESC;
-- Filtered index applies for ValidTo='3000-01-01' filter
```

---

## 9. Atlassian Knowledge Sources

Related Confluence pages found:
- "Funding Type Updates" (Confluence 949092542) - documents funding type configuration changes
- "Funding Service changes" (Confluence 8646099006) - Funding service evolution documentation
- "MIMO Tables Fields" (Confluence 8599240947) - MIMO system table field documentation

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.2/10 (Elements: 9.5/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 14 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 3 Confluence + 0 Jira | Procedures: 0 (triggers analyzed) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.BillingFunding | Type: Table | Source: etoro/etoro/History/Tables/History.BillingFunding.sql*
