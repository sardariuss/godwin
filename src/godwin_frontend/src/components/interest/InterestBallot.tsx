import { InterestEnum, getInterestInfo, InterestInfo } from "./InterestTypes";
import HiddenIcon                                      from "../icons/HiddenIcon";
import { timeAgo }                                     from "../../utils/DateUtils";

import { useState, useEffect }                         from "react";

export type InterestBallotInput = {
  answer: InterestEnum | null;
  dateNs: bigint | null;
};

const InterestBallot = ({answer, dateNs} : InterestBallotInput) => {

  const [interestInfo, setInterestInfo] = useState<InterestInfo | null>(answer !== null ? getInterestInfo(answer) : null);

  useEffect(() => {
    setInterestInfo(answer !== null ? getInterestInfo(answer) : null);
  }, [answer]);

  return (
    <div className="flex flex-col items-center w-full grow justify-items-center">
      {
        interestInfo === null ? 
          <div className="w-6 h-6 icon-svg">
            <HiddenIcon/>
          </div> : 
          <div className="flex flex-col items-center">
            <span className="text-xs font-light">
              {interestInfo.name}
            </span>
            <span className="text-xl">
              {interestInfo.symbol}
            </span>
          </div>
      }
      { 
        dateNs === null ?  <></> :
        <div className="flex flex-row items-center">
          <div className="text-xs mt-1 font-extralight dark:text-gray-400 whitespace-nowrap">
            { timeAgo(new Date(Number(dateNs) / 1000000)) }
          </div>
        </div>
      }
    </div>
  );
};

export default InterestBallot;