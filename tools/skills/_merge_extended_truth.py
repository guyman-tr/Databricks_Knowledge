"""Merge eMoney_Dictionary + EXW_Dictionary + InstrumentType rows (fetched via
MCP in the parent conversation) into knowledge/_dictionary_truth.json, on top
of the existing DWH_dbo Dim_* data. Then apply the decoded-sibling alias map.
"""
from __future__ import annotations

import json
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
OUT = REPO / "knowledge" / "_dictionary_truth.json"

# (key, schema, table, id_col, name_col, [(id, name), ...])
EMONEY_ROWS = [
    ("AccountProgramID", "eMoney_Dictionary", "AccountPrograms", "Id", "Name",
     [("0", "Unknown"), ("1", "card"), ("2", "iban")]),
    ("AccountStatusID@eMoney", "eMoney_Dictionary", "AccountStatuses", "Id", "Name",
     [("0", "Active"), ("1", "Suspended"), ("2", "Deleted")]),
    ("AuthorizationTypeID", "eMoney_Dictionary", "AuthorizationTypes", "Id", "Name",
     [("0", "Unknown"), ("1", "Normal"), ("2", "PreAuthorize"),
      ("3", "FinalAuthorize"), ("4", "Incremental"), ("5", "Instalment"),
      ("6", "PreferredCustomer"), ("7", "Recurring"), ("8", "DelayedCharges"),
      ("9", "NoShow"), ("10", "AuthorizeAdvice"), ("11", "Refund"),
      ("12", "Reversal"), ("13", "SysReversal"), ("14", "AccountFunding")]),
    ("CardStatusID", "eMoney_Dictionary", "CardStatuses", "Id", "Name",
     [("0", "NotActivated"), ("1", "Activated"), ("2", "Blocked"),
      ("3", "Suspended"), ("4", "Risk"), ("5", "Stolen"), ("6", "Lost"),
      ("7", "Expired"), ("8", "Fraud")]),
    ("CurrencyBalanceStatusID", "eMoney_Dictionary", "CurrencyBalanceStatuses", "Id", "Name",
     [("0", "Active"), ("1", "ReceiveOnly"), ("2", "SpendOnly"),
      ("3", "Suspended"), ("4", "Blocked")]),
    ("PaymentSchemaTypeID", "eMoney_Dictionary", "PaymentSchemaType", "Id", "Name",
     [("0", "Unknown"), ("1", "Transfer"), ("2", "FasterPayments"),
      ("3", "Chaps"), ("4", "Bacs"), ("5", "SEPAstandart"),
      ("6", "SEPAinstantTransfer"), ("7", "SEPAdirectDebit")]),
    ("PaymentSpecificationStatusTypeID", "eMoney_Dictionary",
     "PaymentSpecificationStatusTypes", "Id", "Name",
     [("0", "New"), ("1", "Active"), ("2", "Cancelled"),
      ("3", "CancelledPending"), ("4", "Error")]),
    ("PaymentSpecificationTypeID", "eMoney_Dictionary", "PaymentSpecificationTypes",
     "Id", "Name", [("0", "Unknown"), ("1", "DirectDebit")]),
    ("ProviderID", "eMoney_Dictionary", "Providers", "Id", "Name",
     [("1", "Tribe")]),
    ("TransactionCategoryID@eMoney", "eMoney_Dictionary", "TransactionCategories",
     "Id", "Name",
     [("0", "Unknown"), ("1", "CardTransaction"), ("2", "BankingTransaction"),
      ("3", "TransferTransaction"), ("4", "BalanceAdjustmentTransaction")]),
    ("TransactionStatusID@eMoney", "eMoney_Dictionary", "TransactionStatuses",
     "Id", "Name",
     [("0", "Failed"), ("1", "Authorized"), ("2", "Settled"), ("3", "Rejected"),
      ("4", "Returned"), ("5", "Expired")]),
    ("TransactionTypeID@eMoney", "eMoney_Dictionary", "TransactionTypes", "Id", "Name",
     [("0", "Unknown"), ("1", "CardPayment"), ("2", "Contactless"),
      ("3", "OnlinePayment"), ("4", "CashWithdrawal"), ("5", "TransferReceived"),
      ("6", "Transfer"), ("7", "PaymentReceived"), ("8", "Payment"),
      ("9", "Refund"), ("10", "Fee"), ("11", "CreditBA"), ("12", "DebitBA"),
      ("13", "DirectDebit"), ("14", "CryptoToFiat")]),
    ("TribeScriptStatusID", "eMoney_Dictionary", "TribeScriptStatus", "Id", "Name",
     [("0", "Unapproved"), ("1", "Approved"), ("2", "Executed")]),
    # InstrumentTypeID synthesized from Dim_Instrument
    ("InstrumentTypeID", "DWH_dbo", "Dim_Instrument (DISTINCT)",
     "InstrumentTypeID", "InstrumentType",
     [("0", "NA"), ("1", "Currencies"), ("2", "Commodities"),
      ("4", "Indices"), ("5", "Stocks"), ("6", "ETF"),
      ("10", "Crypto Currencies")]),
]

EXW_ROWS = [
    ("ChecksumTypeID", "EXW_Dictionary", "ChecksumTypes", "Id", "Name",
     [("1", "WalletPool"), ("2", "Wallet"), ("3", "StakingAddress"),
      ("4", "EtoroExternalAddress")]),
    ("ConversionStatusID", "EXW_Dictionary", "ConversionStatuses", "Id", "Name",
     [("1", "Pending"), ("2", "Failed"), ("3", "Completed")]),
    ("CountryGroupID", "EXW_Dictionary", "CountryGroup", "CountryGroupID", "CountryGroupName",
     [("1", "ESMA_Countries"), ("2", "China_Territories"),
      ("3", "Russia_Territories"), ("4", "US_Territories"),
      ("5", "Gulf Cooperation Council"), ("6", "Latin America"),
      ("7", "South East Asia"), ("8", "South & Central America"),
      ("9", "Asia"), ("10", "European Union"), ("11", "Unknown"),
      ("12", "Arabic"), ("13", "Australia"), ("14", "French"), ("15", "German"),
      ("16", "Italian"), ("17", "ROW"), ("18", "Other EU"), ("19", "Spain"),
      ("20", "UK"), ("21", "AML_Rank1_Countries"), ("22", "CfdRestrictedCountries"),
      ("23", "France_Territories"), ("24", "RealCryptoRestrictedCountries"),
      ("25", "SilverClubCountriesNotEligibleForInterest")]),
    ("CryptoCoinProviderID", "EXW_Dictionary", "CryptoCoinProviders", "Id", "Name",
     [("1", "BitGoBlockchainProviderV2"), ("2", "BitGoEthereumProviderV2"),
      ("3", "BitgoRippleProviderV2"), ("4", "BitGoStellarProviderV2"),
      ("5", "BitGoEOSProviderV2"), ("6", "CUGBlockchainProvider"),
      ("7", "BitGoTronProviderV2")]),
    ("DynamicGroupID", "EXW_Dictionary", "DynamicGroup", "DynamicGroupID", "Name",
     [("2", "Uropean_Investors"), ("3", "AsicHighLeverageUsers"),
      ("5", "FrenchRejectedRedeems"), ("6", "CopyPortfolio500USDMin"),
      ("7", "CopyPortfolio5000USDMin"), ("8", "DefaultLeverageGroupStocks"),
      ("9", "US_SSN_WalletClosure"), ("10", "USCopyAlphaUsers"),
      ("11", "ROWCopyAlphaUsers"), ("12", "IsraelEligibleUsers"),
      ("14", "StakingHolders_Eth"), ("16", "C2F_Rollout"),
      ("17", "C2F_Test"), ("18", "WalletBlockedGermanCustomers"),
      ("21", "GermanyAirdropBlockedUsers")]),
    ("ManualApproveTransactionStatusID", "EXW_Dictionary",
     "ManualApproveTransactionStatus", "Id", "Name",
     [("1", "Pending"), ("2", "Approved"), ("3", "Rejected"), ("4", "Sent")]),
    ("PaymentStatusID@EXW", "EXW_Dictionary", "PaymentStatuses", "Id", "Name",
     [("1", "PendingProvider"), ("2", "InitiateStarted"), ("3", "DocumentCompleted"),
      ("4", "InitiateCompleted"), ("5", "InitiateFailed"), ("6", "TransferCompleted"),
      ("7", "PendingTransaction"), ("8", "Failed"), ("9", "Completed"),
      ("10", "InternalError"), ("11", "ProviderSubmitted")]),
    ("ReceivedTransactionTypeID", "EXW_Dictionary", "ReceivedTransactionTypes",
     "Id", "Name",
     [("1", "MoneyIn"), ("2", "Redeem"), ("3", "Funding"),
      ("4", "ConversionFromUser"), ("5", "ConversionFromEtoro"),
      ("6", "Payment"), ("7", "RedeemAsic"), ("8", "StakeAndRewardsRefund")]),
    ("RequestStatusID", "EXW_Dictionary", "RequestStatuses", "Id", "Name",
     [("0", "Start"), ("1", "Done"), ("2", "Error"), ("3", "ExecuterEnqueued"),
      ("4", "ReadByExecuter"), ("5", "TransactionSentToBlockChain"),
      ("6", "TransactionConfirmed"), ("7", "TransactionVerified"),
      ("8", "AmlEnqueued"), ("9", "ReadByAml"), ("16", "TemporaryError"),
      ("25", "WaitingForManualApproval"), ("26", "ManuallyApproved"),
      ("27", "ManuallyRejected"), ("28", "StakingEnqueued"),
      ("29", "ReadByStakingService"), ("30", "ConversionWorkerEnqueued"),
      ("31", "ReadByConversionWorker"), ("32", "FiatAccountFunded"),
      ("33", "MarketMakerUpdated"), ("34", "OperationRejected")]),
    ("RequestTypeID", "EXW_Dictionary", "RequestTypes", "Id", "Name",
     [("0", "CreateWallet"), ("1", "SendTransaction"), ("2", "InitiatePayment"),
      ("3", "Redeem"), ("4", "Conversion"), ("5", "Funding"), ("6", "Staking"),
      ("7", "ConversionToFiat")]),
    ("StakingStatusID", "EXW_Dictionary", "StakingStatuses", "Id", "Name",
     [("1", "Pending"), ("2", "Failed"), ("3", "Completed")]),
    ("TransactionStatusID@EXW", "EXW_Dictionary", "TransactionStatus", "Id", "Name",
     [("0", "Pending"), ("1", "Confirmed"), ("2", "Verified"),
      ("3", "Error"), ("4", "Timeout"), ("5", "PermanentError"),
      ("6", "WavedError")]),
    ("TransactionTypeID@EXW", "EXW_Dictionary", "TransactionTypes", "Id", "Name",
     [("0", "Redeem"), ("1", "CustomerMoneyOut"), ("2", "AmlMoneyBack"),
      ("4", "Funding"), ("5", "ConversionMoneyIn"), ("6", "ConversionMoneyOut"),
      ("7", "Payment"), ("8", "RedeemAsic"), ("9", "Staking"),
      ("10", "BlockChainActivation"), ("11", "OmnibusMoneyOut"),
      ("12", "ConversionToFiat"), ("13", "ManualUserMoneyOut"),
      ("14", "StakeAndRewardsRefund")]),
    ("WalletPoolStatusID", "EXW_Dictionary", "WalletPoolStatuses", "Id", "Name",
     [("1", "Pending"), ("2", "Verified"), ("3", "Failed"),
      ("4", "FundingInitiated"), ("5", "FundingSent"),
      ("6", "FundingVerified"), ("7", "FundingFailed")]),
    ("WalletProviderID", "EXW_Dictionary", "WalletProvider", "Id", "Name",
     [("1", "Bitgo"), ("2", "CUG"), ("3", "None")]),
    ("WalletTypeID", "EXW_Dictionary", "WalletTypes", "Id", "Name",
     [("1", "Redeem"), ("2", "Conversion"), ("3", "Funding"),
      ("4", "Payment"), ("5", "Customer"), ("6", "C2F"), ("7", "StakingRefund")]),
]

ALIAS_MAP: dict[str, str] = {
    # Decoded siblings of DWH dims
    "Country": "CountryID",
    "Currency": "CurrencyID",
    "PlayerLevel": "PlayerLevelID",
    "Club": "PlayerLevelID",
    "Tier": "PlayerLevelID",
    "CurrentTier": "PlayerLevelID",
    "PlayerStatus": "PlayerStatusID",
    "AccountType": "AccountTypeID",
    "AccountStatus": "AccountStatusID",
    "Label": "LabelID",
    "Regulation": "RegulationID",
    "Language": "LanguageID",
    "CardType": "CardTypeID",
    "ContractType": "ContractTypeID",
    "GuruStatus": "GuruStatusID",
    "DocumentStatus": "DocumentStatusID",
    "CreditType": "CreditTypeID",
    "MoveMoneyReason": "MoveMoneyReasonID",
    "BonusType": "BonusTypeID",
    "ActionType": "ActionTypeID",
    "ClosePositionReason": "ClosePositionReasonID",
    "CashoutMode": "CashoutModeID",
    "CashoutStatus": "CashoutStatusID",
    "EvMatchStatus": "EvMatchStatusID",
    "FundType": "FundTypeID",
    "FundingType": "FundingTypeID",
    "MifidCategorization": "MifidCategorizationID",
    "PaymentStatus": "PaymentStatusID",
    "PendingClosureStatus": "PendingClosureStatusID",
    "PhoneVerified": "PhoneVerifiedID",
    "Platform": "PlatformID",
    "Product": "ProductID",
    "RiskClassification": "RiskClassificationID",
    "RiskManagementStatus": "RiskManagementStatusID",
    "RiskStatus": "RiskStatusID",
    "ScreeningStatus": "ScreeningStatusID",
    "SocialNetwork": "SocialNetworkID",
    "VerificationLevel": "VerificationLevelID",
    "WorldCheck": "WorldCheckID",
    "MirrorType": "MirrorTypeID",
    "CustomerChangeType": "CustomerChangeTypeID",
    "InstrumentType": "InstrumentTypeID",
    # Decoded siblings of eMoney / EXW
    "AccountProgram": "AccountProgramID",
    "AuthorizationType": "AuthorizationTypeID",
    "CardStatus": "CardStatusID",
    "CurrencyBalanceStatus": "CurrencyBalanceStatusID",
    "PaymentSchemaType": "PaymentSchemaTypeID",
    "Provider": "ProviderID",
    "TransactionCategory": "TransactionCategoryID@eMoney",
    "TxCategory": "TransactionCategoryID@eMoney",
    "TxCategoryID": "TransactionCategoryID@eMoney",
    "TransactionType": "TransactionTypeID@eMoney",
    "TransactionTypeID": "TransactionTypeID@eMoney",
    "TxType": "TransactionTypeID@eMoney",
    "TxTypeID": "TransactionTypeID@eMoney",
    "TransactionStatus": "TransactionStatusID@eMoney",
    "TransactionStatusID": "TransactionStatusID@eMoney",
    "TxStatus": "TransactionStatusID@eMoney",
    "TxStatusID": "TransactionStatusID@eMoney",
    "ConversionStatus": "ConversionStatusID",
    "RequestStatus": "RequestStatusID",
    "RequestLastStatus": "RequestStatusID",
    "RequestLastStatusID": "RequestStatusID",
    "LastWalletPoolStatus": "WalletPoolStatusID",
    "WalletPoolStatus": "WalletPoolStatusID",
    "WalletType": "WalletTypeID",
    "WalletProvider": "WalletProviderID",
    "StakingStatus": "StakingStatusID",
    "CountryGroup": "CountryGroupID",
    "DynamicGroup": "DynamicGroupID",
    "RequestType": "RequestTypeID",
    "ReceivedTransactionType": "ReceivedTransactionTypeID",
    "ChecksumType": "ChecksumTypeID",
    "CryptoCoinProvider": "CryptoCoinProviderID",
    "ManualApproveTransactionStatus": "ManualApproveTransactionStatusID",
}


def main() -> None:
    if OUT.exists():
        truth = json.loads(OUT.read_text(encoding="utf-8"))
    else:
        truth = {}

    # Drop pre-existing aliases so we rebuild them cleanly.
    truth = {k: v for k, v in truth.items() if not v.get("alias_of")}

    for key, schema, table, id_col, name_col, rows in EMONEY_ROWS + EXW_ROWS:
        truth[key] = {
            "schema": schema,
            "table": table,
            "dim": f"{schema}.{table}",
            "id_col": id_col,
            "name_col": name_col,
            "rows": {i: n for i, n in rows},
        }

    # Apply aliases. For every alias X -> Y, also create X@scope -> Y@scope
    # automatically when Y has a scoped variant (so decoded-column lookups
    # in eMoney/EXW files resolve to the right dictionary, not DWH default).
    added = 0
    for alias, primary in ALIAS_MAP.items():
        if primary not in truth:
            print(f"WARN: alias '{alias}' -> '{primary}' (primary missing)", flush=True)
            continue
        if alias not in truth:
            truth[alias] = {**truth[primary], "alias_of": primary}
            added += 1
        for scope in ("eMoney", "EXW"):
            scoped_primary = f"{primary}@{scope}"
            scoped_alias = f"{alias}@{scope}"
            if scoped_primary in truth and scoped_alias not in truth:
                truth[scoped_alias] = {**truth[scoped_primary], "alias_of": scoped_primary}
                added += 1
    # Also create scoped variants for the base primary keys themselves where a
    # scoped sibling exists (so column='AccountStatusID' in an eMoney file can
    # resolve to AccountStatusID@eMoney via the resolver's @scope path).
    for key in list(truth.keys()):
        if "@" in key:
            continue
        for scope in ("eMoney", "EXW"):
            scoped = f"{key}@{scope}"
            # If a scoped sibling exists for THIS exact key, leave alone -- the
            # resolver will pick it up via the file context. No alias needed.
            _ = scoped

    OUT.write_text(json.dumps(truth, indent=2, sort_keys=True), encoding="utf-8")
    total = sum(len(t.get("rows") or {}) for t in truth.values()
                if not t.get("alias_of"))
    print(f"Wrote {OUT.relative_to(REPO)}: {len(truth)} keys "
          f"({added} aliases added), {total} truth rows")


if __name__ == "__main__":
    main()
