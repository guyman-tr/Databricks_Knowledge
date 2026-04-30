# dbo.FiatCards

> Entity table representing debit cards issued to fiat accounts, linking to card instances, card statuses, and provider mappings.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | Id (BIGINT, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (+ PK + unique) |

---

## 1. Business Meaning

FiatCards represents the logical debit card entity associated with a fiat account. Each record is a card that has been issued to a customer, identified by a unique CardGuid. A card is linked to exactly one FiatAccount and can have multiple physical/virtual card instances (replacements, reissues) tracked in FiatCardInstances.

This table exists because customers in card-based sub-programs (AccountProgramId=1) receive debit cards for spending. The card entity is the parent of card instances (physical/virtual cards) and card statuses (lifecycle events). It also links to CardsProvidersMapping for the provider-side card ID.

Data is created by dbo.AddFiatCard when the operational system notifies the DWH of a new card issuance. Cards are looked up by GUID via dbo.GetCardByGuid.

---

## 2. Business Logic

### 2.1 Card-Account-Instance Hierarchy

**What**: Three-level hierarchy: Account -> Card -> Card Instances.

**Columns/Parameters Involved**: `Id`, `CardGuid`, `AccountId`

**Rules**:
- One account can have multiple cards (e.g., card replacement creates a new Card)
- Each card can have multiple instances (physical card, virtual card, reissued card)
- CardGuid is unique per card and is the external-facing identifier
- UIX ensures unique (CardGuid, AccountId) combination

---

## 3. Data Overview

| Id | CardGuid | AccountId | Created | Meaning |
|---|---|---|---|---|
| 105279 | E109348B-... | 748744 | 2026-04-14 | New or replacement card for account 748744 |
| 105278 | 1DB55CD1-... | 2135563 | 2026-04-14 | Card issued to recently created account |
| 105277 | FC763CC9-... | 1288342 | 2026-04-14 | Card issued to account 1288342 |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate primary key. Referenced by FiatCardStatuses.CardId, FiatCardInstances (implicit), and CardsProvidersMapping.CardId. |
| 2 | CardGuid | uniqueidentifier | NO | - | CODE-BACKED | External-facing unique identifier for this card. Used in application APIs and provider integrations. Part of unique constraint with AccountId. |
| 3 | AccountId | bigint | NO | - | CODE-BACKED | FK to dbo.FiatAccount.Id. The fiat account this card belongs to. |
| 4 | Created | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this card record was created in the data warehouse. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| AccountId | dbo.FiatAccount | FK | The account this card belongs to |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.FiatCardStatuses | CardId | FK | Card lifecycle status events |
| dbo.FiatCardInstances | CardId | Implicit | Physical/virtual card instances |
| dbo.CardsProvidersMapping | CardId | FK | Provider-side card ID mapping |
| dbo.FiatTransactions | CardId | FK | Transactions made with this card |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.FiatCards (table)
└── dbo.FiatAccount (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.FiatAccount | Table | FK from AccountId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.FiatCardStatuses | Table | FK from CardId |
| dbo.FiatCardInstances | Table | Implicit ref from CardId |
| dbo.CardsProvidersMapping | Table | FK from CardId |
| dbo.FiatTransactions | Table | FK from CardId |
| dbo.AddFiatCard | Stored Procedure | Inserts card records |
| dbo.GetCardByGuid | Stored Procedure | Reads card by GUID |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_FiatCards | CLUSTERED | Id ASC | - | - | Active |
| UIX_FiatCards_CardGuid_AccountId | NC UNIQUE | CardGuid ASC, AccountId ASC | - | - | Active |
| IX_FiatCards_Created | NONCLUSTERED | Created ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_FiatCards_AccountId_FiatAccount_Id | FK | AccountId -> dbo.FiatAccount.Id |
| UIX_FiatCards_CardGuid_AccountId | UNIQUE | Unique card per account |

---

## 8. Sample Queries

### 8.1 Find cards for an account
```sql
SELECT c.Id, c.CardGuid, c.Created
FROM dbo.FiatCards c WITH (NOLOCK)
WHERE c.AccountId = 748744 ORDER BY c.Created;
```

### 8.2 Find card with current status
```sql
SELECT c.Id, c.CardGuid, cs.CardStatusId, ds.Name AS Status, cs.Created AS StatusDate
FROM dbo.FiatCards c WITH (NOLOCK)
CROSS APPLY (SELECT TOP 1 * FROM dbo.FiatCardStatuses WITH (NOLOCK) WHERE CardId = c.Id ORDER BY Created DESC) cs
JOIN Dictionary.CardStatuses ds WITH (NOLOCK) ON ds.Id = cs.CardStatusId
WHERE c.AccountId = 748744;
```

### 8.3 Find card by GUID with account info
```sql
SELECT c.Id, c.CardGuid, a.Gcid, a.AccountGuid
FROM dbo.FiatCards c WITH (NOLOCK)
JOIN dbo.FiatAccount a WITH (NOLOCK) ON a.Id = c.AccountId
WHERE c.CardGuid = 'E109348B-357D-441D-8FD0-49AB77CB1EFE';
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Important DB Queries](https://etoro-jira.atlassian.net/wiki/spaces/~935552433/pages/13290274878) | Confluence | Card lookup patterns via CugCardId; card reissue queries reference FiatWallet.Cards |

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.FiatCards | Type: Table | Source: FiatDwhDB/dbo/Tables/dbo.FiatCards.sql*
