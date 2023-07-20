import { InterestEnum, interestToEnum, enumToInterest } from "./InterestTypes";
import UpdateProgress                                   from "../UpdateProgress";
import InterestBallot                                   from "../interest/InterestBallot";
import SvgButton                                        from "../base/SvgButton";
import PutBallotIcon                                    from "../icons/PutBallotIcon";
import ArrowDownIcon                                    from "../icons/ArrowDownIcon";
import ArrowUpIcon                                      from "../icons/ArrowUpIcon";
import { ActorContext, Sub }                            from "../../ActorContext"
import { putBallotErrorToString }                       from "../../utils";
import { getDocElementById }                            from "../../utils/DocumentUtils";
import { PutBallotError, VoteData }                     from "../../../declarations/godwin_sub/godwin_sub.did";

import React, { useState, useEffect, useContext }       from "react";
import { createPortal }                                 from 'react-dom';

const unwrapBallotDate = (vote_data: VoteData) : bigint  | undefined => {
  if (vote_data.user_ballot['INTEREST'] !== undefined){
		return vote_data.user_ballot['INTEREST'].date;
	}
  return undefined;
}

const unwrapBallotAnswer = (vote_data: VoteData) : InterestEnum => {
  if (vote_data.user_ballot['INTEREST'] !== undefined){
		return interestToEnum(vote_data.user_ballot['INTEREST'].answer);
	}
  return InterestEnum.Neutral;
}

type Props = {
  sub: Sub,
  voteData: VoteData;
  voteElementId: string;
  ballotElementId: string;
};

const InterestVote = ({sub, voteData, voteElementId, ballotElementId}: Props) => {

  const {refreshBalance} = useContext(ActorContext);

  const countdownDurationMs = 5000;

  const [countdownVote, setCountdownVote] = useState<boolean>           (false                       );
  const [triggerVote,   setTriggerVote  ] = useState<boolean>           (false                       );
  const [voteDate,      setVoteDate     ] = useState<bigint | undefined>(unwrapBallotDate(voteData)  );
  const [interest,      setInterest     ] = useState<InterestEnum>      (unwrapBallotAnswer(voteData));

  const incrementCursorValue = () => {
    if (interest === InterestEnum.Neutral){
      setInterest(InterestEnum.Up);
    } else if (interest === InterestEnum.Down) {
      setInterest(InterestEnum.Neutral);
    }
  }

  const decrementCursorValue = () => {
    if (interest === InterestEnum.Neutral){
      setInterest(InterestEnum.Down);
    } else if (interest === InterestEnum.Up) {
      setInterest(InterestEnum.Neutral);
    }
  }

  const refreshBallot = () : Promise<void> => {
    return sub.actor.getInterestBallot(voteData.id).then((result) => {
      if (result['ok'] !== undefined){
        if (result['ok'].answer[0] !== undefined){
          setInterest(interestToEnum(result['ok'].answer[0]));
        }
        if (result['ok'].date !== undefined){
          setVoteDate(result['ok'].date);
        }
      }
    });
  }

  const putBallot = () : Promise<PutBallotError | null> => {
    if (interest === InterestEnum.Neutral) throw new Error("Invalid interest");
    return sub.actor.putInterestBallot(voteData.id, enumToInterest(interest)).then((result) => {
      refreshBalance();
      return result['err'] ?? null;
    });
  }

  useEffect(() => {
    setCountdownVote(interest !== InterestEnum.Neutral);
  }, [interest]);

  return (
    <>
    {
      createPortal(
        <>
          { voteDate !== undefined ?
              <InterestBallot answer={interest} dateNs={voteDate}/> : <></>
          }
        </>,
        getDocElementById(ballotElementId)
      )
    }
    {
      createPortal(
        <>
          { voteDate === undefined ?
            <div className="grid grid-cols-3 w-full content-center items-center">
              <div className={`w-full flex flex-col col-span-2 items-center justify-center content-center transition duration-2000 
                ${triggerVote ? "opacity-0" : "opacity-100"}`}>
                <div className={`w-10 flex -m-2 justify-center ${voteDate !== undefined ? "hidden" : ""}`}>
                  <SvgButton onClick={ () => { incrementCursorValue(); } } disabled={triggerVote || interest === InterestEnum.Up}>
                    <ArrowUpIcon/>
                  </SvgButton>
                </div>
                <InterestBallot answer={interest} dateNs={voteDate}/>
                <div className={`w-10 flex -m-2 justify-center ${voteDate !== undefined ? "hidden" : ""}`}>
                  <SvgButton onClick={ () => { decrementCursorValue(); } } disabled={triggerVote || interest === InterestEnum.Down}>
                    <ArrowDownIcon/>
                  </SvgButton>
                </div>
              </div>
              <div className={`col-span-1 justify-center`}>
                {
                  voteDate !== undefined || interest === InterestEnum.Neutral ? 
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
                      <SvgButton 
                        onClick={() => setTriggerVote(true)}
                        disabled={false}
                        hidden={false}
                      >
                        <div className="w-6 h-6">
                          <PutBallotIcon/>
                        </div>
                      </SvgButton>
                    </UpdateProgress>
                }
              </div>
            </div> : <></>
          }
        </>,
        getDocElementById(voteElementId)
      )
    }
  </>
	);
};

export default InterestVote;
