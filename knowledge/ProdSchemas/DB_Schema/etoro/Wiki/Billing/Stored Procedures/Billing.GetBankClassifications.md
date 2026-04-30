# Billing.GetBankClassifications

> Returns bank quality-tier classifications for a specific country and payment method (typically Trustly/FundingTypeID=35), filtering to only banks where the standard and eToro-specific classification tiers agree, used by the deposit finalize flow to determine routing behavior.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns ID (Billing.BankClassification row identifier) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetBankClassifications` retrieves the bank quality-tier assignments for a specific country and funding type combination, joining the stored bank-level data with the classification lookup to produce human-readable tier names. It is the primary read path for the Trustly bank classification system — every Trustly deposit finalization that needs to know a bank's quality tier calls this procedure (via Ixopay service, Deposit service, or NotificationGateway).

In the Trustly payment flow, when a customer completes a Trustly deposit, the provider sends back a notification containing the bank name and country. The deposit service calls this procedure to look up the bank's classification tier for that country, then uses the classification to determine finalization behavior: for example, which club levels can be finalized immediately vs. requiring further processing (per the `bankClassification: [1, 2, 3]` logic in the Trustly notification config).

A key architectural detail: the JOIN condition (`BBC.ClassificationID = DBC.ClassificationID AND BBC.EtoroClassificationID = DBC.ClassificationID`) means only rows where both the standard and eToro-specific classification tiers are identical are returned. Banks where the two tiers disagree are excluded from this query — they would require a separate lookup or manual review. In practice, all 42,721 rows in `Billing.BankClassification` are for FundingTypeID=35 (Trustly), so `@WFundingTypeID=35` is the dominant use case.

---

## 2. Business Logic

### 2.1 Dual-Tier Consensus Filter

**What**: The SP's JOIN condition enforces a "both tiers must agree" filter, returning only banks where the standard classification and eToro's classification assessment are identical.

**Columns/Parameters Involved**: `ClassificationID`, `EtoroClassificationID`

**Rules**:
- `BBC.ClassificationID = DBC.ClassificationID AND BBC.EtoroClassificationID = DBC.ClassificationID` requires both IDs to equal the same Dictionary row
- This is equivalent to: only return rows where `ClassificationID = EtoroClassificationID`
- Banks with divergent tier assignments (e.g., standard=1 but eToro=3) are NOT returned by this SP
- The returned `ClassificationName` and `EtoroClassificationName` are the same value (both from the same DBC row), making the two output columns redundant
- Classification tiers: 1=Basic (default/new), 2=Evaluation (under review), 3=Optimised (high-performance)

**Diagram**:
```
Bank row in Billing.BankClassification
  ClassificationID = 3 ---> Dictionary.BankClassification(3) = "Optimised"
  EtoroClassificationID = 3 ---> Dictionary.BankClassification(3) = "Optimised"
  RESULT: Returned (both tiers agree = 3)

  ClassificationID = 1 ---> Dictionary.BankClassification(1) = "Basic"
  EtoroClassificationID = 3 ---> Dictionary.BankClassification(3) = "Optimised"
  RESULT: NOT returned (tiers differ)
```

### 2.2 Trustly Deposit Finalization Context

**What**: Bank classification determines which Trustly deposit notifications trigger immediate finalization vs. deferred processing.

**Columns/Parameters Involved**: `@WFundingTypeID`, `ClassificationID`

**Rules**:
- The Trustly notification config uses `bankClassification: [3]` with certain club levels for immediate finalization (Optimised banks only for club levels 1/3/4/5)
- All classification values `[1, 2, 3]` are accepted for finalization when payment_state is "credited" (funds already transferred)
- This procedure is called by NotificationGateway, Ixopay, and Deposit service during the Trustly post-payment notification handling
- Practically exclusive to FundingTypeID=35 (Trustly) - all 42,721 rows in Billing.BankClassification are for this funding type

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WFundingTypeID | int | - | (required) | CODE-BACKED | Payment method filter. In practice always 35 (Trustly) since all bank classification data is for Trustly. The 'W' prefix is a legacy convention. References Dictionary.FundingType.FundingTypeID implicitly. |
| 2 | @CountryID | int | - | (required) | CODE-BACKED | Country filter for bank lookup. References Dictionary.Country.CountryID. Dominant countries in the data are Germany and UK (where Trustly is most active for eToro). |

**Return Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | CODE-BACKED | Row identity key from Billing.BankClassification (IDENTITY PK). Uniquely identifies the bank-country-classification mapping row. |
| 2 | BankID | int | NO | - | CODE-BACKED | Legacy integer bank identifier from Billing.BankClassification. Always 0 in practice since December 2020 when BankIDStr replaced it as the primary identifier. Preserved for backward compatibility. |
| 3 | BankName | nvarchar | NO | - | CODE-BACKED | The bank name as received from Trustly in the payment notification (e.g., 'Barclays', 'Commerzbank'). The key lookup field used to resolve a bank to its classification tier during deposit finalization. |
| 4 | ClassificationID | int | NO | - | VERIFIED | Standard quality tier assigned to this bank: 1=Basic (new/unoptimized), 2=Evaluation (under review), 3=Optimised (high-performance). Only returned when equals EtoroClassificationID. (Dictionary.BankClassification) |
| 5 | EtoroClassificationID | int | NO | - | VERIFIED | eToro's own quality tier assessment for this bank. Same lookup as ClassificationID (1/2/3). Only returned when equals ClassificationID. Both fields will always be equal in this result set due to the JOIN condition. |
| 6 | ClassificationName | varchar | NO | - | VERIFIED | Human-readable tier name from Dictionary.BankClassification: 'Basic', 'Evaluation', or 'Optimised'. Populated from DBC where DBC.ClassificationID = BBC.ClassificationID. |
| 7 | EtoroClassificationName | varchar | NO | - | VERIFIED | Same value as ClassificationName (aliased from the same DBC.ClassificationName column). Both fields will always be identical because the JOIN requires both classification IDs to reference the same Dictionary row. Present for backward compatibility with callers expecting separate fields. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @WFundingTypeID filter | Dictionary.FundingType | Lookup (implicit) | Filters Billing.BankClassification rows by FundingTypeID. In practice always 35 (Trustly). |
| @CountryID filter | Dictionary.Country | Lookup (implicit) | Filters Billing.BankClassification rows by CountryID. |
| ClassificationID/EtoroClassificationID | Dictionary.BankClassification | JOIN (explicit) | Resolves classification IDs to human-readable tier names (Basic/Evaluation/Optimised). Both IDs must reference the same Dictionary row. |
| (main data) | Billing.BankClassification | Read | Source table for bank-to-classification mappings, filtered by country + funding type. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| NotificationGatewayUser (role) | EXECUTE permission | Permission | NotificationGateway service calls this during Trustly payment notification processing. |
| IxopayUser (role) | EXECUTE permission | Permission | Ixopay payment processor integration service calls this during Trustly transaction handling. |
| DepositUser (role) | EXECUTE permission | Permission | Deposit service calls this to look up bank classification during Trustly deposit finalization. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetBankClassifications (procedure)
├── Billing.BankClassification (table)
└── Dictionary.BankClassification (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.BankClassification | Table | Main data source. Filtered by @CountryID and @WFundingTypeID. Provides ID, BankID, BankName, ClassificationID, EtoroClassificationID. |
| Dictionary.BankClassification | Table | INNER JOIN on ClassificationID (AND EtoroClassificationID) to resolve tier IDs to ClassificationName. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| NotificationGatewayUser (role) | Permission | Trustly notification processing |
| IxopayUser (role) | Permission | Ixopay payment integration |
| DepositUser (role) | Permission | Deposit finalization flow |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Get bank classifications for Trustly deposits from Germany
```sql
EXEC Billing.GetBankClassifications @WFundingTypeID = 35, @CountryID = 79
-- Returns all German banks with matching classification tiers
```

### 8.2 Get bank classifications for Trustly deposits from United Kingdom
```sql
EXEC Billing.GetBankClassifications @WFundingTypeID = 35, @CountryID = 235
```

### 8.3 Direct query - find optimised banks by country for Trustly
```sql
SELECT bc.ID, bc.BankName, bc.BankIDStr, bc.ClassificationID, dbc.ClassificationName
FROM Billing.BankClassification bc WITH (NOLOCK)
JOIN Dictionary.BankClassification dbc WITH (NOLOCK)
  ON dbc.ClassificationID = bc.ClassificationID
  AND bc.EtoroClassificationID = dbc.ClassificationID
WHERE bc.FundingTypeID = 35
  AND bc.CountryID = 79
  AND bc.ClassificationID = 3  -- Optimised only
ORDER BY bc.BankName
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Trustly Funding Data Flow](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/1419280512/Trustly+Funding+Data+Flow) | Confluence | Confirms bankClassification [1,2,3] values are used in Trustly notification config to determine which deposit finalizations trigger immediately. Shows NotificationGateway, Ixopay, and Deposit service as the consuming services. |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.1/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 9/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 (1, 8, 10, 11)*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetBankClassifications | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetBankClassifications.sql*
