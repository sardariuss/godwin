import { Sub }             from "../ActorContext";
import Momentum            from "./Momentum";

import React, { useState } from "react";
import { Link }            from "react-router-dom";

type Props = {
  sub: Sub;
};

const SubBanner = ({sub} : Props) => {

  const [shift, setShift] = useState<number>(0);
  const [diff,  setDiff ] = useState<number>(0);

  return (
    <div className="flex flex-col text-center w-full items-center">
      <Link className="w-full text-black dark:text-white font-medium pt-2 pb-1
          bg-gradient-to-r from-purple-200 dark:from-purple-700 from-10% 
                           via-indigo-100  dark:via-indigo-800  via-30% 
                           to-sky-200      dark:to-sky-600      to-90%" to={"/sub/" + sub.id}>
        { sub.info.name }
      </Link>
      { /* use a gradient because setting the background color normally does not apply to the sides (when scrolling the bar left and right) */ }
      <div className="relative w-full overflow-clip bg-gradient-to-b from-gray-200 from-50% to-slate-100 to-50% dark:from-gray-700 dark:from-50% dark:to-gray-800 dark:to-50%">
        <div className="dark:text-white flex flex-col font-normal whitespace-nowrap w-full items-center"
          style={{transform: `translate(` + `${(shift - diff) * 100}` + `vw, 0)`}}>
          <div>
          { [...Array.from(sub.info.categories)].map((category, index) => 
            <span key={category[0]}>
              <span className="text-xs font-medium">{category[1].left.name.toLocaleLowerCase()  + " " }</span>
              <span>{category[1].left.symbol}</span>
              <span className="text-xs font-light">{" vs "}</span>
              <span>{category[1].right.symbol}</span>
              <span className="text-xs font-medium">{" " + category[1].right.name.toLocaleLowerCase() }</span>
              {
                index < sub.info.categories.size - 1 ? 
                <span>{" · "}</span> : <></>
              }
            </span>
          )}
          </div>
          <div className="text-xs font-light py-1 dark:text-white font-normal whitespace-nowrap">
            <Momentum sub={sub}/>
          </div>
        </div>
        <div className="absolute inset-0 w-full flex flex-col self-align-center">
          <input 
            id={"cursor_test"}
            min="-0.5"
            max="0.5"
            step="0.01"
            type="range"
            onChange={(e) => { if (diff === 0) { setDiff(Number(e.target.value) - shift) }; setShift(Number(e.target.value)); }}
            onTouchEnd={(e) => { setShift(shift - diff); setDiff(0);}}
            onMouseUp={(e) => { setShift(shift - diff); setDiff(0);}}
            className={"input categories appearance-none h-16 w-full grow"}
            style={{"--cursor-hover" : `grab`, "--cursor-grabbing" : `grabbing`} as React.CSSProperties }
          />
        </div>
      </div>
    </div>
  );
}

export default SubBanner;