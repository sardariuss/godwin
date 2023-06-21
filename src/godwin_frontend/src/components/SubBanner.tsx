import { Sub }      from "../ActorContext";
import Momentum     from "./Momentum";

import { useState } from "react";

type Props = {
  sub: Sub;
};

const SubBanner = ({sub} : Props) => {

  const [shift, setShift] = useState<number>(0);
  const [diff,  setDiff ] = useState<number>(0);

  return (
    <div className="flex flex-col text-center w-full items-center">
      <div className="w-full bg-gradient-to-r from-purple-200 dark:from-purple-700 from-10% dark:via-indigo-800 via-indigo-100 via-30% dark:to-sky-600 to-sky-200 to-90% text-black dark:text-white font-medium pt-2 pb-1">
        { sub.name }
      </div>
      <div className="relative w-full overflow-clip bg-gray-200 dark:bg-gray-700 py-1">
        <div className="dark:text-white font-normal whitespace-nowrap"
          style={{transform: `translate(` + `${(shift - diff) * 100}` + `vw, 0)`}}>
          { sub.categories.map((category, index) => 
            <span key={category[0]}>
              <span className="text-xs font-medium">{category[1].left.name.toLocaleLowerCase()  + " " }</span>
              <span>{category[1].left.symbol}</span>
              <span className="text-xs font-light">{" vs "}</span>
              <span>{category[1].right.symbol}</span>
              <span className="text-xs font-medium">{" " + category[1].right.name.toLocaleLowerCase() }</span>
              {
                index < sub.categories.length - 1 ? 
                <span>{" · "}</span> : <></>
              }
            </span>
          )}
        </div>
        <div className="absolute inset-0 w-full flex flex-col self-align-center">
          <input 
            id={"cursor_test"}
            min="-0.5"
            max="0.5"
            step="0.01"
            type="range"
            onChange={(e) => { if (diff === 0) { setDiff(Number(e.target.value) - shift) }; setShift(Number(e.target.value)); }}
            onMouseUp={(e) => { setShift(shift - diff); setDiff(0);}}
            onMouseDown={(e) => {}}
            className={"input categories appearance-none h-16 w-full grow"}
            style={{"--cursor-hover" : `grab`, "--cursor-grabbing" : `grabbing`} as React.CSSProperties }
          />
        </div>
      </div>
      <div className="bg-slate-100 dark:bg-gray-800 text-xs font-light relative w-full overflow-clip bg-gray-100 dark:bg-gray-700 py-1 dark:text-white font-normal whitespace-nowrap">
        <Momentum sub={sub}/>
      </div>
    </div>
  );
}

export default SubBanner;