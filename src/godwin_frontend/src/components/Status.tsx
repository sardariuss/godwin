import { Status } from "./../../declarations/godwin_backend/godwin_backend.did";

import { nsToStrDate, statusToString } from "../utils";

// @todo: put the SVGs into the assets directory
const statusToPath = (status: Status) => {
  if (status['CANDIDATE'] !== undefined) return "m550 972-42-42 142-142-382-382-142 142-42-42 56-58-56-56 85-85-42-42 42-42 43 41 84-84 56 56 58-56 42 42-142 142 382 382 142-142 42 42-56 58 56 56-86 86 42 42-42 42-42-42-84 84-56-56-58 56Z";
  if (status['OPEN'] !== undefined) return "M180 976q-24 0-42-18t-18-42V718l135-149 43 43-118 129h600L669 615l43-43 128 146v198q0 24-18 42t-42 18H180Zm0-60h600V801H180v115Zm262-245L283 512q-19-19-17-42.5t20-41.5l212-212q16.934-16.56 41.967-17.28Q565 198 583 216l159 159q17 17 17.5 40.5T740 459L528 671q-17 17-42 18t-44-18Zm249-257L541 264 333 472l150 150 208-208ZM180 916V801v115Z";
  if (status['CLOSED'] !== undefined) return "M431 922H180q-24 0-42-18t-18-42V280q0-24 15.5-42t26.5-18h202q7-35 34.5-57.5T462 140q36 0 63.5 22.5T560 220h202q24 0 42 18t18 42v203h-60V280H656v130H286V280H180v582h251v60Zm189-25L460 737l43-43 117 117 239-239 43 43-282 282ZM480 276q17 0 28.5-11.5T520 236q0-17-11.5-28.5T480 196q-17 0-28.5 11.5T440 236q0 17 11.5 28.5T480 276Z";
  if (status['REJECTED'] !== undefined) return "M480 534q69 0 116.5-50.5T644 362V236H316v126q0 71 47.5 121.5T480 534ZM160 976v-60h96V789q0-70 36.5-128.5T394 576q-65-26-101.5-85T256 362V236h-96v-60h640v60h-96v126q0 70-36.5 129T566 576q65 26 101.5 84.5T704 789v127h96v60H160Z";
  return "m249 849-42-42 231-231-231-231 42-42 231 231 231-231 42 42-231 231 231 231-42 42-231-231-231 231Z";
};

type Props = {
  status: Status;
  date: bigint;
  iteration: bigint;
  isHistory: boolean;
  showBorder: boolean;
  borderDashed: boolean;
};

const StatusComponent = ({status, date, iteration, isHistory, showBorder, borderDashed}: Props) => {

	return (
    <div className={(showBorder? ( borderDashed ? "border-l-2 border-dashed" : "border-l-2 border-solid") : "") + " relative text-gray-500 dark:text-gray-400 border-gray-200 dark:border-gray-500 pl-2 ml-4"}>
      <div className={"text-gray-900 dark:text-white " + (borderDashed ? "ml-6 pb-2" : "ml-6 pb-5")}>
        <span className={"absolute flex items-center justify-center w-8 h-8 rounded-full -left-4 ring-4 ring-white dark:ring-gray-900 " + ( isHistory ? "bg-gray-100 dark:bg-gray-700" : "bg-blue-200 dark:bg-blue-900" )} >
          <svg xmlns="http://www.w3.org/2000/svg" className={"w-5 h-5 " + ( isHistory ? "text-gray-500 dark:text-gray-400" : "text-blue-500 dark:text-blue-400" )} fill="currentColor" viewBox="0 96 960 960" width="48"><path d={statusToPath(status)}/></svg>
        </span>
        <div>
          <span className="font-light text-sm">{ statusToString(status) } </span>
          <span className="text-xs font-extralight"> { (iteration > 0 ? "(" + (Number(iteration) + 1).toString() + ")" : "") }</span>
        </div>
        <div className="text-xs font-extralight">{ nsToStrDate(date)}</div>
      </div>
    </div>
	);
};

export default StatusComponent;
