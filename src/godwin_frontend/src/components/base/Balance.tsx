import BitcoinToken from "../icons/BitcoinToken";
import GodwinToken from "../icons/GodwinToken";
import { LedgerType, LedgerUnit } from "../token/TokenTypes"
import { ledgerToTokenUnit, balanceToString } from "../../utils/LedgerUtils";

import { useState } from "react";

type Props = {
  amount: bigint | undefined;
  ledger_type: LedgerType;
  default_unit?: LedgerUnit;
  allow_conversion?: boolean;
}

const Balance = ({amount, ledger_type, default_unit, allow_conversion} : Props) => {

  const [unit, setUnit] = useState<LedgerUnit>(default_unit === undefined ? LedgerUnit.E8S : default_unit);

  const changeUnit = () => {
    if (allow_conversion) {
      setUnit(unit === LedgerUnit.E8S ? LedgerUnit.ORIGINAL : LedgerUnit.E8S);
    }
  }

  return (
      <div className={`flex flex-row space-x-1 items-center px-1 ${allow_conversion ? "hover:cursor-pointer text-gray-700 dark:text-gray-300 hover:text-black dark:hover:text-white" : ""}`}
        onClick={(e) => { changeUnit()}}>
        { 
          ledger_type === LedgerType.BTC ? 
            <div className="w-4 h-4">
              <BitcoinToken/>
            </div>
          : ledger_type === LedgerType.GWC ? 
            <div className="w-5 h-5">
              <GodwinToken/>
            </div> 
          : <></> 
        }
      <span>
        <span>
          { balanceToString(amount, unit) }
        </span>
        <span className={`font-extralight text-xs pl-1 ${unit === LedgerUnit.E8S ? "italic" : ""}`}>
          { ledgerToTokenUnit(ledger_type, unit) }
        </span>
      </span>
    </div>
  );
}

export default Balance;