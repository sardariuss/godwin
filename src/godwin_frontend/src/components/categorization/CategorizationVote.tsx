import CursorBallot                                                      from "../base/CursorBallot";
import { CursorSlider }                                                  from "../base/CursorSlider";
import SvgButton                                                         from "../base/SvgButton";
import ResetIcon                                                         from "../icons/ResetIcon";
import PutBallotIcon                                                     from "../icons/PutBallotIcon";
import UpdateProgress                                                    from "../UpdateProgress";
import ReturnIcon                                                        from "../icons/ReturnIcon";
import { putBallotErrorToString, getStrongestCategoryCursorInfo, 
  toMap, CursorInfo, voteStatusToEnum, VoteStatusEnum }                  from "../../utils";
import { getDocElementById }                                             from "../../utils/DocumentUtils";
import CONSTANTS                                                         from "../../Constants";
import { Sub, ActorContext }                                             from "../../ActorContext";
import { CursorArray, Category, CategoryInfo, PutBallotError, 
  VoteData, RevealedCategorizationBallot }                               from "../../../declarations/godwin_sub/godwin_sub.did";

import React, { useContext, useState }                                   from "react";
import { createPortal }                                                  from 'react-dom';
import { fromNullable }                                                  from "@dfinity/utils";

const initCategorization = (categories: Map<Category, CategoryInfo>) => {
  let categorization: CursorArray = [];
  for (const [category, _] of categories.entries()) {
    categorization.push([category, 0.0]);
  }
  return categorization;
}

const unwrapBallot = (vote_data: VoteData) : RevealedCategorizationBallot | undefined => {
  let vote_kind_ballot = fromNullable(vote_data.user_ballot);
  if (vote_kind_ballot !== undefined && vote_kind_ballot['CATEGORIZATION'] !== undefined){
    return vote_kind_ballot['CATEGORIZATION'];
  }
  return undefined;
}

const getOptStrongestCategory = (categorization: CursorArray | undefined, sub: Sub) : CursorInfo | undefined => {
  if (categorization !== undefined){
    return getStrongestCategoryCursorInfo(toMap(categorization), sub.categories);
  }
  return undefined;
}

type Props = {
  sub: Sub;
  voteData: VoteData;
  allowVote: boolean;
  votePlaceholderId: string;
  ballotPlaceholderId: string;
};

const CategorizationVote = ({sub, voteData, allowVote, votePlaceholderId, ballotPlaceholderId}: Props) => {

  const {refreshBalance}   = useContext(ActorContext);

  const countdownDurationMs = 5000;

  const [countdownVote,  setCountdownVote ] = useState<boolean>                                 (false                               );
  const [triggerVote,    setTriggerVote   ] = useState<boolean>                                 (false                               );
  const [ballot,         setBallot        ] = useState<RevealedCategorizationBallot | undefined>(unwrapBallot(voteData)              );
  const [categorization, setCategorization] = useState<CursorArray>                             (initCategorization(sub.categories)  );
  const [showVote,       setShowVote      ] = useState<boolean>                                 (unwrapBallot(voteData) === undefined);

  const resetCategorization = () => {
    setCategorization(initCategorization(sub.categories));
  };

  const setCategoryCursor = (category_index: number, cursor: number) => {
    setCategorization(old_categorization => {
      let new_categorization = [...old_categorization];
      new_categorization[category_index] = [new_categorization[category_index][0], cursor];
      return new_categorization;
    });
  };

  const refreshBallot = () : Promise<void> => {
    return sub.actor.getCategorizationBallot(voteData.id).then((result) => {
      if (result['ok'] !== undefined){
        setBallot(result['ok']);
        setShowVote(false);
      }
    });
  }

  const putBallot = () : Promise<PutBallotError | null> => {
    return sub.actor.putCategorizationBallot(voteData.id, categorization).then((result) => {
      refreshBalance();
      return result['err'] ?? null;
    });
  }

  const canVote = (voteData: VoteData) : boolean => {
    return allowVote && voteStatusToEnum(voteData.status) !== VoteStatusEnum.CLOSED;
  }

  return (
    <>
    {
      createPortal(
        <>
          { !showVote && ballot !== undefined ?
            <div className={`flex flex-row justify-center items-center w-20`}>
              <CursorBallot cursorInfo={getOptStrongestCategory(fromNullable(ballot.answer), sub)} dateNs={ballot.date}/> 
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
            <div className={`flex flex-row justify-center items-center w-full transition duration-2000 ${triggerVote ? "opacity-0" : "opacity-100"}`}>
            <div className={`justify-center w-6 h-6`}>
              <SvgButton onClick={ () => { resetCategorization(); setCountdownVote(false);}} disabled={ triggerVote } hidden={false}>
                <ResetIcon/>
              </SvgButton>
            </div>
            <ol className="w-50 list-none">
            {
              categorization.map(([category, cursor], index) => (
                <li key={category} className="flex flex-col items-center">
                  <CursorSlider
                    id={ category + voteData.id.toString() }
                    cursor={ cursor }
                    disabled={ triggerVote }
                    setCursor={ (cursor: number) => { setCategoryCursor(index, cursor); } }
                    polarizationInfo = {{
                      left: sub.categories.get(category).left,
                      center: {...CONSTANTS.CATEGORIZATION_INFO.center, name: category + ": " + CONSTANTS.CATEGORIZATION_INFO.center.name},
                      right: sub.categories.get(category).right
                    }}
                    onMouseUp={ () => { setCountdownVote(true)} }
                    onMouseDown={ () => { setCountdownVote(false)} }
                    isLate={false}
                  />
                  {
                    index !== categorization.length - 1 ?
                    <div className="h-1 w-3/4 bg-slate-400/25"/> : <></>
                  }
                </li>
              ))
            }
            </ol>
            <div className="mb-2">
              <UpdateProgress<PutBallotError> 
                  delay_duration_ms={countdownDurationMs}
                  update_function={putBallot}
                  error_to_string={putBallotErrorToString}
                  callback_function={refreshBallot}
                  run_countdown={countdownVote}
                  set_run_countdown={setCountdownVote}
                  trigger_update={triggerVote}
                  set_trigger_update={setTriggerVote}
                  cost={BigInt(350_000_000)}>
                <div className="w-8 h-8">
                  <SvgButton onClick={ () => { setTriggerVote(true); } } disabled={ triggerVote } hidden={false}>
                    <PutBallotIcon/>
                  </SvgButton>
                </div>
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