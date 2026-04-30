# AffiliateCommission.AffiliateTraderCreditQueue

> Message queue table storing XML-encoded credit events (deposits, chargebacks) awaiting processing by the affiliate commission pipeline. Analogous to AffiliateTraderRegistrationQueue but for credit events.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Table |
| **Key Identifier** | CreditID (bigint, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

AffiliateTraderCreditQueue is a message queue table that temporarily holds credit events (deposits, chargebacks) for affiliate commission processing. Each row represents one credit event that needs to be processed to determine if an affiliate commission should be paid or reversed. It is the credit-domain counterpart of AffiliateTraderRegistrationQueue.

This table exists as an intermediary in the asynchronous credit processing pipeline. When a customer makes a deposit or a chargeback occurs, the event details are placed here as an XML message. A background process reads unhandled messages, processes them (creating Credit, CreditEvent, and CreditCommission records), and removes processed messages.

The table holds 4,247 rows with data from February 2025. Unlike the registration queue (which was disabled via PART-1253), this queue appears to retain messages longer. The CreditID in the PK maps to the same CreditID that will be used in the Credit table, indicating the CreditID is assigned at the source system before reaching this queue.

---

## 2. Business Logic

### 2.1 Credit Queue Processing

**What**: Credit events are queued, processed, and removed with a retry mechanism.

**Columns/Parameters Involved**: `CreditID`, `CreditMessage`, `DateCreated`, `DateModified`

**Rules**:
- ReadCreditUnhandledMessages picks up messages where DateModified is more than 10 minutes old (same pattern as RegistrationQueue)
- Each pickup updates DateModified, resetting the 10-minute retry window
- Processed messages are deleted by RemoveCreditUnhandledMessage
- XML contains: CID, OriginalCID, ProviderID chain, CountryID, AffiliateID, AffiliateCampaign, Amount, IsFirstDeposit, Type, BannerID, DownloadID, LabelID, FunnelID, PlayerLevelID, Occurred, CreditID, GCID

### 2.2 XML Message Structure

**What**: Each credit message contains the full context for commission processing.

**Columns/Parameters Involved**: `CreditMessage`

**Rules**:
- Root element: `<AffiliateTraderCredit>`
- Type field maps to CreditTypeID (1=Deposit, 4/5=Chargeback)
- IsFirstDeposit indicates FTD status - critical for CPA commission models
- CreditID is pre-assigned by the source system (unlike Registration which uses IDENTITY)

---

## 3. Data Overview

| CreditID | DateCreated | CreditMessage (key fields) | Meaning |
|---|---|---|---|
| 2166743217 | 2025-02-23 11:28 | CID 19025328, Amount 10622, FTD, Type 1, Country 143, Affiliate 3 | Large first deposit ($10,622) queued for processing. Copy-trade customer (OriginalCID 13522611). |
| 2166743216 | 2025-02-23 11:28 | CID 19025329, Amount 12953, FTD, Type 1, Country 218, Affiliate 3 | Another large FTD ($12,953). Same batch, same affiliate. Country 218. |
| 2166743215 | 2025-02-23 11:24 | CID 19025326, Amount 12953, FTD, Type 1, Country 218, Affiliate 3 | Same pattern - large FTD from same affiliate batch. FunnelID -9 (possibly unresolved/default). |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CreditID | bigint | NO | - | CODE-BACKED | Unique identifier of the credit event. PK. Pre-assigned by the source system (not IDENTITY). Maps to Credit.CreditID after processing. |
| 2 | CreditMessage | xml | YES | - | CODE-BACKED | Full XML payload containing the credit event data. Includes CID, OriginalCID, ProviderID chain, CountryID, AffiliateID, AffiliateCampaign, Amount, IsFirstDeposit, Type (CreditTypeID), tracking IDs (BannerID, DownloadID, FunnelID, LabelID, PlayerLevelID), Occurred timestamp, and GCID. |
| 3 | DateCreated | datetime | NO | getutcdate() | CODE-BACKED | UTC timestamp when the message entered the queue. Auto-set via default constraint. |
| 4 | DateModified | datetime | NO | getutcdate() | CODE-BACKED | UTC timestamp of last processing attempt. Updated by ReadCreditUnhandledMessages on each pickup. The 10-minute gap between DateModified and current time determines retry eligibility. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CreditID | AffiliateCommission.Credit | Implicit | Links to the Credit record created during processing |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| AffiliateCommission.LoadAffiliateTraderCreditQueue | INSERT | Writer | Loads messages from Service Broker |
| AffiliateCommission.ReadCreditUnhandledMessages | UPDATE/OUTPUT | Reader/Modifier | Picks up unhandled messages |
| AffiliateCommission.RemoveCreditUnhandledMessage | DELETE | Deleter | Removes processed messages |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.AffiliateTraderCreditQueue (table)
└── AffiliateCommission.Credit (table) [implicit, via CreditID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.Credit | Table | CreditID references Credit records (created during processing) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.LoadAffiliateTraderCreditQueue | Stored Procedure | Writer |
| AffiliateCommission.ReadCreditUnhandledMessages | Stored Procedure | Reader/Modifier |
| AffiliateCommission.RemoveCreditUnhandledMessage | Stored Procedure | Deleter |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_AffiliateTraderCreditQueue | CLUSTERED PK | CreditID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_AffiliateTraderCreditQueue | PRIMARY KEY | Unique CreditID - prevents duplicate messages |
| DF_AffiliateCommissionAffiliateTraderCreditQueue_DateCreated | DEFAULT | getutcdate() |
| DF_AffiliateTraderCreditQueue_DateModified | DEFAULT | getutcdate() |

---

## 8. Sample Queries

### 8.1 Count unhandled messages
```sql
SELECT COUNT(*) AS UnhandledCount
FROM AffiliateCommission.AffiliateTraderCreditQueue WITH (NOLOCK)
WHERE DATEADD(minute, 10, DateModified) < GETUTCDATE();
```

### 8.2 Extract key fields from XML messages
```sql
SELECT TOP 10 CreditID,
    CreditMessage.value('(/AffiliateTraderCredit/CID)[1]', 'bigint') AS CID,
    CreditMessage.value('(/AffiliateTraderCredit/Amount)[1]', 'float') AS Amount,
    CreditMessage.value('(/AffiliateTraderCredit/IsFirstDeposit)[1]', 'bit') AS IsFirstDeposit,
    CreditMessage.value('(/AffiliateTraderCredit/Type)[1]', 'tinyint') AS CreditTypeID,
    CreditMessage.value('(/AffiliateTraderCredit/AffiliateID)[1]', 'int') AS AffiliateID,
    DateCreated
FROM AffiliateCommission.AffiliateTraderCreditQueue WITH (NOLOCK)
ORDER BY CreditID DESC;
```

### 8.3 Join with Credit to find processed vs unprocessed
```sql
SELECT q.CreditID,
       CASE WHEN c.CreditID IS NOT NULL THEN 'Processed' ELSE 'Pending' END AS Status,
       q.DateCreated, q.DateModified
FROM AffiliateCommission.AffiliateTraderCreditQueue q WITH (NOLOCK)
LEFT JOIN AffiliateCommission.Credit c WITH (NOLOCK) ON q.CreditID = c.CreditID
ORDER BY q.CreditID DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.AffiliateTraderCreditQueue | Type: Table | Source: fiktivo/AffiliateCommission/Tables/AffiliateCommission.AffiliateTraderCreditQueue.sql*
