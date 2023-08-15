import PolarizationBar, { BallotPoint }               from "../base/PolarizationBar";
import ChartTypeToggle                                from "../base/ChartTypeToggle";
import { ChartTypeEnum, VoteKind, toPolarizationInfo,
  voteKindToCandidVariant, unwrapCategorizationVote } from "../../utils";
import CONSTANTS                                      from "../../Constants";
import { Sub }                                        from "../../ActorContext";
import { CategorizationVote }                         from "../../../declarations/godwin_sub/godwin_sub.did";

import React, { useState, useEffect }                 from "react";

type CategorizationPolarizationBarsProps = {
  sub: Sub;
  vote_id: bigint;
}

const CategorizationPolarizationBars = ({sub, vote_id}: CategorizationPolarizationBarsProps) => {

  const [vote,      setVote     ] = useState<CategorizationVote|undefined>(undefined            );
  const [chartType, setChartType] = useState<ChartTypeEnum               >(ChartTypeEnum.Bar    );

  const queryVote = async () => {
    const vote = await sub.actor.revealVote(voteKindToCandidVariant(VoteKind.CATEGORIZATION), vote_id);
    if (vote['ok'] !== undefined) {
      console.log(vote['ok']);
      setVote(unwrapCategorizationVote(vote['ok']));
    } else {
      console.error("Failed to query vote: ", vote['err']);
      setVote(undefined);
    }
  }

  useEffect(() => {
    queryVote();
  }, [vote_id]);

  const getBallotsFromCategory = (categorizationVote: CategorizationVote, category: string) : BallotPoint[] => {
    let ballots : BallotPoint[] = [];
    for (let [principal, ballot] of categorizationVote.ballots){
      for (let single_cat of ballot.answer) {
        if (single_cat[0] === category){
          ballots.push({
            label: principal.toString(),
            cursor: single_cat[1],
            date: ballot.date,
            coef: 1.0
          });
          break;
        }
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
          {[...Array.from(vote.aggregate)].map(([category, aggregate]) => (
            <li key={category}>
              <PolarizationBar 
                name={category}
                showName={true}
                polarizationInfo={toPolarizationInfo(sub.info.categories.get(category), CONSTANTS.CATEGORIZATION_INFO.center)}
                polarizationValue={aggregate}
                ballots={getBallotsFromCategory(vote, category)}
                chartType={chartType}
              />
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