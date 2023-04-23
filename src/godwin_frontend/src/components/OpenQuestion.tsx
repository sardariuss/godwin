import { ActorContext } from "../ActorContext"

import { useContext, useState } from "react";

type Props = {
  canSelectSub: boolean,
  subId: string | null,
  onSubmitQuestion: () => (void)
};

const OpenQuestion = ({canSelectSub, subId, onSubmitQuestion}: Props) => {

  const {subs} = useContext(ActorContext);
  const [showSubsList, setShowSubsList] = useState<boolean>(false);
  const [selectedSubId, setSelectedSubId] = useState<string | null>((subId !== null && subs.has(subId)) ? subId : null);

  const placeholder = "What's interesting to vote on?";
  const noSubSelected = "Choose a sub-godwin";

  const [text, setText] = useState("");

  const updateText = (input) => {
    if (input === placeholder) {
      setText("");
    } else {
      setText(input);
    }
  }

  const submitQuestion = async () => {
    if (selectedSubId !== null){
      subs.get(selectedSubId)?.actor.openQuestion(text).then((res) => {
        console.log(res);
        setText("");
        onSubmitQuestion();
      });
    }
  }

	return (
    <form>
      <div className="w-full border-b border-gray-200 dark:border-gray-600">
        <div className="px-4 py-2">
          <textarea rows={4} onChange={(e) => updateText(e.target.value)} className="w-full focus:outline-none px-0 text-sm text-gray-900 dark:text-white dark:placeholder-gray-400" placeholder={placeholder} required></textarea>
        </div>
        <div className="flex flex-row-reverse gap-x-3 px-3 py-2 border-t dark:border-gray-600">
          <button type="submit" className={"py-2.5 px-4 text-xs font-medium text-center text-white bg-blue-700 rounded-lg inline-flex focus:ring-2 focus:ring-blue-200 dark:focus:ring-blue-900 hover:enabled:bg-blue-800 disabled:bg-gray-700"} disabled={selectedSubId===null || text.length <= 0} onClick={(e) => submitQuestion()}>
            Suggest question
          </button>
          {
          canSelectSub ? 
            <div>
              <button onClick={(e)=>{setShowSubsList(!showSubsList)}} className="text-white bg-blue-700 hover:enabled:bg-blue-800 font-medium rounded-lg text-xs px-4 py-2.5 text-center inline-flex focus:ring-2 focus:ring-blue-200 items-center dark:hover:enabled:bg-blue-700 dark:focus:ring-blue-800 disabled:bg-gray-700" type="button">
                {
                  selectedSubId !== null ? subs.get(selectedSubId)?.name : noSubSelected
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
        </div>
      </div>
    </form>
	);
};

export default OpenQuestion;
