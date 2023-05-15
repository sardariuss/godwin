import { CursorInfo, timeAgo } from "../../utils";

type BallotProps = {
  cursorInfo: CursorInfo;
  dateNs: bigint;
  children?: React.ReactNode;
};

const Ballot = ({cursorInfo, dateNs, children} : BallotProps) => {

  return (
    <div className="flex flex-row items-center w-full">
      <div className="flex flex-col items-center w-full grow justify-items-center">
        <div className="flex flex-row items-center">
          <span className="text-xs font-light">
            {cursorInfo.value.toFixed(2)}
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
        <div className="flex flex-row items-center">
          <div className="text-xs mt-1 font-extralight dark:text-gray-400 whitespace-nowrap">
            { timeAgo(new Date(Number(dateNs) / 1000000)) }
          </div>
        </div>
      </div>
    </div>
  );
};

export default Ballot;