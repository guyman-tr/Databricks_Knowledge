# Wallet.AmlProviderUsers

> Maps customers to their user identity on AML screening providers (Chainalysis), enabling per-user AML screening and risk profile tracking across blockchain analytics services.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | Id (bigint, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 2 active NC (1 unique) + 1 clustered PK |

---

## 1. Business Meaning

This table stores the mapping between eToro customer accounts (Gcid) and their corresponding user identities on AML screening providers. When a customer first performs a crypto transaction, the system registers them with the AML provider and stores the provider's user ID here. Subsequent AML checks reference this mapping to associate screening results with the correct customer profile.

Without this table, each AML screening would be stateless - the system could not maintain a customer's risk profile history across multiple transactions. The provider user ID enables Chainalysis to build up a risk profile for each customer over time.

Rows are created by `Wallet.StoreAmlProviderUsers` when a customer is first registered with an AML provider. With ~207K rows, this covers all customers who have performed at least one crypto transaction. The `ProviderUserId` appears to be a base64-encoded representation of the Gcid.

---

## 2. Business Logic

### 2.1 Provider-Specific User Registration

**What**: Each customer is registered independently with each AML provider they interact with.

**Columns/Parameters Involved**: `AmlProviderId`, `Gcid`, `ProviderUserId`

**Rules**:
- Unique constraint on (AmlProviderId, Gcid) ensures one registration per customer per provider
- Most customers are registered with AmlProviderId=1 (Chainalysis direct API)
- Newer customers may also be registered with AmlProviderId=4 (ChainalysisCDN)
- ProviderUserId is a base64-encoded string derived from the Gcid
- See [AML Provider](../../_glossary.md#aml-provider). FK to Dictionary.AmlProviders.

---

## 3. Data Overview

| Id | AmlProviderId | Gcid | ProviderUserId | Meaning |
|---|---|---|---|---|
| 226951 | 4 (ChainalysisCDN) | 46870594 | NDY4NzA1OTQ= | Customer registered with ChainalysisCDN for cached AML screening on newer blockchains |
| 226950 | 1 (Chainalysis) | 47401575 | NDc0MDE1NzU= | Customer registered with direct Chainalysis API for original blockchain AML screening |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate primary key. |
| 2 | AmlProviderId | int | NO | - | VERIFIED | The AML screening provider this registration is for: 1=Chainalysis, 4=ChainalysisCDN. See [AML Provider](../../_glossary.md#aml-provider). FK to Dictionary.AmlProviders. |
| 3 | Gcid | bigint | NO | - | CODE-BACKED | Global Customer ID. The eToro customer this AML provider registration belongs to. Part of unique constraint with AmlProviderId. |
| 4 | ProviderUserId | varchar(40) | NO | - | CODE-BACKED | The customer's user identifier on the AML provider's system. Base64-encoded representation of the Gcid (e.g., Gcid 46870594 -> "NDY4NzA1OTQ="). Used in all API calls to the provider. |
| 5 | Occurred | datetime2(7) | NO | - | CODE-BACKED | Timestamp when this customer was first registered with the AML provider. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| AmlProviderId | Dictionary.AmlProviders | FK | Identifies which AML provider |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.StoreAmlProviderUsers | - | Writer | Registers customers with AML providers |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies (FK targets are Dictionary tables).

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.AmlProviders | Table | FK target for AmlProviderId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.StoreAmlProviderUsers | Stored Procedure | Inserts/updates registrations |
| Wallet.GetAmlProviders | Stored Procedure | Reads provider user mappings |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_AmlProviderUsers | CLUSTERED PK | Id ASC | - | - | Active |
| IX_Wallet_AmlProviderUsers__Gcid | NC UNIQUE | AmlProviderId, Gcid | - | - | Active |
| nci_wi_AmlProviderUsers_... | NC | Gcid | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_...AmlProviderId__Wallet_AmlProviders_AmlProviderId | FK | AmlProviderId -> Dictionary.AmlProviders.Id |

---

## 8. Sample Queries

### 8.1 Find AML provider registration for a customer
```sql
SELECT ap.Name AS Provider, apu.ProviderUserId, apu.Occurred
FROM Wallet.AmlProviderUsers apu WITH (NOLOCK)
JOIN Dictionary.AmlProviders ap WITH (NOLOCK) ON apu.AmlProviderId = ap.Id
WHERE apu.Gcid = 46870594
```

### 8.2 Count registrations per provider
```sql
SELECT ap.Name AS Provider, COUNT(*) AS RegisteredUsers
FROM Wallet.AmlProviderUsers apu WITH (NOLOCK)
JOIN Dictionary.AmlProviders ap WITH (NOLOCK) ON apu.AmlProviderId = ap.Id
GROUP BY ap.Name
```

### 8.3 Recent registrations
```sql
SELECT TOP 10 apu.Gcid, ap.Name AS Provider, apu.Occurred
FROM Wallet.AmlProviderUsers apu WITH (NOLOCK)
JOIN Dictionary.AmlProviders ap WITH (NOLOCK) ON apu.AmlProviderId = ap.Id
ORDER BY apu.Occurred DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.8/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.AmlProviderUsers | Type: Table | Source: WalletDB/Wallet/Tables/Wallet.AmlProviderUsers.sql*
