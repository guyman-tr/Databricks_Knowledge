# Wallet.TermsAndConditions

> Version-controlled registry of Terms and Conditions documents that customers must accept before using the crypto wallet, with associated legal links and configuration per legal entity type.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | Id (int, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active NC UNIQUE + 1 clustered PK |
| **Temporal** | Yes - SYSTEM_VERSIONING with history table Wallet.TermsAndConditions_History |

---

## 1. Business Meaning

This table stores all versions of the Terms and Conditions documents that users must accept to use the eToro crypto wallet. Each row represents a specific T&C version for a specific legal entity type (TypeId), containing the document URL and associated legal links (fees, terms of use, customer support) in JSON format. The table uses temporal (system-versioned) tracking to maintain a full audit trail of T&C changes.

Regulatory compliance requires that users explicitly accept the current T&C before accessing wallet features. When T&C are updated, a new version is inserted, and all users must re-accept before proceeding. The `TypeId` allows different T&C versions for different eToro legal entities (e.g., eToroX vs eToroUS may have jurisdiction-specific terms).

The table has 37 rows representing the history of T&C versions from V1 (Aug 2018) through the current version. `Wallet.CustomerTermsAndConditions` tracks which version each customer has accepted. `Wallet.GetCustomerTermsAndConditions` and `Wallet.StoreCustomerTermsAndConditions` manage the customer acceptance flow.

---

## 2. Business Logic

### 2.1 Versioned T&C per Legal Entity

**What**: Each T&C version is scoped to a specific legal entity type, allowing jurisdiction-specific terms.

**Columns/Parameters Involved**: `Version`, `TypeId`, `Url`

**Rules**:
- The combination (Version, TypeId) is unique - each legal entity gets its own version track
- TypeId differentiates T&C sets (e.g., TypeId=1 for eToroX, TypeId=2 for other entities)
- When T&C are updated, a new row is inserted with the next version number
- The system checks the latest version for the user's legal entity against what they accepted

### 2.2 Temporal Audit Trail

**What**: All changes to T&C records are tracked via SQL Server temporal tables.

**Columns/Parameters Involved**: `ValidFrom`, `ValidTo` (hidden)

**Rules**:
- System-versioned table automatically tracks all modifications
- History stored in `Wallet.TermsAndConditions_History`
- Enables regulatory audits: "What T&C was active on date X?"
- Hidden columns (ValidFrom, ValidTo) managed by SQL Server automatically

---

## 3. Data Overview

| Id | Version | TypeId | Url (truncated) | Meaning |
|---|---|---|---|---|
| 1 | V1 | 1 | http://etorox.com/eToroX Wallet T&C.pdf | Original eToroX wallet T&C (Aug 2018). First version users accepted during initial crypto wallet launch. |
| 4 | V4 | 1 | http://etorox.com/...V4... | Fourth revision of eToroX T&C. Each version reflects regulatory or product changes. |
| 37 | (latest) | (varies) | (varies) | Most recent T&C version. New users and existing users who haven't accepted are prompted. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate primary key. Referenced by Wallet.CustomerTermsAndConditions to record which version a user accepted. |
| 2 | Version | varchar(20) | NO | - | VERIFIED | Version identifier string (e.g., "V1", "V2", "V3"). Combined with TypeId forms a unique business key. Sequential versioning allows easy comparison of acceptance currency. |
| 3 | Url | varchar(1024) | NO | - | CODE-BACKED | URL to the PDF document containing the full T&C text. Hosted on eToro domains (etorox.com, etoro.com). Used to present the document to users for review before acceptance. |
| 4 | Occured | datetime2(7) | NO | getutcdate() | CODE-BACKED | Timestamp when this T&C version was published/inserted. Note: column name contains a typo ("Occured" instead of "Occurred"). Used to determine the chronological order of T&C versions. |
| 5 | TypeId | int | YES | - | CODE-BACKED | Legal entity type identifier that scopes this T&C version. Different eToro entities (eToroX, eToroUS, eToroEU, etc.) may have jurisdiction-specific terms. Part of unique constraint with Version. Implicit reference to the eToro legal entity system. |
| 6 | LinksJson | nvarchar(max) | YES | - | CODE-BACKED | JSON object containing associated legal links: feesAndLimitsUrl, termsOfUseUrl, sendTransactionWarningLink, customerSupport. These links are displayed in the wallet UI alongside the T&C acceptance prompt. Schema is consistent across versions. |
| 7 | ValidFrom | datetime2(7) | NO | getutcdate() | CODE-BACKED | System-versioned temporal column (HIDDEN). Automatically set by SQL Server when a row is inserted or updated. Marks the start of this row version's validity period. |
| 8 | ValidTo | datetime2(7) | NO | 9999-12-31 23:59:59.9999999 | CODE-BACKED | System-versioned temporal column (HIDDEN). Automatically set by SQL Server when a row is superseded by an update. Default value indicates the row is currently active. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.CustomerTermsAndConditions | TermsAndConditionsId (implicit) | Implicit | Records which T&C version each customer has accepted |
| Wallet.TermsAndConditions_History | - | Temporal | System-versioned history table tracking all changes to T&C records |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.CustomerTermsAndConditions | Table | Implicit FK - stores user acceptance records |
| Wallet.TermsAndConditions_History | Table | Temporal history table |
| Wallet.GetCustomerTermsAndConditions | Stored Procedure | Reads T&C for customer acceptance check |
| Wallet.StoreCustomerTermsAndConditions | Stored Procedure | Records customer T&C acceptance |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_TermsAndConditions | CLUSTERED PK | Id ASC | - | - | Active |
| IX_Wallet_TermsAndConditions_Version_TypeId | NC UNIQUE | Version ASC, TypeId ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_TermsAndConditions_Occured | DEFAULT | getutcdate() - auto-sets publication timestamp |
| DF (ValidFrom) | DEFAULT | getutcdate() - temporal period start |
| DF (ValidTo) | DEFAULT | 9999-12-31 23:59:59.9999999 - temporal period end (current row) |

---

## 8. Sample Queries

### 8.1 Get the latest T&C version per type
```sql
SELECT t1.Id, t1.Version, t1.TypeId, t1.Url, t1.Occured
FROM Wallet.TermsAndConditions t1 WITH (NOLOCK)
WHERE t1.Id = (
    SELECT MAX(t2.Id)
    FROM Wallet.TermsAndConditions t2 WITH (NOLOCK)
    WHERE t2.TypeId = t1.TypeId
)
```

### 8.2 List all T&C versions for a specific type
```sql
SELECT Id, Version, Url, Occured
FROM Wallet.TermsAndConditions WITH (NOLOCK)
WHERE TypeId = 1
ORDER BY Id
```

### 8.3 View T&C with associated links
```sql
SELECT Id, Version, TypeId, Url,
    JSON_VALUE(LinksJson, '$.feesAndLimitsUrl') AS FeesUrl,
    JSON_VALUE(LinksJson, '$.termsOfUseUrl') AS TermsUrl,
    JSON_VALUE(LinksJson, '$.customerSupport') AS SupportUrl
FROM Wallet.TermsAndConditions WITH (NOLOCK)
ORDER BY Id DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 8.8/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.TermsAndConditions | Type: Table | Source: WalletDB/Wallet/Tables/Wallet.TermsAndConditions.sql*
