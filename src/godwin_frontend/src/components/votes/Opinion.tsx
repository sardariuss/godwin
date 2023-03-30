import { ActorContext } from "../../ActorContext"
import { nsToStrDate } from "../../utils";
import { RangeSlider } from "./RangeSlider";

import React, { useContext, useState, useEffect } from "react";
import CONSTANTS from "../../Constants";

type Props = {
  questionId: bigint;
};

const VoteOpinion = ({questionId}: Props) => {

	const {actor, isAuthenticated} = useContext(ActorContext);
  const [opinion, setOpinion] = useState<number>(0.0);
  const [voteDate, setVoteDate] = useState<bigint | null>(null);

  const updateOpinion = async () => {
    let opinion_vote = await actor.putOpinionBallot(questionId, opinion);
    console.log(opinion_vote);
    await getBallot();
	};

  const getBallot = async () => {
    if (isAuthenticated){
      let opinion_vote = await actor.getOpinionBallot(questionId);
      if (opinion_vote['ok'] !== undefined) {
        setOpinion(opinion_vote['ok'].answer);
        setVoteDate(opinion_vote['ok'].date);
      } else {
        setOpinion(0.0);
        setVoteDate(null);
      }
    }
  }

  useEffect(() => {
    getBallot();
  }, []);

	return (
    <div className="flex flex-col items-center space-y-2">
      <RangeSlider 
        id={ "slider_opinion_" + questionId }
        cursor={ opinion }
        setCursor={ setOpinion }
        polarizationInfo = { CONSTANTS.OPINION_INFO }
        onMouseUp={ () => updateOpinion() }
      ></RangeSlider>
      {
        voteDate !== null ?
          <div className="w-full p-2 items-center text-center text-xs font-extralight">{ "🗳️ " + nsToStrDate(voteDate) }</div> :
          <></>
      }
    </div>
	);
};

export default VoteOpinion;