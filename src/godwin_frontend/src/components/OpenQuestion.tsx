import { ActorContext }                           from "../ActorContext"
import Balance                                    from "./base/Balance";
import Spinner                                    from "./Spinner";
import { openQuestionErrorToString }              from "../utils";
import CONSTANTS                                  from "../Constants";
import { Sub } from "../ActorContext";

import React, { useContext, useState, useEffect } from "react";

import { Tooltip }                                from "@mui/material";
import ErrorOutlineIcon                           from "@mui/icons-material/ErrorOutline";

type Props = {
  canSelectSub: boolean,
  subId: string | undefined,
  onSubmitQuestion: (question_id: bigint) => (void)
};

const OpenQuestion = ({canSelectSub, subId, onSubmitQuestion}: Props) => {

  const {subs, refreshBalance} = useContext(ActorContext);
  
  const [sub,           setSub          ] = useState<Sub | undefined>   (undefined);
  const [showSubsList,  setShowSubsList ] = useState<boolean>           (false    );
  const [selectedSubId, setSelectedSubId] = useState<string | undefined>(subId    );
  const [text,          setText         ] = useState<string>            (""       );
  const [submitting,    setSubmitting   ] = useState<boolean>           (false    );
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
    setSubmitting(true);
    if (sub !== undefined){
      sub.actor.openQuestion(text).then((res) => {
        if (res['ok'] !== undefined){
          setText("");
          refreshBalance();
          onSubmitQuestion(res['ok']);
        } else if (res['err'] !== undefined){
          setError(openQuestionErrorToString(res['err']));
        }
      }).catch((err) => {
        setError(err.toString());
      }).finally(() => {
        setSubmitting(false);
      });
    }
  }

  useEffect(() => {
    setError(undefined);
  }, []);

	return (
    <form>
      <div className="flex flex-col w-full dark:border-gray-700">
        <div className="px-4 py-2 border-b dark:border-gray-700">
          <textarea 
            className="w-full focus:outline-none px-0 text-sm text-gray-900 dark:text-white dark:placeholder-gray-400"
            rows={4}
            onChange={(e) => { setError(undefined); setText(e.target.value)} }
            placeholder={CONSTANTS.OPEN_QUESTION.PLACEHOLDER} 
            disabled={submitting}
            required
          />
        </div>
        <div className="flex flex-row px-2 py-2 space-x-2 items-center place-self-end">
          {
            canSelectSub ? 
            <div>
              <button 
                onClick={(e)=>{setShowSubsList(!showSubsList)}} 
                className="button-simple h-9"
                type="button"
              >
                {
                  sub !== undefined ? sub.name : CONSTANTS.OPEN_QUESTION.PICK_SUB
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
            disabled={sub===undefined || text.length <= 0 || submitting}
            onClick={(e) => submitQuestion()}
          >
            {
              submitting ?
              <div className="w-5 h-5">
                <Spinner/>
              </div> :
              <div className="flex flex-row items-center gap-x-1 text-white">
                Propose
                <Balance amount={sub !== undefined ? sub.price_parameters.open_vote_price_e8s : undefined}/>
              </div>
            }
          </button>
          <div className="flex flex-col w-6 min-w-6 items-center text-sm">
          {
            error !== undefined ?
            <div className="w-full">
              <Tooltip title={error} arrow>
                <ErrorOutlineIcon color="error"></ErrorOutlineIcon>
              </Tooltip>
            </div> : 
            <></>
          }
          </div>
        </div>
      </div>
    </form>
	);
};

export default OpenQuestion;
