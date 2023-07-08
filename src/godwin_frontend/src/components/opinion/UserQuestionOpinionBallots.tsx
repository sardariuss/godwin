import CursorBallot                             from "../base/CursorBallot";
import SvgButton                                from "../base/SvgButton";
import ReturnIcon                               from "../icons/ReturnIcon";
import CONSTANTS                                from "../../Constants";
import { toCursorInfo }                         from "../../utils";
import { nsToStrDate }                          from "../../utils/DateUtils";
import { Question, UserQuestionOpinionBallots as QuestionBallots, RevealedBallot } from "../../../declarations/godwin_sub/godwin_sub.did";

import { useState, useEffect }                  from "react";
import { fromNullable }                         from "@dfinity/utils";


export type UserQuestionOpinionBallotsInput = {
  question_ballots: QuestionBallots;
};

const UserQuestionOpinionBallots = ({question_ballots} : UserQuestionOpinionBallotsInput) => {

  const [question, setQuestion] = useState<Question | undefined>(undefined);
  const [showHistory, setShowHistory] = useState<boolean>(false);
  const [lastBallot, setLastBallot] = useState<[bigint, boolean, RevealedBallot] | undefined>(undefined);

  const refresh = () => {
    setQuestion(fromNullable(question_ballots.question));
    setLastBallot(question_ballots.ballots.length > 0 ? question_ballots.ballots[question_ballots.ballots.length - 1] : undefined);
  };

  useEffect(() => {
    refresh();
  }, [question_ballots]);

  return (
    <div className="flex flex-col items-center w-full grow justify-items-center border-b dark:border-gray-700 hover:bg-slate-50 hover:dark:bg-slate-850 pl-5" onClick={() => { setShowHistory(!showHistory); }}>
      <div className="grid grid-cols-10 text-black dark:text-white w-full space-x-10 items-center">
        <div className="col-span-7 flex flex-col py-1 justify-between w-full space-y-2 justify-start text-sm font-normal break-words">
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
         {/* @todo: setting a relative size does not seem to work here*/}
        <div className="w-4 col-span-1 justify-self-end" hidden={showHistory}>
          <SvgButton disabled={false} hidden={false}>
            <ReturnIcon/>
          </SvgButton>
        </div>
        {/* Cursor ballots require some x padding because of the range input*/}
        <div className="w-full col-span-1 justify-self-center" hidden={showHistory}>
        {
          lastBallot !== undefined ? 
            <CursorBallot 
              cursorInfo={fromNullable(lastBallot[2].answer) !== undefined ? 
                toCursorInfo(fromNullable(lastBallot[2].answer), CONSTANTS.OPINION_INFO) : null}
              can_edit={lastBallot[1].valueOf()}
              dateNs={lastBallot[2].date}/> : <></>
        }
        </div>
      </div>
      <div className="w-full" hidden={!showHistory}>
      {
        Array.from(question_ballots.ballots).slice(0).reverse().map((ballot) => (
          <li className="grid grid-cols-10 text-black dark:text-white w-full space-x-10 items-center" key={ballot[2].vote_id.toString()}>
            <div className="col-span-3 text-xs font-light justify-start break-words">{"Vote " + ballot[0].toString() }</div>
            <div className="col-span-4 text-xs font-light  justify-start break-words">{nsToStrDate(ballot[2].date)}</div>
            <div className="w-full col-span-1">{/*spacer*/}</div>
            <div className="w-full col-span-1 justify-self-center">
              <CursorBallot 
                cursorInfo={fromNullable(ballot[2].answer) !== undefined ? toCursorInfo(fromNullable(ballot[2].answer), CONSTANTS.OPINION_INFO) : null}
                can_edit={ballot[1].valueOf()}
                dateNs={ballot[2].date}/>
            </div>
          </li>
        ))
       }
      </div>
    </div>
  );
};

export default UserQuestionOpinionBallots;