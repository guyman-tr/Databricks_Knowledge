-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.bi_output.vg_emoney_openbankingdeposit
-- Captured: 2026-05-19T14:56:32Z
-- ==========================================================================

select
    CID,
    TransferID                                   as OpenBankingDeposit_Attempt_ID,

    case
        when TransferStatusID = 10
            then 'Success'
        else 'Pending_or_Failed'
    end                                          as OpenBankingDeposit_Attempt_Status,

    case
        when left(p.ExReferenceID, 2) = 'TZ' then 'Volt'
        when left(p.ExReferenceID, 2) = 'TK' then 'Tink'
        else 'Other'
    end                                          as OpenBankingDeposit_Provider, 
    Amount as OpenBankingDeposit_Attempt_USDAmount , ModificationDate as OpenBankingDeposit_Attempt_Date

from main.bi_db.bronze_moneytransfer_billing_transfers p
