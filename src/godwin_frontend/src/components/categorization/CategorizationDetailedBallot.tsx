import CursorBallot                               from "../base/CursorBallot";
import SvgButton                                  from "../base/SvgButton";
import TransactionIcon                            from "../icons/TransactionIcon";
import TransactionsRecordComponent                from "../token/TransactionsRecord";
import { toMap, getStrongestCategoryCursorInfo }  from "../../utils";
import { Sub }                                    from "../../ActorContext";
import CONSTANTS                                  from "../../Constants";
import { Question, RevealedCategorizationBallot } from "../../../declarations/godwin_backend/godwin_backend.did";

import { useState, useEffect }                    from "react";
import { fromNullable }                           from "@dfinity/utils";


export type CategorizationDetailedBallotInput = {
  sub: Sub;
  ballot: RevealedCategorizationBallot;
};

const CategorizationDetailedBallot = ({sub, ballot} : CategorizationDetailedBallotInput) => {

  const [question, setQuestion] = useState<Question | null | undefined>(undefined);
  const [showTransactions, setShowTransactions] = useState<boolean>(false);

  const refreshQuestionIteration = async () => {
    setQuestion(old => { return undefined; });
    let question_iteration = await sub.actor.getQuestionIteration({ 'CATEGORIZATION' : null }, ballot.vote_id)
    if (question_iteration['ok'] !== undefined){
      let q : Question | undefined = fromNullable(question_iteration['ok'][2]);
      setQuestion(old => { return (q === undefined ? null : q); });
    }
  }
  useEffect(() => {
    refreshQuestionIteration();
  }, [ballot]);

  return (
    <div className="flex flex-col items-center w-full grow justify-items-center border-b dark:border-gray-700 hover:bg-slate-50 hover:dark:bg-slate-850 pl-5">
      <div className="grid grid-cols-10 text-black dark:text-white w-full space-x-5 items-center pr-12">
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
          <div className="italic">
            { CONSTANTS.HELP_MESSAGE.DELETED_QUESTION }
          </div> :
					<div className={`w-full justify-start text-sm font-normal`}>
          	{question.text}
        	</div>
				}
        </div>
        {/* Cursor ballots require some padding in x because of the range input*/}
        <div className="col-span-2 grid grid-cols-2 w-full space-x-10 items-center">
          <div className="w-full col-span-1 justify-self-center">
            <CursorBallot 
              cursorInfo={fromNullable(ballot.answer) !== undefined ? getStrongestCategoryCursorInfo(toMap(fromNullable(ballot.answer)), toMap(sub.categories)) : null}
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

export default CategorizationDetailedBallot;