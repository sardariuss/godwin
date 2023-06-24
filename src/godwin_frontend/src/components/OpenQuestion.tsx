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

  const {subs} = useContext(ActorContext);
  
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
                className="whitespace-nowrap h-9 text-white bg-blue-700 hover:enabled:bg-blue-800 font-medium rounded-lg text-xs px-4 py-2.5 text-center inline-flex focus:ring-2 focus:ring-blue-200 items-center dark:focus:ring-blue-800 disabled:bg-gray-700" 
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
            className={`w-32 min-w-36 flex flex-col px-3 h-9 justify-center items-center whitespace-nowrap text-xs font-medium text-center text-white bg-blue-700 rounded-lg inline-flex focus:ring-2 focus:ring-blue-200 dark:focus:ring-blue-900 hover:enabled:bg-blue-800 disabled:bg-gray-300 dark:disabled:bg-gray-700`}
            type="submit"
            disabled={selectedSubId===null || text.length <= 0 || submitting}
            onClick={(e) => submitQuestion()}
          >
            {
              submitting ?
              <Spinner/> :
              <div>
                { "Suggest question" }
              </div>
            }
          </button>
          <div className="flex flex-col w-14 min-w-14 items-center text-sm">
          {
            error !== null ?
            <Tooltip title={error} arrow>
              <ErrorOutlineIcon color="error"></ErrorOutlineIcon>
            </Tooltip> : 
            <Balance amount={BigInt(1_000_000_000)}/>
          }
          </div>
        </div>
      </div>
    </form>
	);
};

export default OpenQuestion;
