import InterestBallot                            from "./InterestBallot";
import { interestToEnum }                        from "./InterestTypes";
import SvgButton                                 from "../base/SvgButton";
import TransactionIcon                           from "../icons/TransactionIcon";
import TransactionsRecordComponent               from "../token/TransactionsRecord";
import CONSTANTS                                 from "../../Constants";
import { Question, UserQuestionInterestBallots as QuestionBallots } from "../../../declarations/godwin_sub/godwin_sub.did";

import { useState, useEffect }                   from "react";
import { fromNullable }                          from "@dfinity/utils";


export type UserQuestionInterestBallotsInput = {
  question_ballots: QuestionBallots;
};

const UserQuestionInterestBallots = ({question_ballots} : UserQuestionInterestBallotsInput) => {

  const [showTransactions, setShowTransactions] = useState<boolean>(false);
  const [question, setQuestion] = useState<Question | undefined>(undefined);
  const [showHistory, setShowHistory] = useState<boolean>(false);

  const refreshQuestion = () => {
    setQuestion(fromNullable(question_ballots.question));
  };

  useEffect(() => {
    refreshQuestion();
  }, [question_ballots]);

  return (
    <div className="flex flex-col items-center w-full grow justify-items-center border-b dark:border-gray-700 hover:bg-slate-50 hover:dark:bg-slate-850 px-5">
      <div className="grid grid-cols-10 text-black dark:text-white w-full space-x-5 items-center">
        <div className="col-span-8 flex flex-col py-1 justify-between w-full space-y-2 justify-start text-sm font-normal break-words">
        {
          question === undefined ?
          <div className="italic text-gray-600 dark:text-gray-400 text-xs">
            { CONSTANTS.HELP_MESSAGE.DELETED_QUESTION }
          </div> :
					<div>
          	{ question.text }
        	</div>
				}
        </div>
        {
          Array.from(question_ballots.ballots).map((ballot) => (
            <div className="w-full col-span-1 justify-self-center">
              <InterestBallot 
                answer={fromNullable(ballot.answer) !== undefined ? interestToEnum(fromNullable(ballot.answer)) : null} 
                dateNs={ballot.date}/>
            </div>
          ))
        }
        <div className="col-span-1 svg-button w-6 h-6 self-center justify-self-center">
          <SvgButton disabled={false} onClick={(e) => {setShowTransactions(old => { return !old; })}} hidden={false}>
            <TransactionIcon/>
          </SvgButton>
        </div>
      </div>
      <div className="w-full">
      {
        showTransactions ?
          Array.from(question_ballots.ballots).map((ballot) => (
            <TransactionsRecordComponent tx_record={fromNullable(ballot.transactions_record)}/> 
          ))
        : <></>
      }
      </div>
    </div>
  );
};

export default UserQuestionInterestBallots;