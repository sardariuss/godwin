import { frome9s } from "../token/TokenUtils";
import Coin        from "../icons/Coin";
import CONSTANTS   from "../../Constants";

import React       from "react";

type Props = {
  amount: bigint | undefined;
}

const Balance = ({amount} : Props) => {
  return (
    <div className="flex flex-row space-x-1 items-center">
      <div>
        { frome9s(amount !== undefined ? amount : BigInt(0)).toFixed(CONSTANTS.TOKEN_DECIMALS) }
      </div>
      <div className="w-4 h-4">
        <Coin/>
      </div>
    </div>
  );
}

export default Balance;