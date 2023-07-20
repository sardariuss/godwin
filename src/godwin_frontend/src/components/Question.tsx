import { UserAction }                                            from "./MainQuestions";
import OpinionVote                                               from "./opinion/OpinionVote";
import CategorizationVote                                        from "./categorization/CategorizationVote";
import StatusHistoryComponent                                    from "./StatusHistory";
import ReopenButton                                              from "./ReopenButton";
import InterestVote                                              from "./interest/InterestVote";
import { StatusEnum, VoteKind, statusToEnum,
	 voteKindFromCandidVariant, VoteStatusEnum, voteStatusToEnum } from "../utils";
import { Sub }                                                   from "../ActorContext";
import { QueryQuestionItem, VoteKind__1, VoteData }              from "../../declarations/godwin_sub/godwin_sub.did";

import React, { useEffect, useState }                            from "react";

export type QuestionInput = {
	sub: Sub,
  queried_question: QueryQuestionItem,
	user_action: UserAction | undefined
};

const getVoteData = (vote_links: [VoteKind__1, VoteData][], vote_kind: VoteKind) : (VoteData | undefined) => {
	let found_vote = vote_links.find(([kind, _]) : boolean => {
		return voteKindFromCandidVariant(kind) === vote_kind;
	})
	return found_vote ? found_vote[1] : undefined;
}

const QuestionComponent = ({sub, queried_question, user_action}: QuestionInput) => {
	
	const [rightPlaceHolderId ] = useState<string>(queried_question.question.id + "_right_placeholder" );
	const [bottomPlaceHolderId] = useState<string>(queried_question.question.id + "_bottom_placeholder");
  const [activeVote,         setActiveVote          ] = useState<VoteKind | null | undefined>(undefined);
	const [voteData,           setVoteData            ] = useState<VoteData | undefined>       (undefined);
	const [showReopenQuestion, setShowReopenQuestion  ] = useState<boolean             >       (false    );

	const refreshActiveVote = () => {
		setActiveVote(
			user_action === UserAction.SELECT ?     VoteKind.INTEREST       :
			user_action === UserAction.VOTE ?       VoteKind.OPINION        :
			user_action === UserAction.CATEGORIZE ? VoteKind.CATEGORIZATION : null);
	}

	const refreshVoteId = () => {
		// Checking if null allow to avoid showing the status history preemptively
		setVoteData(activeVote !== undefined && activeVote !== null ? getVoteData(queried_question.votes, activeVote) : undefined);
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

	return (
		<div className={`flex flex-row text-black dark:text-white border-b dark:border-gray-700 hover:bg-slate-50 hover:dark:bg-slate-850 pl-10 items-center
			${activeVote === VoteKind.INTEREST || showReopenQuestion ? "" : "pr-10"}`} id={rightPlaceHolderId}>
			<div className={`flex flex-col py-1 px-1 justify-between space-y-1 
				${activeVote === VoteKind.INTEREST ? "w-4/5" : "w-full"}`} id={bottomPlaceHolderId}>
				<div className="flex flex-row justify-between grow">
					<div className={`w-full justify-start text-sm font-normal break-words`}>
          	{queried_question.question.text}
        	</div>
					{
						user_action === UserAction.REOPEN_QUESTION && (
							statusToEnum(queried_question.status_data.status_info.status) === StatusEnum.CLOSED ||
							statusToEnum(queried_question.status_data.status_info.status) === StatusEnum.TIMED_OUT) ?
								<div className="flex flex-row grow self-start justify-end mr-5">
									<ReopenButton actor={sub.actor} questionId={queried_question.question.id} onReopened={()=>{}}/>
								</div> : <></>
					}
				</div>
				{
					activeVote === null ?
						<StatusHistoryComponent sub={sub} questionId={queried_question.question.id} currentStatusData={queried_question.status_data}/> : <></>
				}
			</div>
			{
				voteData === undefined || voteStatusToEnum(voteData.status) === VoteStatusEnum.CLOSED ? <></> :
					user_action === UserAction.SELECT ?
						<InterestVote       sub={sub} voteData={voteData} voteElementId={rightPlaceHolderId}  ballotElementId={rightPlaceHolderId}/> : 
					user_action === UserAction.VOTE ? 
						<OpinionVote        sub={sub} voteData={voteData} voteElementId={bottomPlaceHolderId} ballotElementId={rightPlaceHolderId}/> :
					user_action === UserAction.CATEGORIZE ?
						<CategorizationVote sub={sub} voteData={voteData} voteElementId={bottomPlaceHolderId} ballotElementId={rightPlaceHolderId}/> : <></>
			}
		</div>
	);
};

export default QuestionComponent;
