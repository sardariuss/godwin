import Color from 'colorjs.io';

import { CategorySide } from "./../../../declarations/godwin_backend/godwin_backend.did";
import CONSTANTS from '../../Constants';

import { toCursorInfo } from '../../utils';

import React, { useState, useEffect } from "react";

type Props = {
  id: string;
  cursor: number;
  setCursor: (cursor: number) => (void);
  polarizationInfo: {
    left: CategorySide;
    center: CategorySide;
    right: CategorySide;
  };
  onMouseUp: () => (void);
  onMouseDown: () => (void);
};

export const CursorSlider = ({id, cursor, polarizationInfo, setCursor, onMouseUp, onMouseDown}: Props) => {

  const sliderWidth = 200;
  const thumbSize = 50;
  const marginWidth = thumbSize / 2;
  const marginRatio = marginWidth / sliderWidth;

  const [sliderLeftColor, setSliderLeftColor] = useState<string>("white");
  const [sliderRightColor, setSliderRightColor] = useState<string>("white");
  const [sliderValue, setSliderValue] = useState<number>(cursor);

  const white = new Color("white");
  // Invert the color ranges to get the correct gradient
  const leftColorRange = white.range(polarizationInfo.right.color, { space: "lch", outputSpace: "lch"});
  const rightColorRange = white.range(polarizationInfo.left.color, { space: "lch", outputSpace: "lch"});

  const refreshSlider = (value: number) => {
    setSliderValue(value);
    setSliderLeftColor(new Color(leftColorRange(value > 0 ? value : 0).toString()).to("srgb").toString({format: "hex"}));
    setSliderRightColor(new Color(rightColorRange(value < 0 ? -value : 0).toString()).to("srgb").toString({format: "hex"}));
  };

  const refreshValue = (value: number) => {
    setCursor(value);
    refreshSlider(value);
  };

  useEffect(() => {
    refreshSlider(cursor)
  }, [cursor]);

	return (
    <div id={"cursor_" + id} className="flex flex-col items-center">
      <div className="text-xs mb-2">
        {
          toCursorInfo(sliderValue, polarizationInfo).name
        }
      </div>
      <input 
        id={"cursor_input_" + id}
        min="-1"
        max="1"
        step="0.02"
        value={sliderValue}
        type="range"
        onChange={(e) => refreshValue(Number(e.target.value))}
        onMouseUp={(e) => onMouseUp()}
        onMouseDown={(e) => onMouseDown()}
        className={"input appearance-none " + (sliderValue > CONSTANTS.CURSOR_SIDE_THRESHOLD ? "right" : sliderValue < -CONSTANTS.CURSOR_SIDE_THRESHOLD ? "left" : "center") } 
        style={{
          "--progress-percent": `${ ((marginRatio + ((sliderValue + 1) * 0.5) * (1 - 2 * marginRatio)) * 100).toString() + "%"}`,
          "--slider-left-color": `${sliderLeftColor}`,
          "--slider-right-color": `${sliderRightColor}`,
          "--margin-left": `${(marginRatio * 100).toString() + "%"}`,
          "--margin-right": `${((1 - marginRatio) * 100).toString() + "%"}`,
          "--slider-width": `${sliderWidth + "px"}`,
          "--thumb-left": `url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' height='128px' width='128px' style='fill:black;font-size:64px;'><text x='50%' y='50%' dominant-baseline='middle' text-anchor='middle'>` + `${polarizationInfo.left.symbol}` + `</text></svg>")`,
          "--thumb-center": `url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' height='128px' width='128px' style='fill:black;font-size:64px;'><text x='50%' y='50%' dominant-baseline='middle' text-anchor='middle'>` + `${polarizationInfo.center.symbol}` + `</text></svg>")`,
          "--thumb-right": `url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' height='128px' width='128px' style='fill:black;font-size:64px;'><text x='50%' y='50%' dominant-baseline='middle' text-anchor='middle'>` + `${polarizationInfo.right.symbol}` + `</text></svg>")`,
          "--thumb-size": `${thumbSize + "px"}`} as React.CSSProperties
        }
      />
      <div className="text-xs font-extralight mt-1">
        { sliderValue }
      </div>
    </div>
	);
};

