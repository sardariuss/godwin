import PolarizationBar                         from "../base/PolarizationBar";
import ChartTypeToggle                         from "../base/ChartTypeToggle";
import { OpinionVote }                         from "../../../declarations/godwin_sub/godwin_sub.did";
import { ChartTypeEnum, VoteKind, 
  voteKindToCandidVariant, unwrapOpinionVote } from "../../utils";
import CONSTANTS                               from "../../Constants";
import { Sub }                                 from "../../ActorContext";

import React, { useState, useEffect }          from "react";
import { fromNullable }                        from "@dfinity/utils";

type OpinionPolarizationBarProps = {
  sub: Sub;
  vote_id: bigint;
}

const OpinionPolarizationBar = ({sub, vote_id}: OpinionPolarizationBarProps) => {

  const [vote,      setVote     ] = useState<OpinionVote | undefined>(undefined        );
  const [chartType, setChartType] = useState<ChartTypeEnum          >(ChartTypeEnum.Bar);

  const queryVote = async () => {
    const vote = await sub.actor.revealVote(voteKindToCandidVariant(VoteKind.OPINION), vote_id);
    if (vote['ok'] !== undefined) {
      console.log(vote['ok']);
      setVote(unwrapOpinionVote(vote['ok']));
    } else {
      console.error("Failed to query vote: ", vote['err']);
      setVote(undefined);
    }
  }

  useEffect(() => {
    queryVote();
  }, [vote_id]);

  return (
    vote === undefined ? <></> :
    <div className="flex flex-col w-full">
      { vote.ballots.length === 0 ? <></> :
      <div className="w-full">
        <PolarizationBar 
          name={"OPINION"}
          showName={false}
          polarizationInfo={CONSTANTS.OPINION_INFO}
          polarizationValue={vote.aggregate.polarization}
          ballots={
            // Do not show late ballots
            vote.ballots.filter(([_, ballot]) => { return fromNullable(ballot.answer.late_decay) === undefined })
            .map(([principal, ballot]) => { return { label: principal.toString(), cursor: ballot.answer.cursor, date: ballot.date, coef: 1.0 }})
          }
          chartType={chartType}/>
      </div>
      }
      <div className="grid grid-cols-3 w-full items-center">
        <div className="text-xs font-light text-gray-600 dark:text-gray-400 place-self-center">
          { (vote.aggregate.polarization.left + vote.aggregate.polarization.center + vote.aggregate.polarization.right).toString() + " votes" }
        </div>
        <ChartTypeToggle 
          chartType={chartType}
          setChartType={setChartType}
        />
        <div className="text-xs font-light text-gray-600 dark:text-gray-400 place-self-center">
          { "id " + vote.id.toString() }
        </div>
      </div>
    </div>
  );
}

export default OpinionPolarizationBar;