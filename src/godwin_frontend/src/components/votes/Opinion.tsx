import { ActorContext } from "../../ActorContext"
import Color from 'colorjs.io';

import React, { useContext, useState, useEffect } from "react";

type Props = {
  question_id: bigint;
};

// @todo: change the state of the buttons based on the opinion for the logged user for this question
const VoteOpinion = ({question_id}: Props) => {

	const {actor, isAuthenticated} = useContext(ActorContext);
  const [opinion, setOpinion] = useState<number>(0.0);
  const [leftColor, setLeftColor] = useState<string>("#DB4437");
  const [rightColor, setRightColor] = useState<string>("#0F9D58");
  const sliderWidth = 200;
  const thumbSize = 50;
  const marginWidth = thumbSize / 2;
  const marginRatio = marginWidth / sliderWidth;

  useEffect(() => {
    const white = new Color("white");
    const greenwhite = white.range("#0F9D58", { space: "lch", outputSpace: "lch" });
    setLeftColor(new Color(greenwhite(opinion > 0 ? opinion : 0).toString()).to("srgb").toString({format: "hex"}));
    const redwhite = white.range("#DB4437", { space: "lch", outputSpace: "lch"});
    setRightColor(new Color(redwhite(opinion < 0 ? -opinion : 0).toString()).to("srgb").toString({format: "hex"}));
  }, [opinion]);

  const updateOpinion = async () => {
    await actor.putOpinionBallot(question_id, opinion);
	};

	return (
    <div className="flex flex-col items-center space-x-1 space-y-2">
      <div className="text-xs font-extralight">
        { opinion }
      </div>
      <input id={"opinion_input_" + question_id.toString()} min="-1" max="1" step="0.02" disabled={!isAuthenticated} type="range" onChange={(e) => setOpinion(Number(e.target.value))} onMouseUp={(e) => updateOpinion()} className={"input appearance-none " + (opinion > 0.1 ? "up" : opinion < -0.1 ? "down" : "shrug") } 
      style={{
        "--progress-percent": `${ ((marginRatio + ((opinion + 1) * 0.5) * (1 - 2 * marginRatio)) * 100).toString() + "%"}`,
        "--left-color": `${leftColor}`,
        "--right-color": `${rightColor}`,
        "--margin-left": `${(marginRatio * 100).toString() + "%"}`,
        "--margin-right": `${((1 - marginRatio) * 100).toString() + "%"}`,
        "--slider-width": `${sliderWidth + "px"}`,
        "--thumb-size": `${thumbSize + "px"}`} as React.CSSProperties
      }/>
    </div>
	);
};

export default VoteOpinion;