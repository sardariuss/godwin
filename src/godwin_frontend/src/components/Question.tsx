import { godwin_backend } from "../../../declarations/godwin_backend";
import { Question } from "../../../declarations/godwin_backend/godwin_backend.did";

import { statusToString, nsToStrDate } from "../utils";

import { useEffect, useState } from "react";

type Props = {
  id: number;
};

const QuestionBody = ({id}: Props) => {

	const [question, setQuestion] = useState<Question | undefined>();

	const refreshQuestion = async () => {
		let query_question = await godwin_backend.getQuestion(id);
		if (query_question.err !== undefined){
			console.log("Could not find question!");
		} else {
			setQuestion(query_question.ok);
		}
	}

	useEffect(() => {
		refreshQuestion();
  }, []);

	return (
		<div className="flex flex-col py-1 px-10 bg-white dark:bg-gray-800 mb-2 text-gray-900 dark:text-white">
			<div className="flex flex-row justify-start gap-x-10 text-lg font-semibold">
				<ul className="flex flex-row items-center justify-evenly space-x-1">
          <li>
            <input type="radio" onChange={(e) => (e)} id={"up-vote_" + id} name={"vote_" + id} value="up-vote" className="hidden peer" required/>
            <label htmlFor={"up-vote_" + id} className="inline-flex font-bold cursor-pointer justify-center items-center px-4 py-2 text-gray-500 bg-white rounded-lg dark:hover:text-gray-300 dark:border-gray-700 dark:peer-checked:text-green-500 peer-checked:border-green-500 peer-checked:text-green-500 hover:text-gray-600 hover:bg-gray-100 dark:text-gray-400 dark:bg-gray-800 dark:hover:bg-gray-700">                           
              ⇧
            </label>
          </li>
          <li>
            <input type="radio" onChange={(e) => (e)} id={"down-vote_" + id} name={"vote_" + id} value="down-vote" className="hidden peer"/>
            <label htmlFor={"down-vote_" + id} className="inline-flex font-bold cursor-pointer justify-center items-center px-5 py-2 text-gray-500 bg-white rounded-lg dark:hover:text-gray-300 dark:border-gray-700 dark:peer-checked:text-red-500 peer-checked:border-red-500 peer-checked:text-red-500 hover:text-gray-600 hover:bg-gray-100 dark:text-gray-400 dark:bg-gray-800 dark:hover:bg-gray-700">
              ⇩
            </label>
          </li>
        </ul>
				<div className="flex flex-col justify-start gap-x-10 text-lg font-semibold">
					<div className="flex flex-row justify-start gap-x-10 text-lg font-semibold">
						<div> { question === undefined ? "id" : question.id} </div>
						<div> { question === undefined ? "title" : question.title} </div>
					</div>
					<div className="flex flex-row justify-start gap-x-10">
						<div>Iteration: {question === undefined ? "iteration" : question.vote_history.length}</div>
						<div>Status: { question === undefined ? "status" : statusToString(question.status)} </div>
						<div>Created: { question === undefined ? "date" : nsToStrDate(question.date)}</div>
					</div>
				</div>
			</div>
		</div>
	);
};

export default QuestionBody;
