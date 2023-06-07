import UpdateProgress                                                           from "../UpdateProgress";
import InterestBallot                                                           from "../ballots/InterestBallot";
import SvgButton                                                                from "../base/SvgButton";
import LockIcon                                                                 from "../icons/LockIcon";
import PutBallotIcon                                                            from "../icons/PutBallotIcon";
import ArrowDownIcon                                                            from "../icons/ArrowDownIcon";
import ArrowUpIcon                                                              from "../icons/ArrowUpIcon";
import { ActorContext }                                                         from "../../ActorContext"
import { putBallotErrorToString, InterestEnum, interestToEnum, enumToInterest } from "../../utils";
import { PutBallotError, _SERVICE }                                             from "../../../declarations/godwin_backend/godwin_backend.did";

import { ActorSubclass }                                                        from "@dfinity/agent";
import { useState, useEffect, useContext }                                      from "react";

type Props = {
  actor: ActorSubclass<_SERVICE>,
  voteId: bigint;
};

const InterestVote = ({actor, voteId}: Props) => {

  const {refreshBalance} = useContext(ActorContext);

  const countdownDurationMs = 3000;

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
      setInterest(result['ok'] !== undefined && result['ok'].answer[0] !== undefined ? interestToEnum(result['ok'].answer[0]) : InterestEnum.Neutral);
      setVoteDate(result['ok'] !== undefined ? result['ok'].date : null);
    });
  }

  const putBallot = () : Promise<PutBallotError | null> => {
    if (interest === null) return Promise.resolve(null);
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
      <div className="grid grid-cols-3 items-center w-full justify-items-center">
        <div className={`w-full flex flex-col col-span-2 items-center justify-center content-center transition duration-2000 ${triggerVote ? "opacity-0" : "opacity-100"}`}>
          <div className={`w-full flex justify-center -m-1.5 ${voteDate !== null ? "hidden" : ""}`}>
            <SvgButton onClick={ () => { incrementCursorValue(); } } disabled={triggerVote || interest === InterestEnum.Up}>
              <ArrowUpIcon/>
            </SvgButton>
          </div>
          <InterestBallot answer={interest} dateNs={voteDate}/>
          <div className={`w-full flex justify-center -m-1.5 ${voteDate !== null ? "hidden" : ""}`}>
            <SvgButton onClick={ () => { decrementCursorValue(); } } disabled={triggerVote || interest === InterestEnum.Down}>
              <ArrowDownIcon/>
            </SvgButton>
          </div>
        </div>
        <div className={`col-span-1 justify-center`}>
          {
            voteDate !== null ? 
              <div className="w-1/2 icon-svg">
                <LockIcon/>
              </div> :
              <UpdateProgress<PutBallotError> 
                delay_duration_ms={countdownDurationMs}
                update_function={putBallot}
                error_to_string={putBallotErrorToString}
                callback_function={refreshBallot}
                run_countdown={countdownVote}
                set_run_countdown={setCountdownVote}
                trigger_update={triggerVote}
                set_trigger_update={setTriggerVote}
              >
                <div className={`flex flex-col items-center justify-center w-full`}>
                  <SvgButton 
                    onClick={() => setTriggerVote(true)}
                    disabled={interest === InterestEnum.Neutral}
                    hidden={interest === InterestEnum.Neutral}
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
