import { transactionFromIdlType, transactionKindToString } from "./TokenUtils"
import { Transaction }                                     from "./TokenTypes"
import Balance                                             from "../base/Balance"
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
      tx === null ? <></> :
      <div className="flex flex-col text-xs text-gray-500 dark:text-gray-400">
        <div>
          { "Index: " + tx.index.toString() }
        </div>
        <div>
          { "Type: " + transactionKindToString(tx.kind) }
        </div>
        <Balance amount={tx.amount}/>
        <div>
          { "Timestamp: " + nsToStrDate(tx.timestamp) }
        </div>
      </div>
    }
    </div>
  )
}