# History.WithdrawLog

> Encrypted audit log of request/response message pairs for external withdrawal/payout API calls. Each row captures the encrypted payload sent to a payment service and the encrypted response received, linked to a specific WithdrawToFunding record. Written by History.WithdrawLogAdd (called by SQL_SecurePay, RedeemServiceUser, and PayoutUser).

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | ID (int, IDENTITY PK) |
| **Partition** | No - CLUSTERED PK on [PRIMARY] |
| **Indexes** | 1 (CLUSTERED PK on ID) |

---

## 1. Business Meaning

This table is a compliance and debugging audit trail for external payment/withdrawal API calls. Every request sent to an external payment service (withdrawal processor, crypto transfer gateway, payout provider) and its response are logged here in encrypted form. The encryption is intentional - messages likely contain PII, payment account details, or PCI-scope data.

The table is highly active: ID=54,107,780 as of 2026-03-19, with multiple entries per minute. This indicates it logs all withdrawal-related API traffic across all withdrawal types (standard withdrawal, redeem/crypto transfer, payouts).

Three distinct services write to this table:
- **SQL_SecurePay**: The primary payment processing service
- **RedeemServiceUser**: The crypto redeem service (crypto transfer to eToro Wallet)
- **PayoutUser**: The payout scheduling/processing service

All three call `History.WithdrawLogAdd` to insert records.

---

## 2. Business Logic

### 2.1 Write Pattern - History.WithdrawLogAdd

**What**: Simple SP-based insert. All three writing services use this same SP.

**Rules**:
```sql
CREATE PROCEDURE [History].[WithdrawLogAdd]
    @WithdrawToFundingID int,
    @RequestMessage varchar(max),
    @ResponseMessage varchar(max),
    @RequestDate smalldatetime,
    @ResponseDateDateTime smalldatetime
AS BEGIN
    INSERT INTO [History].[WithdrawLog]
        ([WithdrawToFundingID], [RequestMessage], [ResponseMessage],
         [RequestDate], [ResponseDateDateTime])
    VALUES (@WithdrawToFundingID, @RequestMessage, @ResponseMessage,
            @RequestDate, @ResponseDateDateTime)
END
```
- `RequestDate` and `ResponseDateDateTime` are `smalldatetime` params (1-minute precision) - times are rounded to the nearest minute
- Table has DEFAULT (getutcdate()) on `RequestDate` as safety net, but SP always passes explicit values
- `ResponseMessage` can be NULL (if response not yet received or call failed before response)
- No transaction wrapping - each log entry is an independent atomic insert

### 2.2 Encrypted Message Format

**What**: RequestMessage and ResponseMessage store encrypted payloads, not plain text.

**Rules** (observed in data):
- Both fields contain what appears to be Base64-encoded ciphertext (e.g., `"ZCM5ajAFlbEaGBdKnO1IpF/d8rF+EW7CHDe6OBnOIWw="`)
- Encryption is applied by the calling service before passing to the SP - the database does not encrypt/decrypt
- Purpose: compliance (PCI DSS, PII protection for payment details)
- Content likely includes: payment gateway API request payloads, transaction IDs, payment amounts, account references
- The same ResponseMessage can appear across multiple rows (same gateway response applied to multiple funding records)

### 2.3 WithdrawToFunding Context

**What**: Each log entry links to a specific withdrawal destination record.

**Columns/Parameters Involved**: `WithdrawToFundingID`

**Rules**:
- `WithdrawToFundingID` is NULL-allowed (some log entries may not be tied to a specific funding destination, e.g., system-level errors or pre-funding-record requests)
- `Billing.WithdrawToFunding` holds the customer's registered withdrawal destinations (bank accounts, e-wallets, crypto wallet addresses)
- Multiple log entries per WithdrawToFundingID are expected (each API call = one row)

### 2.4 Request vs Response Timing

**What**: RequestDate and ResponseDateDateTime track the roundtrip latency of external API calls.

**Rules**:
- `RequestDate`: when the request was dispatched (smalldatetime = 1-minute granularity)
- `ResponseDateDateTime`: when the response was received (NULL if no response received)
- In observed data, both timestamps are equal (within the same minute), suggesting rapid API responses
- A NULL `ResponseDateDateTime` with non-NULL `RequestDate` indicates a pending or failed call

---

## 3. Data Overview

| Metric | Value |
|--------|-------|
| Total rows (approx) | ~54,107,780 (ID=54107780 as of 2026-03-19) |
| Date range | Active as of 2026-03-19 (earliest data predates clone range) |
| Write frequency | Multiple entries per minute (active payment processing environment) |

Sample (recent rows, messages truncated):

| ID | WithdrawToFundingID | RequestDate | ResponseDateDateTime | Notes |
|----|-------------------|-------------|---------------------|-------|
| 54107780 | 1371607 | 2026-03-19 04:53 | 2026-03-19 04:53 | Encrypted request/response pair |
| 54107779 | 1371609 | 2026-03-19 04:50 | 2026-03-19 04:50 | Encrypted request/response pair |
| 54107778 | 1371607 | 2026-03-19 04:50 | 2026-03-19 04:50 | Same WithdrawToFundingID, different request |

Repeated WithdrawToFundingIDs (e.g., 1371607 appears in both ID 54107780 and 54107778 within 3 minutes) confirms multiple API calls per funding record are normal (e.g., status checks, retries, final settlement calls).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incremented log entry ID. CLUSTERED PK. Approximately 54 million rows in production as of Mar 2026. |
| 2 | WithdrawToFundingID | int | YES | - | CODE-BACKED | The withdrawal destination record this API call is associated with (FK to Billing.WithdrawToFunding). NULL-allowed for calls not tied to a specific destination. |
| 3 | RequestMessage | varchar(max) | NO | - | CODE-BACKED | The encrypted request payload sent to the external payment API. Base64-encoded ciphertext. NOT NULL - every log entry must have a request. Content is PCI/PII-sensitive and encrypted by the calling service. |
| 4 | ResponseMessage | varchar(max) | YES | - | CODE-BACKED | The encrypted response received from the external payment API. NULL if no response received (pending or failed call). Same response message can appear across multiple rows (same gateway response). |
| 5 | RequestDate | datetime | NO | getutcdate() | CODE-BACKED | When the API request was sent. Passed as smalldatetime by History.WithdrawLogAdd (1-minute precision). DEFAULT=getutcdate() as safety net. |
| 6 | ResponseDateDateTime | datetime | YES | - | CODE-BACKED | When the API response was received. NULL for unanswered requests. Passed as smalldatetime (1-minute precision). Note: column name typo - "DateTime" suffix is redundant given the datetime type. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Target Object | Target Element | Relationship Type | Description |
|--------------|----------------|-------------------|-------------|
| Billing.WithdrawToFunding | WithdrawToFundingID | Implicit FK (no constraint) | The customer's registered withdrawal destination. NULL-allowed. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.WithdrawLogAdd | ID | Writer (INSERT) | SP used by all 3 writing services to insert log entries. Created 2019-11-05 (Ran Ovadia). |
| SQL_SecurePay | (service) | Writer (via SP) | Primary payment processing service. GRANT EXECUTE on History.WithdrawLogAdd. |
| RedeemServiceUser | (service) | Writer (via SP) | Crypto redeem/transfer service. GRANT EXECUTE on History.WithdrawLogAdd. |
| PayoutUser | (service) | Writer (via SP) | Payout scheduling service. GRANT EXECUTE on History.WithdrawLogAdd. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.WithdrawLog (table)
- Written by: History.WithdrawLogAdd (SP)
  - Called by SQL_SecurePay, RedeemServiceUser, PayoutUser services
  - Logs each external payment API call (request + encrypted response)
- Referenced by: Billing.WithdrawToFunding (implied by WithdrawToFundingID)
```

### 6.1 Objects This Depends On

No FK constraints. Implicit dependency: Billing.WithdrawToFunding (WithdrawToFundingID).

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.WithdrawLogAdd | SP | INSERT wrapper - used by all writing services |
| (Payment/audit reporting) | (external) | Compliance and debugging queries on encrypted logs |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_History_WithdrawLog | CLUSTERED | ID ASC | - | - | Active (FILLFACTOR=90, PAGE compression, PRIMARY filegroup) |

Note: TEXTIMAGE_ON [PRIMARY] - the varchar(max) columns are stored on the PRIMARY filegroup (same as the table). No secondary indexes - with 54M+ rows and encrypted varchar(max) payloads, lookups are typically by ID or by application-level correlation, not by WithdrawToFundingID.

### 7.2 Constraints

| Name | Type | Definition |
|------|------|------------|
| PK_History_WithdrawLog | PRIMARY KEY | ID ASC - clustered |
| Df_History_WithdrawLog_RequestDate | DEFAULT | RequestDate = getutcdate() |

---

## 8. Sample Queries

### 8.1 Recent withdrawal API calls for a funding destination

```sql
SELECT
    l.ID,
    l.WithdrawToFundingID,
    l.RequestDate,
    l.ResponseDateDateTime,
    CASE WHEN l.ResponseMessage IS NOT NULL THEN 'Responded' ELSE 'No Response' END AS Status,
    DATEDIFF(SECOND, l.RequestDate, l.ResponseDateDateTime) AS RoundtripSec
FROM History.WithdrawLog l WITH (NOLOCK)
WHERE l.WithdrawToFundingID = @WithdrawToFundingID
ORDER BY l.ID DESC;
```

### 8.2 Check for unanswered API calls (pending/failed requests)

```sql
SELECT
    l.ID,
    l.WithdrawToFundingID,
    l.RequestDate
FROM History.WithdrawLog l WITH (NOLOCK)
WHERE l.ResponseMessage IS NULL
  AND l.RequestDate >= DATEADD(HOUR, -1, GETUTCDATE())
ORDER BY l.RequestDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to History.WithdrawLog.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 8.8/10, Logic: 8.8/10, Relationships: 8.5/10, Sources: 7.5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (History.WithdrawLogAdd) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.WithdrawLog | Type: Table | Source: etoro/etoro/History/Tables/History.WithdrawLog.sql*
