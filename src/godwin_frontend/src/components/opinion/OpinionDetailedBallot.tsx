import CursorBallot                           from "../base/CursorBallot";
import { toCursorInfo, revealAnswer }         from "../../utils";
import CONSTANTS                              from "../../Constants";
import { Sub }                                from "../../ActorContext";
import { Question, RevealableOpinionBallot }  from "../../../declarations/godwin_sub/godwin_sub.did";

import React, { useState, useEffect }         from "react";
import { fromNullable }                       from "@dfinity/utils";


export type OpinionDetailedBallotInput = {
  sub: Sub;
  ballot: RevealableOpinionBallot;
};

const OpinionDetailedBallot = ({sub, ballot} : OpinionDetailedBallotInput) => {

  const [question, setQuestion] = useState<Question | null | undefined>(undefined);

  const refreshQuestionIteration = async () => {
    setQuestion(old => { return undefined; });
    let question_iteration = await sub.actor.getQuestionIteration({ 'OPINION' : null }, ballot.vote_id)
    if (question_iteration['ok'] !== undefined){
      let q : Question | undefined = fromNullable(question_iteration['ok'][2]);
      setQuestion(old => { return (q === undefined ? null : q); });
    }
  }

  useEffect(() => {
    refreshQuestionIteration();
  }, [ballot]);

  return (
    <div className={`w-full border-b dark:border-gray-700`}>
      <div className={`flex flex-col items-center w-full grow justify-items-center hover:bg-slate-50 hover:dark:bg-slate-850 pl-5 pr-12`}>
        <div className={`grid grid-cols-10 text-black dark:text-white w-full space-x-10 items-center`}>
          <div className={`col-span-9 flex flex-col py-1 justify-between w-full space-y-2 justify-start text-sm font-normal break-words`}>
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
          {/* Cursor ballots require some x padding because of the range input*/}
          <div className="col-span-1 w-full justify-self-center">
            <CursorBallot 
              cursorInfo={revealAnswer(ballot.answer) !== undefined ? toCursorInfo(revealAnswer(ballot.answer).cursor, CONSTANTS.OPINION_INFO) : undefined}
              dateNs={ballot.date}
              isLate={false}
              />
          </div>
        </div>
      </div>
    </div>
  );
};

export default OpinionDetailedBallot;