import { BarChart }            from "../charts/BarChart";
import CONSTANTS               from "../../Constants";
import { Sub }                 from "../../ActorContext";
import { InterestVote }        from "../../../declarations/godwin_sub/godwin_sub.did";

import { useState, useEffect } from "react";

export const voteLabels = (ctx: any) : string => {
  return ctx.dataset.labels[ctx.dataIndex] + " " + ctx.parsed.x;
}

const getBarChartData = (vote: InterestVote) => {
  const labels = ['INTEREST'];

  const border_color =  document.documentElement.classList.contains('dark') ? CONSTANTS.CHART.BORDER_COLOR_DARK : CONSTANTS.CHART.BORDER_COLOR_LIGHT;

  return {
    labels,
    datasets: [
      {
        borderColor: border_color,
        borderWidth: 1.2,
        borderSkipped: false,
        labels: [CONSTANTS.INTEREST_INFO.down.name + " " + CONSTANTS.INTEREST_INFO.down.symbol],
        data: labels.map(() => Number(vote.aggregate.downs)),
        backgroundColor: CONSTANTS.INTEREST_INFO.down.color,
      },
      {
        borderColor: border_color,
        borderWidth: 1.2,
        borderSkipped: false,
        labels: [CONSTANTS.INTEREST_INFO.up.name + " " + CONSTANTS.INTEREST_INFO.up.symbol],
        data: labels.map(() => Number(vote.aggregate.ups)),
        backgroundColor: CONSTANTS.INTEREST_INFO.up.color,
      },
    ],
  };
}

type AppealBarProps = {
  sub: Sub;
  vote_id: bigint;
}

const AppealBar = ({sub, vote_id}: AppealBarProps) => {

  const [vote,    setVote   ] = useState<InterestVote|undefined>(         );
  const [barData, setBarData] = useState<any                   >(undefined);

  const queryVote = async () => {
    const vote = await sub.actor.revealInterestVote(vote_id);
    if (vote['ok'] !== undefined) {
      setVote(vote['ok']);
    } else {
      console.error("Failed to query vote: ", vote['err']);
      setVote(undefined);
    }
  }

  const refreshData = () => {
    if (vote !== undefined) {
      setBarData(getBarChartData(vote));
    }
  }

  useEffect(() => {
    queryVote();
  }, [vote_id]);

  useEffect(() => {
    refreshData();
  }, [vote]);

  return (
    vote === undefined ? <></> :
    <div className="flex flex-col w-full">
      {
        vote.ballots.length > 0 && barData !== undefined ?
          <div className="grid grid-cols-5 w-full">
            <div className="flex flex-col items-center z-10 grow place-self-center text-3xl">
              { CONSTANTS.INTEREST_INFO.down.symbol }
            </div>
            <div className={"col-span-3 z-0 grow max-h-16 w-full"}>
              <BarChart chart_data={barData} generate_label={voteLabels} bar_size={vote.ballots.length}/>
            </div>
            <div className="flex flex-col items-center z-10 grow place-self-center text-3xl">
              { CONSTANTS.INTEREST_INFO.up.symbol }
            </div>
          </div> : <></>
      }
      <div className="grid grid-cols-3 w-full items-center">
        <div className="text-xs font-light text-gray-600 dark:text-gray-400 place-self-center">
          { (vote.aggregate.ups + vote.aggregate.downs).toString() + " votes" }
        </div>
        <div>{ /* spacer */ }</div>
        <div className="text-xs font-light text-gray-600 dark:text-gray-400 place-self-center">
          { "id " + vote.id.toString() }
        </div>
      </div>
    </div>
  );
}

export default AppealBar;