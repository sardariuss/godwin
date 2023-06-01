import Ballot                                                            from "./Ballot";
import { CursorSlider }                                                  from "../base/CursorSlider";
import ResetButton                                                       from "../base/ResetButton";
import UpdateProgress                                                    from "../UpdateProgress";
import { ActorContext }                                                  from "../../ActorContext"
import { putBallotErrorToString, toMap, getStrongestCategoryCursorInfo } from "../../utils";
import CONSTANTS                                                         from "../../Constants";
import { CursorArray, Category, CategoryInfo, Result_9, _SERVICE }       from "../../../declarations/godwin_backend/godwin_backend.did";

import { ActorSubclass }                                                 from "@dfinity/agent";
import { useContext, useState, useEffect }                               from "react";

type Props = {
  actor: ActorSubclass<_SERVICE>,
  categories: Map<Category, CategoryInfo>,
  voteId: bigint
};

const initCategorization = (categories: Map<Category, CategoryInfo>) => {
  let categorization: CursorArray = [];
  for (const [category, _] of categories.entries()) {
    categorization.push([category, 0.0]);
  }
  return categorization;
}

const CategorizationVote = ({actor, categories, voteId}: Props) => {

  const countdownDurationMs = 8000;

	const {isAuthenticated, refreshBalance}   = useContext(ActorContext);
  const [countdownVote, setCountdownVote]   = useState<boolean>(false);
  const [triggerVote, setTriggerVote]       = useState<boolean>(false);
  const [categorization, setCategorization] = useState<CursorArray | undefined>(undefined);
  const [voteDate, setVoteDate]             = useState<bigint | null>(null);

  const resetCategorization = () => {
    setCategorization(initCategorization(categories));
  };

  const setCategoryCursor = (category_index: number, cursor: number) => {
    setCategorization(old_categorization => {
      let new_categorization = (old_categorization !== undefined ? [...old_categorization] : initCategorization(categories));
      new_categorization[category_index] = [new_categorization[category_index][0], cursor];
      return new_categorization;
    });
  };

  const getBallot = async () => {
    if (isAuthenticated){
      let categorization_vote = await actor.getCategorizationBallot(voteId);
      if (categorization_vote['ok'] !== undefined) {
        setCategorization(categorization_vote['ok'].answer);
        setVoteDate(categorization_vote['ok'].date);
      } else {
        setCategorization(initCategorization(categories));
        setVoteDate(null);
      }
    }
  }

  const refreshBallotResult = (result: Result_9) : string => {
    if (result['ok'] !== undefined) {
      setCategorization(result['ok'].answer);
      setVoteDate(result['ok'].date);
      refreshBalance();
      return "";
    } else {
      setVoteDate(null);
      return putBallotErrorToString(result['err']);
    }
  }

  useEffect(() => {
    getBallot();
  }, []);

	return (
    <div className="w-full">
    {
      categorization === undefined ? <></> :
      voteDate !== null ?
      <div className="mb-3">
        <Ballot cursorInfo={getStrongestCategoryCursorInfo(toMap(categorization), categories)} dateNs={voteDate}/>
      </div> :
      <div className="flex flex-col items-center space-y-2 mb-2">
        <div className="justify-center items-center text-xs font-extralight italic">
          Users who agree on this statement shall have their convictions updated towards...
        </div>
        <div className={`grid grid-cols-8 items-center w-full justify-items-center transition duration-2000 ${triggerVote ? "opacity-0" : "opacity-100"}`}>
          <div className={`col-start-2 col-span-1 justify-center`}>
            <ResetButton 
              reset={ () => { resetCategorization(); setCountdownVote(false);}}
              disabled={ triggerVote }
            />
          </div>
          <ol className="col-span-4 list-none divide-y-4 divide-slate-400/25">
          {
            categorization.map(([category, cursor], index) => (
              <li key={category}>
                <CursorSlider
                  id={ category + voteId.toString() }
                  cursor={ cursor }
                  disabled={ triggerVote }
                  setCursor={ (cursor: number) => { setCategoryCursor(index, cursor); } }
                  polarizationInfo = {{ left: categories.get(category).left, center: {...CONSTANTS.CATEGORIZATION_INFO.center, name: category + ": " + CONSTANTS.CATEGORIZATION_INFO.center.name}, right: categories.get(category).right}}
                  onMouseUp={ () => { setCountdownVote(true)} }
                  onMouseDown={ () => { setCountdownVote(false)} }
                />
              </li>
            ))
          }
          </ol>
          <div className="col-span-1 justify-center">
            <UpdateProgress<Result_9> 
                delay_duration_ms={countdownDurationMs}
                update_function={() => { return actor.putCategorizationBallot(voteId, categorization); }}
                callback_function={(res: Result_9) => { return refreshBallotResult(res); } }
                run_countdown={countdownVote}
                set_run_countdown={setCountdownVote}
                trigger_update={triggerVote}
                set_trigger_update={setTriggerVote}>
              <div className="flex flex-col items-center justify-center w-full">
                <button className="w-full button-svg" onClick={(e) => setTriggerVote(true)} disabled={triggerVote}>
                  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 96 960 960"><path d="M180 976q-24 0-42-18t-18-42V718l135-149 43 43-118 129h600L669 615l43-43 128 146v198q0 24-18 42t-42 18H180Zm0-60h600V801H180v115Zm262-245L283 512q-19-19-17-42.5t20-41.5l212-212q16.934-16.56 41.967-17.28Q565 198 583 216l159 159q17 17 17.5 40.5T740 459L528 671q-17 17-42 18t-44-18Zm249-257L541 264 333 472l150 150 208-208ZM180 916V801v115Z"/></svg>
                </button>
              </div>
            </UpdateProgress>
          </div>
        </div>
      </div>
    }
    </div>
	);
};

export default CategorizationVote;