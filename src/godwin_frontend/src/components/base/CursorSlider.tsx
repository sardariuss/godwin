import { PolarizationInfo, toCursorInfo }     from '../../utils';

import React, { useState, useEffect, useRef } from "react";

type Props = {
  id: string;
  disabled: boolean;
  cursor: number;
  polarizationInfo: PolarizationInfo;
  setCursor: (cursor: number) => (void);
  onMouseUp: () => (void);
  onMouseDown: () => (void);
  isLate: boolean;
};

export const CursorSlider = ({id, disabled, cursor, polarizationInfo, setCursor, onMouseUp, onMouseDown, isLate}: Props) => {

  const [cursorInfo, setCursorInfo] = useState(toCursorInfo(cursor, polarizationInfo));

  const minimum_slider_width = 200;
  const maximum_slider_width = 500;

  const [thumbSize] = useState(50);
  const [marginWidth] = useState(25);
  const [marginRatio, setMarginRatio] = useState(marginWidth / 200);
  const [sliderWidth, setSliderWidth] = useState(200);

  const demoRef = useRef<any>();

  useEffect(() => {
    const resizeObserver = new ResizeObserver((event) => {
      // Depending on the layout, you may need to swap inlineSize with blockSize
      // https://developer.mozilla.org/en-US/docs/Web/API/ResizeObserverEntry/contentBoxSize
      let width = Math.min(maximum_slider_width, Math.max(minimum_slider_width, event[0].contentBoxSize[0].inlineSize));
      setSliderWidth(width);
      setMarginRatio(marginWidth / width);
    });

    if (demoRef) {
      resizeObserver.observe(demoRef.current);
    }

    return () => {
      resizeObserver.disconnect();
    }
  }, [demoRef]);

  const refreshValue = (value: number) => {
    setCursor(value);
    setCursorInfo(toCursorInfo(value, polarizationInfo));
  };

  useEffect(() => {
    refreshValue(cursor)
  }, [cursor]);

	return (
    <div id={"cursor_" + id} className="w-full flex flex-col items-center" ref={demoRef}>
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
        onTouchEnd={(e) => onMouseUp()}
        onMouseUp={(e) => onMouseUp()}
        onTouchStart={(e) => onMouseDown()}
        onMouseDown={(e) => onMouseDown()}
        className={`input appearance-none ${isLate ? "late-vote" : ""}`} 
        style={{
          "--progress-percent": `${ ((marginRatio + ((cursorInfo.value + 1) * 0.5) * (1 - 2 * marginRatio)) * 100).toString() + "%"}`,
          "--slider-left-color": `${cursorInfo.colors.left}`,
          "--slider-right-color": `${cursorInfo.colors.right}`,
          "--margin-left": `${(marginRatio * 100).toString() + "%"}`,
          "--margin-right": `${((1 - marginRatio) * 100).toString() + "%"}`,
          "--slider-width": `${sliderWidth + "px"}`,
          "--slider-image": `url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' height='128px' width='128px' style='fill:black;font-size:64px;'><text x='50%' y='50%' opacity='1' dominant-baseline='middle' text-anchor='middle'>` + `${cursorInfo.symbol}` + `</text></svg>")`,
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

