import { Question } from "../../../declarations/godwin_backend/godwin_backend.did";

const QuestionBody = (question: Question) => {
	
	return (
		<div className="flex flex-col py-1 px-10 bg-white dark:bg-gray-800 mb-2 text-lg font-semibold text-gray-900 dark:text-white">
			<div className="flex flex-row">
				{question.title}
			</div>
		</div>
	);
};

export default QuestionBody;
