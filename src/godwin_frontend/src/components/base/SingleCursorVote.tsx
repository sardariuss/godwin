import { Result_7, Result_14 } from "../../../declarations/godwin_backend/godwin_backend.did";

import { putBallotErrorToString, PolarizationInfo, toCursorInfo, nsToStrDate } from "../../utils";
import ResetButton from "./ResetButton";
import { CursorSlider } from "./CursorSlider";
import UpdateProgress from "../UpdateProgress";

import { useState, useEffect } from "react";

type Props = {
  countdownDurationMs: number;
  polarizationInfo: PolarizationInfo;
  questionId: bigint;
  allowUpdateBallot: boolean;
  putBallot: (args_0: bigint, args_1: number) => Promise<Result_7>;
  getBallot: (args_0: bigint) => Promise<Result_14>;
};

// @todo: change the state of the buttons if the user already voted
const SingleCursorVote = ({countdownDurationMs, polarizationInfo, questionId, allowUpdateBallot, putBallot, getBallot}: Props) => {

  const [cursor, setCursor] = useState<number>(0.0);
  const [countdownVote, setCountdownVote] = useState<boolean>(false);
  const [triggerVote, setTriggerVote] = useState<boolean>(false);
  const [voteDate, setVoteDate] = useState<bigint | null>(null);

  useEffect(() => {
    getBallot(questionId).then((result: Result_14) => {
      if (result['ok'] !== undefined) {
        setCursor(result['ok'].answer);
        setVoteDate(result['ok'].date);
      }
    });
  }, []);

  const refreshBallotResult = (result: Result_7) : string => {
    if (result['ok'] !== undefined) {
      setCursor(result['ok'].answer);
      setVoteDate(result['ok'].date);
      return "";
    } else {
      setVoteDate(null);
      return putBallotErrorToString(result['err']);
    }
  }

	return (
    <div className="grow w-full">
    {
      voteDate !== null ?
        <div className="flex flex-col items-center w-full grow justify-items-center">
            <div className="text-2xl">
              {toCursorInfo(cursor, polarizationInfo).symbol}
            </div>
            <div className="text-xs font-extralight">
              {cursor.toFixed(2)}
            </div>
            <div className="flex flex-row gap-x-1 items-center justify-items-center align-center">
              <div className="text-xs font-extralight dark:text-gray-400 whitespace-nowrap">
                { nsToStrDate(voteDate) }
              </div>
              {
                allowUpdateBallot ?
                <div className="w-4 h-4 dark:fill-gray-400 hover:dark:fill-white hover:cursor-pointer" onClick={(e) => { console.log(triggerVote); setVoteDate(null); }}>
                  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 96 960 960"><path d="M280 856v-60h289q70 0 120.5-46.5T740 634q0-69-50.5-115.5T569 472H274l114 114-42 42-186-186 186-186 42 42-114 114h294q95 0 163.5 64T800 634q0 94-68.5 158T568 856H280Z"/></svg>
                </div> :
                <div className="w-4 h-4 dark:fill-gray-400">
                  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 96 960 960"><path d="M220 976q-24.75 0-42.375-17.625T160 916V482q0-24.75 17.625-42.375T220 422h70v-96q0-78.85 55.606-134.425Q401.212 136 480.106 136T614.5 191.575Q670 247.15 670 326v96h70q24.75 0 42.375 17.625T800 482v434q0 24.75-17.625 42.375T740 976H220Zm0-60h520V482H220v434Zm260.168-140Q512 776 534.5 753.969T557 701q0-30-22.668-54.5t-54.5-24.5Q448 622 425.5 646.5t-22.5 55q0 30.5 22.668 52.5t54.5 22ZM350 422h260v-96q0-54.167-37.882-92.083-37.883-37.917-92-37.917Q426 196 388 233.917 350 271.833 350 326v96ZM220 916V482v434Z"/></svg>
                </div>
              }
            </div>
        </div> :
        <div className="grid grid-cols-8 items-center w-full justify-items-center">
          <div className={`col-start-2 col-span-1 justify-center transition duration-2000 ${triggerVote ? "opacity-0" : "opacity-100"}`}>
            <ResetButton 
              reset={ () => { setCursor(0.0); setCountdownVote(false); }}
              disabled={ triggerVote }
            />
          </div>
          <div className={`col-span-4 justify-center transition duration-2000 ${triggerVote ? "opacity-0" : "opacity-100"}`}>
            <CursorSlider
              cursor={ cursor }
              polarizationInfo = { polarizationInfo }
              disabled={ triggerVote }
              setCursor={ setCursor }
              onMouseUp={ () => { setCountdownVote(true)} }
              onMouseDown={ () => { setCountdownVote(false)} }
            />
          </div>
          <div className="col-span-1 justify-center">
            <UpdateProgress<Result_7> 
              delay_duration_ms={countdownDurationMs}
              update_function={() => putBallot(questionId, cursor)}
              callback_function={(res: Result_7) => { return refreshBallotResult(res); } }
              run_countdown={countdownVote}
              set_run_countdown={setCountdownVote}
              trigger_update={triggerVote}
              set_trigger_update={setTriggerVote}
            >
              <div className="flex flex-col items-center justify-center w-full">
                <div className="w-full dark:fill-gray-400 hover:dark:fill-white hover:cursor-pointer" onClick={(e) => setTriggerVote(true)}>
                  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 96 960 960"><path d="M180 976q-24 0-42-18t-18-42V718l135-149 43 43-118 129h600L669 615l43-43 128 146v198q0 24-18 42t-42 18H180Zm0-60h600V801H180v115Zm262-245L283 512q-19-19-17-42.5t20-41.5l212-212q16.934-16.56 41.967-17.28Q565 198 583 216l159 159q17 17 17.5 40.5T740 459L528 671q-17 17-42 18t-44-18Zm249-257L541 264 333 472l150 150 208-208ZM180 916V801v115Z"/></svg>
                </div>
              </div>
            </UpdateProgress>
          </div>
        </div>
    }
    </div>
	);
};

export default SingleCursorVote;
