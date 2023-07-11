import CursorBallot                                                           from "../base/CursorBallot";
import { CursorSlider }                                                       from "../base/CursorSlider";
import UpdateProgress                                                         from "../UpdateProgress";
import SvgButton                                                              from "../base/SvgButton";
import ReturnIcon                                                             from "../icons/ReturnIcon";
import PutBallotIcon                                                          from "../icons/PutBallotIcon";
import { putBallotErrorToString, PolarizationInfo, CursorInfo, toCursorInfo } from "../../utils";
import { PutBallotError, _SERVICE }                                           from "../../../declarations/godwin_sub/godwin_sub.did";

import { useState, useEffect }                                                from "react";

import { ActorSubclass }                                                      from "@dfinity/agent";

type Props = {
  polarizationInfo: PolarizationInfo;
  voteId: bigint;
  isLocked: boolean;
  actor: ActorSubclass<_SERVICE>;
};

const OpinionVote = ({polarizationInfo, voteId, isLocked, actor}: Props) => {

  const COUNTDOWN_DURATION_MS = 0;

  const [countdownVote, setCountdownVote] = useState<boolean>          (false);
  const [triggerVote,   setTriggerVote  ] = useState<boolean>          (false);
  const [voteDate,      setVoteDate     ] = useState<bigint | null>    (null);
  const [cursorInfo,    setCursorInfo   ] = useState<CursorInfo | null>(null);

  const refreshBallot = () : Promise<void> => {
    return actor.getOpinionBallot(voteId).then((result) => {
      setCursorInfo(toCursorInfo((result['ok'] !== undefined && result['ok'].answer[0] !== undefined ? result['ok'].answer[0].cursor : 0.0), polarizationInfo));
      setVoteDate(result['ok'] !== undefined ? result['ok'].date : null);
    });
  }

  const putBallot = () : Promise<PutBallotError | null> => {
    if (cursorInfo === null) return Promise.resolve(null);
    return actor.putOpinionBallot(voteId, cursorInfo.value).then((result) => {
      return result['err'] ?? null;
    });
  }

  const refreshCursorInfo = (value: number) => {
    setCursorInfo(toCursorInfo(value, polarizationInfo));
  };

  useEffect(() => {
    refreshBallot();
  }, []);

	return (
    <div>
    {
      cursorInfo === null ? <></> :
      <div className={`flex flex-row justify-center items-center w-full transition duration-2000 ${triggerVote ? "opacity-0" : "opacity-100"}`}>
        <div className={`pl-6`}>
        {
          voteDate !== null ?
          <CursorBallot cursorInfo={cursorInfo} dateNs={voteDate} isLate={isLocked}/> :
          <CursorSlider
            cursor = { cursorInfo.value }
            polarizationInfo={ polarizationInfo }
            disabled={ triggerVote }
            setCursor={ refreshCursorInfo }
            onMouseUp={ () => { setCountdownVote(true)} }
            onMouseDown={ () => { setCountdownVote(false)} }
            isLate={isLocked}
          />
        }
        </div>
        <div>
          {
            voteDate !== null ?
            <div className="ml-2 w-4 h-4"> {/* @todo: setting a relative size does not seem to work here*/}
              <SvgButton onClick={() => setVoteDate(null)} disabled={false} hidden={false}>
                <ReturnIcon/>
              </SvgButton>
            </div> :
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
              <div className="flex flex-col items-center justify-center w-full">
                <SvgButton onClick={() => setTriggerVote(true)} disabled={triggerVote} hidden={false}>
                  <PutBallotIcon/>
                </SvgButton>
              </div>
            </UpdateProgress>
          }
        </div>
      </div>
    }
    </div>
	);
};

export default OpinionVote;
