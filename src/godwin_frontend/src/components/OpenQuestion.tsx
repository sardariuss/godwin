import { ActorContext } from "../ActorContext"

import { useContext, useState } from "react";

type Props = {
  setShowAskQuestion: (boolean) => (void)
};

const OpenQuestion = ({setShowAskQuestion}: Props) => {

  const {actor} = useContext(ActorContext);

  const placeholder = "What's interesting to vote on?";

  const [text, setText] = useState("");

  const updateText = (input) => {
    if (input === placeholder) {
      setText("");
    } else {
      setText(input);
    }
  }

  const submitQuestion = async () => {
    actor.openQuestion(text).then((res) => {
      console.log(res);
      setText("");
      setShowAskQuestion(false);
    });
  }

	return (
    <form>
      <div className="w-full border-b border-gray-200 rounded-lg dark:border-gray-600">
        <div className="px-4 py-2 bg-gray-100 dark:bg-gray-800 dark:bg-gray-800">
          <textarea id="comment" rows={4} onChange={(e) => updateText(e.target.value)} className="w-full px-0 text-sm text-gray-900 bg-gray-100 dark:bg-gray-800 dark:bg-gray-800 dark:text-white dark:placeholder-gray-400" placeholder={placeholder} required></textarea>
        </div>
        <div className="flex items-center justify-between px-3 py-2 border-t dark:border-gray-600">
          <button type="submit" className="inline-flex items-center py-2.5 px-4 text-xs font-medium text-center text-white bg-blue-700 rounded-lg focus:ring-4 focus:ring-blue-200 dark:focus:ring-blue-900 hover:bg-blue-800" onClick={(e) => submitQuestion()}>
            Open question
          </button>
        </div>
      </div>
    </form>
	);
};

export default OpenQuestion;
