import PolarizationBar from "./PolarizationBar";
import ChartTypeToggle from "./ChartTypeToggle";
import { PublicVote } from "../../../declarations/godwin_backend/godwin_backend.did";
import { ChartTypeEnum, PolarizationInfo } from "../../utils";

import { useState } from "react";

type SinglePolarizationBarProps = {
  name: string;
  showName: boolean;
  polarizationInfo: PolarizationInfo;
  vote: PublicVote;
}

const SinglePolarizationBar = ({name, showName, polarizationInfo, vote}: SinglePolarizationBarProps) => {

  const [chartType, setChartType] = useState<ChartTypeEnum>(ChartTypeEnum.Bar);

  return (
    <div className="flex flex-col w-full">
      <div className="w-full">
        <PolarizationBar 
          name={name}
          showName={showName}
          polarizationInfo={polarizationInfo}
          polarizationValue={vote.aggregate}
          ballots={vote.ballots.map(([principal, ballot]) => { return [principal.toText(), ballot, 1.0] })}
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

export default SinglePolarizationBar;