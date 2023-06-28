import { ActorContext }              from "../ActorContext"
import Balance                       from "./base/Balance";
import Spinner                       from "./Spinner";
import { openQuestionErrorToString } from "../utils";
import CONSTANTS                     from "../Constants";

import { useContext, useState, useEffect } from "react";

import { Tooltip }                   from "@mui/material";
import ErrorOutlineIcon              from '@mui/icons-material/ErrorOutline';

type Props = {
  canSelectSub: boolean,
  subId: string | null,
  onSubmitQuestion: (question_id: bigint) => (void)
};

const OpenQuestion = ({canSelectSub, subId, onSubmitQuestion}: Props) => {

  const {subs, refreshBalance} = useContext(ActorContext);
  
  const [showSubsList,  setShowSubsList ] = useState<boolean>      (false                                             );
  const [selectedSubId, setSelectedSubId] = useState<string | null>((subId !== null && subs.has(subId)) ? subId : null);
  const [text,          setText         ] = useState<string>       (""                                                );
  const [submitting,    setSubmitting   ] = useState<boolean>      (false                                             );
  const [error,         setError        ] = useState<string | null>(null                                              );

  const submitQuestion = async () => {
    setError(null);
    setSubmitting(true);
    if (selectedSubId !== null){
      subs.get(selectedSubId)?.actor.openQuestion(text).then((res) => {
        setSubmitting(false);
        if (res['ok'] !== undefined){
          setText("");
          refreshBalance();
          onSubmitQuestion(res['ok']);
        } else if (res['err'] !== undefined){
          setError(openQuestionErrorToString(res['err']));
        } else {
          throw new Error("Invalid open question result");
        }
      });
    }
  }

  useEffect(() => {
    setError(null);
  }, []);

	return (
    <form>
      <div className="flex flex-col w-full dark:border-gray-700">
        <div className="px-4 py-2 border-b dark:border-gray-700">
          <textarea 
            className="w-full focus:outline-none px-0 text-sm text-gray-900 dark:text-white dark:placeholder-gray-400"
            rows={4}
            onChange={(e) => { setError(null); setText(e.target.value)} }
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
                  selectedSubId !== null ? subs.get(selectedSubId)?.name : CONSTANTS.OPEN_QUESTION.PICK_SUB
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
            disabled={selectedSubId===null || text.length <= 0 || submitting}
            onClick={(e) => submitQuestion()}
          >
            {
              submitting ?
              <div className="w-5 h-5">
                <Spinner/>
              </div> :
              <div className="flex flex-row items-center gap-x-1 text-white">
                Propose
                <Balance amount={BigInt(1_000_000_000)}/>
              </div>
            }
          </button>
          <div className="flex flex-col w-6 min-w-6 items-center text-sm">
          {
            error !== null ?
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
