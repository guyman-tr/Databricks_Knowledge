# Trade.CashoutRange

> Configuration table defining withdrawal (cashout) fee amounts per fee group, using monetary range brackets to determine the fee charged for each withdrawal request.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | RangeID (INT, IDENTITY, CLUSTERED PK) |
| **Partition** | No (PRIMARY filegroup) |
| **Row Count** | 4 (MCP verified) |
| **Indexes** | 1 active (PK only) |
| **Temporal** | Yes - SYSTEM_VERSIONING ON, history: History.TradeCashoutRange |

---

## 1. Business Meaning

Trade.CashoutRange defines the fee schedule for customer withdrawals (cashouts) on the eToro platform. Each row specifies a monetary range (FromValue to ToValue) and the fee charged for withdrawals within that range, scoped to a specific fee group. Fee groups classify customers into tiers - Default (standard fees), Exempt (zero fees), and Discount (reduced fees) - based on their eToro Club loyalty level and Popular Investor status.

Without this table, the platform would have no way to determine what fee to charge when a customer requests a withdrawal. The withdrawal process (Billing.WithdrawRequestAdd) depends on this table to look up the applicable fee based on the customer's fee group and the withdrawal amount.

Rows are managed by back-office operations and are not created by automated processes. The table uses temporal versioning (History.TradeCashoutRange) to track all fee schedule changes over time. At withdrawal time, Billing.WithdrawRequestAdd reads the customer's CashoutFeeGroupID from BackOffice.Customer, then queries this table to find the fee where the withdrawal amount falls within the FromValue-ToValue range for that group.

---

## 2. Business Logic

### 2.1 Fee Range Lookup at Withdrawal Time

**What**: Determines the withdrawal fee for a customer based on their fee group and withdrawal amount.

**Columns/Parameters Involved**: `CashoutFeeGroupID`, `FromValue`, `ToValue`, `Fee`

**Rules**:
- Billing.WithdrawRequestAdd retrieves the customer's CashoutFeeGroupID from BackOffice.Customer
- It then selects the first matching row from Trade.CashoutRange where CashoutFeeGroupID matches AND the withdrawal amount (in dollars) falls between FromValue and ToValue
- The fee is multiplied by 100 (converted to cents) and subtracted from the withdrawal amount
- Fees are exempted entirely for specific compensation reasons: CompensationReasonID 41 (Guru cash with CO), 51 (Affiliate payment with CO), and 121 (PI Reimbursement)
- The fee is applied as a negative balance entry via Customer.SetBalance with credit type 15 (cashout fee)

**Diagram**:
```
Customer requests withdrawal ($X)
       |
       v
Lookup CashoutFeeGroupID from BackOffice.Customer
       |
       v
Query Trade.CashoutRange:
  WHERE CashoutFeeGroupID = @GroupID
    AND @Amount >= FromValue
    AND @Amount <= ToValue
       |
       v
  +-------------------+-------------------+-------------------+
  | Group 1 (Default) | Group 2 (Exempt)  | Group 3 (Discount)|
  | $1 - $100M: $5    | $1 - $100M: $0    | $1 - $500: $0     |
  |                    |                    | $500+ : $5        |
  +-------------------+-------------------+-------------------+
       |
       v
Net withdrawal = $X - Fee
Fee deducted as separate balance entry (CreditType=15)
```

### 2.2 Fee Group Tiering

**What**: Customers are classified into fee groups based on loyalty and Popular Investor status.

**Columns/Parameters Involved**: `CashoutFeeGroupID`, `IsDefault`

**Rules**:
- Fee groups are assigned via Billing.ProcessCashoutFeeGroupUpdate based on the customer's PlayerLevel (eToro Club tier) and GuruStatus (Popular Investor tier)
- Mapping tables Billing.PlayerLevelToCashoutFeeGroup and Billing.GuruStatusToCashoutFeeGroup determine which fee group applies
- Manual override is possible via BackOffice.CustomerSetCashoutFeeGroup
- The IsDefault flag marks the default fee range within a group (RangeID 7 for group 1 is the system-wide default)
- New customers default to CashoutFeeGroupID=1 (Default) at registration via Customer.InsertRealCustomer

---

## 3. Data Overview

| RangeID | CashoutFeeGroupID | FromValue | ToValue | Fee | IsDefault | Meaning |
|---|---|---|---|---|---|---|
| 4 | 2 (Exempt) | $1 | $100,000,000 | $0 | No | Full exemption range - premium customers (high-tier eToro Club members, active Popular Investors) pay zero withdrawal fees regardless of amount |
| 5 | 3 (Discount) | $1 | $500 | $0 | No | Discount group small-amount range - withdrawals up to $500 are fee-free for mid-tier loyalty customers |
| 6 | 3 (Discount) | $500.01 | $100,000,000 | $5 | No | Discount group large-amount range - withdrawals above $500 incur a reduced $5 fee for mid-tier customers |
| 7 | 1 (Default) | $1 | $100,000,000 | $5 | Yes | Default fee range - standard $5 flat fee for all withdrawal amounts. This is the system default row (IsDefault=1), applied to most customers |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RangeID | int | NO | IDENTITY(1,1) | VERIFIED | Auto-incrementing primary key identifying each fee range row. NOT FOR REPLICATION - identity values are not reseeded during replication. Used internally only; not referenced by other tables. |
| 2 | CashoutFeeGroupID | int | YES | 0 | VERIFIED | FK to Dictionary.CashoutFeeGroup identifying which customer fee tier this range belongs to. 1=Default (standard fees), 2=Exempt (zero fees for premium customers), 3=Discount (reduced fees for mid-tier). See [Cashout Fee Group](../../Dictionary/Tables/Dictionary.CashoutFeeGroup.md). Joined by Billing.WithdrawRequestAdd to match customer's group from BackOffice.Customer.CashoutFeeGroupID. Default 0 is a safety net but all live rows have valid group IDs. |
| 3 | FromValue | money | YES | - | CODE-BACKED | Lower bound (inclusive) of the withdrawal amount range in dollars. Billing.WithdrawRequestAdd checks `@Amount/100.0 >= FromValue` (amount is passed in cents, divided by 100 for dollar comparison). Defines the minimum withdrawal amount for this fee bracket. |
| 4 | ToValue | money | YES | - | CODE-BACKED | Upper bound (inclusive) of the withdrawal amount range in dollars. Billing.WithdrawRequestAdd checks `@Amount/100.0 <= ToValue`. Current data uses $100,000,000 as the effective maximum (no upper limit). Together with FromValue, defines the fee bracket. |
| 5 | Fee | money | YES | - | CODE-BACKED | Flat fee amount in dollars charged for withdrawals within this range. Billing.WithdrawRequestAdd multiplies by 100 to convert to cents (`Fee*100`), then deducts from withdrawal via Customer.SetBalance with CreditType=15. Current values: $0 (exempt/small discount) or $5 (default/large discount). |
| 6 | IsDefault | bit | YES | - | CODE-BACKED | Marks the system-wide default fee range. Currently only RangeID 7 (Default group, $1-$100M, $5 fee) has IsDefault=1. Used to identify the fallback fee configuration when a specific group match is not found. |
| 7 | Trace | computed | NO | - | VERIFIED | Computed audit column: `concat('{"HostName": "',host_name(),'","AppName": "',app_name(),'","SUserName": "',suser_name(),'","SPID": "',@@spid,'","DBName": "',db_name(),'","ObjectName": "',object_name(@@procid),'"}')`. Captures the session context (host, application, SQL login, SPID, database, calling procedure) for every DML operation. Standard eToro audit pattern for temporal tables. |
| 8 | ValidFrom | datetime2(7) | NO | - | VERIFIED | System-versioned temporal column (GENERATED ALWAYS AS ROW START). Records when this row version became current. Part of PERIOD FOR SYSTEM_TIME. Managed automatically by SQL Server - set on INSERT and UPDATE. |
| 9 | ValidTo | datetime2(7) | NO | - | VERIFIED | System-versioned temporal column (GENERATED ALWAYS AS ROW END). Records when this row version was superseded. Part of PERIOD FOR SYSTEM_TIME. Value of 9999-12-31 indicates the row is current. When updated, the old version moves to History.TradeCashoutRange with the actual end time. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CashoutFeeGroupID | Dictionary.CashoutFeeGroup | Explicit FK (FK_DCFG_TPL) | Maps each fee range row to its fee group tier (Default/Exempt/Discount). The group determines which customers see this fee range. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.TradeCashoutRange | - | Temporal History | System-versioned history table storing all previous versions of CashoutRange rows |
| Billing.WithdrawRequestAdd | CashoutFeeGroupID, FromValue, ToValue | SELECT WHERE | Primary consumer - looks up the applicable withdrawal fee during cashout processing |
| Billing.WithdrawalService_GetCustomerFeeGroups | CashoutFeeGroupID | JOIN | Returns fee ranges for a specific customer by joining to BackOffice.Customer |
| MIMOAlerts.FinancialDiscrepancies_GetWithdrawRequestFeeSettings | - | SELECT * | Reads all fee settings for financial discrepancy alert monitoring |
| Customer.RegisterDemo | - | Reference | Referenced during demo account setup |
| Customer.GetMiscData | - | Reference | Returns fee configuration as part of customer miscellaneous data |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.CashoutRange (table)
└── Dictionary.CashoutFeeGroup (table) [FK target]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.CashoutFeeGroup | Table | FK target - CashoutFeeGroupID references CashoutFeeGroupID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.TradeCashoutRange | Table | Temporal history table |
| Billing.WithdrawRequestAdd | Stored Procedure | Reads fee by group and amount range during withdrawal |
| Billing.WithdrawalService_GetCustomerFeeGroups | Stored Procedure | JOINs to return fee ranges per customer |
| MIMOAlerts.FinancialDiscrepancies_GetWithdrawRequestFeeSettings | Stored Procedure | Reads all rows for financial alert monitoring |
| Customer.RegisterDemo | Stored Procedure | References during demo registration |
| Customer.GetMiscData | Stored Procedure | Reads as part of customer configuration |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_TRCR_TPL | CLUSTERED PK | RangeID ASC | - | - | Active (FILLFACTOR=95) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_TRCR_TPL | PRIMARY KEY | Unique range identifier, CLUSTERED on PRIMARY filegroup |
| FK_DCFG_TPL | FOREIGN KEY | CashoutFeeGroupID -> Dictionary.CashoutFeeGroup(CashoutFeeGroupID). WITH CHECK - validates all existing and new rows |
| (unnamed) | DEFAULT | CashoutFeeGroupID defaults to 0 - safety net for rows inserted without explicit group |

---

## 8. Sample Queries

### 8.1 Show all fee ranges with group names
```sql
SELECT  cr.RangeID,
        dcfg.Name           AS FeeGroupName,
        cr.FromValue,
        cr.ToValue,
        cr.Fee,
        cr.IsDefault
FROM    Trade.CashoutRange cr WITH (NOLOCK)
JOIN    Dictionary.CashoutFeeGroup dcfg WITH (NOLOCK)
        ON cr.CashoutFeeGroupID = dcfg.CashoutFeeGroupID
ORDER BY cr.CashoutFeeGroupID, cr.FromValue;
```

### 8.2 Find the fee for a specific customer and withdrawal amount
```sql
DECLARE @CID INT = 12345;
DECLARE @AmountInCents INT = 75000; -- $750

SELECT  TOP 1 cr.Fee
FROM    Trade.CashoutRange cr WITH (NOLOCK)
JOIN    BackOffice.Customer bc WITH (NOLOCK)
        ON bc.CashoutFeeGroupID = cr.CashoutFeeGroupID
WHERE   bc.CID = @CID
        AND @AmountInCents / 100.0 >= cr.FromValue
        AND @AmountInCents / 100.0 <= cr.ToValue;
```

### 8.3 View fee schedule change history (temporal query)
```sql
SELECT  RangeID,
        CashoutFeeGroupID,
        FromValue,
        ToValue,
        Fee,
        IsDefault,
        ValidFrom,
        ValidTo
FROM    Trade.CashoutRange
FOR SYSTEM_TIME ALL
ORDER BY RangeID, ValidFrom;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found with direct information about Trade.CashoutRange. Business meaning derived from procedure logic analysis (Billing.WithdrawRequestAdd, Billing.WithdrawalService_GetCustomerFeeGroups) and the documented Dictionary.CashoutFeeGroup table.

---

*Generated: 2026-03-15 | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 5 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.CashoutRange | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.CashoutRange.sql*
