# Preflight report — UC ALTER deployment queue

- **Run date:** 2026-05-03
- **Mode:** APPLY (writes)
- **Files scanned:** 644
- **Files auto-fixed:** 21
- **Files BLOCKED:** 0

Blocks = encoding errors, prose-as-target, bogus `Tier N` as column,
unterminated COMMENT literal, or missing `;`. Auto-fixes = mojibake / unicode
punctuation normalization and backtick-wrapping of unsafe column tokens.

## Auto-fixed files

### `knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/Tribe/Tables/Tribe.AccountsActivities_AccountActivity-833937.alter.sql`

- **Identifier backtick wrap**: 18 change(s)
    - line 29: `@Created -> `@Created``
    - line 30: `@Id -> `@Id``
    - line 31: `@AccountsActivities@Id-862157 -> `@AccountsActivities@Id-862157``
    - line 10: `main.emoney.bronze_fiatdwhdb_tribe_accountsactivities_accountactivity-833937 -> main.emoney.`bronze_fiatdwhdb_tribe_accountsactivities_accountactivity-833937``
    - line 14: `main.emoney.bronze_fiatdwhdb_tribe_accountsactivities_accountactivity-833937 -> main.emoney.`bronze_fiatdwhdb_tribe_accountsactivities_accountactivity-833937``
    - line 29: `main.emoney.bronze_fiatdwhdb_tribe_accountsactivities_accountactivity-833937 -> main.emoney.`bronze_fiatdwhdb_tribe_accountsactivities_accountactivity-833937``
    - line 30: `main.emoney.bronze_fiatdwhdb_tribe_accountsactivities_accountactivity-833937 -> main.emoney.`bronze_fiatdwhdb_tribe_accountsactivities_accountactivity-833937``
    - line 31: `main.emoney.bronze_fiatdwhdb_tribe_accountsactivities_accountactivity-833937 -> main.emoney.`bronze_fiatdwhdb_tribe_accountsactivities_accountactivity-833937``
    - line 32: `main.emoney.bronze_fiatdwhdb_tribe_accountsactivities_accountactivity-833937 -> main.emoney.`bronze_fiatdwhdb_tribe_accountsactivities_accountactivity-833937``
    - line 33: `main.emoney.bronze_fiatdwhdb_tribe_accountsactivities_accountactivity-833937 -> main.emoney.`bronze_fiatdwhdb_tribe_accountsactivities_accountactivity-833937``
    - line 34: `main.emoney.bronze_fiatdwhdb_tribe_accountsactivities_accountactivity-833937 -> main.emoney.`bronze_fiatdwhdb_tribe_accountsactivities_accountactivity-833937``
    - line 35: `main.emoney.bronze_fiatdwhdb_tribe_accountsactivities_accountactivity-833937 -> main.emoney.`bronze_fiatdwhdb_tribe_accountsactivities_accountactivity-833937``
    - line 36: `main.emoney.bronze_fiatdwhdb_tribe_accountsactivities_accountactivity-833937 -> main.emoney.`bronze_fiatdwhdb_tribe_accountsactivities_accountactivity-833937``
    - line 37: `main.emoney.bronze_fiatdwhdb_tribe_accountsactivities_accountactivity-833937 -> main.emoney.`bronze_fiatdwhdb_tribe_accountsactivities_accountactivity-833937``
    - line 38: `main.emoney.bronze_fiatdwhdb_tribe_accountsactivities_accountactivity-833937 -> main.emoney.`bronze_fiatdwhdb_tribe_accountsactivities_accountactivity-833937``
    - line 39: `main.emoney.bronze_fiatdwhdb_tribe_accountsactivities_accountactivity-833937 -> main.emoney.`bronze_fiatdwhdb_tribe_accountsactivities_accountactivity-833937``
    - line 40: `main.emoney.bronze_fiatdwhdb_tribe_accountsactivities_accountactivity-833937 -> main.emoney.`bronze_fiatdwhdb_tribe_accountsactivities_accountactivity-833937``
    - line 41: `main.emoney.bronze_fiatdwhdb_tribe_accountsactivities_accountactivity-833937 -> main.emoney.`bronze_fiatdwhdb_tribe_accountsactivities_accountactivity-833937``

### `knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/Tribe/Tables/Tribe.AccountsActivities_RiskActions-322546.alter.sql`

- **Identifier backtick wrap**: 9 change(s)
    - line 29: `@Created -> `@Created``
    - line 30: `@Id -> `@Id``
    - line 31: `@AccountsActivities@Id-862157 -> `@AccountsActivities@Id-862157``
    - line 10: `main.emoney.bronze_fiatdwhdb_tribe_accountsactivities_riskactions-322546 -> main.emoney.`bronze_fiatdwhdb_tribe_accountsactivities_riskactions-322546``
    - line 14: `main.emoney.bronze_fiatdwhdb_tribe_accountsactivities_riskactions-322546 -> main.emoney.`bronze_fiatdwhdb_tribe_accountsactivities_riskactions-322546``
    - line 29: `main.emoney.bronze_fiatdwhdb_tribe_accountsactivities_riskactions-322546 -> main.emoney.`bronze_fiatdwhdb_tribe_accountsactivities_riskactions-322546``
    - line 30: `main.emoney.bronze_fiatdwhdb_tribe_accountsactivities_riskactions-322546 -> main.emoney.`bronze_fiatdwhdb_tribe_accountsactivities_riskactions-322546``
    - line 31: `main.emoney.bronze_fiatdwhdb_tribe_accountsactivities_riskactions-322546 -> main.emoney.`bronze_fiatdwhdb_tribe_accountsactivities_riskactions-322546``
    - line 32: `main.emoney.bronze_fiatdwhdb_tribe_accountsactivities_riskactions-322546 -> main.emoney.`bronze_fiatdwhdb_tribe_accountsactivities_riskactions-322546``

### `knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/Tribe/Tables/Tribe.AccountsActivities_SecurityChecks-471048.alter.sql`

- **Identifier backtick wrap**: 9 change(s)
    - line 29: `@Created -> `@Created``
    - line 30: `@Id -> `@Id``
    - line 31: `@AccountsActivities@Id-862157 -> `@AccountsActivities@Id-862157``
    - line 10: `main.emoney.bronze_fiatdwhdb_tribe_accountsactivities_securitychecks-471048 -> main.emoney.`bronze_fiatdwhdb_tribe_accountsactivities_securitychecks-471048``
    - line 14: `main.emoney.bronze_fiatdwhdb_tribe_accountsactivities_securitychecks-471048 -> main.emoney.`bronze_fiatdwhdb_tribe_accountsactivities_securitychecks-471048``
    - line 29: `main.emoney.bronze_fiatdwhdb_tribe_accountsactivities_securitychecks-471048 -> main.emoney.`bronze_fiatdwhdb_tribe_accountsactivities_securitychecks-471048``
    - line 30: `main.emoney.bronze_fiatdwhdb_tribe_accountsactivities_securitychecks-471048 -> main.emoney.`bronze_fiatdwhdb_tribe_accountsactivities_securitychecks-471048``
    - line 31: `main.emoney.bronze_fiatdwhdb_tribe_accountsactivities_securitychecks-471048 -> main.emoney.`bronze_fiatdwhdb_tribe_accountsactivities_securitychecks-471048``
    - line 32: `main.emoney.bronze_fiatdwhdb_tribe_accountsactivities_securitychecks-471048 -> main.emoney.`bronze_fiatdwhdb_tribe_accountsactivities_securitychecks-471048``

### `knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/Tribe/Tables/Tribe.AccountsSnapshots-509416.alter.sql`

- **Identifier backtick wrap**: 9 change(s)
    - line 29: `@Created -> `@Created``
    - line 30: `@Id -> `@Id``
    - line 31: `@FileName -> `@FileName``
    - line 10: `main.emoney.bronze_fiatdwhdb_tribe_accountssnapshots-509416 -> main.emoney.`bronze_fiatdwhdb_tribe_accountssnapshots-509416``
    - line 14: `main.emoney.bronze_fiatdwhdb_tribe_accountssnapshots-509416 -> main.emoney.`bronze_fiatdwhdb_tribe_accountssnapshots-509416``
    - line 29: `main.emoney.bronze_fiatdwhdb_tribe_accountssnapshots-509416 -> main.emoney.`bronze_fiatdwhdb_tribe_accountssnapshots-509416``
    - line 30: `main.emoney.bronze_fiatdwhdb_tribe_accountssnapshots-509416 -> main.emoney.`bronze_fiatdwhdb_tribe_accountssnapshots-509416``
    - line 31: `main.emoney.bronze_fiatdwhdb_tribe_accountssnapshots-509416 -> main.emoney.`bronze_fiatdwhdb_tribe_accountssnapshots-509416``
    - line 32: `main.emoney.bronze_fiatdwhdb_tribe_accountssnapshots-509416 -> main.emoney.`bronze_fiatdwhdb_tribe_accountssnapshots-509416``

### `knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/Tribe/Tables/Tribe.AccountsSnapshots_AccountSnapshot-956050.alter.sql`

- **Identifier backtick wrap**: 9 change(s)
    - line 29: `@Created -> `@Created``
    - line 30: `@Id -> `@Id``
    - line 31: `@AccountsSnapshots@Id-509416 -> `@AccountsSnapshots@Id-509416``
    - line 10: `main.emoney.bronze_fiatdwhdb_tribe_accountssnapshots_accountsnapshot-956050 -> main.emoney.`bronze_fiatdwhdb_tribe_accountssnapshots_accountsnapshot-956050``
    - line 14: `main.emoney.bronze_fiatdwhdb_tribe_accountssnapshots_accountsnapshot-956050 -> main.emoney.`bronze_fiatdwhdb_tribe_accountssnapshots_accountsnapshot-956050``
    - line 29: `main.emoney.bronze_fiatdwhdb_tribe_accountssnapshots_accountsnapshot-956050 -> main.emoney.`bronze_fiatdwhdb_tribe_accountssnapshots_accountsnapshot-956050``
    - line 30: `main.emoney.bronze_fiatdwhdb_tribe_accountssnapshots_accountsnapshot-956050 -> main.emoney.`bronze_fiatdwhdb_tribe_accountssnapshots_accountsnapshot-956050``
    - line 31: `main.emoney.bronze_fiatdwhdb_tribe_accountssnapshots_accountsnapshot-956050 -> main.emoney.`bronze_fiatdwhdb_tribe_accountssnapshots_accountsnapshot-956050``
    - line 32: `main.emoney.bronze_fiatdwhdb_tribe_accountssnapshots_accountsnapshot-956050 -> main.emoney.`bronze_fiatdwhdb_tribe_accountssnapshots_accountsnapshot-956050``

### `knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/Tribe/Tables/Tribe.AccountsSnapshots_BankAccount-393561.alter.sql`

- **Identifier backtick wrap**: 9 change(s)
    - line 29: `@Created -> `@Created``
    - line 30: `@Id -> `@Id``
    - line 31: `@AccountsSnapshots@Id-509416 -> `@AccountsSnapshots@Id-509416``
    - line 10: `main.emoney.bronze_fiatdwhdb_tribe_accountssnapshots_bankaccount-393561 -> main.emoney.`bronze_fiatdwhdb_tribe_accountssnapshots_bankaccount-393561``
    - line 14: `main.emoney.bronze_fiatdwhdb_tribe_accountssnapshots_bankaccount-393561 -> main.emoney.`bronze_fiatdwhdb_tribe_accountssnapshots_bankaccount-393561``
    - line 29: `main.emoney.bronze_fiatdwhdb_tribe_accountssnapshots_bankaccount-393561 -> main.emoney.`bronze_fiatdwhdb_tribe_accountssnapshots_bankaccount-393561``
    - line 30: `main.emoney.bronze_fiatdwhdb_tribe_accountssnapshots_bankaccount-393561 -> main.emoney.`bronze_fiatdwhdb_tribe_accountssnapshots_bankaccount-393561``
    - line 31: `main.emoney.bronze_fiatdwhdb_tribe_accountssnapshots_bankaccount-393561 -> main.emoney.`bronze_fiatdwhdb_tribe_accountssnapshots_bankaccount-393561``
    - line 32: `main.emoney.bronze_fiatdwhdb_tribe_accountssnapshots_bankaccount-393561 -> main.emoney.`bronze_fiatdwhdb_tribe_accountssnapshots_bankaccount-393561``

### `knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/Tribe/Tables/Tribe.AccountsSnapshots_BankAccounts-795870.alter.sql`

- **Identifier backtick wrap**: 9 change(s)
    - line 29: `@Created -> `@Created``
    - line 30: `@Id -> `@Id``
    - line 31: `@AccountsSnapshots@Id-509416 -> `@AccountsSnapshots@Id-509416``
    - line 10: `main.emoney.bronze_fiatdwhdb_tribe_accountssnapshots_bankaccounts-795870 -> main.emoney.`bronze_fiatdwhdb_tribe_accountssnapshots_bankaccounts-795870``
    - line 14: `main.emoney.bronze_fiatdwhdb_tribe_accountssnapshots_bankaccounts-795870 -> main.emoney.`bronze_fiatdwhdb_tribe_accountssnapshots_bankaccounts-795870``
    - line 29: `main.emoney.bronze_fiatdwhdb_tribe_accountssnapshots_bankaccounts-795870 -> main.emoney.`bronze_fiatdwhdb_tribe_accountssnapshots_bankaccounts-795870``
    - line 30: `main.emoney.bronze_fiatdwhdb_tribe_accountssnapshots_bankaccounts-795870 -> main.emoney.`bronze_fiatdwhdb_tribe_accountssnapshots_bankaccounts-795870``
    - line 31: `main.emoney.bronze_fiatdwhdb_tribe_accountssnapshots_bankaccounts-795870 -> main.emoney.`bronze_fiatdwhdb_tribe_accountssnapshots_bankaccounts-795870``
    - line 32: `main.emoney.bronze_fiatdwhdb_tribe_accountssnapshots_bankaccounts-795870 -> main.emoney.`bronze_fiatdwhdb_tribe_accountssnapshots_bankaccounts-795870``

### `knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/Tribe/Tables/Tribe.Authorizes-837045.alter.sql`

- **Identifier backtick wrap**: 9 change(s)
    - line 29: `@Created -> `@Created``
    - line 30: `@Id -> `@Id``
    - line 31: `@FileName -> `@FileName``
    - line 10: `main.emoney.bronze_fiatdwhdb_tribe_authorizes-837045 -> main.emoney.`bronze_fiatdwhdb_tribe_authorizes-837045``
    - line 14: `main.emoney.bronze_fiatdwhdb_tribe_authorizes-837045 -> main.emoney.`bronze_fiatdwhdb_tribe_authorizes-837045``
    - line 29: `main.emoney.bronze_fiatdwhdb_tribe_authorizes-837045 -> main.emoney.`bronze_fiatdwhdb_tribe_authorizes-837045``
    - line 30: `main.emoney.bronze_fiatdwhdb_tribe_authorizes-837045 -> main.emoney.`bronze_fiatdwhdb_tribe_authorizes-837045``
    - line 31: `main.emoney.bronze_fiatdwhdb_tribe_authorizes-837045 -> main.emoney.`bronze_fiatdwhdb_tribe_authorizes-837045``
    - line 32: `main.emoney.bronze_fiatdwhdb_tribe_authorizes-837045 -> main.emoney.`bronze_fiatdwhdb_tribe_authorizes-837045``

### `knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/Tribe/Tables/Tribe.Authorizes_Authorize-312243.alter.sql`

- **Identifier backtick wrap**: 9 change(s)
    - line 29: `@Created -> `@Created``
    - line 30: `@Id -> `@Id``
    - line 31: `@Authorizes@Id-837045 -> `@Authorizes@Id-837045``
    - line 10: `main.emoney.bronze_fiatdwhdb_tribe_authorizes_authorize-312243 -> main.emoney.`bronze_fiatdwhdb_tribe_authorizes_authorize-312243``
    - line 14: `main.emoney.bronze_fiatdwhdb_tribe_authorizes_authorize-312243 -> main.emoney.`bronze_fiatdwhdb_tribe_authorizes_authorize-312243``
    - line 29: `main.emoney.bronze_fiatdwhdb_tribe_authorizes_authorize-312243 -> main.emoney.`bronze_fiatdwhdb_tribe_authorizes_authorize-312243``
    - line 30: `main.emoney.bronze_fiatdwhdb_tribe_authorizes_authorize-312243 -> main.emoney.`bronze_fiatdwhdb_tribe_authorizes_authorize-312243``
    - line 31: `main.emoney.bronze_fiatdwhdb_tribe_authorizes_authorize-312243 -> main.emoney.`bronze_fiatdwhdb_tribe_authorizes_authorize-312243``
    - line 32: `main.emoney.bronze_fiatdwhdb_tribe_authorizes_authorize-312243 -> main.emoney.`bronze_fiatdwhdb_tribe_authorizes_authorize-312243``

### `knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/Tribe/Tables/Tribe.Authorizes_RiskActions-796100.alter.sql`

- **Identifier backtick wrap**: 9 change(s)
    - line 29: `@Created -> `@Created``
    - line 30: `@Id -> `@Id``
    - line 31: `@Authorizes@Id-837045 -> `@Authorizes@Id-837045``
    - line 10: `main.emoney.bronze_fiatdwhdb_tribe_authorizes_riskactions-796100 -> main.emoney.`bronze_fiatdwhdb_tribe_authorizes_riskactions-796100``
    - line 14: `main.emoney.bronze_fiatdwhdb_tribe_authorizes_riskactions-796100 -> main.emoney.`bronze_fiatdwhdb_tribe_authorizes_riskactions-796100``
    - line 29: `main.emoney.bronze_fiatdwhdb_tribe_authorizes_riskactions-796100 -> main.emoney.`bronze_fiatdwhdb_tribe_authorizes_riskactions-796100``
    - line 30: `main.emoney.bronze_fiatdwhdb_tribe_authorizes_riskactions-796100 -> main.emoney.`bronze_fiatdwhdb_tribe_authorizes_riskactions-796100``
    - line 31: `main.emoney.bronze_fiatdwhdb_tribe_authorizes_riskactions-796100 -> main.emoney.`bronze_fiatdwhdb_tribe_authorizes_riskactions-796100``
    - line 32: `main.emoney.bronze_fiatdwhdb_tribe_authorizes_riskactions-796100 -> main.emoney.`bronze_fiatdwhdb_tribe_authorizes_riskactions-796100``

### `knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/Tribe/Tables/Tribe.Authorizes_SecurityChecks-30662.alter.sql`

- **Identifier backtick wrap**: 9 change(s)
    - line 29: `@Created -> `@Created``
    - line 30: `@Id -> `@Id``
    - line 31: `@Authorizes@Id-837045 -> `@Authorizes@Id-837045``
    - line 10: `main.emoney.bronze_fiatdwhdb_tribe_authorizes_securitychecks-30662 -> main.emoney.`bronze_fiatdwhdb_tribe_authorizes_securitychecks-30662``
    - line 14: `main.emoney.bronze_fiatdwhdb_tribe_authorizes_securitychecks-30662 -> main.emoney.`bronze_fiatdwhdb_tribe_authorizes_securitychecks-30662``
    - line 29: `main.emoney.bronze_fiatdwhdb_tribe_authorizes_securitychecks-30662 -> main.emoney.`bronze_fiatdwhdb_tribe_authorizes_securitychecks-30662``
    - line 30: `main.emoney.bronze_fiatdwhdb_tribe_authorizes_securitychecks-30662 -> main.emoney.`bronze_fiatdwhdb_tribe_authorizes_securitychecks-30662``
    - line 31: `main.emoney.bronze_fiatdwhdb_tribe_authorizes_securitychecks-30662 -> main.emoney.`bronze_fiatdwhdb_tribe_authorizes_securitychecks-30662``
    - line 32: `main.emoney.bronze_fiatdwhdb_tribe_authorizes_securitychecks-30662 -> main.emoney.`bronze_fiatdwhdb_tribe_authorizes_securitychecks-30662``

### `knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/Tribe/Tables/Tribe.CardsSnapshots-890718.alter.sql`

- **Identifier backtick wrap**: 9 change(s)
    - line 29: `@Created -> `@Created``
    - line 30: `@Id -> `@Id``
    - line 31: `@FileName -> `@FileName``
    - line 10: `main.emoney.bronze_fiatdwhdb_tribe_cardssnapshots-890718 -> main.emoney.`bronze_fiatdwhdb_tribe_cardssnapshots-890718``
    - line 14: `main.emoney.bronze_fiatdwhdb_tribe_cardssnapshots-890718 -> main.emoney.`bronze_fiatdwhdb_tribe_cardssnapshots-890718``
    - line 29: `main.emoney.bronze_fiatdwhdb_tribe_cardssnapshots-890718 -> main.emoney.`bronze_fiatdwhdb_tribe_cardssnapshots-890718``
    - line 30: `main.emoney.bronze_fiatdwhdb_tribe_cardssnapshots-890718 -> main.emoney.`bronze_fiatdwhdb_tribe_cardssnapshots-890718``
    - line 31: `main.emoney.bronze_fiatdwhdb_tribe_cardssnapshots-890718 -> main.emoney.`bronze_fiatdwhdb_tribe_cardssnapshots-890718``
    - line 32: `main.emoney.bronze_fiatdwhdb_tribe_cardssnapshots-890718 -> main.emoney.`bronze_fiatdwhdb_tribe_cardssnapshots-890718``

### `knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/Tribe/Tables/Tribe.CardsSnapshots_Account-513255.alter.sql`

- **Identifier backtick wrap**: 9 change(s)
    - line 29: `@Created -> `@Created``
    - line 30: `@Id -> `@Id``
    - line 31: `@CardsSnapshots@Id-890718 -> `@CardsSnapshots@Id-890718``
    - line 10: `main.emoney.bronze_fiatdwhdb_tribe_cardssnapshots_account-513255 -> main.emoney.`bronze_fiatdwhdb_tribe_cardssnapshots_account-513255``
    - line 14: `main.emoney.bronze_fiatdwhdb_tribe_cardssnapshots_account-513255 -> main.emoney.`bronze_fiatdwhdb_tribe_cardssnapshots_account-513255``
    - line 29: `main.emoney.bronze_fiatdwhdb_tribe_cardssnapshots_account-513255 -> main.emoney.`bronze_fiatdwhdb_tribe_cardssnapshots_account-513255``
    - line 30: `main.emoney.bronze_fiatdwhdb_tribe_cardssnapshots_account-513255 -> main.emoney.`bronze_fiatdwhdb_tribe_cardssnapshots_account-513255``
    - line 31: `main.emoney.bronze_fiatdwhdb_tribe_cardssnapshots_account-513255 -> main.emoney.`bronze_fiatdwhdb_tribe_cardssnapshots_account-513255``
    - line 32: `main.emoney.bronze_fiatdwhdb_tribe_cardssnapshots_account-513255 -> main.emoney.`bronze_fiatdwhdb_tribe_cardssnapshots_account-513255``

### `knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/Tribe/Tables/Tribe.CardsSnapshots_Accounts-350640.alter.sql`

- **Identifier backtick wrap**: 9 change(s)
    - line 29: `@Created -> `@Created``
    - line 30: `@Id -> `@Id``
    - line 31: `@CardsSnapshots@Id-890718 -> `@CardsSnapshots@Id-890718``
    - line 10: `main.emoney.bronze_fiatdwhdb_tribe_cardssnapshots_accounts-350640 -> main.emoney.`bronze_fiatdwhdb_tribe_cardssnapshots_accounts-350640``
    - line 14: `main.emoney.bronze_fiatdwhdb_tribe_cardssnapshots_accounts-350640 -> main.emoney.`bronze_fiatdwhdb_tribe_cardssnapshots_accounts-350640``
    - line 29: `main.emoney.bronze_fiatdwhdb_tribe_cardssnapshots_accounts-350640 -> main.emoney.`bronze_fiatdwhdb_tribe_cardssnapshots_accounts-350640``
    - line 30: `main.emoney.bronze_fiatdwhdb_tribe_cardssnapshots_accounts-350640 -> main.emoney.`bronze_fiatdwhdb_tribe_cardssnapshots_accounts-350640``
    - line 31: `main.emoney.bronze_fiatdwhdb_tribe_cardssnapshots_accounts-350640 -> main.emoney.`bronze_fiatdwhdb_tribe_cardssnapshots_accounts-350640``
    - line 32: `main.emoney.bronze_fiatdwhdb_tribe_cardssnapshots_accounts-350640 -> main.emoney.`bronze_fiatdwhdb_tribe_cardssnapshots_accounts-350640``

### `knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/Tribe/Tables/Tribe.CardsSnapshots_BankAccount-341626.alter.sql`

- **Identifier backtick wrap**: 7 change(s)
    - line 29: `@Id -> `@Id``
    - line 30: `@CardsSnapshots_BankAccounts@Id-83854 -> `@CardsSnapshots_BankAccounts@Id-83854``
    - line 10: `main.emoney.bronze_fiatdwhdb_tribe_cardssnapshots_bankaccount-341626 -> main.emoney.`bronze_fiatdwhdb_tribe_cardssnapshots_bankaccount-341626``
    - line 14: `main.emoney.bronze_fiatdwhdb_tribe_cardssnapshots_bankaccount-341626 -> main.emoney.`bronze_fiatdwhdb_tribe_cardssnapshots_bankaccount-341626``
    - line 29: `main.emoney.bronze_fiatdwhdb_tribe_cardssnapshots_bankaccount-341626 -> main.emoney.`bronze_fiatdwhdb_tribe_cardssnapshots_bankaccount-341626``
    - line 30: `main.emoney.bronze_fiatdwhdb_tribe_cardssnapshots_bankaccount-341626 -> main.emoney.`bronze_fiatdwhdb_tribe_cardssnapshots_bankaccount-341626``
    - line 31: `main.emoney.bronze_fiatdwhdb_tribe_cardssnapshots_bankaccount-341626 -> main.emoney.`bronze_fiatdwhdb_tribe_cardssnapshots_bankaccount-341626``

### `knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/Tribe/Tables/Tribe.CardsSnapshots_BankAccounts-83854.alter.sql`

- **Identifier backtick wrap**: 9 change(s)
    - line 29: `@Created -> `@Created``
    - line 30: `@Id -> `@Id``
    - line 31: `@CardsSnapshots@Id-890718 -> `@CardsSnapshots@Id-890718``
    - line 10: `main.emoney.bronze_fiatdwhdb_tribe_cardssnapshots_bankaccounts-83854 -> main.emoney.`bronze_fiatdwhdb_tribe_cardssnapshots_bankaccounts-83854``
    - line 14: `main.emoney.bronze_fiatdwhdb_tribe_cardssnapshots_bankaccounts-83854 -> main.emoney.`bronze_fiatdwhdb_tribe_cardssnapshots_bankaccounts-83854``
    - line 29: `main.emoney.bronze_fiatdwhdb_tribe_cardssnapshots_bankaccounts-83854 -> main.emoney.`bronze_fiatdwhdb_tribe_cardssnapshots_bankaccounts-83854``
    - line 30: `main.emoney.bronze_fiatdwhdb_tribe_cardssnapshots_bankaccounts-83854 -> main.emoney.`bronze_fiatdwhdb_tribe_cardssnapshots_bankaccounts-83854``
    - line 31: `main.emoney.bronze_fiatdwhdb_tribe_cardssnapshots_bankaccounts-83854 -> main.emoney.`bronze_fiatdwhdb_tribe_cardssnapshots_bankaccounts-83854``
    - line 32: `main.emoney.bronze_fiatdwhdb_tribe_cardssnapshots_bankaccounts-83854 -> main.emoney.`bronze_fiatdwhdb_tribe_cardssnapshots_bankaccounts-83854``

### `knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/Tribe/Tables/Tribe.CardsSnapshots_CardSnapshot-140457.alter.sql`

- **Identifier backtick wrap**: 13 change(s)
    - line 29: `@Created -> `@Created``
    - line 30: `@Id -> `@Id``
    - line 31: `@CardsSnapshots@Id-890718 -> `@CardsSnapshots@Id-890718``
    - line 10: `main.emoney.bronze_fiatdwhdb_tribe_cardssnapshots_cardsnapshot-140457 -> main.emoney.`bronze_fiatdwhdb_tribe_cardssnapshots_cardsnapshot-140457``
    - line 14: `main.emoney.bronze_fiatdwhdb_tribe_cardssnapshots_cardsnapshot-140457 -> main.emoney.`bronze_fiatdwhdb_tribe_cardssnapshots_cardsnapshot-140457``
    - line 29: `main.emoney.bronze_fiatdwhdb_tribe_cardssnapshots_cardsnapshot-140457 -> main.emoney.`bronze_fiatdwhdb_tribe_cardssnapshots_cardsnapshot-140457``
    - line 30: `main.emoney.bronze_fiatdwhdb_tribe_cardssnapshots_cardsnapshot-140457 -> main.emoney.`bronze_fiatdwhdb_tribe_cardssnapshots_cardsnapshot-140457``
    - line 31: `main.emoney.bronze_fiatdwhdb_tribe_cardssnapshots_cardsnapshot-140457 -> main.emoney.`bronze_fiatdwhdb_tribe_cardssnapshots_cardsnapshot-140457``
    - line 32: `main.emoney.bronze_fiatdwhdb_tribe_cardssnapshots_cardsnapshot-140457 -> main.emoney.`bronze_fiatdwhdb_tribe_cardssnapshots_cardsnapshot-140457``
    - line 33: `main.emoney.bronze_fiatdwhdb_tribe_cardssnapshots_cardsnapshot-140457 -> main.emoney.`bronze_fiatdwhdb_tribe_cardssnapshots_cardsnapshot-140457``
    - line 34: `main.emoney.bronze_fiatdwhdb_tribe_cardssnapshots_cardsnapshot-140457 -> main.emoney.`bronze_fiatdwhdb_tribe_cardssnapshots_cardsnapshot-140457``
    - line 35: `main.emoney.bronze_fiatdwhdb_tribe_cardssnapshots_cardsnapshot-140457 -> main.emoney.`bronze_fiatdwhdb_tribe_cardssnapshots_cardsnapshot-140457``
    - line 36: `main.emoney.bronze_fiatdwhdb_tribe_cardssnapshots_cardsnapshot-140457 -> main.emoney.`bronze_fiatdwhdb_tribe_cardssnapshots_cardsnapshot-140457``

### `knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/Tribe/Tables/Tribe.SettlementsTransactions-333243.alter.sql`

- **Identifier backtick wrap**: 9 change(s)
    - line 29: `@Created -> `@Created``
    - line 30: `@Id -> `@Id``
    - line 31: `@FileName -> `@FileName``
    - line 10: `main.emoney.bronze_fiatdwhdb_tribe_settlementstransactions-333243 -> main.emoney.`bronze_fiatdwhdb_tribe_settlementstransactions-333243``
    - line 14: `main.emoney.bronze_fiatdwhdb_tribe_settlementstransactions-333243 -> main.emoney.`bronze_fiatdwhdb_tribe_settlementstransactions-333243``
    - line 29: `main.emoney.bronze_fiatdwhdb_tribe_settlementstransactions-333243 -> main.emoney.`bronze_fiatdwhdb_tribe_settlementstransactions-333243``
    - line 30: `main.emoney.bronze_fiatdwhdb_tribe_settlementstransactions-333243 -> main.emoney.`bronze_fiatdwhdb_tribe_settlementstransactions-333243``
    - line 31: `main.emoney.bronze_fiatdwhdb_tribe_settlementstransactions-333243 -> main.emoney.`bronze_fiatdwhdb_tribe_settlementstransactions-333243``
    - line 32: `main.emoney.bronze_fiatdwhdb_tribe_settlementstransactions-333243 -> main.emoney.`bronze_fiatdwhdb_tribe_settlementstransactions-333243``

### `knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/Tribe/Tables/Tribe.SettlementsTransactions_RiskActions-236807.alter.sql`

- **Identifier backtick wrap**: 9 change(s)
    - line 29: `@Created -> `@Created``
    - line 30: `@Id -> `@Id``
    - line 31: `@SettlementsTransactions@Id-333243 -> `@SettlementsTransactions@Id-333243``
    - line 10: `main.emoney.bronze_fiatdwhdb_tribe_settlementstransactions_riskactions-236807 -> main.emoney.`bronze_fiatdwhdb_tribe_settlementstransactions_riskactions-236807``
    - line 14: `main.emoney.bronze_fiatdwhdb_tribe_settlementstransactions_riskactions-236807 -> main.emoney.`bronze_fiatdwhdb_tribe_settlementstransactions_riskactions-236807``
    - line 29: `main.emoney.bronze_fiatdwhdb_tribe_settlementstransactions_riskactions-236807 -> main.emoney.`bronze_fiatdwhdb_tribe_settlementstransactions_riskactions-236807``
    - line 30: `main.emoney.bronze_fiatdwhdb_tribe_settlementstransactions_riskactions-236807 -> main.emoney.`bronze_fiatdwhdb_tribe_settlementstransactions_riskactions-236807``
    - line 31: `main.emoney.bronze_fiatdwhdb_tribe_settlementstransactions_riskactions-236807 -> main.emoney.`bronze_fiatdwhdb_tribe_settlementstransactions_riskactions-236807``
    - line 32: `main.emoney.bronze_fiatdwhdb_tribe_settlementstransactions_riskactions-236807 -> main.emoney.`bronze_fiatdwhdb_tribe_settlementstransactions_riskactions-236807``

### `knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/Tribe/Tables/Tribe.SettlementsTransactions_SecurityChecks-426253.alter.sql`

- **Identifier backtick wrap**: 9 change(s)
    - line 29: `@Created -> `@Created``
    - line 30: `@Id -> `@Id``
    - line 31: `@SettlementsTransactions@Id-333243 -> `@SettlementsTransactions@Id-333243``
    - line 10: `main.emoney.bronze_fiatdwhdb_tribe_settlementstransactions_securitychecks-426253 -> main.emoney.`bronze_fiatdwhdb_tribe_settlementstransactions_securitychecks-426253``
    - line 14: `main.emoney.bronze_fiatdwhdb_tribe_settlementstransactions_securitychecks-426253 -> main.emoney.`bronze_fiatdwhdb_tribe_settlementstransactions_securitychecks-426253``
    - line 29: `main.emoney.bronze_fiatdwhdb_tribe_settlementstransactions_securitychecks-426253 -> main.emoney.`bronze_fiatdwhdb_tribe_settlementstransactions_securitychecks-426253``
    - line 30: `main.emoney.bronze_fiatdwhdb_tribe_settlementstransactions_securitychecks-426253 -> main.emoney.`bronze_fiatdwhdb_tribe_settlementstransactions_securitychecks-426253``
    - line 31: `main.emoney.bronze_fiatdwhdb_tribe_settlementstransactions_securitychecks-426253 -> main.emoney.`bronze_fiatdwhdb_tribe_settlementstransactions_securitychecks-426253``
    - line 32: `main.emoney.bronze_fiatdwhdb_tribe_settlementstransactions_securitychecks-426253 -> main.emoney.`bronze_fiatdwhdb_tribe_settlementstransactions_securitychecks-426253``

### `knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/Tribe/Tables/Tribe.SettlementsTransactions_SettlementTransaction-637239.alter.sql`

- **Identifier backtick wrap**: 9 change(s)
    - line 29: `@Created -> `@Created``
    - line 30: `@Id -> `@Id``
    - line 31: `@SettlementsTransactions@Id-333243 -> `@SettlementsTransactions@Id-333243``
    - line 10: `main.emoney.bronze_fiatdwhdb_tribe_settlementstransactions_settlementtransaction-637239 -> main.emoney.`bronze_fiatdwhdb_tribe_settlementstransactions_settlementtransaction-637239``
    - line 14: `main.emoney.bronze_fiatdwhdb_tribe_settlementstransactions_settlementtransaction-637239 -> main.emoney.`bronze_fiatdwhdb_tribe_settlementstransactions_settlementtransaction-637239``
    - line 29: `main.emoney.bronze_fiatdwhdb_tribe_settlementstransactions_settlementtransaction-637239 -> main.emoney.`bronze_fiatdwhdb_tribe_settlementstransactions_settlementtransaction-637239``
    - line 30: `main.emoney.bronze_fiatdwhdb_tribe_settlementstransactions_settlementtransaction-637239 -> main.emoney.`bronze_fiatdwhdb_tribe_settlementstransactions_settlementtransaction-637239``
    - line 31: `main.emoney.bronze_fiatdwhdb_tribe_settlementstransactions_settlementtransaction-637239 -> main.emoney.`bronze_fiatdwhdb_tribe_settlementstransactions_settlementtransaction-637239``
    - line 32: `main.emoney.bronze_fiatdwhdb_tribe_settlementstransactions_settlementtransaction-637239 -> main.emoney.`bronze_fiatdwhdb_tribe_settlementstransactions_settlementtransaction-637239``

## Clean files: 623
