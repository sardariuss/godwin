import SvgButton                            from "../base/SvgButton";
import TransactionIcon                      from "../icons/TransactionIcon";
import TransactionsRecordComponent          from "../token/TransactionsRecord";
import CONSTANTS                            from "../../Constants";
import { Question, TransactionsRecord }     from "../../../declarations/godwin_sub/godwin_sub.did";

import { useState }                         from "react";


export type AuthorQuestionInput = {
  question: Question | undefined;
  tx_record: TransactionsRecord | undefined;
};

const AuthorQuestion = ({question, tx_record} : AuthorQuestionInput) => {

  const [showTransactions, setShowTransactions] = useState<boolean>(false);

  return (
    <div className="flex flex-col items-center w-full grow justify-items-center border-b dark:border-gray-700 hover:bg-slate-50 hover:dark:bg-slate-850 px-5">
      <div className="grid grid-cols-9 text-black dark:text-white w-full space-x-5 items-center">
        <div className="col-span-8 flex flex-col py-1 justify-between w-full space-y-2 justify-start text-sm font-normal break-words">
        {
          question === undefined ?
          <div className="italic text-gray-600 dark:text-gray-400 text-xs">
            { CONSTANTS.HELP_MESSAGE.DELETED_QUESTION }
          </div> :
					<div>
          	{question.text}
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
          <TransactionsRecordComponent tx_record={tx_record}/> 
        : <></>
      }
      </div>
    </div>
  );
};

export default AuthorQuestion;