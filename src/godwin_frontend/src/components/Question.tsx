import { Appeal, Polarization, PolarizationArray, Question, _SERVICE} from "./../../declarations/godwin_backend/godwin_backend.did";
import ActorContext from "../ActorContext"
import VoteInterest from "./votes/Interest";
import VoteOpinion from "./votes/Opinion";
import VoteCategorization from "./votes/Categorization";
import Aggregates from "./votes/Aggregates";

import { statusToString, nsToStrDate } from "../utils";

import { useEffect, useState, useContext } from "react";
import { ActorSubclass } from "@dfinity/agent";

type Props = {
  question_id: bigint,
	categories: string[]
};

type ActorContextValues = {
  actor: ActorSubclass<_SERVICE>,
  logged_in: boolean
};

// @todo: change the state of the buttons based on the interest for the logged user for this question
const QuestionBody = ({question_id, categories}: Props) => {

	const {actor} = useContext(ActorContext) as ActorContextValues;
	const [question, setQuestion] = useState<Question | undefined>(undefined);
	const [interestAggregate, setInterestAggregate] = useState<Appeal | undefined>(undefined);
	const [opinionAggregate, setOpinionAggregate] = useState<Polarization | undefined>(undefined);
	const [categorizationAggregate, setCategorizationAggregate] = useState<PolarizationArray | undefined>(undefined);

	const getQuestion = async () => {
		let question = await actor.getQuestion(question_id);
		setQuestion(question['ok']);
	};

	// @todo: need to check status and handle case where history is empty
	const getInterestAggregate = async () => {
		let aggregate = await actor.getInterestAggregate(question_id, BigInt(0)); // @todo: hardcoded iteration
		setInterestAggregate(aggregate['ok']?.['INTEREST']);
	};

	// @todo: need to check status and handle case where history is empty
	const getOpinionAggregate = async () => {
		let aggregate = await actor.getOpinionAggregate(question_id, BigInt(0)); // @todo: hardcoded iteration
		setOpinionAggregate(aggregate['ok']?.['OPINION']);
	};

	// @todo: need to check status and handle case where history is empty
	const getCategorizationAggregate = async () => {
		let aggregate = await actor.getCategorizationAggregate(question_id, BigInt(0)); // @todo: hardcoded iteration
		setCategorizationAggregate(aggregate['ok']?.['CATEGORIZATION']);
	};

	useEffect(() => {
		getQuestion();
		getInterestAggregate();
		getOpinionAggregate();
		getCategorizationAggregate();
  }, []);

	return (
		<div className="flex flex-col py-1 px-10 bg-white dark:bg-gray-800 mb-2 text-gray-900 dark:text-white">
			<div className="flex flex-row justify-start gap-x-10 text-lg font-semibold">
				{ 
					question?.status_info.current.status['VOTING']['INTEREST'] !== undefined ?
						<VoteInterest question_id={question.id}/> : 
					question?.status_info.current.status['VOTING']['OPINION'] !== undefined ?
						<VoteOpinion question_id={question.id}/> :
					question?.status_info.current.status['VOTING']['CATEGORIZATION'] !== undefined ?
						<VoteCategorization question_id={question.id} categories={categories}/> :
					question?.status_info.current.status['CLOSED'] !== undefined || question?.status_info.current.status['REJECTED'] !== undefined ?
						<Aggregates 
							interest_aggregate={interestAggregate}
							opinion_aggregate={opinionAggregate}
							categorization_aggregate={categorizationAggregate}
						/> : <div>@todo impossible</div>
				}
				<div className="flex flex-col justify-start gap-x-10 text-lg font-semibold">
					<div className="flex flex-row justify-start gap-x-10 text-lg font-semibold">
						<div> { question === undefined ? "id" : question.id} </div>
						<div> { question === undefined ? "title" : question.title} </div>
					</div>
					<div className="flex flex-row justify-start gap-x-10">
						<div>History size: {question === undefined ? "iteration" : question.status_info.history.length}</div>
						<div>Status: { question === undefined ? "status" : statusToString(question.status_info.current.status)} </div>
						<div>Created: { question === undefined ? "date" : nsToStrDate(question.date)}</div>
					</div>
				</div>
			</div>
		</div>
	);
};

export default QuestionBody;
