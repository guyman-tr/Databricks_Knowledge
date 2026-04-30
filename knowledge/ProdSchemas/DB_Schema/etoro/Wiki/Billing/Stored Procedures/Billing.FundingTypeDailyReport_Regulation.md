# Billing.FundingTypeDailyReport_Regulation

> Returns yesterday's deposit count grouped by regulatory entity for a given payment type, as JSON - used to monitor compliance/regulatory distribution of a payment method.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns JSON array of {Count, Regulation} sorted by Count DESC |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.FundingTypeDailyReport_Regulation` is the regulatory entity dimension slice of the daily funding type monitoring suite. eToro operates under multiple regulatory frameworks (CySEC, FCA, ASIC, etc.), and each deposit is processed under a specific `ProcessRegulationID` from `Dictionary.Regulation`. Operations and compliance teams use this procedure to verify that deposits for a specific payment method are being routed through the expected regulatory entities.

See `Billing.FundingTypeDailyReport_All` for full suite documentation.

---

## 2. Business Logic

### 2.1 Regulatory Distribution

**What**: Counts deposits yesterday grouped by the regulatory entity under which they were processed.

**Columns/Parameters Involved**: `@fundingTypeID`, `Regulation` (from BASE - Dictionary.Regulation.Name via Billing.Deposit.ProcessRegulationID)

**Rules**:
- Regulation is the legal/regulatory entity that processed the deposit (from Dictionary.Regulation.Name via Billing.Deposit.ProcessRegulationID).
- Ordered by Count DESC.
- Used for compliance monitoring: ensures payment methods are being used under the correct regulatory frameworks.

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
| R1 | Count | int | CODE-BACKED | Number of deposits under this regulation yesterday. |
| R2 | Regulation | nvarchar | CODE-BACKED | Regulatory entity name (from Dictionary.Regulation.Name via Billing.Deposit.ProcessRegulationID). Examples: "CySEC", "FCA", "ASIC". |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @fundingTypeID | Billing.FundingTypeDailyReport_BASE | Function call | All data retrieval delegated to this inline TVF |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Operations/compliance dashboards | External | Caller | Regulatory distribution monitoring for payment methods |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.FundingTypeDailyReport_Regulation (procedure)
└── Billing.FundingTypeDailyReport_BASE (inline TVF)
      ├── Billing.Deposit (table)
      ├── Billing.Funding (table)
      ├── Dictionary.Regulation (table)
      └── [other BASE dependencies - see FundingTypeDailyReport_All.md]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.FundingTypeDailyReport_BASE | Inline TVF | Provides base dataset; this proc adds GROUP BY Regulation + COUNT + FOR JSON AUTO |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Operations/compliance dashboards | External | Regulatory distribution monitoring |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure. FOR JSON AUTO output.

---

## 8. Sample Queries

### 8.1 Get regulation breakdown for funding type 35

```sql
EXEC [Billing].[FundingTypeDailyReport_Regulation] @fundingTypeID = 35;
-- Returns JSON: [{"Count":200,"Regulation":"CySEC"},{"Count":80,"Regulation":"FCA"},...]
```

### 8.2 Ad-hoc regulation breakdown without JSON

```sql
SELECT COUNT(*) AS [Count], Regulation
FROM [Billing].[FundingTypeDailyReport_BASE](35)
GROUP BY Regulation
ORDER BY COUNT(*) DESC;
```

### 8.3 Cross-check regulation distribution with expected routing

```sql
SELECT reg.Name AS Regulation, reg.ID, COUNT(*) AS DepositCount
FROM [Billing].[Deposit] d WITH (NOLOCK)
JOIN [Billing].[Funding] f WITH (NOLOCK) ON f.FundingID = d.FundingID
JOIN [Dictionary].[Regulation] reg WITH (NOLOCK) ON reg.ID = d.ProcessRegulationID
WHERE f.FundingTypeID = 35
  AND d.PaymentDate >= GETDATE() - 1
GROUP BY reg.Name, reg.ID
ORDER BY DepositCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 5, 8, 9, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.FundingTypeDailyReport_Regulation | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.FundingTypeDailyReport_Regulation.sql*
