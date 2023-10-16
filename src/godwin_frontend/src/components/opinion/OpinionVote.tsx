import CursorBallot                                            from "../base/CursorBallot";
import { CursorSlider }                                        from "../base/CursorSlider";
import UpdateProgress                                          from "../UpdateProgress";
import SvgButton                                               from "../base/SvgButton";
import CertifiedIcon                                           from "../icons/CertifiedIcon";
import ReturnIcon                                              from "../icons/ReturnIcon";
import PutBallotIcon                                           from "../icons/PutBallotIcon";
import { putBallotErrorToString, VoteStatusEnum, voteStatusToEnum, RevealableBallot,
  getOpinionBallot, VoteKind, voteKindToCandidVariant, toOpinionKindAnswer,
  unwrapRevealedOpinionBallot, toOptCursorInfo, VoteView }     from "../../utils";
import { nsToStrDate }                                         from "../../utils/DateUtils";
import { getDocElementById }                                   from "../../utils/DocumentUtils";
import CONSTANTS                                               from "../../Constants";
import { Sub }                                                 from "../../ActorContext";
import { PutBallotError, VoteData, Cursor, OpinionAnswer }     from "../../../declarations/godwin_sub/godwin_sub.did";
import React, { useState, useEffect }                          from "react";
import { createPortal }                                        from "react-dom";
import { fromNullable }                                        from "@dfinity/utils";
import { Principal }                                           from "@dfinity/principal";

type Props = {
  sub: Sub;
  voteData: VoteData;
  allowVote: boolean;
  onOpinionChange?: () => void;
  bottomPlaceholderId: string;
  rightPlaceholderId: string;
  question_id: bigint;
  principal: Principal;
  showHistory: boolean;
};

const OpinionVote = ({sub, voteData, allowVote, onOpinionChange, bottomPlaceholderId, rightPlaceholderId, question_id, principal, showHistory}: Props) => {

  const COUNTDOWN_DURATION_MS = 0;
  const voteKind = voteKindToCandidVariant(VoteKind.OPINION);

  const [countdownVote, setCountdownVote] = useState<boolean>                                                (false                     );
  const [triggerVote,   setTriggerVote  ] = useState<boolean>                                                (false                     );
  const [ballot,        setBallot       ] = useState<RevealableBallot<OpinionAnswer> | undefined>            (getOpinionBallot(voteData));
  const [cursor,        setCursor       ] = useState<Cursor>                                                 (0.0                       );
  const [voteView,      setVoteView     ] = useState<VoteView>                                               (VoteView.LAST_BALLOT      );
  const [ballotHistory, setBallotHistory] = useState<[bigint, RevealableBallot<OpinionAnswer> | undefined][]>([]                        );

  const refreshBallot = () : Promise<void> => {
    return sub.actor.revealBallot(voteKind, principal, voteData.id).then((result) => {
      if (result['ok'] !== undefined){
        setBallot(unwrapRevealedOpinionBallot(result['ok']));
      };
    });
  }

  const putBallot = () : Promise<PutBallotError | null> => {
    return sub.actor.putBallot(voteKind, voteData.id, toOpinionKindAnswer(cursor)).then((result) => {
      if (result['ok'] !== undefined){
        onOpinionChange?.();
      };
      return result['err'] ?? null;
    });
  }

  const isLateBallot = (ballot: RevealableBallot<OpinionAnswer>) : boolean => {
    if (ballot.answer !== undefined){
      return fromNullable(ballot.answer.late_decay) !== undefined;
    }
    return false;
  }

  const isLateVote = (voteData: VoteData) : boolean => {
    return voteStatusToEnum(voteData.status) === VoteStatusEnum.LOCKED;
  }

  const canVote = (voteData: VoteData) : boolean => {
    return allowVote && voteStatusToEnum(voteData.status) !== VoteStatusEnum.CLOSED;
  }

  const fetchBallotHistory = () => {
    sub.actor.queryVoterQuestionBallots(question_id, voteKind, principal).then((iteration_ballots) => {
      let history = iteration_ballots.map((ballot) : [bigint, RevealableBallot<OpinionAnswer> | undefined] => {
        let b = fromNullable(ballot[1]);
        return [ballot[0], (b !== undefined ? unwrapRevealedOpinionBallot(b) : undefined)];
      });
      setBallotHistory(history);
    });
  }

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
          { 
            voteView === VoteView.LAST_BALLOT && ballot !== undefined ?
            <div className={`flex flex-row justify-center items-center w-32 pr-10`}>
              <CursorBallot
                cursorInfo={ toOptCursorInfo(ballot.answer?.cursor, CONSTANTS.OPINION_INFO) } 
                dateNs={ballot.date}
                isLate={ballot.answer !== undefined ? fromNullable(ballot.answer.late_decay) !== undefined : false}
              />
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
            <div className={`relative flex flex-row items-center justify-center w-full transition duration-2000 ${triggerVote ? "opacity-0" : "opacity-100"}`}>
              <div className="absolute flex flex-col items-center left-0 w-1/5">
                { 
                  isLateVote(voteData) ? <></> : 
                    <div className="w-6 h-6">
                      <CertifiedIcon/>
                    </div>
                }
              </div>
              <div className="w-2/5">
                <CursorSlider
                    id={ bottomPlaceholderId + "_slider" }
                    cursor={ cursor }
                    polarizationInfo={ CONSTANTS.OPINION_INFO }
                    disabled={ triggerVote }
                    setCursor={ setCursor }
                    onMouseUp={ () => { setCountdownVote(true)} }
                    onMouseDown={ () => { setCountdownVote(false)} }
                    isLate={isLateVote(voteData)}
                  />
              </div>
              <div className="absolute right-0 w-1/5">
                <UpdateProgress<PutBallotError> 
                    delay_duration_ms={COUNTDOWN_DURATION_MS}
                    update_function={putBallot}
                    error_to_string={putBallotErrorToString}
                    callback_success={refreshBallot}
                    run_countdown={countdownVote}
                    set_run_countdown={setCountdownVote}
                    trigger_update={triggerVote}
                    set_trigger_update={setTriggerVote}
                  >
                  <div className="w-7 h-7">
                    <SvgButton onClick={() => setTriggerVote(true)} disabled={triggerVote} hidden={false}>
                      <PutBallotIcon/>
                    </SvgButton>
                  </div>
                </UpdateProgress>
              </div>
              <div className="col-span-2 bg-green-300 "> { /* spacer to center the content */ }</div>
            </div> : <></>
          }
        </>,
        getDocElementById(bottomPlaceholderId)
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
                  <li className={`flex flex-row justify-between items-center w-full`} key={index.toString()}>
                    <div className="text-sm font-light">
                      { "Iteration " + (Number(iteration) + 1).toString() }
                    </div>
                    <div className="text-sm font-light">
                      { nsToStrDate(ballot.date) }
                    </div>
                    <CursorBallot
                      cursorInfo={toOptCursorInfo((ballot.answer)?.cursor, CONSTANTS.OPINION_INFO)}
                      showValue={true}
                      isLate={isLateBallot(ballot)}
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

export default OpinionVote;
