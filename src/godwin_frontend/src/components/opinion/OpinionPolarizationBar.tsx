import PolarizationBar                     from "../base/PolarizationBar";
import ChartTypeToggle                     from "../base/ChartTypeToggle";
import { OpinionVote }                     from "../../../declarations/godwin_sub/godwin_sub.did";
import { ChartTypeEnum, PolarizationInfo } from "../../utils";

import { useState }                        from "react";

type OpinionPolarizationBarProps = {
  name: string;
  showName: boolean;
  polarizationInfo: PolarizationInfo;
  vote: OpinionVote;
}

const OpinionPolarizationBar = ({name, showName, polarizationInfo, vote}: OpinionPolarizationBarProps) => {

  const [chartType, setChartType] = useState<ChartTypeEnum>(ChartTypeEnum.Bar);

  return (
    <div className="flex flex-col w-full">
      <div className="w-full">
        <PolarizationBar 
          name={name}
          showName={showName}
          polarizationInfo={polarizationInfo}
          polarizationValue={vote.aggregate}
          ballots={vote.ballots.map(([principal, ballot]) => { return {
            label: principal.toString(),
            cursor: ballot.answer,
            date: ballot.date,
            coef: 1.0
          }})}
          chartType={chartType}>
        </PolarizationBar>
      </div>
      <div className="grid grid-cols-3 w-full items-center">
        <div className="text-xs font-light text-gray-600 dark:text-gray-400 place-self-center">
          { (vote.aggregate.left + vote.aggregate.center + vote.aggregate.right).toString() + " voters" }
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