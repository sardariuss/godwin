import { Appeal, Polarization, PolarizationArray, Question } from "./../../declarations/godwin_backend/godwin_backend.did";
import { ActorContext } from "../ActorContext"
import VoteInterest from "./votes/Interest";
import VoteOpinion from "./votes/Opinion";
import VoteCategorization from "./votes/Categorization";

import StatusHistoryComponent from "./StatusHistory";

import { useEffect, useState, useContext } from "react";

type Props = {
  question_id: bigint,
	categories: string[]
};

// @todo: change the state of the buttons based on the interest for the logged user for this question
const QuestionBody = ({question_id, categories}: Props) => {

	const {actor} = useContext(ActorContext);
	const [question, setQuestion] = useState<Question | undefined>(undefined);
	// @todo
	const [interestAggregate, setInterestAggregate] = useState<Appeal | undefined>(undefined);
	const [opinionAggregate, setOpinionAggregate] = useState<Polarization | undefined>(undefined);
	const [categorizationAggregate, setCategorizationAggregate] = useState<PolarizationArray | undefined>(undefined);

	const getQuestion = async () => {
		let question = await actor.getQuestion(question_id);
		setQuestion(question['ok']);
	};

	useEffect(() => {
		getQuestion();
  }, []);

	const show = true;

	return (
		<div className="flex flex-row py-1 px-10 bg-white dark:bg-gray-800 mb-2 text-gray-900 dark:text-white hover:dark:border">
			<div className="flex flex-row w-2/3 justify-start">
				<div className="flex flex-col justify-start text-lg font-semibold gap-y-2">
					<div className="justify-start text-lg font-normal">
						{ question === undefined ? "n/a" : question.title }
					</div>
					<div className="flex items-center space-x-10">
						<StatusHistoryComponent questionId={question_id}/>
					</div>
				</div>
			</div>
			<div className="flex flex-row w-1/3">
				{
					question?.status_info.status['CANDIDATE'] !== undefined ?
						<VoteInterest questionId={question.id}/> : 
					question?.status_info.status['OPEN'] !== undefined ?
						<div className="flex flex-col justify-start">
							<VoteOpinion questionId={question.id}/>
							<VoteCategorization questionId={question.id}/>
						</div>
						: 
					question?.status_info.status['CLOSED'] !== undefined || question?.status_info.status['REJECTED'] !== undefined ?
						<div> @todo </div> : <div>@todo impossible</div>
				}
			</div>
		</div>
	);
};

export default QuestionBody;
