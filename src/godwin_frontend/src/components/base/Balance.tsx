import { frome9s } from "../token/TokenUtils";
import Coin        from "../icons/Coin";
import CONSTANTS   from "../../Constants";
import SatToken from "../icons/SatToken";
import GodwinToken from "../icons/GodwinToken";
import { LedgerType } from "../token/TokenTypes"

type Props = {
  amount: bigint | undefined;
  ledger_type: LedgerType;
}

const Balance = ({amount, ledger_type} : Props) => {
  return (
    <div className="flex flex-row space-x-1 items-center px-1">
      <div>
        { (amount !== undefined ? amount : BigInt(0)).toString() }
      </div>
        { 
          ledger_type === LedgerType.BTC ? 
            <div className="w-4 h-4">
              <SatToken/>
            </div>
          : ledger_type === LedgerType.GWC ? 
            <div className="w-5 h-5">
              <GodwinToken/>
            </div> 
          : <></> 
        }
    </div>
  );
}

export default Balance;