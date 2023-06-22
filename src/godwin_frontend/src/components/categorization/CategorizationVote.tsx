import CursorBallot                                                      from "../base/CursorBallot";
import { CursorSlider }                                                  from "../base/CursorSlider";
import SvgButton                                                         from "../base/SvgButton";
import ResetIcon                                                         from "../icons/ResetIcon";
import PutBallotIcon                                                     from "../icons/PutBallotIcon";
import UpdateProgress                                                    from "../UpdateProgress";
import { ActorContext }                                                  from "../../ActorContext"
import { putBallotErrorToString, toMap, getStrongestCategoryCursorInfo } from "../../utils";
import CONSTANTS                                                         from "../../Constants";
import { CursorArray, Category, CategoryInfo, PutBallotError, _SERVICE } from "../../../declarations/godwin_sub/godwin_sub.did";

import { ActorSubclass }                                                 from "@dfinity/agent";
import { useContext, useState, useEffect }                               from "react";

type Props = {
  actor: ActorSubclass<_SERVICE>,
  categories: Map<Category, CategoryInfo>,
  voteId: bigint,
};

const initCategorization = (categories: Map<Category, CategoryInfo>) => {
  let categorization: CursorArray = [];
  for (const [category, _] of categories.entries()) {
    categorization.push([category, 0.0]);
  }
  return categorization;
}

const CategorizationVote = ({actor, categories, voteId}: Props) => {

  const {refreshBalance}   = useContext(ActorContext);

  const countdownDurationMs = 5000;

  const [countdownVote,  setCountdownVote ] = useState<boolean>           (false);
  const [triggerVote,    setTriggerVote   ] = useState<boolean>           (false);
  const [categorization, setCategorization] = useState<CursorArray | null>(null);
  const [voteDate,       setVoteDate      ] = useState<bigint | null>     (null);

  const resetCategorization = () => {
    setCategorization(initCategorization(categories));
  };

  const setCategoryCursor = (category_index: number, cursor: number) => {
    setCategorization(old_categorization => {
      let new_categorization = (old_categorization !== null ? [...old_categorization] : initCategorization(categories));
      new_categorization[category_index] = [new_categorization[category_index][0], cursor];
      return new_categorization;
    });
  };

  const refreshBallot = () : Promise<void> => {
    return actor.getCategorizationBallot(voteId).then((result) => {
      setCategorization(result['ok'] !== undefined && result['ok'].answer[0] !== undefined ? result['ok'].answer[0] : initCategorization(categories));
      setVoteDate(result['ok'] !== undefined ? result['ok'].date : null);
    });
  }

  const putBallot = () : Promise<PutBallotError | null> => {
    if (categorization === null) return Promise.resolve(null);
    return actor.putCategorizationBallot(voteId, categorization).then((result) => {
      refreshBalance();
      return result['err'] ?? null;
    });
  }

  useEffect(() => {
    refreshBallot();
  }, []);

	return (
    <div className="w-full">
    {
      categorization === null ? <></> :
      voteDate !== null ?
      <div className="mb-3">
        <CursorBallot cursorInfo={getStrongestCategoryCursorInfo(toMap(categorization), categories)} dateNs={voteDate}/>
      </div> :
      <div className={`grid grid-cols-8 items-center w-full justify-items-center transition duration-2000 ${triggerVote ? "opacity-0" : "opacity-100"}`}>
        <div className={`col-start-2 col-span-1 justify-center w-2/5`}>
          <SvgButton onClick={ () => { resetCategorization(); setCountdownVote(false);}} disabled={ triggerVote } hidden={false}>
            <ResetIcon/>
          </SvgButton>
        </div>
        <ol className="col-span-4 list-none">
        {
          categorization.map(([category, cursor], index) => (
            <li key={category} className="flex flex-col items-center">
              <CursorSlider
                id={ category + voteId.toString() }
                cursor={ cursor }
                disabled={ triggerVote }
                setCursor={ (cursor: number) => { setCategoryCursor(index, cursor); } }
                polarizationInfo = {{
                  left: categories.get(category).left,
                  center: {...CONSTANTS.CATEGORIZATION_INFO.center, name: category + ": " + CONSTANTS.CATEGORIZATION_INFO.center.name},
                  right: categories.get(category).right
                }}
                onMouseUp={ () => { setCountdownVote(true)} }
                onMouseDown={ () => { setCountdownVote(false)} }
              />
              {
                index !== categorization.length - 1 ?
                <div className="h-1 w-3/4 bg-slate-400/25"/> : <></>
              }
            </li>
          ))
        }
        </ol>
        <div className="col-span-1 justify-center mb-2">
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
            <div className="flex flex-col items-center justify-center w-full">
              <SvgButton onClick={ () => { setTriggerVote(true); } } disabled={ triggerVote } hidden={false}>
                <PutBallotIcon/>
              </SvgButton>
            </div>
          </UpdateProgress>
        </div>
      </div>
    }
    </div>
	);
};

export default CategorizationVote;