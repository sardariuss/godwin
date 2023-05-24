import { Result_7, Result_15, _SERVICE } from "../../../declarations/godwin_backend/godwin_backend.did";

import { putBallotErrorToString, CursorInfo, toCursorInfo } from "../../utils";
import UpdateProgress from "../UpdateProgress";
import Ballot from "../votes/Ballot";
import { ActorSubclass } from "@dfinity/agent";

import CONSTANTS from "../../Constants";

import { useState, useEffect } from "react";

type Props = {
  actor: ActorSubclass<_SERVICE>,
  voteId: bigint;
};

const InterestVote = ({actor, voteId}: Props) => {

  const COUNTDOWN_DURATION_MS = 3000;

  const [countdownVote, setCountdownVote] = useState<boolean>(false);
  const [triggerVote, setTriggerVote] = useState<boolean>(false);
  const [voteDate, setVoteDate] = useState<bigint | null>(null);
  const [cursorInfo, setCursorInfo] = useState<CursorInfo | undefined>(undefined);

  useEffect(() => {
    actor.getInterestBallot(voteId).then((result: Result_15) => {
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
    setCursorInfo(toCursorInfo(value, CONSTANTS.INTEREST_INFO));
  };

  const incrementCursorValue = () => {
    if (cursorInfo === undefined) return;
    if (cursorInfo.value == 1.0) {
      return;
    } else {
      let new_value = cursorInfo.value + 1.0;
      refreshCursorInfo(new_value);
      if (new_value == 1.0){
        setCountdownVote(true);
      } else {
        setCountdownVote(false);
      }
    }
  }

  const decrementCursorValue = () => {
    if (cursorInfo === undefined) return;
    if (cursorInfo.value == -1.0) {
      return;
    } else {
      let new_value = cursorInfo.value - 1.0;
      refreshCursorInfo(new_value);
      if (new_value == -1.0){
        setCountdownVote(true);
      } else {
        setCountdownVote(false);
      }
    }
  }

	return (
    <div>
      {
      cursorInfo === undefined ? <></> :
        voteDate !== null ?
          <div className="w-full">
            <Ballot cursorInfo={cursorInfo} dateNs={voteDate}/>
          </div> :
          <div className="grid grid-cols-3 items-center w-full justify-items-center">
            <div className={`w-full flex flex-col col-span-2 items-center justify-center content-center transition duration-2000 ${triggerVote ? "opacity-0" : "opacity-100"}`}>
              <button className={`w-full flex button-svg justify-center -m-1.5 rotate-180`}
                disabled={triggerVote || cursorInfo.value == 1.0} 
                onClick={ () => { incrementCursorValue(); } }
              >
                <svg className="w-10" xmlns="http://www.w3.org/2000/svg" viewBox="0 96 960 960"><path d="M480 696 280 497h400L480 696Z"/></svg>
              </button>
              <div className="text-xs">
                {cursorInfo.name}
              </div>
              <div className="text-xl">
                {cursorInfo.symbol}
              </div>
              <button className={`w-full flex button-svg justify-center -m-1.5`}
                disabled={triggerVote || cursorInfo.value == -1.0} 
                onClick={ () => { decrementCursorValue(); } }
            >
                <svg className="w-10" xmlns="http://www.w3.org/2000/svg" viewBox="0 96 960 960"><path d="M480 696 280 497h400L480 696Z"/></svg>
              </button>
            </div>
            <div className="col-span-1 justify-center">
              <UpdateProgress<Result_7> 
                delay_duration_ms={COUNTDOWN_DURATION_MS}
                update_function={() => actor.putInterestBallot(voteId, cursorInfo.value)}
                callback_function={(res: Result_7) => { return refreshBallotResult(res); } }
                run_countdown={countdownVote}
                set_run_countdown={setCountdownVote}
                trigger_update={triggerVote}
                set_trigger_update={setTriggerVote}
              >
                <div className="flex flex-col items-center justify-center w-full">
                  <button className="w-full button-svg" onClick={(e) => setTriggerVote(true)} disabled={cursorInfo.value === 0.0} hidden={cursorInfo.value === 0.0}>
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

export default InterestVote;
