import CursorBallot                                                      from "../base/CursorBallot";
import { CursorSlider }                                                  from "../base/CursorSlider";
import SvgButton                                                         from "../base/SvgButton";
import ResetIcon                                                         from "../icons/ResetIcon";
import PutBallotIcon                                                     from "../icons/PutBallotIcon";
import UpdateProgress                                                    from "../UpdateProgress";
import ReturnIcon                                                        from "../icons/ReturnIcon";
import { putBallotErrorToString, getStrongestCategoryCursorInfo, 
  toMap, CursorInfo, voteStatusToEnum, VoteStatusEnum, 
  RevealableBallot, getCategorizationBallot, VoteKind, voteKindToCandidVariant,
  toCategorizationKindAnswer, unwrapRevealedCategorizationBallot }       from "../../utils";
import { getDocElementById }                                             from "../../utils/DocumentUtils";
import CONSTANTS                                                         from "../../Constants";
import { Sub, ActorContext }                                             from "../../ActorContext";
import { CursorArray, Category, CategoryInfo, PutBallotError, VoteData } from "../../../declarations/godwin_sub/godwin_sub.did";

import React, { useContext, useState, useEffect }                        from "react";
import { createPortal }                                                  from "react-dom";
import { Principal }                                                     from "@dfinity/principal";

const initCategorization = (categories: Map<Category, CategoryInfo>) => {
  let categorization: CursorArray = [];
  for (const [category, _] of categories.entries()) {
    categorization.push([category, 0.0]);
  }
  return categorization;
}

const getOptStrongestCategory = (categorization: CursorArray | undefined, sub: Sub) : CursorInfo | undefined => {
  if (categorization !== undefined){
    return getStrongestCategoryCursorInfo(toMap(categorization), sub.info.categories);
  }
  return undefined;
}

type Props = {
  sub: Sub;
  voteData: VoteData;
  allowVote: boolean;
  votePlaceholderId: string;
  ballotPlaceholderId: string;
  principal: Principal;
};

const CategorizationVote = ({sub, voteData, allowVote, votePlaceholderId, ballotPlaceholderId, principal}: Props) => {

  const {refreshBalance}   = useContext(ActorContext);

  const countdownDurationMs = 5000;

  const [countdownVote,  setCountdownVote ] = useState<boolean>                                  (false                                  );
  const [triggerVote,    setTriggerVote   ] = useState<boolean>                                  (false                                  );
  const [ballot,         setBallot        ] = useState<RevealableBallot<CursorArray> | undefined>(getCategorizationBallot(voteData)      );
  const [categorization, setCategorization] = useState<CursorArray>                              (initCategorization(sub.info.categories));
  const [showVote,       setShowVote      ] = useState<boolean>                                  (false                                  );

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
    return sub.actor.revealBallot(voteKindToCandidVariant(VoteKind.CATEGORIZATION), principal, voteData.id).then((result) => {
      if (result['ok'] !== undefined){
        setBallot(unwrapRevealedCategorizationBallot(result['ok']));
      }
    });
  }

  const putBallot = () : Promise<PutBallotError | null> => {
    return sub.actor.putBallot(voteKindToCandidVariant(VoteKind.CATEGORIZATION), voteData.id, toCategorizationKindAnswer(categorization)).then((result) => {
      refreshBalance();
      return result['err'] ?? null;
    });
  }

  const canVote = (voteData: VoteData) : boolean => {
    return allowVote && voteStatusToEnum(voteData.status) !== VoteStatusEnum.CLOSED;
  }

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
            <div className={`flex flex-row justify-center items-center w-20`}>
              <CursorBallot cursorInfo={getOptStrongestCategory(ballot.answer, sub)} dateNs={ballot.date}/> 
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
                        left: sub.info.categories.get(category).left,
                        center: {...CONSTANTS.CATEGORIZATION_INFO.center, name: category + ": " + CONSTANTS.CATEGORIZATION_INFO.center.name},
                        right: sub.info.categories.get(category).right
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
                    cost={sub.info.prices.categorization_vote_price_e8s}>
                  <SvgButton onClick={ () => { setTriggerVote(true); } } disabled={ triggerVote }>
                    <PutBallotIcon/>
                  </SvgButton>
                </UpdateProgress>
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

export default CategorizationVote;