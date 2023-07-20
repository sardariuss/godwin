import CursorBallot                             from "../base/CursorBallot";
import { CursorSlider }                         from "../base/CursorSlider";
import UpdateProgress                           from "../UpdateProgress";
import SvgButton                                from "../base/SvgButton";
import ReturnIcon                               from "../icons/ReturnIcon";
import PutBallotIcon                            from "../icons/PutBallotIcon";
import { putBallotErrorToString, toCursorInfo,
  VoteStatusEnum, voteStatusToEnum }            from "../../utils";
import { getDocElementById }                    from "../../utils/DocumentUtils";
import CONSTANTS                                from "../../Constants";
import { Sub }                                  from "../../ActorContext";
import { PutBallotError, VoteData, Cursor }     from "../../../declarations/godwin_sub/godwin_sub.did";

import React, { useState }                      from "react";
import { createPortal }                         from 'react-dom';

const unwrapBallotDate = (vote_data: VoteData) : bigint  | undefined => {
  if (vote_data.user_ballot['OPINION'] !== undefined){
		return vote_data.user_ballot['OPINION'].date;
	}
  return undefined;
}

const unwrapBallotCursor = (vote_data: VoteData) : Cursor => {
  if (vote_data.user_ballot['OPINION'] !== undefined){
		return vote_data.user_ballot['OPINION'].answer.cursor;
	}
  return 0.0;
}

type Props = {
  sub: Sub;
  voteData: VoteData;
  voteElementId: string;
  ballotElementId: string;
};

const OpinionVote = ({sub, voteData, voteElementId, ballotElementId}: Props) => {

  const COUNTDOWN_DURATION_MS = 0;

  const [countdownVote, setCountdownVote] = useState<boolean>           (false                       );
  const [triggerVote,   setTriggerVote  ] = useState<boolean>           (false                       );
  const [voteDate,      setVoteDate     ] = useState<bigint | undefined>(unwrapBallotDate(voteData)  );
  const [cursor,        setCursor       ] = useState<Cursor>            (unwrapBallotCursor(voteData));

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
              <CursorBallot cursorInfo={toCursorInfo(cursor, CONSTANTS.OPINION_INFO)} dateNs={voteDate} isLate={isLate()}/>
              <div className="ml-2 w-4 h-4"> {/* @todo: setting a relative size does not seem to work here*/}
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
          { voteDate === undefined ?
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
