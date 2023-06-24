import { frome8s } from "../token/TokenUtils";
import Coin        from "../icons/Coin";
import CONSTANTS   from "../../Constants";

type Props = {
  amount: bigint | undefined;
}

const Balance = ({amount} : Props) => {
  return (
    <div className="flex flex-row space-x-1 items-center text-black dark:text-white">
      <div>
        { frome8s(amount !== undefined ? amount : BigInt(0)).toFixed(CONSTANTS.TOKEN_DECIMALS) }
      </div>
      <div className="w-4 h-4">
        <Coin/>
      </div>
    </div>
  );
}

export default Balance;