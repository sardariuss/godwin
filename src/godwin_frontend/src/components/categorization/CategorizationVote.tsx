import CategorizationDetailedBallot                                      from "./CategorizationDetailedBallot";
import CursorBallot                                                      from "../base/CursorBallot";
import { CursorSlider }                                                  from "../base/CursorSlider";
import SvgButton                                                         from "../base/SvgButton";
import ResetIcon                                                         from "../icons/ResetIcon";
import PutBallotIcon                                                     from "../icons/PutBallotIcon";
import UpdateProgress                                                    from "../UpdateProgress";
import ReturnIcon                                                        from "../icons/ReturnIcon";
import { putBallotErrorToString, getStrongestCategoryCursorInfo, voteStatusToEnum,
  VoteStatusEnum, VoteView, RevealableBallot, getCategorizationBallot, VoteKind,
  voteKindToCandidVariant, toCategorizationKindAnswer,
  unwrapRevealedCategorizationBallot }                                   from "../../utils";
import { getDocElementById }                                             from "../../utils/DocumentUtils";
import CONSTANTS                                                         from "../../Constants";
import { Sub, ActorContext }                                             from "../../ActorContext";
import { CursorArray, Category, CategoryInfo, PutBallotError, VoteData } from "../../../declarations/godwin_sub/godwin_sub.did";

import React, { useContext, useState, useEffect }                        from "react";
import { createPortal }                                                  from "react-dom";
import { Principal }                                                     from "@dfinity/principal";
import { fromNullable }                                                  from "@dfinity/utils";

const initCategorization = (categories: Map<Category, CategoryInfo>) => {
  let categorization: CursorArray = [];
  for (const [category, _] of categories.entries()) {
    categorization.push([category, 0.0]);
  }
  return categorization;
}

type Props = {
  sub: Sub;
  voteData: VoteData;
  allowVote: boolean;
  bottomPlaceholderId: string;
  rightPlaceholderId: string;
  question_id: bigint;
  principal: Principal;
  showHistory: boolean;
};

const CategorizationVote = ({sub, voteData, allowVote, bottomPlaceholderId, rightPlaceholderId, question_id, principal, showHistory}: Props) => {

  const {refreshBalance, priceParameters}   = useContext(ActorContext);

  const countdownDurationMs = 10000;
  const voteKind = voteKindToCandidVariant(VoteKind.CATEGORIZATION);

  const [countdownVote,  setCountdownVote ] = useState<boolean>                                            (false                                  );
  const [triggerVote,    setTriggerVote   ] = useState<boolean>                                            (false                                  );
  const [ballot,         setBallot        ] = useState<RevealableBallot<CursorArray> | undefined>          (getCategorizationBallot(voteData)      );
  const [categorization, setCategorization] = useState<CursorArray>                                        (initCategorization(sub.info.categories));
  const [voteView,      setVoteView     ] = useState<VoteView>                                             (VoteView.LAST_BALLOT                   );
  const [ballotHistory, setBallotHistory] = useState<[bigint, RevealableBallot<CursorArray> | undefined][]>([]                                     );

  const resetCategorization = () => {
    setCategorization(initCategorization(sub.info.categories));
  };

  const setCategoryCursor = (category_index: number, cursor: number) => {
    setCategorization(old_categorization => {
      let new_categorization = [...old_categorization];
      new_categorization[category_index] = [new_categorization[category_index][0], cursor];
      return new_categorization;
    });
  };

  const refreshBallot = () : Promise<void> => {
    return sub.actor.revealBallot(voteKind, principal, voteData.id).then((result) => {
      if (result['ok'] !== undefined){
        setBallot(unwrapRevealedCategorizationBallot(result['ok']));
      }
    });
  }

  const putBallot = () : Promise<PutBallotError | null> => {
    return sub.actor.putBallot(voteKind, voteData.id, toCategorizationKindAnswer(categorization)).then((result) => {
      refreshBalance();
      return result['err'] ?? null;
    });
  }

  const canVote = (voteData: VoteData) : boolean => {
    return allowVote && voteStatusToEnum(voteData.status) !== VoteStatusEnum.CLOSED;
  }

  const fetchBallotHistory = () => {
    sub.actor.queryVoterQuestionBallots(question_id, voteKind, principal).then((iteration_ballots) => {
      let history = iteration_ballots.map((ballot) : [bigint, RevealableBallot<CursorArray> | undefined] => {
        let b = fromNullable(ballot[1]);
        return [ballot[0], (b !== undefined ? unwrapRevealedCategorizationBallot(b) : undefined)];
      });
      setBallotHistory(history);
    });
  }

  useEffect(() => {
    if (showHistory) {
      fetchBallotHistory();
    }
  }, [showHistory]);

  useEffect(() => {
    setVoteView(ballot === undefined ? VoteView.VOTE : showHistory ? VoteView.BALLOT_HISTORY : VoteView.LAST_BALLOT);
  }, [ballot, showHistory]);

  return (
    <>
    {
      createPortal(
        <>
          { voteView === VoteView.LAST_BALLOT && ballot !== undefined ?
            <div className={`flex flex-row justify-center items-center w-20`}>
              <CursorBallot cursorInfo={getStrongestCategoryCursorInfo(ballot.answer, sub.info.categories)} dateNs={ballot.date}/> 
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
              <div className={`absolute flex flex-col items-center left-0 w-1/5`}>
                <div className="w-5 h-5">
                  <SvgButton onClick={ () => { resetCategorization(); setCountdownVote(false);}} disabled={ triggerVote } hidden={false}>
                    <ResetIcon/>
                  </SvgButton>
                </div>
              </div>
              <ol className="w-2/5 list-none">
              {
                categorization.map(([category, cursor], index) => (
                  <li key={category} className="flex flex-col items-center">
                    <CursorSlider
                      id={ category + voteData.id.toString() }
                      cursor={ cursor }
                      disabled={ triggerVote }
                      setCursor={ (cursor: number) => { setCategoryCursor(index, cursor); } }
                      polarizationInfo = {{
                        left: sub.info.categories.get(category)?.left,
                        center: {...CONSTANTS.CATEGORIZATION_INFO.center, name: category + ": " + CONSTANTS.CATEGORIZATION_INFO.center.name},
                        right: sub.info.categories.get(category)?.right
                      }}
                      onMouseUp={ () => { setCountdownVote(true)} }
                      onMouseDown={ () => { setCountdownVote(false)} }
                      isLate={false}
                    />
                    {
                      index !== categorization.length - 1 ?
                      <div className="h-1 w-full bg-slate-400/25"/> : <></>
                    }
                  </li>
                ))
              }
              </ol>
              <div className="absolute flex flex-col right-0 w-1/5">
                <UpdateProgress<PutBallotError> 
                    delay_duration_ms={countdownDurationMs}
                    update_function={putBallot}
                    error_to_string={putBallotErrorToString}
                    callback_success={refreshBallot}
                    run_countdown={countdownVote}
                    set_run_countdown={setCountdownVote}
                    trigger_update={triggerVote}
                    set_trigger_update={setTriggerVote}
                    cost={priceParameters?.categorization_vote_price_sats}>
                  <SvgButton onClick={ () => { setTriggerVote(true); } } disabled={ triggerVote }>
                    <PutBallotIcon/>
                  </SvgButton>
                </UpdateProgress>
              </div>
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
                  <li className="w-full" key={index.toString()}>
                    <CategorizationDetailedBallot
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

export default CategorizationVote;