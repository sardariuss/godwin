import InterestVote from "./votes/InterestVote";
import StatusHistoryComponent from "./StatusHistory";
import OpenVotes from "./votes/OpenVotes";
import CONSTANTS from "../Constants";

import { Question, StatusInfo, Category, CategoryInfo, _SERVICE } from "./../../declarations/godwin_backend/godwin_backend.did";

import { useEffect, useState } from "react";
import { ActorSubclass } from "@dfinity/agent";
import { VoteType } from "../utils";

type Props = {
	actor: ActorSubclass<_SERVICE>,
	categories: Map<Category, CategoryInfo>,
  questionId: bigint
};

const QuestionBody = ({actor, categories, questionId}: Props) => {

	const [question, setQuestion] = useState<Question | undefined>(undefined);
	const [showHistory, setShowHistory] = useState<boolean>(false);
	const [iterationHistory, setIterationHistory] = useState<StatusInfo[][]>([]);
	const [statusHistory, setStatusHistory] = useState<StatusInfo[]>([]);
	const [currentStatus, setCurrentStatus] = useState<StatusInfo | undefined>(undefined);
	const [questionVoteJoins, setQuestionVoteJoins] = useState<Map<VoteType, bigint>>(new Map<VoteType, bigint>());

	const fetchQuestion = async () => {
		const question = await actor.getQuestion(questionId);
		setQuestion(question['ok']);
	}

	const fetchIterationHistory = async () => {
		var iterations : StatusInfo[][] = [];
		var statuses : StatusInfo[] = [];
		var current : StatusInfo | undefined = undefined;

		const history = await actor.getIterationHistory(questionId);
		
		if (history['ok'] !== undefined){
			iterations = history['ok'];	
			if (iterations.length !== 0) {
				statuses = iterations[iterations.length - 1];
				if (statuses.length !== 0) {
					current = statuses[statuses.length - 1];
				}
			}
		}
	
		setIterationHistory(iterations);
		setStatusHistory(statuses);
		setCurrentStatus(current);
	}

	const fetchQuestionVoteJoins = async (iteration_index: number, status_info: StatusInfo) => {

		var joins = new Map<VoteType, bigint>();
				
		if (status_info.status['CANDIDATE'] !== undefined) {
			let interest_vote_id = (await actor.findInterestVoteId(questionId, BigInt(iteration_index)))['ok'];
			if (interest_vote_id !== undefined) {
				joins.set(VoteType.INTEREST, interest_vote_id);
			}
		} else if (status_info.status['OPEN'] !== undefined) {
			let opinion_vote_id = (await actor.findOpinionVoteId(questionId, BigInt(iteration_index)))['ok'];
			if (opinion_vote_id !== undefined) {
				joins.set(VoteType.OPINION, opinion_vote_id);
			}
			let categorization_vote_id = (await actor.findCategorizationVoteId(questionId, BigInt(iteration_index)))['ok'];
			if (categorization_vote_id !== undefined) {
				joins.set(VoteType.CATEGORIZATION, categorization_vote_id);
			}
		}

		setQuestionVoteJoins(joins);
	};

	useEffect(() => {
		fetchQuestion();
		fetchIterationHistory();
  }, []);

	useEffect(() => {
		if (iterationHistory.length > 0 && currentStatus !== undefined) {
			fetchQuestionVoteJoins(iterationHistory.length - 1, currentStatus);
		} else {
			setQuestionVoteJoins(new Map<VoteType, bigint>());
		}
	}, [iterationHistory, currentStatus]);

	return (
		<div className="flex flex-col text-black dark:text-white border-b dark:border-gray-700 hover:bg-slate-50 hover:dark:bg-slate-850">
			<div className="flex flex-col py-1 px-10 justify-start w-full space-y-2">
				{
					question === undefined ? 
					<div role="status" className="w-full animate-pulse">
						<div className="h-2 bg-gray-200 rounded-full dark:bg-gray-700 my-2"></div>
						<div className="h-2 bg-gray-200 rounded-full dark:bg-gray-700 my-2"></div>
						<div className="h-2 bg-gray-200 rounded-full dark:bg-gray-700 max-w-[330px] my-2"></div>
						<span className="sr-only">Loading...</span>
					</div> :
					currentStatus !== undefined ?
						questionVoteJoins.get(VoteType.INTEREST) !== undefined ?
							<InterestVote 
								countdownDurationMs={5000} 
								polarizationInfo={CONSTANTS.INTEREST_INFO} 
								asToggle={true}
								voteId={questionVoteJoins.get(VoteType.INTEREST)}
								allowUpdateBallot={false}
								putBallot={actor.putInterestBallot}
								getBallot={actor.getInterestBallot}
							>
								{ question.text }
							</InterestVote> : 
						questionVoteJoins.get(VoteType.OPINION) !== undefined && questionVoteJoins.get(VoteType.CATEGORIZATION) !== undefined?
							<OpenVotes 
								actor={actor}
								opinionVoteId={questionVoteJoins.get(VoteType.OPINION)}
								categorizationVoteId={questionVoteJoins.get(VoteType.CATEGORIZATION)}
								categories={categories}
							/> :
							currentStatus.status['CANDIDATE'] !== undefined || currentStatus.status['OPEN'] !== undefined ?
							<div role="status">
								<svg className="inline w-6 h-6 text-gray-200 animate-spin dark:text-gray-600 fill-gray-600 dark:fill-gray-300" viewBox="0 0 100 101" fill="none" xmlns="http://www.w3.org/2000/svg">
									<path d="M100 50.5908C100 78.2051 77.6142 100.591 50 100.591C22.3858 100.591 0 78.2051 0 50.5908C0 22.9766 22.3858 0.59082 50 0.59082C77.6142 0.59082 100 22.9766 100 50.5908ZM9.08144 50.5908C9.08144 73.1895 27.4013 91.5094 50 91.5094C72.5987 91.5094 90.9186 73.1895 90.9186 50.5908C90.9186 27.9921 72.5987 9.67226 50 9.67226C27.4013 9.67226 9.08144 27.9921 9.08144 50.5908Z" fill="currentColor"/>
									<path d="M93.9676 39.0409C96.393 38.4038 97.8624 35.9116 97.0079 33.5539C95.2932 28.8227 92.871 24.3692 89.8167 20.348C85.8452 15.1192 80.8826 10.7238 75.2124 7.41289C69.5422 4.10194 63.2754 1.94025 56.7698 1.05124C51.7666 0.367541 46.6976 0.446843 41.7345 1.27873C39.2613 1.69328 37.813 4.19778 38.4501 6.62326C39.0873 9.04874 41.5694 10.4717 44.0505 10.1071C47.8511 9.54855 51.7191 9.52689 55.5402 10.0491C60.8642 10.7766 65.9928 12.5457 70.6331 15.2552C75.2735 17.9648 79.3347 21.5619 82.5849 25.841C84.9175 28.9121 86.7997 32.2913 88.1811 35.8758C89.083 38.2158 91.5421 39.6781 93.9676 39.0409Z" fill="currentFill"/>
								</svg>
							</div> :
							<></> : <></>
				}
				{
					currentStatus !== undefined && showHistory ?
						<div className="border-y dark:border-gray-700">
							<StatusHistoryComponent actor={actor} categories={categories} questionId={questionId} statusInfo={currentStatus} statusHistory={statusHistory.slice(0, statusHistory.length - 1)}/>
						</div> :
						<></>
				}
				<div className="flex flex-row grow justify-around items-center text-gray-400 dark:fill-gray-400">
					<div className="flex w-1/3 justify-center items-center">
						<div className="h-4 w-4 hover:cursor-pointer hover:dark:dark:fill-white" onClick={(e) => setShowHistory(!showHistory)}>
							<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 96 960 960"><path d="M477 936q-149 0-253-105.5T120 575h60q0 125 86 213t211 88q127 0 215-89t88-216q0-124-89-209.5T477 276q-68 0-127.5 31T246 389h105v60H142V241h60v106q52-61 123.5-96T477 216q75 0 141 28t115.5 76.5Q783 369 811.5 434T840 574q0 75-28.5 141t-78 115Q684 879 618 907.5T477 936Zm128-197L451 587V373h60v189l137 134-43 43Z"/></svg>
						</div>
					</div>
					<div className="flex w-1/3 justify-center items-center">
						<div className=" h-4 w-4 hover:cursor-pointer hover:dark:dark:fill-white">
							<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 96 960 960"><path d="M727 976q-47.5 0-80.75-33.346Q613 909.307 613 861.669q0-6.669 1.5-16.312T619 828L316 652q-15 17-37 27.5T234 690q-47.5 0-80.75-33.25T120 576q0-47.5 33.25-80.75T234 462q23 0 44 9t38 26l303-174q-3-7.071-4.5-15.911Q613 298.25 613 290q0-47.5 33.25-80.75T727 176q47.5 0 80.75 33.25T841 290q0 47.5-33.25 80.75T727 404q-23.354 0-44.677-7.5T646 372L343 540q2 8 3.5 18.5t1.5 17.741q0 7.242-1.5 15Q345 599 343 607l303 172q15-14 35-22.5t46-8.5q47.5 0 80.75 33.25T841 862q0 47.5-33.25 80.75T727 976Zm.035-632Q750 344 765.5 328.465q15.5-15.535 15.5-38.5T765.465 251.5q-15.535-15.5-38.5-15.5T688.5 251.535q-15.5 15.535-15.5 38.5t15.535 38.465q15.535 15.5 38.5 15.5Zm-493 286Q257 630 272.5 614.465q15.5-15.535 15.5-38.5T272.465 537.5q-15.535-15.5-38.5-15.5T195.5 537.535q-15.5 15.535-15.5 38.5t15.535 38.465q15.535 15.5 38.5 15.5Zm493 286Q750 916 765.5 900.465q15.5-15.535 15.5-38.5T765.465 823.5q-15.535-15.5-38.5-15.5T688.5 823.535q-15.5 15.535-15.5 38.5t15.535 38.465q15.535 15.5 38.5 15.5ZM727 290ZM234 576Zm493 286Z"/></svg>
						</div>
					</div>
					<div className="flex w-1/3 justify-center items-center">
						<div className="text-xs font-light">
							{ "#CLASSIC6Q" + questionId.toString() }
						</div>
					</div>
				</div>
			</div>
		</div>
	);
};

export default QuestionBody;
