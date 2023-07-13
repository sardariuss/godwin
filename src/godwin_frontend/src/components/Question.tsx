import OpinionVote                                   from "./opinion/OpinionVote";
import CategorizationVote                            from "./categorization/CategorizationVote";
import StatusHistoryComponent                        from "./StatusHistory";
import ReopenButton                                  from "./ReopenButton";
import InterestVote                                  from "./interest/InterestVote";
import { StatusEnum, VoteKind, statusToEnum, toMap, voteKindFromCandidVariant } from "../utils";
import { Sub }                                       from "../ActorContext";
import CONSTANTS                                     from "../Constants";
import { Question, StatusInfo, QueryQuestionItem, VoteLink, VoteKind__1, VoteData }   from "../../declarations/godwin_sub/godwin_sub.did";

import { UserAction } from "./MainQuestions";

import { useEffect, useState }                       from "react";

export type QuestionInput = {
	sub: Sub,
  queried_question: QueryQuestionItem,
	user_action: UserAction | undefined
};

const findVoteId = (vote_links: [VoteKind__1, VoteData][], vote_kind: VoteKind) : bigint | undefined => {
	let found_vote = vote_links.find(([kind, data]) : boolean => {
		return voteKindFromCandidVariant(kind) === vote_kind && data.status['OPEN'] !== undefined;
	})
	return found_vote !== undefined ? found_vote[1].id : undefined;
}

const QuestionComponent = ({sub, queried_question, user_action}: QuestionInput) => {

  const [activeVote, setActiveVote] = useState<VoteKind | undefined>(undefined);
	const [voteId, setVoteId] = useState<bigint | undefined>(undefined);
	const [showReopenQuestion, setShowReopenQuestion] = useState<boolean>(false);

	const refreshActiveVote = () => {
		setActiveVote(
			user_action === UserAction.SELECT ? VoteKind.INTEREST :
			user_action === UserAction.VOTE ? VoteKind.OPINION :
			user_action === UserAction.CATEGORIZE ? VoteKind.CATEGORIZATION : undefined);
	}

	const refreshVoteId = () => {
		setVoteId(activeVote !== undefined ? findVoteId(queried_question.votes, activeVote) : undefined);
	}

	const refreshShowReopenQuestion = () => {
		setShowReopenQuestion(
			user_action === UserAction.REOPEN_QUESTION && (
				statusToEnum(queried_question.status_data.status_info.status) === StatusEnum.CLOSED ||
				statusToEnum(queried_question.status_data.status_info.status) === StatusEnum.TIMED_OUT));
	}

	useEffect(() => {
		refreshActiveVote();
	}, [user_action]);

	useEffect(() => {
		refreshVoteId();
	}, [activeVote, queried_question]);

	useEffect(() => {
		refreshShowReopenQuestion();
	}, [user_action, queried_question]);

//	const [question, setQuestion] = useState<Question | undefined>(undefined);
//	const [statusHistory, setStatusHistory] = useState<StatusInfo[]>([]);
//	const [questionVoteJoins, setQuestionVoteJoins] = useState<Map<VoteKind, bigint>>(new Map<VoteKind, bigint>());
//	const [isLocked, setIsLocked] = useState<boolean>(false); // @todo: one should not use a specific state for the opinion vote
//	const [canReopen, setCanReopen] = useState<boolean>(false);
//
//	const refreshQuestion = async () => {
//		const question = await sub.actor.getQuestion(questionId);
//		setQuestion(question['ok']);
//	}
//
//	const refreshStatusHistory = async () => {
//		var statuses : StatusInfo[] = [];
//		const history = await sub.actor.getStatusHistory(questionId);
//		if (history['ok'] !== undefined){
//			statuses = history['ok'];	
//		}
//		setStatusHistory(statuses);
//	}
//
//	const refreshQuestionVoteJoins = async () => {
//
//		if (statusHistory.length === 0) {
//			setQuestionVoteJoins(new Map<VoteKind, bigint>());
//		} else {
//			let currentStatus = statusHistory[statusHistory.length - 1];
//			let previousOpenStatus = findLastVote(statusHistory, 'OPEN');
//			
//			var joins = new Map<VoteKind, bigint>();
//					
//			if (user_action === VoteKind.INTEREST) {
//				if (currentStatus.status['CANDIDATE'] !== undefined) {
//					let interest_vote_id = (await sub.actor.findInterestVoteId(questionId, BigInt(currentStatus.iteration)))['ok'];
//					if (interest_vote_id !== undefined) {
//						joins.set(VoteKind.INTEREST, interest_vote_id);
//					}
//				}
//			} else if (user_action === VoteKind.OPINION) {
//				// Include late votes
//				var iteration : bigint | undefined = undefined;
//				if (currentStatus.status['OPEN'] !== undefined){
//					iteration = currentStatus.iteration;
//					setIsLocked(false);
//				} else if (previousOpenStatus !== undefined){
//					iteration = previousOpenStatus.iteration;
//					setIsLocked(true);
//				}
//				if (iteration !== undefined) {
//					let opinion_vote_id = (await sub.actor.findOpinionVoteId(questionId, iteration))['ok'];
//					if (opinion_vote_id !== undefined) {
//						joins.set(VoteKind.OPINION, opinion_vote_id);
//					}
//				}
//			} else if (user_action === VoteKind.CATEGORIZATION) {
//				if (currentStatus.status['OPEN'] !== undefined) {
//					let categorization_vote_id = (await sub.actor.findCategorizationVoteId(questionId, BigInt(currentStatus.iteration)))['ok'];
//					if (categorization_vote_id !== undefined) {
//						joins.set(VoteKind.CATEGORIZATION, categorization_vote_id);
//					}
//				}
//			}
//
//			setQuestionVoteJoins(joins);
//		}
//	};
//
//	const refreshCanReopen = async () => {
//		setCanReopen(
//			user_action === undefined && statusHistory.length > 0 && (
//			(statusToEnum(statusHistory[statusHistory.length - 1].status)) === StatusEnum.CLOSED
//	 || (statusToEnum(statusHistory[statusHistory.length - 1].status)) === StatusEnum.TIMED_OUT));
//	}
//
//	const findLastVote = (history: StatusInfo[], status_name: string) : StatusInfo | undefined => {
//		for (let i = history.length - 1; i >= 0; i--) {
//			if (history[i].status[status_name] !== undefined) {
//				return history[i];
//			}
//		}
//		return undefined;
//	};
//
//	useEffect(() => {
//		refreshQuestion();
//		refreshStatusHistory();
//  }, [questionId]);
//
//	useEffect(() => {
//		refreshQuestionVoteJoins();
//		refreshCanReopen();
//	}, [statusHistory, user_action]);

	return (
		<div className={`flex flex-row text-black dark:text-white border-b dark:border-gray-700 hover:bg-slate-50 hover:dark:bg-slate-850 pl-10 
			${activeVote === VoteKind.INTEREST || showReopenQuestion ? "" : "pr-10"}`}>
			<div className={`flex flex-col py-1 px-1 justify-between space-y-1 
				${activeVote === VoteKind.INTEREST ? "w-4/5" : "w-full"}`}>
				<div className="flex flex-row justify-between grow">
					<div className={`w-full justify-start text-sm font-normal break-words`}>
          	{queried_question.question.text}
        	</div>
				{
				showReopenQuestion ?
					<div className="flex flex-row grow self-start justify-end mr-5">
						<ReopenButton actor={sub.actor} questionId={queried_question.question.id} onReopened={()=>{}}/>
					</div> : <></>
				}
				</div>
				{
					activeVote === VoteKind.OPINION && voteId !== undefined ? 
						<OpinionVote
							actor={sub.actor}
							polarizationInfo={CONSTANTS.OPINION_INFO}
							isLocked={false}
							voteId={voteId} /> :
					activeVote === VoteKind.CATEGORIZATION && voteId !== undefined ?
						<CategorizationVote 
							actor={sub.actor}
							categories={toMap(sub.categories)}
							voteId={voteId}/> : <></>
				}
				{
					/*
					statusHistory.length === 0 ? <></> :
						<StatusHistoryComponent 
							sub={sub}
							questionId={questionId}
							statusHistory={statusHistory}
						/>
					*/
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
				activeVote === VoteKind.INTEREST && voteId !== undefined ?
				<div className="w-1/5 mr-5">
					<InterestVote actor={sub.actor} voteId={voteId}/>
				</div> : <></>
			}
		</div>
	);
};

export default QuestionComponent;
