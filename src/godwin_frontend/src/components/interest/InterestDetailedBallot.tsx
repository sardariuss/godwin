import { InterestEnum }                                        from "./InterestTypes";
import InterestBallot                                          from "./InterestBallot";
import SvgButton                                               from "../base/SvgButton";
import TransactionIcon                                         from "../icons/TransactionIcon";
import TransactionsRecordComponent                             from "../token/TransactionsRecord";
import { Sub }                                                 from "../../ActorContext";
import { TransactionsRecord }                                  from "../../../declarations/godwin_sub/godwin_sub.did";
import { RevealableBallot, VoteKind, voteKindToCandidVariant } from "../../utils";
import { nsToStrDate }                                         from "../../utils/DateUtils";

import React, { useState, useEffect }                          from "react";
import { fromNullable }                                        from "@dfinity/utils";
import { Principal }                                           from "@dfinity/principal";


export type InterestDetailedBallotInput = {
  sub: Sub;
  vote_id: bigint;
  iteration: bigint;
  ballot: RevealableBallot<InterestEnum>;
  principal: Principal;
};

const InterestDetailedBallot = ({sub, vote_id, iteration, ballot, principal} : InterestDetailedBallotInput) => {

  const voteKind = voteKindToCandidVariant(VoteKind.INTEREST);
  
  const [showTransactions,   setShowTransactions  ] = useState<boolean>                       (false    );
  const [transactionsRecord, setTransactionsRecord] = useState<TransactionsRecord | undefined>(undefined);

  const fetchTransaction = () => {
    sub.actor.findBallotTransactions(voteKind, principal, vote_id).then((record) => {
      console.log(fromNullable(record));
      setTransactionsRecord(fromNullable(record));
    });
  }

  useEffect(() => {
    if (showTransactions && transactionsRecord === undefined){
      fetchTransaction();
    };
  }, [showTransactions]);

  return (
    <div className={`flex flex-col justify-between items-center w-full`}>
      <div className={`flex flex-row justify-between items-center w-full`}>
        <div className="text-sm font-light">
          { "Iteration " + (Number(iteration) + 1).toString() }
        </div>
        <div className="text-sm font-light">
          { nsToStrDate(ballot.date) }
        </div>
        <InterestBallot answer={ballot.answer} dateNs={undefined}/>
        <div className="svg-button w-6 h-6 self-center justify-self-center">
          <SvgButton onClick={(e) => {setShowTransactions(old => { return !old; })}}>
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

export default InterestDetailedBallot;