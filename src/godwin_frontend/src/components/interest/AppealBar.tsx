import PolarizationBar                     from "../base/PolarizationBar";
import { InterestVote }                    from "../../../declarations/godwin_backend/godwin_backend.did";
import { ChartTypeEnum, PolarizationInfo } from "../../utils";

type AppealBarProps = {
  name: string;
  showName: boolean;
  polarizationInfo: PolarizationInfo;
  vote: InterestVote;
}

// @todo: do not use a PolarizationBar, but a new component
const AppealBar = ({name, showName, polarizationInfo, vote}: AppealBarProps) => {

  return (
    <div className="flex flex-col w-full">
      <div className="w-full">
        <PolarizationBar 
          name={name}
          showName={showName}
          polarizationInfo={polarizationInfo}
          polarizationValue={{ left: Number(vote.aggregate.downs), center: 0, right: Number(vote.aggregate.ups) }}
          ballots={[]}
          chartType={ChartTypeEnum.Bar}>
        </PolarizationBar>
      </div>
      <div className="grid grid-cols-3 w-full items-center">
        <div className="text-xs font-light text-gray-600 dark:text-gray-400 place-self-center">
          { (vote.aggregate.ups + vote.aggregate.downs).toString() + " voters" }
        </div>
        <div>
          {/* space */}
        </div>
        <div className="text-xs font-light text-gray-600 dark:text-gray-400 place-self-center">
          { "id " + vote.id.toString() }
        </div>
      </div>
    </div>
  );
}

export default AppealBar;