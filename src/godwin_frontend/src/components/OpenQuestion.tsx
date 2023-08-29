import { ActorContext }                           from "../ActorContext"
import Balance                                    from "./base/Balance";
import Spinner                                    from "./Spinner";
import { openQuestionErrorToString }              from "../utils";
import CONSTANTS                                  from "../Constants";
import { Sub }                                    from "../ActorContext";

import React, { useContext, useState, useEffect } from "react";

import { Tooltip }                                from "@mui/material";
import ErrorOutlineIcon                           from "@mui/icons-material/ErrorOutline";
import DoneIcon                                   from '@mui/icons-material/Done';

type Props = {
  canSelectSub: boolean,
  subId: string | undefined,
  onSubmitQuestion: (question_id: bigint) => (void)
};

enum SubmittingState {
  STILL,
  SUBMITTING,
  SUCCESS,
  ERROR,
};

const OpenQuestion = ({canSelectSub, subId, onSubmitQuestion}: Props) => {

  const {subs, refreshBalance} = useContext(ActorContext);
  
  const [sub,           setSub          ] = useState<Sub | undefined>   (undefined);
  const [showSubsList,  setShowSubsList ] = useState<boolean>           (false    );
  const [selectedSubId, setSelectedSubId] = useState<string | undefined>(subId    );
  const [text,          setText         ] = useState<string>            (""       );
  const [state,         setState        ] = useState<SubmittingState>   (SubmittingState.STILL);
  const [error,         setError        ] = useState<string | undefined>(undefined);

  useEffect(() => {
    if (selectedSubId !== undefined){
      setSub(subs.get(selectedSubId));
    } else {
      setSub(undefined);
    }
  }, [subs, selectedSubId]);

  const submitQuestion = async () => {
    setError(undefined);
    setState(SubmittingState.SUBMITTING);
    if (sub !== undefined){
      sub.actor.openQuestion(text).then((res) => {
        if (res['ok'] !== undefined){
          setText("");
          refreshBalance();
          setState(SubmittingState.SUCCESS);
          onSubmitQuestion(res['ok']);
        } else if (res['err'] !== undefined){
          setState(SubmittingState.ERROR);
          setError(openQuestionErrorToString(res['err']));
        }
      }).catch((err) => {
        setError(err.toString());
      });
    }
  }

  useEffect(() => {
    setError(undefined);
  }, []);

	return (
    <div className="flex flex-col w-full dark:border-gray-700">
      <div className="px-4 py-2 border-b dark:border-gray-700 outline-red-300 dark:outline-red-300">
        <textarea 
          className={`w-full focus:outline-none px-0 text-sm text-gray-900 dark:text-white dark:placeholder-gray-400`}
          rows={4}
          onChange={(e) => { setError(undefined); setState(SubmittingState.STILL); setText(e.target.value)} }
          placeholder={CONSTANTS.OPEN_QUESTION.PLACEHOLDER} 
          disabled={state === SubmittingState.SUBMITTING}
          value={text}
          required
        />
      </div>
      <div className="flex flex-row p-2 space-x-2 items-center place-self-end">
        { sub !== undefined && text.length > sub.info.character_limit ? 
          <div className="text-red-500 text-xs">{CONSTANTS.MAX_NUM_CHARACTERS_REACHED}</div> : <></>
        }
        {
          canSelectSub ? 
          <div>
            <button 
              onClick={(e)=>{setShowSubsList(!showSubsList)}} 
              className="button-simple h-9"
              type="button"
            >
              {
                sub !== undefined ? sub.info.name : CONSTANTS.OPEN_QUESTION.PICK_SUB
              } 
              <svg className="w-4 h-4 ml-2" aria-hidden="true" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M19 9l-7 7-7-7"></path>
              </svg>
            </button>
            <div id="dropdown" className={"absolute bg-white divide-y divide-gray-100 rounded-lg shadow w-44 dark:bg-gray-700 " + (showSubsList ? "" : "hidden")}>
              <ul className="py-2 text-sm text-gray-700 dark:text-gray-200">
                {
                  [...Array.from(subs.entries())].map((elem) => (
                    <li key={elem[0]}>
                      <div onClick={(e)=>{setSelectedSubId(elem[0]); setShowSubsList(false);}} className="block px-4 py-2 hover:bg-gray-100 dark:hover:bg-gray-600 dark:hover:text-white hover:cursor-pointer">{"g/" + elem[0]}</div>
                    </li>
                  ))
                }
              </ul>
            </div>
          </div> : <></>
        }
        <button 
          className="button-simple w-36 min-w-36 h-9 flex flex-col justify-center items-center"
          type="submit"
          disabled={sub===undefined || text.length <= 0 || state === SubmittingState.SUBMITTING || text.length > sub.info.character_limit}
          onClick={(e) => submitQuestion()}
        >
          {
            state === SubmittingState.SUBMITTING ?
            <div className="w-5 h-5">
              <Spinner/>
            </div> :
            <div className="flex flex-row items-center gap-x-1 text-white">
              Propose
              <Balance amount={sub !== undefined ? sub.info.prices.open_vote_price_e8s : undefined}/>
            </div>
          }
        </button>
        <div className="flex flex-col w-6 min-w-6 items-center text-sm">
        {
          state === SubmittingState.ERROR ?
            <div className="w-full">
              <Tooltip title={error} arrow>
                <ErrorOutlineIcon color="error"></ErrorOutlineIcon>
              </Tooltip>
            </div> : 
          state === SubmittingState.SUCCESS ?
            <div className="w-full">
              <DoneIcon color="success"/>
            </div> :
            <></>
        }
        </div>
      </div>
    </div>
	);
};

export default OpenQuestion;
