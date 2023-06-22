import OpinionVote                                                from "./opinion/OpinionVote";
import CategorizationVote                                         from "./categorization/CategorizationVote";
import StatusHistoryComponent                                     from "./StatusHistory";
import InterestVote                                               from "./interest/InterestVote";
import { VoteKind }                                               from "../utils";
import CONSTANTS                                                  from "../Constants";
import { Question, StatusInfo, Category, CategoryInfo, _SERVICE } from "./../../declarations/godwin_sub/godwin_sub.did";

import { useEffect, useState }                                    from "react";
import { ActorSubclass }                                          from "@dfinity/agent";

export type QuestionInput = {
	actor: ActorSubclass<_SERVICE>,
	categories: Map<Category, CategoryInfo>,
  questionId: bigint,
	vote_kind: VoteKind | undefined
};

const QuestionComponent = ({actor, categories, questionId, vote_kind}: QuestionInput) => {

	const [question, setQuestion] = useState<Question | undefined>(undefined);
	const [statusHistory, setStatusHistory] = useState<StatusInfo[]>([]);
	const [questionVoteJoins, setQuestionVoteJoins] = useState<Map<VoteKind, bigint>>(new Map<VoteKind, bigint>());

	const refreshQuestion = async () => {
		const question = await actor.getQuestion(questionId);
		setQuestion(question['ok']);
	}

	const refreshStatusHistory = async () => {
		var statuses : StatusInfo[] = [];
		const history = await actor.getStatusHistory(questionId);
		if (history['ok'] !== undefined){
			statuses = history['ok'];	
		}
		setStatusHistory(statuses);
	}

	const refreshQuestionVoteJoins = async () => {

		if (statusHistory.length === 0) {
			setQuestionVoteJoins(new Map<VoteKind, bigint>());
		} else {
			let currentStatus = statusHistory[statusHistory.length - 1];
			let previousClosedStatus = findLastVote(statusHistory, 'CLOSED');
			
			var joins = new Map<VoteKind, bigint>();
					
			if (vote_kind === VoteKind.INTEREST) {
				if (currentStatus.status['CANDIDATE'] !== undefined) {
					let interest_vote_id = (await actor.findInterestVoteId(questionId, BigInt(currentStatus.iteration)))['ok'];
					if (interest_vote_id !== undefined) {
						joins.set(VoteKind.INTEREST, interest_vote_id);
					}
				}
			} else if (vote_kind === VoteKind.OPINION) {
				// Include early votes
				let iteration = currentStatus.status['OPEN'] !== undefined ? currentStatus.iteration : previousClosedStatus !== undefined ?
				previousClosedStatus.iteration + BigInt(1) : undefined;
				if (iteration !== undefined) {
					let opinion_vote_id = (await actor.findOpinionVoteId(questionId, iteration))['ok'];
					if (opinion_vote_id !== undefined) {
						joins.set(VoteKind.OPINION, opinion_vote_id);
					}
				}
			} else if (vote_kind === VoteKind.CATEGORIZATION) {
				if (currentStatus.status['OPEN'] !== undefined) {
					let categorization_vote_id = (await actor.findCategorizationVoteId(questionId, BigInt(currentStatus.iteration)))['ok'];
					if (categorization_vote_id !== undefined) {
						joins.set(VoteKind.CATEGORIZATION, categorization_vote_id);
					}
				}
			}

			setQuestionVoteJoins(joins);
		}
	};

	const findLastVote = (history: StatusInfo[], status_name: string) : StatusInfo | undefined => {
		for (let i = history.length - 1; i >= 0; i--) {
			if (history[i].status[status_name] !== undefined) {
				return history[i];
			}
		}
		return undefined;
	};

	useEffect(() => {
		refreshQuestion();
		refreshStatusHistory();
  }, [questionId]);

	useEffect(() => {
		refreshQuestionVoteJoins();
	}, [questionId, statusHistory, vote_kind]);

	return (
		<div className={`flex flex-row text-black dark:text-white border-b dark:border-gray-700 hover:bg-slate-50 hover:dark:bg-slate-850 pl-10
			${questionVoteJoins.get(VoteKind.INTEREST) !== undefined ? "" : "pr-10"}`}>
			<div className={`flex flex-col py-1 px-1 justify-between w-full space-y-1
				${questionVoteJoins.get(VoteKind.INTEREST) !== undefined ? "w-4/5" : "w-1/5"}`}>
				{
					question === undefined ? 
					<div role="status" className="w-full animate-pulse">
						<div className="h-2 bg-gray-200 rounded-full dark:bg-gray-700 my-2"></div>
						<div className="h-2 bg-gray-200 rounded-full dark:bg-gray-700 my-2"></div>
						<div className="h-2 bg-gray-200 rounded-full dark:bg-gray-700 max-w-[330px] my-2"></div>
						<span className="sr-only">Loading...</span>
					</div> :
					<div className={`w-full justify-start text-sm font-normal break-words`}>
          	{question.text}
        	</div>
				}
				{
						questionVoteJoins.get(VoteKind.OPINION) !== undefined ? 
							<OpinionVote
								actor={actor} 
                polarizationInfo={CONSTANTS.OPINION_INFO} 
                voteId={questionVoteJoins.get(VoteKind.OPINION)} 
              /> :
						questionVoteJoins.get(VoteKind.CATEGORIZATION) !== undefined?
							<CategorizationVote 
								actor={actor}
								categories={categories}
								voteId={questionVoteJoins.get(VoteKind.CATEGORIZATION)}
							/> : <></>
				}
				{
					statusHistory.length === 0 ? <></> :
					<StatusHistoryComponent 
						actor={actor}
						categories={categories}
						questionId={questionId}
						statusHistory={statusHistory}
					/>
				}
				{/*
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
				*/}
			</div>
			{
				questionVoteJoins.get(VoteKind.INTEREST) !== undefined ?
				<div className="w-1/5 flex flex-col col-span-2 items-center justify-self-center">
					<InterestVote actor={actor} voteId={questionVoteJoins.get(VoteKind.INTEREST)}/>
				</div> : <></>
			}
		</div>
	);
};

export default QuestionComponent;
