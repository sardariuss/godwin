import CursorBallot                                            from "../base/CursorBallot";
import { CursorSlider }                                        from "../base/CursorSlider";
import UpdateProgress                                          from "../UpdateProgress";
import SvgButton                                               from "../base/SvgButton";
import ReturnIcon                                              from "../icons/ReturnIcon";
import PutBallotIcon                                           from "../icons/PutBallotIcon";
import { putBallotErrorToString, toCursorInfo,
  VoteStatusEnum, voteStatusToEnum, CursorInfo, revealAnswer } from "../../utils";
import { nsToStrDate }                                         from "../../utils/DateUtils";
import { getDocElementById }                                   from "../../utils/DocumentUtils";
import CONSTANTS                                               from "../../Constants";
import { Sub }                                                 from "../../ActorContext";
import { PutBallotError, VoteData, Cursor, 
  RevealableOpinionBallot}                                     from "../../../declarations/godwin_sub/godwin_sub.did";

import React, { useState, useEffect }                          from "react";
import { createPortal }                                        from "react-dom";
import { fromNullable }                                        from "@dfinity/utils";
import { Principal }                                           from "@dfinity/principal";

const unwrapBallot = (vote_data: VoteData) : RevealableOpinionBallot | undefined => {
  let vote_kind_ballot = fromNullable(vote_data.user_ballot);
  if (vote_kind_ballot !== undefined && vote_kind_ballot['OPINION'] !== undefined){
    return vote_kind_ballot['OPINION'];
  }
  return undefined;
}

const optCursorInfo = (cursor: number | undefined) : CursorInfo | undefined => {
  if (cursor !== undefined){
    return toCursorInfo(cursor, CONSTANTS.OPINION_INFO);
  }
  return undefined;
}

enum VoteView {
  VOTE,
  LAST_BALLOT,
  BALLOT_HISTORY
};

const deduceVoteView = (ballot: RevealableOpinionBallot | undefined, showHistory: boolean) : VoteView => {
  return ballot === undefined ? VoteView.VOTE : showHistory ? VoteView.BALLOT_HISTORY : VoteView.LAST_BALLOT;
};

type Props = {
  sub: Sub;
  voteData: VoteData;
  allowVote: boolean;
  onOpinionChange?: () => void;
  votePlaceholderId: string;
  ballotPlaceholderId: string;
  question_id: bigint;
  principal: Principal;
  showHistory: boolean;
};

const OpinionVote = ({sub, voteData, allowVote, onOpinionChange, votePlaceholderId, ballotPlaceholderId, question_id, principal, showHistory}: Props) => {

  const COUNTDOWN_DURATION_MS = 0;

  const [countdownVote, setCountdownVote] = useState<boolean>                            (false                                              );
  const [triggerVote,   setTriggerVote  ] = useState<boolean>                            (false                                              );
  const [ballot,        setBallot       ] = useState<RevealableOpinionBallot | undefined>(unwrapBallot(voteData)                             );
  const [cursor,        setCursor       ] = useState<Cursor>                             (0.0                                                );
  const [voteView,      setVoteView     ] = useState<VoteView>                           (deduceVoteView(unwrapBallot(voteData), showHistory));
  const [ballotHistory, setBallotHistory] = useState<[bigint, RevealableOpinionBallot | undefined][]>([]                                     );

  const refreshBallot = () : Promise<void> => {
    return sub.actor.getOpinionBallot(voteData.id).then((result) => {
      if (result['ok'] !== undefined){
        setBallot(result['ok']);
      };
    });
  }

  const putBallot = () : Promise<PutBallotError | null> => {
    return sub.actor.putOpinionBallot(voteData.id, cursor).then((result) => {
      if (result['ok'] !== undefined){
        onOpinionChange?.();
      };
      return result['err'] ?? null;
    });
  }

  const isLateBallot = (ballot: RevealableOpinionBallot) : boolean => {
    let answer = revealAnswer(ballot.answer);
    if (answer !== undefined){
      return fromNullable(answer.late_decay) !== undefined;
    }
    return false;
  }

  const isLateVote = (voteData: VoteData) : boolean => {
    return voteStatusToEnum(voteData.status) === VoteStatusEnum.LOCKED;
  }

  // allowVote: true for home, false for browse, depend on logging state for user profile
  // @todo: could be renamed readOnly
  const canVote = (voteData: VoteData) : boolean => {
    return allowVote && voteStatusToEnum(voteData.status) !== VoteStatusEnum.CLOSED;
  }

  const fetchBallotHistory = () => {
    sub.actor.queryVoterQuestionBallots(question_id, { 'OPINION' : null }, principal).then((iteration_ballots) => {
      let history = iteration_ballots.map((ballot) : [bigint, RevealableOpinionBallot | undefined] => { 
        return [ballot[0], (fromNullable(ballot[1]) !== undefined ? fromNullable(ballot[1])['OPINION'] : undefined)]; 
      });
      setBallotHistory(history);
    });
  }

  useEffect(() => {
    setVoteView(deduceVoteView(ballot, showHistory));
  }, [ballot, showHistory]);

  useEffect(() => {
    if (showHistory) {
      fetchBallotHistory();
    }
  }, [showHistory]);

	return (
    <>
    {
      createPortal(
        <>
          { 
            voteView === VoteView.LAST_BALLOT && ballot !== undefined ?
            <div className={`flex flex-row justify-center items-center w-32 pr-10`}>
              <CursorBallot
                cursorInfo={ optCursorInfo(revealAnswer(ballot.answer)?.cursor) } 
                dateNs={ballot.date}
                isLate={isLateBallot(ballot)}
              />
              {
                !canVote(voteData) ? <></> :
                voteData.id !== ballot.vote_id ?
                  <div className={`text-sm text-blue-600 dark:text-blue-600 hover:text-blue-800 hover:dark:text-blue-400 hover:cursor-pointer font-bold
                    ${isLateVote(voteData) ? "late-vote": ""}`}
                    onClick={() => { setBallot(undefined); }}
                  > NEW </div> :
                ballot.can_change ?
                  <div className="ml-2 w-4 h-4"> {/* @todo: setting a relative size does not seem to work here*/}
                    <SvgButton onClick={() => { setBallot(undefined); }} disabled={false} hidden={false}>
                      <ReturnIcon/>
                    </SvgButton>
                  </div> : <></>
              }
            </div> : <></>
          }
        </>,
        getDocElementById(ballotPlaceholderId)
      )
    }
    {
      createPortal(
        <>
          { voteView === VoteView.VOTE && canVote(voteData) ?
            <div className={`relative flex flex-row items-center justify-center w-full transition duration-2000 ${triggerVote ? "opacity-0" : "opacity-100"}`}>
              <div className="w-2/5">
                <CursorSlider
                    cursor = { cursor }
                    polarizationInfo={ CONSTANTS.OPINION_INFO }
                    disabled={ triggerVote }
                    setCursor={ setCursor }
                    onMouseUp={ () => { setCountdownVote(true)} }
                    onMouseDown={ () => { setCountdownVote(false)} }
                    isLate={isLateVote(voteData)}
                  />
              </div>
              <div className="absolute right-0 w-1/5">
                <UpdateProgress<PutBallotError> 
                    delay_duration_ms={COUNTDOWN_DURATION_MS}
                    update_function={putBallot}
                    error_to_string={putBallotErrorToString}
                    callback_success={refreshBallot}
                    run_countdown={countdownVote}
                    set_run_countdown={setCountdownVote}
                    trigger_update={triggerVote}
                    set_trigger_update={setTriggerVote}
                  >
                  <div className="w-7 h-7">
                    <SvgButton onClick={() => setTriggerVote(true)} disabled={triggerVote} hidden={false}>
                      <PutBallotIcon/>
                    </SvgButton>
                  </div>
                </UpdateProgress>
              </div>
              <div className="col-span-2 bg-green-300 "> { /* spacer to center the content */ }</div>
            </div> : <></>
          }
        </>,
        getDocElementById(votePlaceholderId)
      )
    }
    {
      createPortal(
        <>
          { 
            voteView === VoteView.BALLOT_HISTORY ?
            <ol className={`flex flex-col justify-center items-center space-y-2`}>
              {
                ballotHistory.reverse().map((ballot, index) => (
                  ballot[1] === undefined ? <></> :
                  <li className={`flex flex-row justify-between items-center w-full`} key={index.toString()}>
                    <div className="text-sm font-light">
                      { "Iteration " + ballot[0].toString() }
                    </div>
                    <div className="text-sm font-light">
                      { nsToStrDate(ballot[1].date) }
                    </div>
                    <CursorBallot
                      cursorInfo={optCursorInfo(revealAnswer(ballot[1].answer)?.cursor)}
                      showValue={true}
                      isLate={isLateBallot(ballot[1])}
                    />
                  </li>
                ))
              }
            </ol> : <></>
          }
        </>,
        getDocElementById(votePlaceholderId)
      )
    }
  </>
	);
};

export default OpinionVote;
