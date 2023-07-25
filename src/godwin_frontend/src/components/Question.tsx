import OpinionVote                        from "./opinion/OpinionVote";
import CategorizationVote                 from "./categorization/CategorizationVote";
import CONSTANTS                          from "../Constants";
import StatusHistoryComponent             from "./StatusHistory";
import ReopenButton                       from "./ReopenButton";
import InterestVote                       from "./interest/InterestVote";
import { VoteKind }                       from "../utils";
import { Sub }                            from "../ActorContext";
import { Question, StatusData, VoteData } from "../../declarations/godwin_sub/godwin_sub.did";

import React, { useEffect, useState }     from "react";

export type QuestionInput = {
	sub: Sub,
	question_id: bigint,
	question: Question | undefined,
	statusData?: StatusData,
	vote?: {
		kind: VoteKind,
		data: VoteData,
	},
	showReopenQuestion?: boolean,
	canVote: boolean,
};

const QuestionComponent = ({sub, question_id, question, statusData, vote, showReopenQuestion, canVote}: QuestionInput) => {
	
	const [rightPlaceHolderId ] = useState<string>(question_id + "_right_placeholder" );
	const [bottomPlaceHolderId] = useState<string>(question_id + "_bottom_placeholder");

	// @todo: hack to be able to initialize the placeholders before initializing the vote components
	const [voteKind, 				 setVoteKind            ] = useState<VoteKind | undefined>(undefined);
	const [voteData, 				 setVoteData            ] = useState<VoteData | undefined>(undefined);

	const refreshVote = () => {
		setVoteKind(vote !== undefined ? vote.kind : undefined);
		setVoteData(vote !== undefined ? vote.data : undefined);
	}

	useEffect(() => {
		refreshVote();
	}, [vote]);

	return (
		<div className={`flex flex-row text-black dark:text-white border-b dark:border-gray-700 hover:bg-slate-50 hover:dark:bg-slate-850 pl-10 items-center
			${(vote !== undefined && voteKind === VoteKind.INTEREST) || showReopenQuestion ? "" : "pr-10"}`} id={rightPlaceHolderId}>
			<div className={`flex flex-col py-1 px-1 justify-between space-y-1 
				${(vote !== undefined && voteKind === VoteKind.INTEREST) ? "w-4/5" : "w-full"}`} id={bottomPlaceHolderId}>
				<div className="flex flex-row justify-between grow">
					<div className={`w-full justify-start text-sm font-normal break-words`}>
          	{question !== undefined ? question.text : CONSTANTS.HELP_MESSAGE.DELETED_QUESTION }
        	</div>
					{
						showReopenQuestion ?
							<div className="flex flex-row grow self-start justify-end mr-5">
								<ReopenButton actor={sub.actor} questionId={question_id} onReopened={()=>{}}/>
							</div> : <></>
					}
				</div>
				{
					statusData !== undefined ?
						<StatusHistoryComponent sub={sub} questionId={question_id} currentStatusData={statusData}/> : <></>
				}
			</div>
			{
				voteKind === undefined ? <></> :
					voteKind === VoteKind.INTEREST && voteData !== undefined ?
						<InterestVote       sub={sub} voteData={voteData} canVote={canVote} voteElementId={rightPlaceHolderId}  ballotElementId={rightPlaceHolderId}/> : 
					voteKind === VoteKind.OPINION && voteData !== undefined ?
						<OpinionVote        sub={sub} voteData={voteData} canVote={canVote} voteElementId={bottomPlaceHolderId} ballotElementId={rightPlaceHolderId}/> :
					voteKind === VoteKind.CATEGORIZATION && voteData !== undefined ?
						<CategorizationVote sub={sub} voteData={voteData} canVote={canVote} voteElementId={bottomPlaceHolderId} ballotElementId={rightPlaceHolderId}/> : <></>
			}
		</div>
	);
};

export default QuestionComponent;
