import { InterestEnum }                                               from "./InterestTypes";
import UpdateProgress                                                 from "../UpdateProgress";
import InterestBallot                                                 from "../interest/InterestBallot";
import SvgButton                                                      from "../base/SvgButton";
import PutBallotIcon                                                  from "../icons/PutBallotIcon";
import ArrowDownIcon                                                  from "../icons/ArrowDownIcon";
import ArrowUpIcon                                                    from "../icons/ArrowUpIcon";
import ReturnIcon                                                     from "../icons/ReturnIcon";
import { ActorContext, Sub }                                          from "../../ActorContext"
import { putBallotErrorToString, VoteStatusEnum, voteStatusToEnum, 
  RevealableBallot, unwrapRevealedInterestBallot, getInterestBallot,
  VoteKind, voteKindToCandidVariant, toInterestKindAnswer }           from "../../utils";
import { getDocElementById }                                          from "../../utils/DocumentUtils";
import { PutBallotError, VoteData }                                   from "../../../declarations/godwin_sub/godwin_sub.did";

import React, { useState, useEffect, useContext }                     from "react";
import { createPortal }                                               from "react-dom";
import { Principal }                                                  from "@dfinity/principal";

type Props = {
  sub: Sub,
  voteData: VoteData;
  allowVote: boolean;
  votePlaceholderId: string;
  ballotPlaceholderId: string;
  principal: Principal;
};

const InterestVote = ({sub, voteData, allowVote, principal, votePlaceholderId, ballotPlaceholderId}: Props) => {

  const {refreshBalance} = useContext(ActorContext);

  const countdownDurationMs = 3000;

  const [countdownVote, setCountdownVote] = useState<boolean>                                   (false                      );
  const [triggerVote,   setTriggerVote  ] = useState<boolean>                                   (false                      );
  const [ballot,        setBallot       ] = useState<RevealableBallot<InterestEnum> | undefined>(getInterestBallot(voteData));
  const [interest,      setInterest     ] = useState<InterestEnum>                              (InterestEnum.Neutral       );
  const [showVote,      setShowVote     ] = useState<boolean>                                   (false                      );
  
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
    return sub.actor.revealBallot(voteKindToCandidVariant(VoteKind.INTEREST), principal, voteData.id).then((result) => {
      if (result['ok'] !== undefined){
        setBallot(unwrapRevealedInterestBallot(result['ok']));
      };
    });
  }

  const putBallot = () : Promise<PutBallotError | null> => {
    if (interest === InterestEnum.Neutral) throw new Error("Cannot put ballot: interest is neutral");
    return sub.actor.putBallot(voteKindToCandidVariant(VoteKind.INTEREST), voteData.id, toInterestKindAnswer(interest)).then((result) => {
      refreshBalance();
      return result['err'] ?? null;
    });
  }

  const canVote = (voteData: VoteData) : boolean => {
    return allowVote && voteStatusToEnum(voteData.status) !== VoteStatusEnum.CLOSED;
  }

  // Start the countdown if the interest is Up or Down, stop it if it is Neutral
  useEffect(() => {
    setCountdownVote(interest !== InterestEnum.Neutral);
  }, [interest]);

  // Show the vote if the ballot is undefined, else show the ballot
  useEffect(() => {
    setShowVote(ballot === undefined);
  }, [ballot]);

  return (
    <>
    {
      createPortal(
        <>
          { !showVote && ballot !== undefined ?
            <div className={`grid grid-cols-2 w-36 content-center items-center -mr-5`}>
              <div className={`w-full flex flex-col`}>
                <InterestBallot answer={ballot.answer} dateNs={ballot.date}/> 
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
            <div className={`grid grid-cols-2 w-32 content-center items-center py-2 -mr-5`}>
              <div className={`w-full flex flex-col items-center justify-center content-center transition duration-2000
                ${triggerVote ? "opacity-0" : "opacity-100"}`}>
                <div className={`w-6`}>
                  <SvgButton onClick={ () => { incrementCursorValue(); } } disabled={triggerVote || interest === InterestEnum.Up}>
                    <ArrowUpIcon/>
                  </SvgButton>
                </div>
                <InterestBallot answer={interest} dateNs={undefined}/>
                <div className={`w-6`}>
                  <SvgButton onClick={ () => { decrementCursorValue(); } } disabled={triggerVote || interest === InterestEnum.Down}>
                    <ArrowDownIcon/>
                  </SvgButton>
                </div>
              </div>
              <div className={`justify-center -ml-5`}>
                {
                  interest === InterestEnum.Neutral ? <></> :
                    <UpdateProgress<PutBallotError> 
                      delay_duration_ms={countdownDurationMs}
                      update_function={putBallot}
                      error_to_string={putBallotErrorToString}
                      callback_success={refreshBallot}
                      run_countdown={countdownVote}
                      set_run_countdown={setCountdownVote}
                      trigger_update={triggerVote}
                      set_trigger_update={setTriggerVote}
                      cost={sub.info.prices.interest_vote_price_e8s}
                    >
                      <SvgButton onClick={() => setTriggerVote(true)}>
                        <PutBallotIcon/>
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
