import StatusHistoryComponent                                  from "./StatusHistory";
import { StatusInfo, Category, CategoryInfo, _SERVICE }        from "./../../declarations/godwin_backend/godwin_backend.did";
import SvgButton                                               from "./base/SvgButton";

import React, { useEffect, useState }                          from "react";
import { ActorSubclass }                                       from "@dfinity/agent";

export type IterationHistoryInput = {
	actor: ActorSubclass<_SERVICE>,
  iterationHistory: StatusInfo[][],
	categories: Map<Category, CategoryInfo>,
  questionId: bigint
};

const IterationHistory = ({actor, categories, iterationHistory, questionId}: IterationHistoryInput) => {

  const [currentIteration, setCurrentIteration] = useState<bigint | undefined>(undefined);
  const [showIterations,   setShowIterations  ] = useState<boolean           >(false);

  const showDropdown = (e: React.MouseEvent<HTMLButtonElement, MouseEvent>) => {
    e.stopPropagation();
    if (iterationHistory.length > 1) {
      setShowIterations(old => !old);
    }
  };

	useEffect(() => {
    
		setCurrentIteration(iterationHistory.length > 0 ? BigInt(iterationHistory.length - 1) : undefined);
  }, [iterationHistory]);

  useEffect(() => {
    document.addEventListener("click", (e) => {
      setShowIterations(false);
    });

    return () => {
      document.removeEventListener("click", (e) => {
        setShowIterations(false);
      });
    }
  }, []);

	return (
    <div>
    {
      currentIteration !== undefined && iterationHistory.length > 0 ? 
      <div className="grid grid-cols-4 content-end">
        <div className="flex col-span-3">
          {
            currentIteration !== undefined ?
            <StatusHistoryComponent 
              actor={actor}
              categories={categories}
              questionId={questionId}
              statusHistory={iterationHistory[Number(currentIteration)]}
              iteration={currentIteration}
            /> : <></>
          }
        </div>
        <div className={`col-span-1 self-end pb-3`}>
          <div className="relative w-full flex flex-row text-gray-700 dark:text-gray-300 text-xs">
            <SvgButton onClick={showDropdown} disabled={iterationHistory.length === 1}>
              <div className="flex flex-row items-center">
                <div>
                  { "iteration " + (currentIteration !== undefined ? (Number(currentIteration) + 1).toString() : "undefined")}
                </div>
                {
                  iterationHistory.length > 1 ?
                  <svg className="w-4 h-4 ml-2" aria-hidden="true" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M19 9l-7 7-7-7"></path>
                  </svg> : <></>
                }
              </div>
            </SvgButton>
            <div className={"absolute bg-white divide-y z-50 divide-gray-100 rounded-lg shadow top-4 w-30 dark:bg-gray-700 " + (showIterations ? "" : "hidden")}>
              <ul className="py-2 text-sm text-gray-700 dark:text-gray-200">
                {
                  [...Array.from(iterationHistory.entries())].reverse().map((elem, index) => (
                    <li key={index}>
                      <div onClick={(e)=>{setCurrentIteration(BigInt(elem[0])); setShowIterations(false);}} className="block px-4 py-2 hover:bg-gray-100 dark:hover:bg-gray-600 dark:hover:text-white hover:cursor-pointer">
                        { "iteration " + (elem[0] + 1).toString()}
                      </div>
                    </li>
                  ))
                }
              </ul>
            </div>
          </div>
        </div>
      </div> :
      <></>
      }
    </div>
	);
};

export default IterationHistory;
