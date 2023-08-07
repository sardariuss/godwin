import OpenQuestion from "./OpenQuestion"

import React        from "react";

type Props = {
  showAskQuestion: boolean,
  setShowAskQuestion: (boolean) => (void)
};

const OpenQuestionPopup = ({showAskQuestion, setShowAskQuestion}: Props) => {
  return (
    <div className="relative z-50" aria-labelledby="modal-title" role="dialog" aria-modal="true" hidden={!showAskQuestion}>
      <div className="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity"></div>
      <div className="fixed inset-0 overflow-y-auto">
        <div className="flex md:min-h-full items-end justify-center md:p-4 py-1/3 text-center sm:items-center">
          <div className="relative transform rounded-lg bg-gray-100 dark:bg-gray-800 text-left shadow-xl transition-all sm:my-8 sm:w-full sm:max-w-lg">
            <button type="button" className="text-gray-400 bg-transparent hover:bg-gray-50 hover:dark:bg-gray-700 hover:text-gray-900 rounded-lg text-sm p-1.5 ml-auto inline-flex items-center dark:hover:text-white" onClick={(e) => setShowAskQuestion(false)}>
              <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg"><path fillRule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clipRule="evenodd"></path></svg>
            </button>
            <OpenQuestion onSubmitQuestion={() => {setShowAskQuestion(false)}} subId={undefined} canSelectSub={true}></OpenQuestion>
          </div>
        </div>
      </div>
    </div>
  )
}

export default OpenQuestionPopup;