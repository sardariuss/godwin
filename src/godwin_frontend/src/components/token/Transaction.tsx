import { Transaction } from "./TokenTypes"

import CONSTANTS from "../../Constants"

import { frome8s, transactionKindToString } from "./TokenUtils"

import { nsToStrDate } from "../../utils/DateUtils"

import { useState, useEffect, useContext } from "react"

import { ActorContext } from "../../ActorContext"

import { transactionFromIdlType } from "./TokenUtils"

import { fromNullable } from "@dfinity/utils"

type TransactionComponentInput = {
  tx_index: bigint;
}

export const TransactionComponent = ({tx_index}: TransactionComponentInput) => {

  const [tx, setTx] = useState<Transaction | null>(null);

  const {token} = useContext(ActorContext);

  const refreshTx = () => {
    token.get_transaction(tx_index).then(tx => {
      let opt_tx = fromNullable(tx);
      setTx(old => { return opt_tx !== undefined ? transactionFromIdlType(opt_tx) : null; });
    });
  }
  
  useEffect(() => {
    refreshTx();
  }, [tx_index]);

  return (
    <div>
    {
      tx === null ? <></> :
      <div className="flex flex-col text-xs text-gray-500 dark:text-gray-400">
        <div>
          { "Index: " + tx.index.toString() }
        </div>
        <div>
          { "Type: " + transactionKindToString(tx.kind) }
        </div>
        <div> 
          { "Amount: " + frome8s(tx.amount).toFixed(2) + " " + CONSTANTS.COIN_EMOJI } 
        </div>
        <div>
          { "Timestamp: " + nsToStrDate(tx.timestamp) }
        </div>
      </div>
    }
    </div>
  )
}