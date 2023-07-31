import CursorBallot                                            from "../base/CursorBallot";
import { CursorSlider }                                        from "../base/CursorSlider";
import UpdateProgress                                          from "../UpdateProgress";
import SvgButton                                               from "../base/SvgButton";
import ReturnIcon                                              from "../icons/ReturnIcon";
import PutBallotIcon                                           from "../icons/PutBallotIcon";
import { putBallotErrorToString, toCursorInfo,
  VoteStatusEnum, voteStatusToEnum, CursorInfo }               from "../../utils";
import { getDocElementById }                                   from "../../utils/DocumentUtils";
import CONSTANTS                                               from "../../Constants";
import { Sub }                                                 from "../../ActorContext";
import { PutBallotError, VoteData, Cursor, 
  RevealedOpinionBallot }                                      from "../../../declarations/godwin_sub/godwin_sub.did";

import React, { useState }                                     from "react";
import { createPortal }                                        from "react-dom";
import { fromNullable }                                        from "@dfinity/utils";

const unwrapBallot = (vote_data: VoteData) : RevealedOpinionBallot | undefined => {
  let vote_kind_ballot = fromNullable(vote_data.user_ballot);
  if (vote_kind_ballot !== undefined && vote_kind_ballot['OPINION'] !== undefined){
    return vote_kind_ballot['OPINION'];
  }
  return undefined;
}

type Props = {
  sub: Sub;
  voteData: VoteData;
  allowVote: boolean;
  onOpinionChange?: () => void;
  votePlaceholderId: string;
  ballotPlaceholderId: string;
};

const optCursorInfo = (cursor: number | undefined) : CursorInfo | undefined => {
  if (cursor !== undefined){
    return toCursorInfo(cursor, CONSTANTS.OPINION_INFO);
  }
  return undefined;
}

const OpinionVote = ({sub, voteData, allowVote, onOpinionChange, votePlaceholderId, ballotPlaceholderId}: Props) => {

  const COUNTDOWN_DURATION_MS = 0;

  const [countdownVote, setCountdownVote] = useState<boolean>                          (false                               );
  const [triggerVote,   setTriggerVote  ] = useState<boolean>                          (false                               );
  const [ballot,        setBallot       ] = useState<RevealedOpinionBallot | undefined>(unwrapBallot(voteData)              );
  const [cursor,        setCursor       ] = useState<Cursor>                           (0.0                                 );
  const [showVote,      setShowVote     ] = useState<boolean>                          (unwrapBallot(voteData) === undefined);

  const refreshBallot = () : Promise<void> => {
    return sub.actor.getOpinionBallot(voteData.id).then((result) => {
      if (result['ok'] !== undefined){
        setBallot(result['ok']);
        setShowVote(false);
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

  const isLateBallot = (ballot: RevealedOpinionBallot) : boolean => {
    let answer = fromNullable(ballot.answer);
    if (answer !== undefined){
      return fromNullable(answer.late_decay) !== undefined;
    }
    return false;
  }

  const isLateVote = (voteData: VoteData) : boolean => {
    return voteStatusToEnum(voteData.status) === VoteStatusEnum.LOCKED;
  }

  const canVote = (voteData: VoteData) : boolean => {
    return allowVote && voteStatusToEnum(voteData.status) !== VoteStatusEnum.CLOSED;
  }

	return (
    <>
    {
      createPortal(
        <>
          { 
            !showVote && ballot !== undefined ?
            <div className={`flex flex-row justify-center items-center w-32 pr-10`}>
              <CursorBallot
                cursorInfo={ optCursorInfo(fromNullable(ballot.answer)?.cursor) } 
                dateNs={ballot.date}
                isLate={isLateBallot(ballot)}
              />
              {
                !canVote(voteData) ? <></> :
                voteData.id !== ballot.vote_id ?
                  <div className={`text-sm text-blue-600 dark:text-blue-600 hover:text-blue-800 hover:dark:text-blue-400 hover:cursor-pointer font-bold
                    ${isLateVote(voteData) ? "late-vote": ""}`}
                    onClick={() => { setShowVote(true); }}
                  > NEW </div> :
                ballot.can_change ?
                  <div className="ml-2 w-4 h-4"> {/* @todo: setting a relative size does not seem to work here*/}
                    <SvgButton onClick={() => { setShowVote(true); }} disabled={false} hidden={false}>
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
          { showVote && canVote(voteData) ?
            <div className={`grid grid-cols-10 items-center w-full transition duration-2000 ${triggerVote ? "opacity-0" : "opacity-100"}`}>
              <div className="col-span-3"> { /* spacer to center the content */ }</div>
              <div className="col-span-4">
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
              <div className="col-span-1">
                <UpdateProgress<PutBallotError> 
                    delay_duration_ms={COUNTDOWN_DURATION_MS}
                    update_function={putBallot}
                    error_to_string={putBallotErrorToString}
                    callback_function={refreshBallot}
                    run_countdown={countdownVote}
                    set_run_countdown={setCountdownVote}
                    trigger_update={triggerVote}
                    set_trigger_update={setTriggerVote}
                  >
                  <div className="w-6 h-6">
                    <SvgButton onClick={() => setTriggerVote(true)} disabled={triggerVote} hidden={false}>
                      <PutBallotIcon/>
                    </SvgButton>
                  </div>
                </UpdateProgress>
              </div>
              <div className="col-span-2"> { /* spacer to center the content */ }</div>
            </div> : <></>
          }
        </>,
        getDocElementById(votePlaceholderId)
      )
    }
  </>
	);
};

export default OpinionVote;
