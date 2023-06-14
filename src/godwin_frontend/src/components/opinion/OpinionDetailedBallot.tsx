import CursorBallot                         from "../base/CursorBallot";
import { toCursorInfo }                     from "../../utils";
import CONSTANTS                            from "../../Constants";
import { Sub }                              from "../../ActorContext";
import { Question, RevealedOpinionBallot }  from "../../../declarations/godwin_backend/godwin_backend.did";

import { useState, useEffect }              from "react";
import { fromNullable }                     from "@dfinity/utils";


export type OpinionDetailedBallotInput = {
  sub: Sub;
  ballot: RevealedOpinionBallot;
};

const OpinionDetailedBallot = ({sub, ballot} : OpinionDetailedBallotInput) => {

  const [question, setQuestion] = useState<Question | undefined>(undefined);

  const refreshQuestionIteration = async () => {
    setQuestion(old => { return undefined; });
    let question_iteration = await await sub.actor.getQuestionIteration({ 'OPINION' : null }, ballot.vote_id)
    if (question_iteration['ok'] !== undefined){
      setQuestion(old => { return question_iteration['ok'][0] });
    }
  }

  useEffect(() => {
    refreshQuestionIteration();
  }, [ballot]);

  return (
    <div className="flex flex-col items-center w-full grow justify-items-center border-b dark:border-gray-700 hover:bg-slate-50 hover:dark:bg-slate-850">
      <div className="grid grid-cols-10 text-black dark:text-white w-full px-2 items-center">
        <div className="col-span-9 flex flex-col py-1 justify-between w-full space-y-2">
        {
					question === undefined ? 
					<div role="status" className="w-full animate-pulse">
						<div className="h-2 bg-gray-200 rounded-full dark:bg-gray-700 my-2"></div>
						<div className="h-2 bg-gray-200 rounded-full dark:bg-gray-700 my-2"></div>
						<div className="h-2 bg-gray-200 rounded-full dark:bg-gray-700 max-w-[330px] my-2"></div>
						<span className="sr-only">Loading...</span>
					</div> :
					<div className={`w-full justify-start text-sm font-normal`}>
          	{question.text}
        	</div>
				}
        </div>
        <div className="w-full col-span-1 justify-self-center">
          <CursorBallot 
            cursorInfo={fromNullable(ballot.answer) !== undefined ? toCursorInfo(fromNullable(ballot.answer), CONSTANTS.OPINION_INFO) : null}
            dateNs={ballot.date}/>
        </div>
      </div>
    </div>
  );
};

export default OpinionDetailedBallot;