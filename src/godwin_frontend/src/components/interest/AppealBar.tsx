import { BarChart }            from "../charts/BarChart";
import { passthroughLabel }    from "../charts/ChartUtils";
import { InterestVote }        from "../../../declarations/godwin_backend/godwin_backend.did";
import { PolarizationInfo }    from "../../utils";

import { useState, useEffect } from "react";

import CONSTANTS               from "../../Constants";

const getBarChartData = (vote: InterestVote) => {
  const labels = ['INTEREST'];

  const border_color =  document.documentElement.classList.contains('dark') ? CONSTANTS.BAR_CHART_BORDER_COLOR_DARK : CONSTANTS.BAR_CHART_BORDER_COLOR_LIGHT;

  return {
    labels,
    datasets: [
      {
        borderColor: border_color,
        borderWidth: 1.2,
        borderSkipped: false,
        labels: [CONSTANTS.INTEREST_INFO.down.symbol],
        data: labels.map(() => Number(vote.aggregate.downs)),
        backgroundColor: CONSTANTS.INTEREST_INFO.down.color,
      },
      {
        borderColor: border_color,
        borderWidth: 1.2,
        borderSkipped: false,
        labels: [CONSTANTS.INTEREST_INFO.up.symbol],
        data: labels.map(() => Number(vote.aggregate.ups)),
        backgroundColor: CONSTANTS.INTEREST_INFO.up.color,
      },
    ],
  };
}

type AppealBarProps = {
  name: string;
  polarizationInfo: PolarizationInfo;
  vote: InterestVote;
}

const AppealBar = ({vote}: AppealBarProps) => {

  const [barData, setBarData] = useState<any>(getBarChartData(vote));

  const refreshData = () => {
    setBarData(getBarChartData(vote));
  }

  useEffect(() => {
    refreshData();
  }, [vote]);

  return (
    <div className="flex flex-col w-full">
      <div className="grid grid-cols-5 w-full">
        <div className="flex flex-col items-center z-10 grow place-self-center">
          <div className="text-3xl">{ CONSTANTS.INTEREST_INFO.down.symbol }</div>
          <div className="text-xs font-extralight">{ CONSTANTS.INTEREST_INFO.down.name }</div>
        </div>
        <div className={"col-span-3 z-0 grow max-h-16 w-full"}>
          <BarChart chart_data={barData} generate_label={passthroughLabel} />
        </div>
        <div className="flex flex-col items-center z-10 grow place-self-center">
          <div className="text-3xl">{ CONSTANTS.INTEREST_INFO.up.symbol }</div>
          <div className="text-xs font-extralight">{ CONSTANTS.INTEREST_INFO.up.name }</div>
        </div>
      </div>
      <div className="grid grid-cols-3 w-full items-center">
        <div className="text-xs font-light text-gray-600 dark:text-gray-400 place-self-center">
          { (vote.aggregate.ups + vote.aggregate.downs).toString() + " voters" }
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