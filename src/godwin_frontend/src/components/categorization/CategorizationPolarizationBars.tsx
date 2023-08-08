import PolarizationBar, { BallotPoint }      from "../base/PolarizationBar";
import ChartTypeToggle                       from "../base/ChartTypeToggle";
import { ChartTypeEnum, toPolarizationInfo } from "../../utils";
import CONSTANTS                             from "../../Constants";
import { Sub }                               from "../../ActorContext";
import { CategorizationVote }                from "../../../declarations/godwin_sub/godwin_sub.did";

import React, { useState, useEffect }        from "react";

type CategorizationPolarizationBarsProps = {
  sub: Sub;
  vote_id: bigint;
}

const CategorizationPolarizationBars = ({sub, vote_id}: CategorizationPolarizationBarsProps) => {

  const [vote,      setVote     ] = useState<CategorizationVote|undefined>(undefined            );
  const [chartType, setChartType] = useState<ChartTypeEnum               >(ChartTypeEnum.Bar    );

  const queryVote = async () => {
    const vote = await sub.actor.revealCategorizationVote(vote_id);
    if (vote['ok'] !== undefined) {
      setVote(vote['ok']);
    } else {
      console.error("Failed to query vote: ", vote['err']);
      setVote(undefined);
    }
  }

  useEffect(() => {
    queryVote();
  }, [vote_id]);

  // @todo: do not use the index
  const getBallotsFromCategory = (categorizationVote: CategorizationVote, cat_index: number) : BallotPoint[] => {
    let ballots : BallotPoint[] = [];
    for (let [principal, ballot] of categorizationVote.ballots){
      if (ballot.answer[cat_index] !== undefined){
        ballots.push({
          label: principal.toString(),
          cursor: ballot.answer[cat_index][1],
          date: ballot.date,
          coef: 1.0
        });
      }
    }
    return ballots;
  }

  return (
    vote === undefined ? <></> :
    <div className="flex flex-col w-full">
      {
        vote.ballots.length === 0 ? <></> :
        <ol className="w-full">
          {[...Array.from(vote.aggregate)].map(([category, aggregate], index) => (
            <li key={category}>
              <PolarizationBar 
                name={category}
                showName={true}
                polarizationInfo={toPolarizationInfo(sub.info.categories.get(category), CONSTANTS.CATEGORIZATION_INFO.center)}
                polarizationValue={aggregate}
                ballots={getBallotsFromCategory(vote, index)}
                chartType={chartType}>
              </PolarizationBar>
            </li>
          ))}
        </ol>
      }
      <div className="grid grid-cols-3 w-full items-center mt-2">
        <div className="text-xs font-light text-gray-400 place-self-center">
          { (vote.aggregate[0][1].left + vote.aggregate[0][1].center + vote.aggregate[0][1].right).toString() + " votes" }
        </div>
        <ChartTypeToggle 
          chartType={chartType}
          setChartType={setChartType}
        />
        <div className="text-xs font-light place-self-center">
          { "id " + vote.id.toString() }
        </div>
      </div>
    </div>
  );
}

export default CategorizationPolarizationBars;