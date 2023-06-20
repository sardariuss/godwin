import InterestBallot                       from "./InterestBallot";
import { interestToEnum }                   from "./InterestTypes";
import SvgButton                            from "../base/SvgButton";
import TransactionIcon                      from "../icons/TransactionIcon";
import TransactionsRecordComponent          from "../token/TransactionsRecord";
import { Sub }                              from "../../ActorContext";
import CONSTANTS                            from "../../Constants";
import { Question, RevealedInterestBallot } from "../../../declarations/godwin_backend/godwin_backend.did";

import { useState, useEffect }              from "react";
import { fromNullable }                     from "@dfinity/utils";


export type InterestDetailedBallotInput = {
  sub: Sub;
  ballot: RevealedInterestBallot;
};

const InterestDetailedBallot = ({sub, ballot} : InterestDetailedBallotInput) => {

  const [question, setQuestion] = useState<Question | null | undefined>(undefined);
  const [showTransactions, setShowTransactions] = useState<boolean>(false);

  const refreshQuestionIteration = async () => {
    setQuestion(old => { return undefined; });
    let question_iteration = await sub.actor.getQuestionIteration({ 'INTEREST' : null }, ballot.vote_id)
    if (question_iteration['ok'] !== undefined){
      let q : Question | undefined = fromNullable(question_iteration['ok'][2]);
      setQuestion(old => { return (q === undefined ? null : q); });
    }
  }

  useEffect(() => {
    refreshQuestionIteration();
  }, [ballot]);

  return (
    <div className="flex flex-col items-center w-full grow justify-items-center border-b dark:border-gray-700 hover:bg-slate-50 hover:dark:bg-slate-850 px-5">
      <div className="grid grid-cols-10 text-black dark:text-white w-full space-x-5 items-center">
        <div className="col-span-8 flex flex-col py-1 justify-between w-full space-y-2 justify-start text-sm font-normal break-words">
        {
					question === undefined ? 
					<div role="status" className="w-full animate-pulse">
						<div className="h-2 bg-gray-200 rounded-full dark:bg-gray-700 my-2"></div>
						<div className="h-2 bg-gray-200 rounded-full dark:bg-gray-700 my-2"></div>
						<div className="h-2 bg-gray-200 rounded-full dark:bg-gray-700 max-w-[330px] my-2"></div>
						<span className="sr-only">Loading...</span>
					</div> :
          question === null ?
          <div className="italic text-gray-600 dark:text-gray-400 text-xs">
            { CONSTANTS.HELP_MESSAGE.DELETED_QUESTION }
          </div> :
					<div>
          	{question.text}
        	</div>
				}
        </div>
        <div className="w-full col-span-1 justify-self-center">
          <InterestBallot 
            answer={fromNullable(ballot.answer) !== undefined ? interestToEnum(fromNullable(ballot.answer)) : null} 
            dateNs={ballot.date}/>
        </div>
        <div className="col-span-1 svg-button w-6 h-6 self-center justify-self-center">
          <SvgButton disabled={false} onClick={(e) => {setShowTransactions(old => { return !old; })}} hidden={false}>
            <div className="flex flex-col items-center">
              <TransactionIcon/>
            </div>
          </SvgButton>
        </div>
      </div>
      <div className="w-full">
      {
        showTransactions ?
          <TransactionsRecordComponent tx_record={fromNullable(ballot.transactions_record)}/> 
        : <></>
      }
      </div>
    </div>
  );
};

export default InterestDetailedBallot;