import { TransactionComponent }                        from "./Transaction";
import { reapAccountErrorToString, mintErrorToString } from "./TokenUtils";
import Balance                                         from "../base/Balance";
import { TransactionsRecord }                          from "../../../declarations/godwin_sub/godwin_sub.did";

import React                                           from "react";
import { Tooltip }                                     from "@mui/material";
import ErrorOutlineIcon                                from "@mui/icons-material/ErrorOutline";
import { fromNullable }                                from "@dfinity/utils";

export type TransactionsRecordInput = {
  tx_record: TransactionsRecord | undefined;
};

export const TransactionsRecordComponent = ({tx_record}: TransactionsRecordInput) => {

	return (
    <div className="py-1 px-6 w-full text-black dark:text-white py-1 text-sm">
    {
      tx_record === undefined ? <></> :
      <div className="grid grid-cols-3 gap-x-1">
        <div className="flex flex-col items-center text-red-600 dark:text-red-400">
          <div className="text-black dark:text-white">Payin</div>
          <div>
            <TransactionComponent tx_index={tx_record.payin} />
          </div>
        </div>
        <div className="flex flex-col items-center">
          <div>Refund</div>
          <div className="text-green-600 dark:text-green-400">
            { tx_record.payout['PROCESSED'] === undefined ? 
              <div className="text-xs text-gray-500 dark:text-gray-400">Pending</div> :
                fromNullable(tx_record.payout['PROCESSED'].refund) === undefined ?
              <Balance amount={BigInt(0)}/> :
                fromNullable(tx_record.payout['PROCESSED'].refund)['err'] !== undefined ?
              <Tooltip title={ reapAccountErrorToString(fromNullable(tx_record.payout['PROCESSED'].refund)['err'])} arrow>
                <ErrorOutlineIcon color="error"></ErrorOutlineIcon>
              </Tooltip> : 
              <TransactionComponent tx_index={fromNullable(tx_record.payout['PROCESSED'].refund)['ok']} />
            }
          </div>
        </div>
        <div className="flex flex-col items-center">
          <div>Reward</div>
          <div className="text-green-600 dark:text-green-400">
            { tx_record.payout['PROCESSED'] === undefined ? 
              <div className="text-xs text-gray-500 dark:text-gray-400">Pending</div> :
                fromNullable(tx_record.payout['PROCESSED'].reward) === undefined ?
              <Balance amount={BigInt(0)}/> :
                fromNullable(tx_record.payout['PROCESSED'].reward)['err'] !== undefined ?
              <Tooltip title={ mintErrorToString(fromNullable(tx_record.payout['PROCESSED'].reward)['err'])} arrow>
                <ErrorOutlineIcon color="error"></ErrorOutlineIcon>
              </Tooltip> : 
              <TransactionComponent tx_index={fromNullable(tx_record.payout['PROCESSED'].reward)['ok']} />
            }
          </div>
        </div>
      </div>
    }
    </div>
	);
};

export default TransactionsRecordComponent;
