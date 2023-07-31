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
	allowVote: boolean,
	onOpinionChange?: () => void
};

const QuestionComponent = ({sub, question_id, question, statusData, vote, showReopenQuestion, allowVote, onOpinionChange}: QuestionInput) => {
	
	const [rightPlaceholderId ] = useState<string>(question_id + "_right_placeholder" );
	const [bottomPlaceholderId] = useState<string>(question_id + "_bottom_placeholder");

	// @todo: hack to be able to initialize the placeholders before initializing the vote components
	const [voteKind, setVoteKind] = useState<VoteKind | undefined>(undefined);
	const [voteData, setVoteData] = useState<VoteData | undefined>(undefined);

	// @todo: this is also a bit hacky, the question shall be hidden only if the new state is not the same
	const [hideQuestion, setHideQuestion] = useState<boolean>(false);

	const refreshVote = () => {
		setVoteKind(vote !== undefined ? vote.kind : undefined);
		setVoteData(vote !== undefined ? vote.data : undefined);
	}

	useEffect(() => {
		refreshVote();
	}, [vote]);

	return (
		<>
		{
			hideQuestion ? <></> :
			<div className={`flex flex-row text-black dark:text-white border-b dark:border-gray-700 hover:bg-slate-50 hover:dark:bg-slate-850 px-5 items-center`} id={rightPlaceholderId}>
				<div className={`flex flex-col py-1 px-1 justify-between space-y-1 w-full`} id={bottomPlaceholderId}>
					<div className="flex flex-row justify-between grow">
						<div className={`w-full justify-start text-sm font-normal break-words`}>
							{ question !== undefined ? question.text : CONSTANTS.HELP_MESSAGE.DELETED_QUESTION }
						</div>
						{
							showReopenQuestion ?
								<div className="flex flex-row grow self-start justify-end">
									<ReopenButton actor={sub.actor} questionId={question_id} onReopened={()=>{setHideQuestion(true)}}/>
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
							<InterestVote       sub={sub} voteData={voteData} allowVote={allowVote} votePlaceholderId={rightPlaceholderId}  ballotPlaceholderId={rightPlaceholderId}/> : 
						voteKind === VoteKind.OPINION && voteData !== undefined ?
							<OpinionVote        sub={sub} voteData={voteData} allowVote={allowVote} votePlaceholderId={bottomPlaceholderId} ballotPlaceholderId={rightPlaceholderId} onOpinionChange={onOpinionChange}/> :
						voteKind === VoteKind.CATEGORIZATION && voteData !== undefined ?
							<CategorizationVote sub={sub} voteData={voteData} allowVote={allowVote} votePlaceholderId={bottomPlaceholderId} ballotPlaceholderId={rightPlaceholderId}/> : <></>
				}
			</div>
		}
		</>
	);
};

export default QuestionComponent;
