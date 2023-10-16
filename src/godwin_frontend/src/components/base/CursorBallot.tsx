import HiddenIcon                  from "../icons/HiddenIcon";
import CertifiedIcon               from "../icons/CertifiedIcon";
import { CursorInfo }              from "../../utils";
import { timeAgo }                 from "../../utils/DateUtils";
import { TransactionsRecord }      from "../../../declarations/godwin_sub/godwin_sub.did";

import TransactionsRecordComponent from "../token/TransactionsRecord";

import React                       from "react";

export type CursorBallotProps = {
  cursorInfo: CursorInfo | undefined;
  dateNs?: bigint;
  isLate?: boolean;
  tx_record?: TransactionsRecord;
  showValue?: boolean;
};

const CursorBallot = ({cursorInfo, dateNs, isLate, tx_record, showValue} : CursorBallotProps) => {

  return (
    <div className="flex flex-row items-center">
      <div className="flex flex-col items-center justify-items-center">
        {
          cursorInfo === undefined ? 
          <div className="w-6 h-6 icon-svg">
            <HiddenIcon/>
          </div> : 
            <div className={`flex flex-col items-center`}>
              <div className="flex flex-row items-center">
                {
                  showValue !== undefined && showValue ?
                  <span className="text-xs font-light">
                    {cursorInfo.value.toFixed(2)}
                  </span> : <></>
                }
                <span className={`ml-1 text-md`}>
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
          dateNs !== undefined ? 
          <div className="flex flex-row items-center mt-1 gap-x-1">
            <div className="text-xs font-extralight dark:text-gray-400 whitespace-nowrap">
              { timeAgo(new Date(Number(dateNs) / 1000000)) }
            </div>
            <div className="w-4 h-4">
            {
              isLate ? <></> : <CertifiedIcon/>
            }
            </div>
          </div> : <></>
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