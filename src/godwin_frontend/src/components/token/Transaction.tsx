import { transactionFromIdlType, transactionKindToString } from "./TokenUtils"
import { Transaction }                                     from "./TokenTypes"
import Balance                                             from "../base/Balance"
import Spinner                                             from "../Spinner"
import { nsToStrDate }                                     from "../../utils/DateUtils"
import { ActorContext }                                    from "../../ActorContext"

import { fromNullable }                                    from "@dfinity/utils"
import { useState, useEffect, useContext }                 from "react"

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
      tx === null ? 
      <Spinner/> :
      <div className="flex flex-col text-sm">
        <div className="self-center">
          <Balance amount={tx.amount}/>
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