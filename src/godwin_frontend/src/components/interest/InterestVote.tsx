import { InterestEnum, interestToEnum, enumToInterest } from "./InterestTypes";
import UpdateProgress                                   from "../UpdateProgress";
import InterestBallot                                   from "../interest/InterestBallot";
import SvgButton                                        from "../base/SvgButton";
import PutBallotIcon                                    from "../icons/PutBallotIcon";
import ArrowDownIcon                                    from "../icons/ArrowDownIcon";
import ArrowUpIcon                                      from "../icons/ArrowUpIcon";
import ReturnIcon                                       from "../icons/ReturnIcon";
import { ActorContext, Sub }                            from "../../ActorContext"
import { putBallotErrorToString, VoteStatusEnum,
  voteStatusToEnum }                                    from "../../utils";
import { getDocElementById }                            from "../../utils/DocumentUtils";
import { PutBallotError, VoteData, Interest, 
  RevealedInterestBallot }                              from "../../../declarations/godwin_sub/godwin_sub.did";

import React, { useState, useEffect, useContext }       from "react";
import { createPortal }                                 from 'react-dom';
import { fromNullable }                                 from "@dfinity/utils";

const unwrapBallot = (vote_data: VoteData) : RevealedInterestBallot | undefined => {
  let vote_kind_ballot = fromNullable(vote_data.user_ballot);
  if (vote_kind_ballot !== undefined && vote_kind_ballot['INTEREST'] !== undefined){
    return vote_kind_ballot['INTEREST'];
  }
  return undefined;
}

const getBallotInterest = (ballot: RevealedInterestBallot) : InterestEnum | undefined => {
  let answer : Interest | undefined = fromNullable(ballot.answer);
  if (answer !== undefined){
    return interestToEnum(answer);
  }
  return undefined;
}

type Props = {
  sub: Sub,
  voteData: VoteData;
  allowVote: boolean;
  votePlaceholderId: string;
  ballotPlaceholderId: string;
};

const InterestVote = ({sub, voteData, allowVote, votePlaceholderId, ballotPlaceholderId}: Props) => {

  const {refreshBalance} = useContext(ActorContext);

  const countdownDurationMs = 3000;

  const [countdownVote, setCountdownVote] = useState<boolean>                           (false                               );
  const [triggerVote,   setTriggerVote  ] = useState<boolean>                           (false                               );
  const [ballot,        setBallot       ] = useState<RevealedInterestBallot | undefined>(unwrapBallot(voteData)              );
  const [interest,      setInterest     ] = useState<InterestEnum>                      (InterestEnum.Neutral                );
  const [showVote,      setShowVote     ] = useState<boolean>                           (unwrapBallot(voteData) === undefined);
  
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
        setBallot(result['ok']);
        setShowVote(false);
      };
    });
  }

  const putBallot = () : Promise<PutBallotError | null> => {
    if (interest === InterestEnum.Neutral) throw new Error("Cannot put ballot: interest is neutral");
    return sub.actor.putInterestBallot(voteData.id, enumToInterest(interest)).then((result) => {
      refreshBalance();
      return result['err'] ?? null;
    });
  }

  const canVote = (voteData: VoteData) : boolean => {
    return allowVote && voteStatusToEnum(voteData.status) !== VoteStatusEnum.CLOSED;
  }

  useEffect(() => {
    setCountdownVote(interest !== InterestEnum.Neutral);
  }, [interest]);

  return (
    <>
    {
      createPortal(
        <>
          { !showVote && ballot !== undefined ?
            <div className={`grid grid-cols-3 w-36 content-center items-center pr-5`}>
              <div className={`w-full flex flex-col col-span-2`}>
                <InterestBallot answer={getBallotInterest(ballot)} dateNs={ballot.date}/> 
                {
                  !canVote(voteData) ? <></> :
                  voteData.id !== ballot.vote_id ?
                    <div className={`text-sm text-blue-600 dark:text-blue-600 hover:text-blue-800 hover:dark:text-blue-400 hover:cursor-pointer font-bold`}
                      onClick={() => { setShowVote(true); }}
                    > NEW </div> :
                  ballot.can_change ?
                    <div className="ml-2 w-4 h-4"> {/* @todo: setting a relative size does not seem to work here*/}
                      <SvgButton onClick={() => { setShowVote(true); }} disabled={false} hidden={false}>
                        <ReturnIcon/>
                      </SvgButton>
                    </div> : <></>
                }
              </div>
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
            <div className={`grid grid-cols-3 w-36 content-center items-center pr-5`}>
              <div className={`w-full flex flex-col col-span-2 items-center justify-center content-center transition duration-2000 
                ${triggerVote ? "opacity-0" : "opacity-100"}`}>
                <div className={`w-10 flex -m-2 justify-center`}>
                  <SvgButton onClick={ () => { incrementCursorValue(); } } disabled={triggerVote || interest === InterestEnum.Up}>
                    <ArrowUpIcon/>
                  </SvgButton>
                </div>
                <InterestBallot answer={interest} dateNs={undefined}/>
                <div className={`w-10 flex -m-2 justify-center`}>
                  <SvgButton onClick={ () => { decrementCursorValue(); } } disabled={triggerVote || interest === InterestEnum.Down}>
                    <ArrowDownIcon/>
                  </SvgButton>
                </div>
              </div>
              <div className={`col-span-1 justify-center`}>
                {
                  interest === InterestEnum.Neutral ? <></> :
                    <UpdateProgress<PutBallotError> 
                      delay_duration_ms={countdownDurationMs}
                      update_function={putBallot}
                      error_to_string={putBallotErrorToString}
                      callback_function={refreshBallot}
                      run_countdown={countdownVote}
                      set_run_countdown={setCountdownVote}
                      trigger_update={triggerVote}
                      set_trigger_update={setTriggerVote}
                      cost={sub.info.prices.interest_vote_price_e8s}
                    >
                      <SvgButton 
                        onClick={() => setTriggerVote(true)}
                        disabled={false}
                        hidden={false}
                      >
                        <div className="w-6 h-6 m-1">
                          <PutBallotIcon/>
                        </div>
                      </SvgButton>
                    </UpdateProgress>
                }
              </div>
            </div> : <></>
          }
        </>,
        getDocElementById(votePlaceholderId)
      )
    }
  </>
	);
};

export default InterestVote;
