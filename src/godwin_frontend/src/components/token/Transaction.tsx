import { transactionFromIdlType, transactionKindToString } from "./TokenUtils"
import { Transaction, LedgerType }                         from "./TokenTypes"
import Balance                                             from "../base/Balance"
import Spinner                                             from "../Spinner"
import { nsToStrDate }                                     from "../../utils/DateUtils"
import { ActorContext }                                    from "../../ActorContext"

import { fromNullable }                                    from "@dfinity/utils"
import React, { useState, useEffect, useContext }          from "react"

type TransactionComponentInput = {
  tx_index: bigint;
  ledger_type: LedgerType;
}

export const TransactionComponent = ({tx_index, ledger_type}: TransactionComponentInput) => {

  const [tx, setTx] = useState<Transaction | null>(null);

  const {token, ck_btc} = useContext(ActorContext);

  // @todo: use get_transactions instead (get_transaction is not part of ckbtc: https://dashboard.internetcomputer.org/canister/mxzaz-hqaaa-aaaar-qaada-cai)
  const refreshTx = () => {
    switch (ledger_type) {
      case LedgerType.BTC: ck_btc?.get_transaction(tx_index).then(tx => {
        let opt_tx = fromNullable(tx);
        setTx(old => { return opt_tx !== undefined ? transactionFromIdlType(opt_tx) : null; });
      }); break;
      case LedgerType.GWC: token?.get_transaction(tx_index).then(tx => {
        let opt_tx = fromNullable(tx);
        setTx(old => { return opt_tx !== undefined ? transactionFromIdlType(opt_tx) : null; });
      }); break;
    }
  }
  
  useEffect(() => {
    refreshTx();
  }, [tx_index]);

  return (
    <div>
    {
      tx === null ? 
      <div className="w-4 h-4">
        <Spinner/>
      </div> :
      <div className="flex flex-col text-sm">
        <div className="self-center">
          <Balance amount={tx.amount} ledger_type={ledger_type}/>
        </div>
        <div className="text-xs text-gray-500 dark:text-gray-400">
          <div>
            { "Type: " + transactionKindToString(tx.kind) }
          </div>
          <div>
            { "Date: " + nsToStrDate(tx.timestamp) }
          </div>
          <div>
            { "Index: " + tx.index.toString() }
          </div>
        </div>
      </div>
    }
    </div>
  )
}