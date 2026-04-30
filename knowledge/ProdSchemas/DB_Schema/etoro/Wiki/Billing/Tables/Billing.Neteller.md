# Billing.Neteller

> Registry of customer Neteller e-wallet accounts registered on the platform; each row stores the Neteller AccountID and its associated SecureID, uniquely keyed by AccountID to prevent duplicate registrations.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | NetellerID (PRIMARY KEY NONCLUSTERED, IDENTITY) |
| **Row Count** | ~1,687 rows |
| **Partition** | N/A - filegroup MAIN |
| **Indexes** | 1 - PK NONCLUSTERED on NetellerID; 1 - UNIQUE NC on AccountID |

---

## 1. Business Meaning

`Billing.Neteller` is the registry of Neteller e-wallet accounts that customers have linked to the etoro platform. Neteller is a digital payment service used for deposits and withdrawals. Each row represents one registered Neteller account identified by the customer's Neteller `AccountID` (the public Neteller account number) and `SecureID` (a Neteller-assigned 6-digit security credential used to authenticate payment requests).

When a customer registers a Neteller account for payment, a new row is inserted via `Billing.NetellerAdd`. The `NetellerID` is the internal etoro identifier for the account, while `AccountID` is the external Neteller reference that is enforced to be unique (a single Neteller account cannot be registered twice).

The table links to:
- `Billing.NetellerToCashout`: associates Neteller accounts with cashout/withdrawal requests
- `Billing.NetellerToPayment`: associates Neteller accounts with deposit payment records
- `Billing.LoadNetellers`: loads the full registry into the application cache at startup

With ~1,687 rows, this represents Neteller's limited but historically significant role in eToro's payment ecosystem - Neteller was an early e-wallet option that predates the current `Billing.Withdraw`/`Billing.Funding` architecture.

---

## 2. Business Logic

### 2.1 Neteller Account Registration

**What**: Records a Neteller account's credentials when a customer links it to their eToro account for use as a payment method.

**Columns Involved**: `NetellerID`, `SecureID`, `AccountID`

**Rules**:
- `Billing.NetellerAdd @SecureID, @AccountID -> @NetellerID OUTPUT`: inserts a new Neteller account; returns the new `NetellerID`
- `AccountID` is UNIQUE (BNET_ACCOUNT index) - one eToro Neteller registration per Neteller account number
- `SecureID` is Neteller's 6-digit PIN/security code required to authenticate fund movements
- No FK from `Neteller` to `Customer.CustomerStatic` - the customer link is maintained in `Billing.NetellerToPayment` or `Billing.NetellerToCashout`

### 2.2 Cashout Processing

The `Billing.CashoutProcessToNeteller` SP uses this table to look up the Neteller credentials when processing a Neteller withdrawal, passing `SecureID` and `AccountID` to the Neteller payment API.

---

## 3. Data Overview

| Metric | Value |
|--------|-------|
| Total rows | ~1,687 |
| ID range | 7 to 1,720 (gaps due to deleted accounts) |
| Unique AccountIDs | 1,687 (UNIQUE constraint) |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | NetellerID | int | NO | IDENTITY(1,1) | CODE-BACKED | Internal etoro primary key for this Neteller account registration. Auto-generated. Referenced by `Billing.NetellerToCashout` and `Billing.NetellerToPayment` to link transactions to this Neteller account. NOT FOR REPLICATION. |
| 2 | SecureID | numeric(6,0) | NO | - | CODE-BACKED | Neteller's 6-digit security credential (PIN) for this account. Required by the Neteller API to authenticate fund transfers. Stored as a 6-digit integer (leading zeros preserved by the numeric type). Sensitive credential - equivalent to a PIN code. |
| 3 | AccountID | numeric(12,0) | NO | - | CODE-BACKED | The customer's Neteller account number (up to 12 digits). This is the public-facing Neteller identifier - the account number the customer registered with Neteller. UNIQUE enforced by BNET_ACCOUNT index. Used as the payee identifier when initiating Neteller transfers. |

---

## 5. Relationships

### 5.1 References To (this object points to)

No FK constraints.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.NetellerToCashout | NetellerID | FK (implicit) | Links cashout/withdrawal records to a registered Neteller account |
| Billing.NetellerToPayment | NetellerID | FK (implicit) | Links deposit payment records to a registered Neteller account |
| Billing.NetellerAdd | NetellerID (OUTPUT) | Write | Inserts new Neteller account registration |
| Billing.LoadNetellers | - | Read | Loads full registry into application cache |
| Billing.LoadNetellerToPayments | - | Read | Loads Neteller-to-payment associations |
| Billing.CashoutProcessToNeteller | AccountID, SecureID | Read | Retrieves credentials for Neteller cashout API call |
| Billing.PaymentByNetellerAdd | NetellerID | Write | Associates a payment with a Neteller account |
| Billing.PaymentByNetellerEdit | NetellerID | Write | Updates Neteller account on a payment |
| Billing.CustomerRemove | NetellerID | Delete | Removes Neteller registrations when customer account is deleted |

---

## 6. Dependencies

### 6.0 Dependency Chain

No dependencies - independent registry table.

---

### 6.1 Objects This Depends On

None.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.NetellerToCashout | Table | FK on NetellerID - links withdrawals to Neteller accounts |
| Billing.NetellerToPayment | Table | FK on NetellerID - links deposits to Neteller accounts |
| Billing.CashoutProcessToNeteller | Stored Procedure | Reads AccountID/SecureID to make Neteller API call |
| Billing.LoadNetellers | Stored Procedure | Full table scan for cache loading |
| Billing.NetellerAdd | Stored Procedure | Writes new registrations |
| Billing.CustomerRemove | Stored Procedure | Deletes Neteller records on customer removal |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Notes |
|-----------|------|-------------|-----------------|--------|-------|
| PK_BNET | NONCLUSTERED PK | NetellerID ASC | - | - | Active; FILLFACTOR=90; heap table (no clustered index) |
| BNET_ACCOUNT | UNIQUE NC | AccountID ASC | - | - | Active; FILLFACTOR=90; prevents duplicate Neteller account registration |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BNET | PRIMARY KEY NONCLUSTERED | One row per NetellerID |
| BNET_ACCOUNT (index) | UNIQUE | One registration per Neteller AccountID |

---

## 8. Sample Queries

### 8.1 View registered Neteller accounts (summary)

```sql
SELECT TOP 20 NetellerID, AccountID
FROM Billing.Neteller WITH (NOLOCK)
ORDER BY NetellerID
-- Note: SecureID omitted - sensitive credential
```

### 8.2 Find Neteller accounts associated with payments

```sql
SELECT TOP 20
    n.NetellerID,
    n.AccountID,
    ntp.PaymentID
FROM Billing.Neteller n WITH (NOLOCK)
JOIN Billing.NetellerToPayment ntp WITH (NOLOCK) ON ntp.NetellerID = n.NetellerID
ORDER BY ntp.PaymentID DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,5,7,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.Neteller | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.Neteller.sql*
