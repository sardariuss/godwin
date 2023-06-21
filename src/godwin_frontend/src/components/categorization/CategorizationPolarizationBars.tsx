import PolarizationBar, { BallotPoint }               from "../base/PolarizationBar";
import ChartTypeToggle                                from "../base/ChartTypeToggle";
import { ChartTypeEnum, toPolarizationInfo }          from "../../utils";
import CONSTANTS                                      from "../../Constants";
import { CategorizationVote, Category, CategoryInfo } from "../../../declarations/godwin_backend/godwin_backend.did";

import { useState }                                   from "react";

type CategorizationPolarizationBarsProps = {
  showName: boolean;
  categorizationVote: CategorizationVote;
  categories: Map<Category, CategoryInfo>
}

const CategorizationPolarizationBars = ({showName, categorizationVote, categories}: CategorizationPolarizationBarsProps) => {

  const [chartType, setChartType] = useState<ChartTypeEnum>(ChartTypeEnum.Bar);

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
    <div className="flex flex-col w-full">
      <ol className="w-full">
        {[...Array.from(categorizationVote.aggregate)].map(([category, aggregate], index) => (
          <li key={category}>
            <PolarizationBar 
              name={category}
              showName={showName}
              polarizationInfo={toPolarizationInfo(categories.get(category), CONSTANTS.CATEGORIZATION_INFO.center)}
              polarizationValue={aggregate}
              ballots={getBallotsFromCategory(categorizationVote, index)}
              chartType={chartType}>
            </PolarizationBar>
          </li>
        ))}
      </ol>
      <div className="grid grid-cols-3 w-full items-center mt-2">
        <div className="text-xs font-light text-gray-400 place-self-center">
          { (categorizationVote.aggregate[0][1].left + categorizationVote.aggregate[0][1].center + categorizationVote.aggregate[0][1].right).toString() + " voters" }
        </div>
        <ChartTypeToggle 
          chartType={chartType}
          setChartType={setChartType}
        />
        <div className="text-xs font-light place-self-center">
          { "id " + categorizationVote.id.toString() }
        </div>
      </div>
    </div>
  );
}

export default CategorizationPolarizationBars;