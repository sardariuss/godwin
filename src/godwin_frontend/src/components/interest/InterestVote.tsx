import { InterestEnum, interestToEnum, enumToInterest } from "./InterestTypes";
import UpdateProgress                                   from "../UpdateProgress";
import InterestBallot                                   from "../interest/InterestBallot";
import SvgButton                                        from "../base/SvgButton";
import PutBallotIcon                                    from "../icons/PutBallotIcon";
import ArrowDownIcon                                    from "../icons/ArrowDownIcon";
import ArrowUpIcon                                      from "../icons/ArrowUpIcon";
import { ActorContext }                                 from "../../ActorContext"
import { putBallotErrorToString }                       from "../../utils";
import { PutBallotError, _SERVICE }                     from "../../../declarations/godwin_backend/godwin_backend.did";

import { ActorSubclass }                                from "@dfinity/agent";
import { useState, useEffect, useContext }              from "react";

type Props = {
  actor: ActorSubclass<_SERVICE>,
  voteId: bigint;
};

const InterestVote = ({actor, voteId}: Props) => {

  const {refreshBalance} = useContext(ActorContext);

  const countdownDurationMs = 5000;

  const [countdownVote, setCountdownVote] = useState<boolean>             (false);
  const [triggerVote,   setTriggerVote  ] = useState<boolean>             (false);
  const [voteDate,      setVoteDate     ] = useState<bigint | null>       (null);
  const [interest,      setInterest     ] = useState<InterestEnum | null> (null);

  const incrementCursorValue = () => {
    if (interest === InterestEnum.Neutral){
      setInterest(InterestEnum.Up);
      setCountdownVote(true);
    } else if (interest === InterestEnum.Down) {
      setInterest(InterestEnum.Neutral);
      setCountdownVote(false);
    }
  }

  const decrementCursorValue = () => {
    if (interest === InterestEnum.Neutral){
      setInterest(InterestEnum.Down);
      setCountdownVote(true);
    } else if (interest === InterestEnum.Up) {
      setInterest(InterestEnum.Neutral);
      setCountdownVote(false);
    }
  }

  const refreshBallot = () : Promise<void> => {
    return actor.getInterestBallot(voteId).then((result) => {
      setInterest(
        old => { return result['ok'] !== undefined && result['ok'].answer[0] !== undefined ? 
          interestToEnum(result['ok'].answer[0]) : old === null ? InterestEnum.Neutral : old});
      setVoteDate(result['ok'] !== undefined ? result['ok'].date : null);
    });
  }

  const putBallot = () : Promise<PutBallotError | null> => {
    if (interest === null || interest === InterestEnum.Neutral) throw new Error("Invalid interest");
    return actor.putInterestBallot(voteId, enumToInterest(interest)).then((result) => {
      refreshBalance();
      return result['err'] ?? null;
    });
  }

  useEffect(() => {
    refreshBallot();
  }, []);

	return (
    <div>
    {
      interest === null ? <></> :
      <div className="grid grid-cols-3 w-full py-2 content-center items-center">
        <div className={`w-full flex flex-col col-span-2 items-center justify-center content-center transition duration-2000 ${triggerVote ? "opacity-0" : "opacity-100"}`}>
          <div className={`w-10 flex -m-2 justify-center ${voteDate !== null ? "hidden" : ""}`}>
            <SvgButton onClick={ () => { incrementCursorValue(); } } disabled={triggerVote || interest === InterestEnum.Up}>
              <ArrowUpIcon/>
            </SvgButton>
          </div>
          <InterestBallot answer={interest} dateNs={voteDate}/>
          <div className={`w-10 flex -m-2 justify-center ${voteDate !== null ? "hidden" : ""}`}>
            <SvgButton onClick={ () => { decrementCursorValue(); } } disabled={triggerVote || interest === InterestEnum.Down}>
              <ArrowDownIcon/>
            </SvgButton>
          </div>
        </div>
        <div className={`col-span-1 justify-center`}>
          {
            voteDate !== null || interest === InterestEnum.Neutral ? 
              <></> :
              <UpdateProgress<PutBallotError> 
                delay_duration_ms={countdownDurationMs}
                update_function={putBallot}
                error_to_string={putBallotErrorToString}
                callback_function={refreshBallot}
                run_countdown={countdownVote}
                set_run_countdown={setCountdownVote}
                trigger_update={triggerVote}
                set_trigger_update={setTriggerVote}
                cost={BigInt(100_000_000)}
              >
                <div className={`flex flex-col items-center justify-center w-full`}>
                  <SvgButton 
                    onClick={() => setTriggerVote(true)}
                    disabled={false}
                    hidden={false}
                  >
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

export default InterestVote;
