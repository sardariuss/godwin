import OpinionVote                        from "./opinion/OpinionVote";
import CategorizationVote                 from "./categorization/CategorizationVote";
import StatusHistoryComponent             from "./StatusHistory";
import ReopenButton                       from "./ReopenButton";
import InterestVote                       from "./interest/InterestVote";
import CONSTANTS                          from "../Constants";
import { VoteKind }                       from "../utils";
import { Sub }                            from "../ActorContext";
import { Question, StatusData, VoteData } from "../../declarations/godwin_sub/godwin_sub.did";

import React, { useEffect, useState }     from "react";
import { Principal }                      from "@dfinity/principal";

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
	principal: Principal,
	allowVote: boolean,
	onOpinionChange?: () => void
};

const QuestionComponent = ({sub, question_id, question, statusData, vote, showReopenQuestion, principal, allowVote, onOpinionChange}: QuestionInput) => {
	
	const [rightPlaceholderId ] = useState<string>(question_id + "_right_placeholder" );
	const [bottomPlaceholderId] = useState<string>(question_id + "_bottom_placeholder");

	// @todo: hack to be able to initialize the placeholders before initializing the vote components
	const [voteKind, setVoteKind] = useState<VoteKind | undefined>(undefined);
	const [voteData, setVoteData] = useState<VoteData | undefined>(undefined);

	// @todo: this is also a bit hacky, the question shall be hidden only if the new state is not the same
	const [hideQuestion, setHideQuestion] = useState<boolean>(false);

	const [showBallotHistory, setShowBallotHistory] = useState<boolean>(false);

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
						<div className={`w-full justify-start text-sm break-words hover:cursor-pointer ${question !== undefined ? "" : "italic text-gray-600 dark:text-gray-400 text-xs"}`} onClick={(e) => {setShowBallotHistory(!showBallotHistory);}}>
							{ question !== undefined ? question.text : CONSTANTS.HELP_MESSAGE.DELETED_QUESTION }
						</div>
						{
							showReopenQuestion ?
								<div className="flex flex-row grow self-start justify-end">
									<ReopenButton sub={sub} questionId={question_id} onReopened={()=>{setHideQuestion(true)}}/>
								</div> : <></>
						}
					</div>
					{
						statusData !== undefined ?
							<StatusHistoryComponent sub={sub} questionId={question_id} statusData={statusData}/> : <></>
					}
				</div>
				{
					voteKind === undefined ? <></> :
						voteKind === VoteKind.INTEREST && voteData !== undefined ?
							<InterestVote       
								sub={sub} 
								voteData={voteData} 
								allowVote={allowVote} 
								rightPlaceholderId={rightPlaceholderId}  
								bottomPlaceholderId={bottomPlaceholderId}
								question_id={question_id}
								principal={principal}
								showHistory={showBallotHistory}/> :
						voteKind === VoteKind.OPINION && voteData !== undefined ?
							<OpinionVote        
								sub={sub}
								voteData={voteData}
								allowVote={allowVote}
								bottomPlaceholderId={bottomPlaceholderId}
								rightPlaceholderId={rightPlaceholderId}
								onOpinionChange={onOpinionChange}
								question_id={question_id}
								principal={principal}
								showHistory={showBallotHistory}/> :
						voteKind === VoteKind.CATEGORIZATION && voteData !== undefined ?
							<CategorizationVote 
								sub={sub} 
								voteData={voteData} 
								allowVote={allowVote} 
								bottomPlaceholderId={bottomPlaceholderId} 
								rightPlaceholderId={rightPlaceholderId}
								question_id={question_id}
								principal={principal}
								showHistory={showBallotHistory}/> : <></>
				}
			</div>
		}
		</>
	);
};

export default QuestionComponent;
