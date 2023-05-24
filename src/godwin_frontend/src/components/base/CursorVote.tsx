import { Result_7, Result_15 } from "../../../declarations/godwin_backend/godwin_backend.did";

import { putBallotErrorToString, PolarizationInfo, CursorInfo, toCursorInfo } from "../../utils";
import ResetButton from "./ResetButton";
import { CursorSlider } from "./CursorSlider";
import UpdateProgress from "../UpdateProgress";
import Ballot from "../votes/Ballot";

import { useState, useEffect } from "react";

type Props = {
  countdownDurationMs: number;
  polarizationInfo: PolarizationInfo;
  voteId: bigint;
  putBallot: (args_0: bigint, args_1: number) => Promise<Result_7>;
  getBallot: (args_0: bigint) => Promise<Result_15>;
};

const CursorVote = ({countdownDurationMs, polarizationInfo, voteId, putBallot, getBallot}: Props) => {

  const [countdownVote, setCountdownVote] = useState<boolean>(false);
  const [triggerVote, setTriggerVote] = useState<boolean>(false);
  const [voteDate, setVoteDate] = useState<bigint | null>(null);
  const [cursorInfo, setCursorInfo] = useState<CursorInfo | undefined>(undefined);

  useEffect(() => {
    getBallot(voteId).then((result: Result_15) => {
      if (result['ok'] !== undefined) {
        refreshCursorInfo(result['ok'].answer);
        setVoteDate(result['ok'].date);
      } else {
        refreshCursorInfo(0.0);
        setVoteDate(null);
      }
    });
  }, []);

  const refreshBallotResult = (result: Result_7) : string => {
    if (result['ok'] !== undefined) {
      refreshCursorInfo(result['ok'].answer);
      setVoteDate(result['ok'].date);
      return "";
    } else {
      setVoteDate(null);
      return putBallotErrorToString(result['err']);
    }
  }

  const refreshCursorInfo = (value: number) => {
    setCursorInfo(toCursorInfo(value, polarizationInfo));
  };

	return (
    <div className="w-full">
    {
      cursorInfo === undefined ? <></> :
      voteDate !== null ?
      <div className="mb-3">
        <Ballot cursorInfo={cursorInfo} dateNs={voteDate}/>
      </div> :
      <div className="grid grid-cols-8 items-center w-full justify-items-center">
        <div className={`col-start-2 col-span-1 justify-center transition duration-2000 ${triggerVote ? "opacity-0" : "opacity-100"}`}>
          <ResetButton 
            reset={ () => { refreshCursorInfo(0.0); setCountdownVote(false); }}
            disabled={ triggerVote }
          />
        </div>
        <div className={`col-span-4 justify-center transition duration-2000 ${triggerVote ? "opacity-0" : "opacity-100"}`}>
          <CursorSlider
            cursor = { cursorInfo.value }
            polarizationInfo={ polarizationInfo }
            disabled={ triggerVote }
            setCursor={ refreshCursorInfo }
            onMouseUp={ () => { setCountdownVote(true)} }
            onMouseDown={ () => { setCountdownVote(false)} }
          />
        </div>
        <div className="col-span-1 justify-center">
          <UpdateProgress<Result_7> 
            delay_duration_ms={countdownDurationMs}
            update_function={() => putBallot(voteId, cursorInfo.value)}
            callback_function={(res: Result_7) => { return refreshBallotResult(res); } }
            run_countdown={countdownVote}
            set_run_countdown={setCountdownVote}
            trigger_update={triggerVote}
            set_trigger_update={setTriggerVote}
          >
            <div className="flex flex-col items-center justify-center w-full">
              <button className="w-full button-svg" onClick={(e) => setTriggerVote(true)} disabled={triggerVote}>
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 96 960 960"><path d="M180 976q-24 0-42-18t-18-42V718l135-149 43 43-118 129h600L669 615l43-43 128 146v198q0 24-18 42t-42 18H180Zm0-60h600V801H180v115Zm262-245L283 512q-19-19-17-42.5t20-41.5l212-212q16.934-16.56 41.967-17.28Q565 198 583 216l159 159q17 17 17.5 40.5T740 459L528 671q-17 17-42 18t-44-18Zm249-257L541 264 333 472l150 150 208-208ZM180 916V801v115Z"/></svg>
              </button>
            </div>
          </UpdateProgress>
        </div>
      </div>
    }
    </div>
	);
};

export default CursorVote;
