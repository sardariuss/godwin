import { ActorContext } from "../../ActorContext"

import React, { useContext, useState } from "react";

type Props = {
  question_id: bigint;
};

// @todo: change the state of the buttons based on the opinion for the logged user for this question
const VoteOpinion = ({question_id}: Props) => {

	const {actor, isAuthenticated} = useContext(ActorContext);
  const [opinion, setOpinion] = useState<number>(0.0);

  const updateOpinion = async () => {
		console.log("updateOpinion");
    let opinionResult = await actor.putOpinionBallot(question_id, opinion);
		console.log(opinionResult);
	};

	return (
    <div className="flex flex-col items-center space-x-1">
      <label htmlFor="small-range" className="block mb-2 text-sm font-medium text-gray-900 dark:text-white">
        { opinion > 0.6 ? "AGREE" : opinion > 0.2 ? "RATHER AGREE" : opinion > -0.2 ? "NEUTRAL" : opinion > -0.6 ? "RATHER DISAGREE" : "DISAGREE" }
      </label>
      <input id="small-range" min="-1" max="1" step="0.1" disabled={!isAuthenticated} type="range" onChange={(e) => setOpinion(Number(e.target.value))} onMouseUp={(e) => updateOpinion()} className="w-24 h-1 mb-6 bg-gray-200 rounded-lg appearance-none cursor-pointer range-sm dark:bg-gray-700"></input>
    </div>
	);
};

export default VoteOpinion;
