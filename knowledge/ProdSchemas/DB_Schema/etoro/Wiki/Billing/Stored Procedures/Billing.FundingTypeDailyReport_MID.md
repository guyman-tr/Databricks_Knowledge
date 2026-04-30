# Billing.FundingTypeDailyReport_MID

> Returns yesterday's deposit count grouped by merchant account (MID) for a given payment type, as JSON - used to monitor which merchant terminals are processing volume.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns JSON array of {Count, MID} sorted by Count DESC |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.FundingTypeDailyReport_MID` is the MID (Merchant ID / Merchant Account) dimension slice of the daily funding type monitoring suite. Operations teams use this to understand which merchant terminals processed the most volume for a specific payment method yesterday. MID distribution matters for load balancing, fee optimization, and detecting if a specific terminal is over- or under-utilized.

MID here refers to `Billing.ProtocolMIDSettings.Description` - the human-readable name of the merchant account configuration used to process the deposit.

See `Billing.FundingTypeDailyReport_All` for full suite documentation.

---

## 2. Business Logic

### 2.1 Merchant Account Volume Distribution

**What**: Counts deposits yesterday grouped by processing merchant account.

**Columns/Parameters Involved**: `@fundingTypeID`, `MID` (from BASE - Billing.ProtocolMIDSettings.Description via Billing.Deposit.ProtocolMIDSettingsID)

**Rules**:
- MID is the description of the merchant account that processed the deposit (from Billing.ProtocolMIDSettings).
- Ordered by Count DESC - busiest merchant account first.
- Used to monitor merchant account load distribution and identify routing patterns.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @fundingTypeID | INT | NO | 35 | CODE-BACKED | Payment instrument type to report on. Default 35. |

**Return columns** (FOR JSON AUTO):

| # | Column | Type | Confidence | Description |
|---|--------|------|------------|-------------|
| R1 | Count | int | CODE-BACKED | Number of deposits processed by this MID yesterday. |
| R2 | MID | nvarchar | CODE-BACKED | Merchant account description (from Billing.ProtocolMIDSettings.Description). Identifies the specific merchant terminal/account. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @fundingTypeID | Billing.FundingTypeDailyReport_BASE | Function call | All data retrieval delegated to this inline TVF |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Operations dashboards | External | Caller | MID load monitoring for payment methods |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.FundingTypeDailyReport_MID (procedure)
└── Billing.FundingTypeDailyReport_BASE (inline TVF)
      ├── Billing.Deposit (table)
      ├── Billing.Funding (table)
      ├── Billing.ProtocolMIDSettings (table)
      └── [other BASE dependencies - see FundingTypeDailyReport_All.md]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.FundingTypeDailyReport_BASE | Inline TVF | Provides base dataset; this proc adds GROUP BY MID + COUNT + FOR JSON AUTO |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Operations dashboards | External | MID distribution monitoring |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure. FOR JSON AUTO output.

---

## 8. Sample Queries

### 8.1 Get MID breakdown for funding type 35

```sql
EXEC [Billing].[FundingTypeDailyReport_MID] @fundingTypeID = 35;
-- Returns JSON: [{"Count":300,"MID":"MerchantAccountA"},{"Count":50,"MID":"MerchantAccountB"},...]
```

### 8.2 Ad-hoc MID breakdown without JSON

```sql
SELECT COUNT(*) AS [Count], MID
FROM [Billing].[FundingTypeDailyReport_BASE](35)
GROUP BY MID
ORDER BY COUNT(*) DESC;
```

### 8.3 Identify MID routing for a specific funding type

```sql
SELECT pms.ID, pms.Description AS MID, COUNT(*) AS DepositCount
FROM [Billing].[Deposit] d WITH (NOLOCK)
JOIN [Billing].[Funding] f WITH (NOLOCK) ON f.FundingID = d.FundingID
JOIN [Billing].[ProtocolMIDSettings] pms WITH (NOLOCK) ON pms.ID = d.ProtocolMIDSettingsID
WHERE f.FundingTypeID = 35
  AND d.PaymentDate >= GETDATE() - 1
GROUP BY pms.ID, pms.Description
ORDER BY DepositCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 5, 8, 9, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.FundingTypeDailyReport_MID | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.FundingTypeDailyReport_MID.sql*
