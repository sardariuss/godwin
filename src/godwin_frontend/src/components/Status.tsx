import { _SERVICE, Status, Category, CategoryInfo, Appeal, Polarization, PublicVote, PublicVote_1, PublicVote_2, Ballot, Ballot_2 } from "./../../declarations/godwin_backend/godwin_backend.did";
import { Principal } from "@dfinity/principal";
import { nsToStrDate, statusToString, toMap, toPolarizationInfo, getNormalizedPolarization } from "../utils";

import InterestAggregate from "./aggregates/InterestAggregate";
import OpinionAggregate from "./aggregates/OpinionAggregate";
import CategorizationAggregate from "./aggregates/CategorizationAggregate";
import AppealChart from "./base/AppealChart";
import PolarizationBar from "./base/PolarizationBar";
import CONSTANTS from "../Constants";

import { ActorSubclass } from "@dfinity/agent";

import { useEffect, useState } from "react";

// @todo: put the SVGs into the assets directory
const statusToPath = (status: Status) => {
  if (status['CANDIDATE'] !== undefined) return "m550 972-42-42 142-142-382-382-142 142-42-42 56-58-56-56 85-85-42-42 42-42 43 41 84-84 56 56 58-56 42 42-142 142 382 382 142-142 42 42-56 58 56 56-86 86 42 42-42 42-42-42-84 84-56-56-58 56Z";
  if (status['OPEN'] !== undefined) return "M180 976q-24 0-42-18t-18-42V718l135-149 43 43-118 129h600L669 615l43-43 128 146v198q0 24-18 42t-42 18H180Zm0-60h600V801H180v115Zm262-245L283 512q-19-19-17-42.5t20-41.5l212-212q16.934-16.56 41.967-17.28Q565 198 583 216l159 159q17 17 17.5 40.5T740 459L528 671q-17 17-42 18t-44-18Zm249-257L541 264 333 472l150 150 208-208ZM180 916V801v115Z";
  if (status['CLOSED'] !== undefined) return "M431 922H180q-24 0-42-18t-18-42V280q0-24 15.5-42t26.5-18h202q7-35 34.5-57.5T462 140q36 0 63.5 22.5T560 220h202q24 0 42 18t18 42v203h-60V280H656v130H286V280H180v582h251v60Zm189-25L460 737l43-43 117 117 239-239 43 43-282 282ZM480 276q17 0 28.5-11.5T520 236q0-17-11.5-28.5T480 196q-17 0-28.5 11.5T440 236q0 17 11.5 28.5T480 276Z";
  if (status['REJECTED'] !== undefined) return "M480 534q69 0 116.5-50.5T644 362V236H316v126q0 71 47.5 121.5T480 534ZM160 976v-60h96V789q0-70 36.5-128.5T394 576q-65-26-101.5-85T256 362V236h-96v-60h640v60h-96v126q0 70-36.5 129T566 576q65 26 101.5 84.5T704 789v127h96v60H160Z";
  return "m249 849-42-42 231-231-231-231 42-42 231 231 231-231 42 42-231 231 231 231-42 42-231-231-231 231Z";
};

type Props = {
  actor: ActorSubclass<_SERVICE>,
  questionId: bigint;
  status: Status;
  date: bigint;
  iteration: bigint;
  isHistory: boolean;
  categories: Map<Category, CategoryInfo>
  showBorder: boolean;
  borderDashed: boolean;
};

enum VoteType {
  INTEREST,
  OPINION,
  CATEGORIZATION,
  NONE
};

// @todo: the normalized polarization and toMap shall be done only once, not every call
const StatusComponent = ({actor, questionId, status, date, iteration, isHistory, categories, showBorder, borderDashed}: Props) => {

  const [selectedVote, setSelectedVote] = useState<VoteType>(VoteType.NONE);
  const [interestVote, setInterestVote] = useState<PublicVote_1 | undefined>();
  const [opinionVote, setOpinionVote] = useState<PublicVote | undefined>();
  const [categorizationVote, setCategorizationVote] = useState<PublicVote_2 | undefined>();

  const fetchRevealedVotes = async () => {
    if (isHistory){
      if (status['CANDIDATE'] !== undefined){
        setInterestVote((await actor.revealInterestVote(questionId, iteration))['ok']);
      }
      if (status['OPEN'] !== undefined){
        setOpinionVote((await actor.revealOpinionVote(questionId, iteration))['ok']);
        setCategorizationVote((await actor.revealCategorizationVote(questionId, iteration))['ok']);
      }
    }
  }

  const toNormalizedMap = (array: [Category, Polarization][]) => {
    let map = new Map<Category, Polarization>();
    for (let [category, polarization] of array){
      map.set(category, getNormalizedPolarization(polarization));
    }
    return map;
  };

  // @todo: do not use the index
  const getBallotsFromCategory = (categorizationVote: PublicVote_2, cat_index: number) : [Principal, Ballot][] => {
    let ballots : [Principal, Ballot][] = [];
    for (let [principal, ballot] of categorizationVote.ballots){
      if (ballot.answer[cat_index] !== undefined){
        ballots.push([principal, {date : ballot.date, answer: ballot.answer[cat_index][1]}]);
      }
    }
    return ballots;
  }

  useEffect(() => {
    fetchRevealedVotes();
  }, []);

	return (
    <div className={(showBorder? ( borderDashed ? "border-l-2 border-dashed" : "border-l-2 border-solid") : "") + " text-gray-500 dark:text-gray-400 border-gray-200 dark:border-gray-500 pl-2 ml-4"}>
      <div className={"text-gray-900 dark:text-white -ml-6 " + (borderDashed ? "pb-3" : "pb-5")}>
        <div className="flex flex-row gap-x-3">
          <span className={"flex items-center justify-center w-8 h-8 rounded-full -left-4 ring-4 ring-white dark:ring-gray-900 " + ( isHistory ? "bg-gray-100 dark:bg-gray-700" : "bg-blue-200 dark:bg-blue-900" )} >
            <svg xmlns="http://www.w3.org/2000/svg" className={"w-5 h-5 " + ( isHistory ? "text-gray-500 dark:text-gray-400" : "text-blue-500 dark:text-blue-400" )} fill="currentColor" viewBox="0 96 960 960" width="48"><path d={statusToPath(status)}/></svg>
          </span>
          <div className="flex flex-col grow">
            <div className="flex flex-row items-center gap-x-1">
              <div className="font-light text-sm">{ statusToString(status) } </div>
              <div className="text-xs font-extralight"> { (iteration > 0 ? "(" + (Number(iteration) + 1).toString() + ")" : "") }</div>
              <div className="flex flex-row items-center gap-x-3">
              {
                isHistory ? 
                  status['CANDIDATE'] !== undefined ?
                    <InterestAggregate 
                      aggregate={interestVote !== undefined ? interestVote.aggregate : undefined}
                      setSelected={(selected: boolean) => { setSelectedVote(selected ? VoteType.INTEREST : VoteType.NONE) }}
                      selected={ selectedVote === VoteType.INTEREST}
                    />
                  : status['OPEN'] !== undefined ?
                  <div className="flex flex-row items-center gap-x-1">
                    <OpinionAggregate
                      aggregate={opinionVote !== undefined ? opinionVote.aggregate : undefined}
                      setSelected={(selected: boolean) => { setSelectedVote(selected ? VoteType.OPINION : VoteType.NONE) }}
                      selected={ selectedVote === VoteType.OPINION}
                    />
                    {" · "}
                    <CategorizationAggregate 
                      aggregate={categorizationVote !== undefined ? toMap(categorizationVote.aggregate) : undefined}
                      categories={categories}
                      setSelected={(selected: boolean) => { setSelectedVote(selected ? VoteType.CATEGORIZATION : VoteType.NONE) }}
                      selected={ selectedVote === VoteType.CATEGORIZATION}
                    />
                  </div>
                  : <> </>
                : <> </>
              }
              </div>
            </div>
            <div className="text-xs font-extralight">{ nsToStrDate(date) }</div>
            <div className={ selectedVote !== VoteType.NONE ? "mt-5" : "" }>
              <div>
              {
                // @todo: take the last iteration
                selectedVote === VoteType.INTEREST && interestVote !== undefined ?
                  <AppealChart appeal={interestVote.aggregate}></AppealChart> : <></>
              }
              </div>
              <div>
              {
                // @todo: take the last iteration
                selectedVote === VoteType.OPINION && opinionVote !== undefined ?
                  <PolarizationBar name={"OPINION"} showName={false} polarizationInfo={CONSTANTS.OPINION_INFO} polarizationValue={getNormalizedPolarization(opinionVote.aggregate)} ballots={opinionVote.ballots}></PolarizationBar>
                : <></>
              }
              </div>
              <ol>
              {
                // @todo: take the last iteration
                selectedVote === VoteType.CATEGORIZATION && categorizationVote !== undefined ? (
                [...Array.from(toNormalizedMap(categorizationVote.aggregate).entries())].map((elem, index) => (
                  <li key={elem[0]} className="mb-2">
                    <PolarizationBar name={elem[0]} showName={true} polarizationInfo={toPolarizationInfo(categories.get(elem[0]), CONSTANTS.CATEGORIZATION_INFO.center)} polarizationValue={elem[1]} ballots={getBallotsFromCategory(categorizationVote, index)}></PolarizationBar>
                  </li>
                ))
                ) : (
                  <></>
                )
              }
              </ol>
            </div>
          </div>
        </div>
      </div>
    </div>
	);
};

export default StatusComponent;
