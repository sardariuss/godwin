import { InterestEnum }                                               from "./InterestTypes";
import InterestDetailedBallot                                         from "./InterestDetailedBallot";
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
  VoteKind, voteKindToCandidVariant, toInterestKindAnswer, VoteView } from "../../utils";
import { getDocElementById }                                          from "../../utils/DocumentUtils";
import { PutBallotError, VoteData }                                   from "../../../declarations/godwin_sub/godwin_sub.did";

import React, { useState, useEffect, useContext }                     from "react";
import { createPortal }                                               from "react-dom";
import { Principal }                                                  from "@dfinity/principal";
import { fromNullable }                                               from "@dfinity/utils";

type Props = {
  sub: Sub,
  voteData: VoteData;
  allowVote: boolean;
  bottomPlaceholderId: string;
  rightPlaceholderId: string;
  question_id: bigint;
  principal: Principal;
  showHistory: boolean;
};

const InterestVote = ({sub, voteData, allowVote, principal, bottomPlaceholderId, rightPlaceholderId, question_id, showHistory}: Props) => {

  const {refreshBalance} = useContext(ActorContext);

  const countdownDurationMs = 3000;
  const voteKind = voteKindToCandidVariant(VoteKind.INTEREST);

  const [countdownVote, setCountdownVote] = useState<boolean>                                               (false                      );
  const [triggerVote,   setTriggerVote  ] = useState<boolean>                                               (false                      );
  const [ballot,        setBallot       ] = useState<RevealableBallot<InterestEnum> | undefined>            (getInterestBallot(voteData));
  const [interest,      setInterest     ] = useState<InterestEnum>                                          (InterestEnum.Neutral       );
  const [voteView,      setVoteView     ] = useState<VoteView>                                              (VoteView.LAST_BALLOT       );
  const [ballotHistory, setBallotHistory] = useState<[bigint, RevealableBallot<InterestEnum> | undefined][]>([]                         );
  
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
    return sub.actor.revealBallot(voteKind, principal, voteData.id).then((result) => {
      if (result['ok'] !== undefined){
        setBallot(unwrapRevealedInterestBallot(result['ok']));
      };
    });
  }

  const putBallot = () : Promise<PutBallotError | null> => {
    if (interest === InterestEnum.Neutral) throw new Error("Cannot put ballot: interest is neutral");
    return sub.actor.putBallot(voteKind, voteData.id, toInterestKindAnswer(interest)).then((result) => {
      refreshBalance();
      return result['err'] ?? null;
    });
  }

  const canVote = (voteData: VoteData) : boolean => {
    return allowVote && voteStatusToEnum(voteData.status) !== VoteStatusEnum.CLOSED;
  }

  const fetchBallotHistory = () => {
    sub.actor.queryVoterQuestionBallots(question_id, voteKind, principal).then((iteration_ballots) => {
      let history = iteration_ballots.map((ballot) : [bigint, RevealableBallot<InterestEnum> | undefined] => {
        let b = fromNullable(ballot[1]);
        return [ballot[0], (b !== undefined ? unwrapRevealedInterestBallot(b) : undefined)];
      });
      setBallotHistory(history);
    });
  }

  // Start the countdown if the interest is Up or Down, stop it if it is Neutral
  useEffect(() => {
    setCountdownVote(interest !== InterestEnum.Neutral);
  }, [interest]);

  useEffect(() => {
    setVoteView(ballot === undefined ? VoteView.VOTE : showHistory ? VoteView.BALLOT_HISTORY : VoteView.LAST_BALLOT);
  }, [ballot, showHistory]);

  useEffect(() => {
    if (showHistory) {
      fetchBallotHistory();
    }
  }, [showHistory]);

  return (
    <>
    {
      createPortal(
        <>
          { voteView === VoteView.LAST_BALLOT && ballot !== undefined ?
            <div className={`grid grid-cols-2 w-36 content-center items-center -mr-5`}>
              <div className={`w-full flex flex-col`}>
                <InterestBallot answer={ballot.answer} dateNs={ballot.date}/> 
                {
                  !canVote(voteData) ? <></> :
                  voteData.id !== ballot.vote_id ?
                    <div className={`text-sm text-blue-600 dark:text-blue-600 hover:text-blue-800 hover:dark:text-blue-400 hover:cursor-pointer font-bold`}
                      onClick={() => { setBallot(undefined); }}
                    > NEW </div> :
                  ballot.can_change ?
                    <div className="ml-2 w-4 h-4"> {/* @todo: setting a relative size does not seem to work here*/}
                      <SvgButton onClick={() => { setBallot(undefined); }} disabled={false} hidden={false}>
                        <ReturnIcon/>
                      </SvgButton>
                    </div> : <></>
                }
              </div>
            </div> : <></>
          }
        </>,
        getDocElementById(rightPlaceholderId)
      )
    }
    {
      createPortal(
        <>
          { voteView === VoteView.VOTE && canVote(voteData) ?
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
                      cost={sub.info.prices.interest_vote_price_e9s}
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
        getDocElementById(rightPlaceholderId)
      )
    }
    {
      createPortal(
        <>
          { 
            voteView === VoteView.BALLOT_HISTORY ?
            <ol className={`flex flex-col justify-center items-center space-y-2`}>
              {
                ballotHistory.reverse().map(([iteration, ballot], index) => (
                  ballot === undefined ? <></> :
                  <li className="w-full" key={index.toString()}>
                    <InterestDetailedBallot
                      sub={sub}
                      vote_id={ballot.vote_id}
                      iteration={iteration}
                      ballot={ballot}
                      principal={principal}
                    />
                  </li>
                ))
              }
            </ol> : <></>
          }
        </>,
        getDocElementById(bottomPlaceholderId)
      )
    }
  </>
	);
};

export default InterestVote;
