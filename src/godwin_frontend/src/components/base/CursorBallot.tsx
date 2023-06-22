import { CursorInfo, }             from "../../utils";
import { timeAgo }                 from "../../utils/DateUtils";
import HiddenIcon                  from "../icons/HiddenIcon";
import { TransactionsRecord }      from "../../../declarations/godwin_sub/godwin_sub.did";

import TransactionsRecordComponent from "../token/TransactionsRecord";

export type CursorBallotProps = {
  cursorInfo: CursorInfo | null;
  dateNs: bigint | null;
  tx_record: TransactionsRecord | undefined;
};

const CursorBallot = ({cursorInfo, dateNs, tx_record} : CursorBallotProps) => {

  return (
    <div className="flex flex-row items-center w-full grow">
      <div className="flex flex-col items-center w-full justify-items-center">
        {
          cursorInfo === null ? 
          <div className="w-6 h-6 icon-svg">
            <HiddenIcon/>
          </div> : 
            <div className="flex flex-col items-center">
              <div className="flex flex-row items-center">
                <span className="text-xs font-light">
                  {}
                </span>
                <span className="ml-1 text-md">
                  {cursorInfo.symbol}
                </span>
              </div>
              <div className="px-8 h-2 bar-result items-center"
                style={{
                  "--progress-percent": `${ (((cursorInfo.value + 1) * 0.5) * 100).toString() + "%"}`,
                  "--slider-left-color": `${cursorInfo.colors.left}`,
                  "--slider-right-color": `${cursorInfo.colors.right}`,
                } as React.CSSProperties }>
              </div>
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
        {
          tx_record === undefined ? <></> :
          <TransactionsRecordComponent tx_record={tx_record}/>
        }
      </div>
    </div>
  );
};

export default CursorBallot;