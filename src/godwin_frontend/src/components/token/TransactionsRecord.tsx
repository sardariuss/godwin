import { useEffect, useState, useContext } from "react";

import { TransactionsRecord, ReapAccountResult, MintResult, ReapAccountError, MintError } from "../../../declarations/godwin_backend/godwin_backend.did";

import { ActorContext } from "../../ActorContext";

import { fromNullable } from "@dfinity/utils";

import { TransactionComponent } from "./Transaction";

import { transactionFromIdlType, reapAccountErrorToString, mintErrorToString } from "./TokenUtils";
import { Transaction } from "./TokenTypes";

import { Tooltip }                      from "@mui/material";
import ErrorOutlineIcon                 from '@mui/icons-material/ErrorOutline';

export type TransactionsRecordInput = {
  tx_record: TransactionsRecord;
};

export const TransactionsRecordComponent = ({tx_record}: TransactionsRecordInput) => {

	return (
    <div className="flex flex-col py-1 px-6 w-full text-black dark:text-white border-b dark:border-gray-700 hover:bg-slate-50 hover:dark:bg-slate-850 py-2">
      { /*
      <div>
        { refund !== undefined && reward !== undefined && payin !== undefined ? 
            (refund + reward - payin) > 0 ?
              <div className="text-xs text-green-500"> {"⬆🪙 " + (refund + reward- payin).toString() } </div> :
            (refund + reward - payin) <= 0 ?
              <div className="text-xs text-red-500"> {"⬇🪙 " + (refund + reward- payin).toString() } </div>
            : 
              <div className="text-xs text-red-500"> {"≈🪙 " + (refund + reward - payin).toString() } </div> 
          :
          <></>
        }
      </div>
      */}
      <div className="flex flex-col">
        <div>Payin</div>
        <TransactionComponent tx_index={tx_record.payin} />
      </div>
      <div>
        <div>Refund</div>
        <div>
          { tx_record.payout['PROCESSED'] === undefined ? 
            <div>Not processed</div> :
              fromNullable(tx_record.payout['PROCESSED'].refund) === undefined ?
            <div>Empty refund</div> :
              fromNullable(tx_record.payout['PROCESSED'].refund)['err'] !== undefined ?
            <Tooltip title={ reapAccountErrorToString(fromNullable(tx_record.payout['PROCESSED'].refund)['err'])} arrow>
              <ErrorOutlineIcon color="error"></ErrorOutlineIcon>
            </Tooltip> : 
            <TransactionComponent tx_index={fromNullable(tx_record.payout['PROCESSED'].refund)['ok']} />
          }
        </div>
      </div>
      <div>
        <div>Reward</div>
        <div>
          { tx_record.payout['PROCESSED'] === undefined ? 
            <div>Not processed</div> :
              fromNullable(tx_record.payout['PROCESSED'].reward) === undefined ?
            <div>Empty reward</div> :
              fromNullable(tx_record.payout['PROCESSED'].reward)['err'] !== undefined ?
            <Tooltip title={ mintErrorToString(fromNullable(tx_record.payout['PROCESSED'].reward)['err'])} arrow>
              <ErrorOutlineIcon color="error"></ErrorOutlineIcon>
            </Tooltip> : 
            <TransactionComponent tx_index={fromNullable(tx_record.payout['PROCESSED'].reward)['ok']} />
          }
        </div>
      </div>
    </div>
	);
};

export default TransactionsRecordComponent;
