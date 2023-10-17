import { frome9s } from "../token/TokenUtils";
import CONSTANTS   from "../../Constants";

type Props = {
  amount: bigint | undefined;
}

const Balance = ({amount} : Props) => {
  return (
    <div className="flex flex-row space-x-1 items-center">
      <div>
        { frome9s(amount !== undefined ? amount : BigInt(0)).toFixed(CONSTANTS.TOKEN_DECIMALS) }
      </div>
      <img src="single_ball.png" alt="single_ball" className="h-5"></img>
    </div>
  );
}

export default Balance;