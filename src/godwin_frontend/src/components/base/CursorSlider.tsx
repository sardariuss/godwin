import { PolarizationInfo, toCursorInfo } from '../../utils';

import { useState, useEffect }            from "react";

type Props = {
  id: string;
  disabled: boolean;
  cursor: number;
  polarizationInfo: PolarizationInfo;
  setCursor: (cursor: number) => (void);
  onMouseUp: () => (void);
  onMouseDown: () => (void);
};

export const CursorSlider = ({id, disabled, cursor, polarizationInfo, setCursor, onMouseUp, onMouseDown}: Props) => {

  const sliderWidth = 200;
  const thumbSize = 50;
  const marginWidth = thumbSize / 2;
  const marginRatio = marginWidth / sliderWidth;

  const [cursorInfo, setCursorInfo] = useState(toCursorInfo(cursor, polarizationInfo));

  const refreshValue = (value: number) => {
    setCursor(value);
    setCursorInfo(toCursorInfo(value, polarizationInfo));
  };

  useEffect(() => {
    refreshValue(cursor)
  }, [cursor]);

	return (
    <div id={"cursor_" + id} className="flex flex-col items-center">
      <div className="text-xs mb-2">
        { cursorInfo.name }
      </div>
      <input 
        id={"cursor_input_" + id}
        min="-1"
        max="1"
        step="0.02"
        value={cursorInfo.value}
        type="range"
        onChange={(e) => refreshValue(Number(e.target.value))}
        onMouseUp={(e) => onMouseUp()}
        onMouseDown={(e) => onMouseDown()}
        className={"input appearance-none"} 
        style={{
          "--progress-percent": `${ ((marginRatio + ((cursorInfo.value + 1) * 0.5) * (1 - 2 * marginRatio)) * 100).toString() + "%"}`,
          "--slider-left-color": `${cursorInfo.colors.left}`,
          "--slider-right-color": `${cursorInfo.colors.right}`,
          "--margin-left": `${(marginRatio * 100).toString() + "%"}`,
          "--margin-right": `${((1 - marginRatio) * 100).toString() + "%"}`,
          "--slider-width": `${sliderWidth + "px"}`,
          "--slider-image": `url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' height='128px' width='128px' style='fill:black;font-size:64px;'><text x='50%' y='50%' dominant-baseline='middle' text-anchor='middle'>` + `${cursorInfo.symbol}` + `</text></svg>")`,
          "--thumb-size": `${thumbSize + "px"}`,
          "--cursor-type": `${disabled ? "auto" : "grab"}`
        } as React.CSSProperties }
        disabled={disabled}
      />
      <div className="text-xs font-extralight mt-1">
        { cursorInfo.value.toFixed(2) }
      </div>
    </div>
	);
};

