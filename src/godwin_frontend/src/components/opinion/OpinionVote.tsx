import CursorBallot                                            from "../base/CursorBallot";
import { CursorSlider }                                        from "../base/CursorSlider";
import UpdateProgress                                          from "../UpdateProgress";
import SvgButton                                               from "../base/SvgButton";
import ReturnIcon                                              from "../icons/ReturnIcon";
import PutBallotIcon                                           from "../icons/PutBallotIcon";
import { putBallotErrorToString, toCursorInfo,
  VoteStatusEnum, voteStatusToEnum }                           from "../../utils";
import { getDocElementById }                                   from "../../utils/DocumentUtils";
import CONSTANTS                                               from "../../Constants";
import { Sub }                                                 from "../../ActorContext";
import { PutBallotError, VoteData, Cursor, OpinionAnswer }     from "../../../declarations/godwin_sub/godwin_sub.did";

import React, { useState }                                     from "react";
import { createPortal }                                        from "react-dom";
import { fromNullable }                                        from "@dfinity/utils";

const unwrapBallotDate = (vote_data: VoteData) : bigint  | undefined => {
  let ballot = fromNullable(vote_data.user_ballot);
  if (ballot !== undefined && ballot['OPINION'] !== undefined){
    return ballot['OPINION'].date;
  }
  return undefined;
}

const unwrapBallotCursor = (vote_data: VoteData, canVote: boolean) : Cursor | undefined => {
  let ballot = fromNullable(vote_data.user_ballot);
  if (ballot !== undefined && ballot['OPINION'] !== undefined){
    let answer : OpinionAnswer | undefined = fromNullable(ballot['OPINION'].answer);
    if (answer !== undefined){
      return answer.cursor;
    }
	}
  if (canVote){
    return 0.0;
  }
  return undefined;
}

type Props = {
  sub: Sub;
  voteData: VoteData;
  canVote: boolean;
  voteElementId: string;
  ballotElementId: string;
};

const OpinionVote = ({sub, voteData, canVote, voteElementId, ballotElementId}: Props) => {

  const COUNTDOWN_DURATION_MS = 0;

  const [countdownVote, setCountdownVote] = useState<boolean>           (false                                );
  const [triggerVote,   setTriggerVote  ] = useState<boolean>           (false                                );
  const [voteDate,      setVoteDate     ] = useState<bigint | undefined>(unwrapBallotDate(voteData)           );
  const [cursor,        setCursor       ] = useState<Cursor | undefined>(unwrapBallotCursor(voteData, canVote));

  const refreshBallot = () : Promise<void> => {
    return sub.actor.getOpinionBallot(voteData.id).then((result) => {
      if (result['ok'] !== undefined){
        if (result['ok'].answer[0] !== undefined){
          setCursor(result['ok'].answer[0].cursor);
        }
        if (result['ok'].date !== undefined){
          setVoteDate(result['ok'].date);
        }
      }
    });
  }

  const putBallot = () : Promise<PutBallotError | null> => {
    if (cursor === undefined) throw new Error("Cannot put ballot: cursor is undefined");
    return sub.actor.putOpinionBallot(voteData.id, cursor).then((result) => {
      return result['err'] ?? null;
    });
  }

  const isLate = () : boolean => {
    return voteStatusToEnum(voteData.status) === VoteStatusEnum.LOCKED;
  }

	return (
    <>
    {
      createPortal(
        <>
          { voteDate !== undefined ?
            <div className={`flex flex-row justify-center items-center w-full`}>
              <CursorBallot cursorInfo={cursor !== undefined ? toCursorInfo(cursor, CONSTANTS.OPINION_INFO) : undefined} dateNs={voteDate} isLate={isLate()}/>
              <div className="ml-2 w-4 h-4" hidden={!canVote}> {/* @todo: setting a relative size does not seem to work here*/}
                <SvgButton onClick={() => setVoteDate(undefined)} disabled={false} hidden={false}>
                  <ReturnIcon/>
                </SvgButton>
              </div>
            </div> : <></>
          }
        </>,
        getDocElementById(ballotElementId)
      )
    }
    {
      createPortal(
        <>
          { voteDate === undefined && cursor !== undefined ?
            <div className={`flex flex-row justify-center items-center w-full transition duration-2000 ${triggerVote ? "opacity-0" : "opacity-100"}`}>
              <CursorSlider
                  cursor = { cursor }
                  polarizationInfo={ CONSTANTS.OPINION_INFO }
                  disabled={ triggerVote }
                  setCursor={ setCursor }
                  onMouseUp={ () => { setCountdownVote(true)} }
                  onMouseDown={ () => { setCountdownVote(false)} }
                  isLate={isLate()}
                />
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
            </div> : <></>
          }
        </>,
        getDocElementById(voteElementId)
      )
    }
  </>
	);
};

export default OpinionVote;
