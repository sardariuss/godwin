import { Category, Polarization, Ballot } from "./../../declarations/godwin_backend/godwin_backend.did";
import { Principal } from "@dfinity/principal";
import ChartTypeToggle from "./base/ChartTypeToggle";
import SubBanner from "./SubBanner";

import { Sub } from "./../ActorContext";

import { useEffect, useState } from "react";

import CONSTANTS from "../Constants";

import { ChartTypeEnum, toMap, toPolarizationInfo } from "../utils";

import PolarizationBar from "./base/PolarizationBar";

type ConvictionsProps = {
  principal: Principal;
  sub: Sub;
};

const Convictions = ({principal, sub} : ConvictionsProps) => {

  const [chartType, setChartType] = useState<ChartTypeEnum>(ChartTypeEnum.Bar);
  const [convictions, setConvictions] = useState<Map<Category, Polarization>>(new Map<Category, Polarization>());
  const [numberBallots, setNumberBallots] = useState<number>(0);
  const [ballots, setBallots] = useState<Map<Category, [string, Ballot, number][]>>(new Map<Category, [string, Ballot, number][]>());
  const [categoryWeights, setCategoryWeights] = useState<Map<Category, number>>(new Map<Category, number>());
  const [categoryMax, setCategoryMax] = useState<number | undefined>(undefined);

  const refreshConvictions = async () => {
    if (principal === undefined) {
      setConvictions(new Map<Category, Polarization>());
      setBallots(new Map<Category, [string, Ballot, number][]>());
      setCategoryWeights(new Map<Category, number>());
      setCategoryMax(undefined);
      return;
    }

    let queryConvictions = await sub.actor.getUserConvictions(principal);
    
    if (queryConvictions[0] !== undefined) {
      setConvictions(toMap(queryConvictions[0]));
    }

    let queryOpinions = await sub.actor.getUserOpinions(principal);

    if (queryOpinions[0] === undefined || queryOpinions[0].length === 0) {
      return;
    }

    let weighted_ballots = new Map<Category, [string, Ballot, number][]>();
    let category_weights = new Map<Category, number>();

    for (let i = 0; i < queryOpinions[0].length; i++){
      let [vote_id, categorization, opinion] = queryOpinions[0][i];
      categorization.forEach(([category, polarization]) => {
        let weight = (polarization.right - polarization.left) / (polarization.left + polarization.center + polarization.right);
        category_weights.set(category, (category_weights.get(category) ?? 0) + Math.abs(weight));
        let array : [string, Ballot, number][] = weighted_ballots.get(category) ?? [];
        array.push([vote_id.toString(), opinion, weight]);
        weighted_ballots.set(category, array);
      });
    }
    setBallots(weighted_ballots);
    setCategoryWeights(category_weights);
    setCategoryMax(Math.max(...Array.from(category_weights.values())));
    setNumberBallots(queryOpinions[0].length);
  }

  useEffect(() => {
    refreshConvictions();
  }, [principal, sub]);

	return (
    <div>
      {
        numberBallots === 0 ? <></> :
        <div className="flex flex-col w-full border-y dark:border-gray-700">
          <SubBanner sub={sub}/>
          <div className="flex flex-col w-full">
            <ol className="w-full">
            {
              [...Array.from(convictions.entries())].map((elem, index) => (
                (
                  <li key={elem[0]}>
                    <PolarizationBar 
                      name={elem[0]}
                      showName={true}
                      polarizationInfo={toPolarizationInfo(sub.categories[index][1], CONSTANTS.CATEGORIZATION_INFO.center)}
                      polarizationValue={elem[1]}
                      polarizationWeight={(categoryWeights.get(elem[0]) ?? 0) / (categoryMax ?? 1)}
                      ballots={ballots.get(elem[0]) ?? []}
                      chartType={chartType}>
                    </PolarizationBar>
                  </li>
                )
              ))
            }
            </ol>
          </div>
          <div className="grid grid-cols-3 w-full items-center mt-2">
            <div className="text-xs font-light text-gray-400 place-self-center">
              { numberBallots.toString() + " votes" }
            </div>
            <ChartTypeToggle 
              chartType={chartType}
              setChartType={setChartType}
            />
          </div>
        </div>
      }
    </div>
	);
};

export default Convictions;
