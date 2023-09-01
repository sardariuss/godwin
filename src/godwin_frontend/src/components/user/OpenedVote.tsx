import SvgButton                                   from "../base/SvgButton";
import TransactionIcon                             from "../icons/TransactionIcon";
import TransactionsRecordComponent                 from "../token/TransactionsRecord";
import CONSTANTS                                   from "../../Constants";
import { Sub }                                     from "../../ActorContext";
import { timeAgo }                                 from "../../utils/DateUtils";
import { QueryOpenedVoteItem, TransactionsRecord } from "../../../declarations/godwin_sub/godwin_sub.did";

import React, { useState, useEffect }              from "react";
import { Principal }                               from "@dfinity/principal";
import { fromNullable }                            from "@dfinity/utils";


export type OpenedVoteInput = {
  sub: Sub;
  principal: Principal;
  opened_vote: QueryOpenedVoteItem;
};

const OpenedVote = ({sub, principal, opened_vote} : OpenedVoteInput) => {

  const [showTransactions,   setShowTransactions  ] = useState<boolean>                       (false    );
  const [transactionsRecord, setTransactionsRecord] = useState<TransactionsRecord | undefined>(undefined);

  const fetchTransaction = () => {
    sub.actor.findOpenedVoteTransactions(principal, opened_vote.vote_id).then((record) => {
      setTransactionsRecord(fromNullable(record));
    });
  }

  useEffect(() => {
    if (showTransactions && transactionsRecord === undefined){
      fetchTransaction();
    };
  }, [showTransactions]);

  return (
    <div className="flex flex-col items-center w-full grow justify-items-center border-b dark:border-gray-700 hover:bg-slate-50 hover:dark:bg-slate-850 px-5">
      <div className="grid grid-cols-12 text-black dark:text-white w-full gap-x-5 items-center py-1">
        <div className="col-span-2 justify-self-start text-sm">
          <div> { opened_vote.iteration > 0 ? "Reopened" : "Author" } </div>
        </div>
        <div className="col-span-2 justify-self-start text-sm">
          <div> { timeAgo(new Date(Number(opened_vote.date) / 1000000)) } </div>
        </div>
        <div className="col-span-7 flex flex-col justify-between w-full space-y-2 justify-start text-sm font-normal break-words">
        {
          fromNullable(opened_vote.question) === undefined ?
          <div className="italic text-gray-600 dark:text-gray-400 text-xs">
            { CONSTANTS.HELP_MESSAGE.DELETED_QUESTION }
          </div> :
					<div>
          	{opened_vote.question[0]?.text}
        	</div>
				}
        </div>
        <div className="col-span-1 svg-button w-6 h-6 self-center justify-self-center">
          <SvgButton disabled={false} onClick={(e) => {setShowTransactions(old => { return !old; })}} hidden={false}>
            <TransactionIcon/>
          </SvgButton>
        </div>
      </div>
      <div className="w-full">
      {
        showTransactions ?
          <TransactionsRecordComponent tx_record={transactionsRecord}/> 
        : <></>
      }
      </div>
    </div>
  );
};

export default OpenedVote;