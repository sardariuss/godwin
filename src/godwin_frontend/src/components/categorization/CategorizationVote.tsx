import CursorBallot                                                      from "../base/CursorBallot";
import { CursorSlider }                                                  from "../base/CursorSlider";
import SvgButton                                                         from "../base/SvgButton";
import ResetIcon                                                         from "../icons/ResetIcon";
import PutBallotIcon                                                     from "../icons/PutBallotIcon";
import UpdateProgress                                                    from "../UpdateProgress";
import { putBallotErrorToString, getStrongestCategoryCursorInfo, toMap } from "../../utils";
import { getDocElementById }                                             from "../../utils/DocumentUtils";
import CONSTANTS                                                         from "../../Constants";
import { Sub, ActorContext }                                             from "../../ActorContext";
import { CursorArray, Category, CategoryInfo, PutBallotError, VoteData } from "../../../declarations/godwin_sub/godwin_sub.did";

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

const unwrapBallotDate = (vote_data: VoteData) : bigint  | undefined => {
  let ballot = fromNullable(vote_data.user_ballot);
  if (ballot !== undefined && ballot['CATEGORIZATION'] !== undefined){
		return ballot['CATEGORIZATION'].date;
	}
  return undefined;
}

const unwrapBallotCategorization = (vote_data: VoteData, canVote, categories: Map<Category, CategoryInfo>) : CursorArray | undefined => {
  let ballot = fromNullable(vote_data.user_ballot);
  if (ballot !== undefined && ballot['CATEGORIZATION'] !== undefined){
    let answer : CursorArray | undefined = fromNullable(ballot['CATEGORIZATION'].answer);
    if (answer !== undefined){
      return answer;
    }
	}
  if (canVote) {
    return initCategorization(categories);
  }
  return undefined;
}

type Props = {
  sub: Sub;
  voteData: VoteData;
  canVote: boolean;
  voteElementId: string;
  ballotElementId: string;
};

const CategorizationVote = ({sub, voteData, canVote, voteElementId, ballotElementId}: Props) => {

  const {refreshBalance}   = useContext(ActorContext);

  const countdownDurationMs = 5000;

  const [countdownVote,  setCountdownVote ] = useState<boolean>                (false                                                        );
  const [triggerVote,    setTriggerVote   ] = useState<boolean>                (false                                                        );
  const [voteDate,       setVoteDate      ] = useState<bigint | undefined>     (unwrapBallotDate(voteData)                                   );
  const [categorization, setCategorization] = useState<CursorArray | undefined>(unwrapBallotCategorization(voteData, canVote, sub.categories));

  const resetCategorization = () => {
    setCategorization(initCategorization(sub.categories));
  };

  const setCategoryCursor = (category_index: number, cursor: number) => {
    setCategorization(old_categorization => {
      if (old_categorization === undefined){
        return undefined;
      }
      let new_categorization = [...old_categorization];
      new_categorization[category_index] = [new_categorization[category_index][0], cursor];
      return new_categorization;
    });
  };

  const refreshBallot = () : Promise<void> => {
    return sub.actor.getCategorizationBallot(voteData.id).then((result) => {
      if (result['ok'] !== undefined){
        if (result['ok'].answer[0] !== undefined){
          setCategorization(result['ok'].answer[0]);
        }
        if (result['ok'].date !== undefined){
          setVoteDate(result['ok'].date);
        }
      }
    });
  }

  const putBallot = () : Promise<PutBallotError | null> => {
    if (categorization === undefined) throw new Error("Cannot put ballot: categorization is undefined");
    return sub.actor.putCategorizationBallot(voteData.id, categorization).then((result) => {
      refreshBalance();
      return result['err'] ?? null;
    });
  }

  return (
    <>
    {
      createPortal(
        <>
          { voteDate !== undefined ?
              <CursorBallot cursorInfo={categorization !== undefined ? getStrongestCategoryCursorInfo(toMap(categorization), sub.categories) : undefined} dateNs={voteDate}/> : <></>
          }
        </>,
        getDocElementById(ballotElementId)
      )
    }
    {
      createPortal(
        <>
          { voteDate === undefined && categorization !== undefined ?
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
        getDocElementById(voteElementId)
      )
    }
  </>
	);
};

export default CategorizationVote;