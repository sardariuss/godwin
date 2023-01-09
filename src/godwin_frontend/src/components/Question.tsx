import { Question, Iteration, Vote, _SERVICE} from "./../../declarations/godwin_backend/godwin_backend.did";
import ActorContext from "../ActorContext"
import VoteInterest from "./votes/Interest";
import VoteOpinion from "./votes/Opinion";
import VoteCategorization from "./votes/Categorization";
import Aggregates from "./votes/Aggregates";

import { statusToString, nsToStrDate } from "../utils";

import { useEffect, useState, useContext } from "react";
import { ActorSubclass } from "@dfinity/agent";

type Props = {
  question_id: number,
	categories: string[]
};

type ActorContextValues = {
  actor: ActorSubclass<_SERVICE>,
  logged_in: boolean
};

// @todo: change the state of the buttons based on the interest for the logged user for this question
const QuestionBody = ({question_id, categories}: Props) => {

	const [question, setQuestion] = useState<Question | undefined>();
	const {actor} = useContext(ActorContext) as ActorContextValues;

	const refreshQuestion = async () => {
		let query_question = await actor.getQuestion(question_id);
		if (query_question.err !== undefined){
			console.log("Could not find question!");
		} else {
			setQuestion(query_question.ok);
		}
	}

	// @todo: need to check status and handle case where history is empty
	const getInterestAggregate = () => {
		const interests : Vote[] = question?.interests_history === undefined ? [] : question?.interests_history;
		if (interests.length == 0) { return undefined; }
		return interests[interests.length - 1].aggregate;
	};

	// @todo: need to check status and handle case where history is empty
	const getOpinionAggregate = () => {
		const iterations : Iteration[] = question?.vote_history === undefined ? [] : question?.vote_history;
		if (iterations.length == 0) { return undefined; }
		return iterations[iterations.length - 1].opinion.aggregate;
	};

	// @todo: need to check status and handle case where history is empty
	const getCategorizationAggregate = () => {
		const iterations : Iteration[] = question?.vote_history === undefined ? [] : question?.vote_history;
		if (iterations.length == 0) { return undefined; }
		return iterations[iterations.length - 1].categorization.aggregate;
	};

	useEffect(() => {
		refreshQuestion();
  }, []);

	return (
		<div className="flex flex-col py-1 px-10 bg-white dark:bg-gray-800 mb-2 text-gray-900 dark:text-white">
			<div className="flex flex-row justify-start gap-x-10 text-lg font-semibold">
				{ 
					question?.status['CANDIDATE'] !== undefined ?
						<VoteInterest question_id={question_id}/> : 
					question?.status['OPEN'] !== undefined ?
					(question?.status['OPEN']['stage']['OPINION'] !== undefined ?
						<VoteOpinion question_id={question_id}/> :
						question?.status['OPEN']['stage']['CATEGORIZATION'] !== undefined ?
						<VoteCategorization question_id={question_id} categories={categories}/> :
						<div>@todo impossible</div>
					) : question?.status['CLOSED'] !== undefined || question?.status['REJECTED'] !== undefined ?
						<Aggregates 
							interest_aggregate={getInterestAggregate()}
							opinion_aggregate={getOpinionAggregate()}
							categorization_aggregate={getCategorizationAggregate()}
						/> : <div>@todo impossible</div>
				}
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
