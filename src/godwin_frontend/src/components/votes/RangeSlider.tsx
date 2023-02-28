import Color from 'colorjs.io';

import React, { useState, useEffect } from "react";

type Props = {
  id: string;
  cursor: number;
  setCursor: (cursor: number) => (void);
  leftColor: string;
  rightColor: string;
  thumbLeft: string;
  thumbCenter: string;
  thumbRight: string;
  onMouseUp: () => (void);
};

export const RangeSlider = ({id, cursor, setCursor, leftColor, rightColor, thumbLeft, thumbCenter, thumbRight, onMouseUp}: Props) => {

  const sliderWidth = 200;
  const thumbSize = 50;
  const marginWidth = thumbSize / 2;
  const marginRatio = marginWidth / sliderWidth;

  const [sliderLeftColor, setSliderLeftColor] = useState<string>(leftColor);
  const [sliderRightColor, setSliderRightColor] = useState<string>(rightColor);

  const white = new Color("white");
  const leftColorRange = white.range(leftColor, { space: "lch", outputSpace: "lch"});
  const rightColorRange = white.range(rightColor, { space: "lch", outputSpace: "lch"});

  useEffect(() => {  
    setSliderLeftColor(new Color(leftColorRange(cursor > 0 ? cursor : 0).toString()).to("srgb").toString({format: "hex"}));
    setSliderRightColor(new Color(rightColorRange(cursor < 0 ? -cursor : 0).toString()).to("srgb").toString({format: "hex"}));
  }, [cursor]);

	return (
    <div id={"cursor_" + id} className="flex flex-col items-center space-y-2">
      <div className="text-xs font-extralight">
        { cursor }
      </div>
      <input id={"cursor_input_" + id} min="-1" max="1" step="0.02" value={cursor} type="range" onChange={(e) => setCursor(Number(e.target.value))} onMouseUp={(e) => onMouseUp()} className={"input appearance-none " + (cursor > 0.33 ? "right" : cursor < -0.33 ? "left" : "center") } 
      style={{
        "--progress-percent": `${ ((marginRatio + ((cursor + 1) * 0.5) * (1 - 2 * marginRatio)) * 100).toString() + "%"}`,
        "--slider-left-color": `${sliderLeftColor}`,
        "--slider-right-color": `${sliderRightColor}`,
        "--margin-left": `${(marginRatio * 100).toString() + "%"}`,
        "--margin-right": `${((1 - marginRatio) * 100).toString() + "%"}`,
        "--slider-width": `${sliderWidth + "px"}`,
        "--thumb-left": `url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' height='128px' width='128px' style='fill:black;font-size:64px;'><text x='50%' y='50%' dominant-baseline='middle' text-anchor='middle'>` + `${thumbLeft}` + `</text></svg>")`,
        "--thumb-center": `url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' height='128px' width='128px' style='fill:black;font-size:64px;'><text x='50%' y='50%' dominant-baseline='middle' text-anchor='middle'>` + `${thumbCenter}` + `</text></svg>")`,
        "--thumb-right": `url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' height='128px' width='128px' style='fill:black;font-size:64px;'><text x='50%' y='50%' dominant-baseline='middle' text-anchor='middle'>` + `${thumbRight}` + `</text></svg>")`,
        "--thumb-size": `${thumbSize + "px"}`} as React.CSSProperties
      }/>
    </div>
	);
};

type Props2 = {
  id: string;
  index: number;
  cursor: number[];
  setCursor: (index: number, cursor: number) => (void);
  category: string;
  leftLabel: string;
  rightLabel: string;
  leftColor: string;
  rightColor: string;
  thumbLeft: string;
  thumbCenter: string;
  thumbRight: string;
  onMouseUp: () => (void);
};

export const RangeSlider2 = ({id, index, cursor, setCursor, category, leftLabel, rightLabel, leftColor, rightColor, thumbLeft, thumbCenter, thumbRight, onMouseUp}: Props2) => {

  const sliderWidth = 200;
  const thumbSize = 50;
  const marginWidth = thumbSize / 2;
  const marginRatio = marginWidth / sliderWidth;

  const [sliderLeftColor, setSliderLeftColor] = useState<string>(leftColor);
  const [sliderRightColor, setSliderRightColor] = useState<string>(rightColor);

  const white = new Color("white");
  const leftColorRange = white.range(leftColor, { space: "lch", outputSpace: "lch"});
  const rightColorRange = white.range(rightColor, { space: "lch", outputSpace: "lch"});

  const [inner, setInner] = useState<number>(cursor[index]);

  const updateInner = (value: number) => {
    setInner(value);
    setCursor(index, value);
  };

  useEffect(() => {
    setSliderLeftColor(new Color(leftColorRange(inner > 0   ?  inner : 0).toString()).to("srgb").toString({format: "hex"}));
    setSliderRightColor(new Color(rightColorRange(inner < 0 ? -inner : 0).toString()).to("srgb").toString({format: "hex"}));
  }, [inner]);

	return (
    <div id={"cursor_" + id} className="flex flex-col items-center space-y-2">
      <div className="text-xs font-extralight">
      { inner }
      </div>
      <input id={"cursor_input_" + id} min="-1" max="1" step="0.02" value={inner} type="range" onChange={(e) => updateInner(Number(e.target.value))} onMouseUp={(e) => onMouseUp()} className={"input appearance-none " + (inner > 0.33 ? "right" : inner < -0.33 ? "left" : "center") } 
      style={{
        "--progress-percent": `${ ((marginRatio + ((inner + 1) * 0.5) * (1 - 2 * marginRatio)) * 100).toString() + "%"}`,
        "--slider-left-color": `${sliderLeftColor}`,
        "--slider-right-color": `${sliderRightColor}`,
        "--margin-left": `${(marginRatio * 100).toString() + "%"}`,
        "--margin-right": `${((1 - marginRatio) * 100).toString() + "%"}`,
        "--slider-width": `${sliderWidth + "px"}`,
        "--thumb-left": `url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' height='128px' width='128px' style='fill:black;font-size:64px;'><text x='50%' y='50%' dominant-baseline='middle' text-anchor='middle'>` + `${thumbLeft}` + `</text></svg>")`,
        "--thumb-center": `url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' height='128px' width='128px' style='fill:black;font-size:64px;'><text x='50%' y='50%' dominant-baseline='middle' text-anchor='middle'>` + `${thumbCenter}` + `</text></svg>")`,
        "--thumb-right": `url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' height='128px' width='128px' style='fill:black;font-size:64px;'><text x='50%' y='50%' dominant-baseline='middle' text-anchor='middle'>` + `${thumbRight}` + `</text></svg>")`,
        "--thumb-size": `${thumbSize + "px"}`} as React.CSSProperties
      }/>
      <div className="text-xs font-extralight items-left">
        { category + ": " + (inner > 0.33 ? rightLabel.toLocaleLowerCase() : inner < -0.33 ? leftLabel.toLocaleLowerCase() : "centered") }
      </div>
    </div>
	);
};
