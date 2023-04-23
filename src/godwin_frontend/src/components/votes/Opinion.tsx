import { ActorContext } from "../../ActorContext"
import { nsToStrDate } from "../../utils";
import { CursorSlider } from "../base//CursorSlider";

import { _SERVICE, Result_7 } from "./../../../declarations/godwin_backend/godwin_backend.did";
import { ActorSubclass } from "@dfinity/agent";

import React, { useContext, useState, useEffect, useRef } from "react";
import CONSTANTS from "../../Constants";

import UpdateProgress from "../UpdateProgress";

type Props = {
  actor: ActorSubclass<_SERVICE>;
  questionId: bigint;
};

const VoteOpinion = ({actor, questionId}: Props) => {

  const delay_duration = 6000; // 6 seconds

	const {isAuthenticated} = useContext(ActorContext);
  const [opinion, setOpinion] = useState<number>(0.0);
  const [voteDate, setVoteDate] = useState<bigint | null>(null);
  
  const [triggerVote, setTriggerVote] = useState<boolean>(false);

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
    <div className="flex flex-row items-center">
      <CursorSlider 
        id={ "slider_opinion_" + questionId }
        cursor={ opinion }
        setCursor={ setOpinion }
        polarizationInfo = { CONSTANTS.OPINION_INFO }
        onMouseUp={ () => setTriggerVote(true) }
        onMouseDown={ () => setTriggerVote(false) }
      ></CursorSlider>
      <UpdateProgress<Result_7> 
        delay_duration_ms={delay_duration}
        update_function={() => actor.putOpinionBallot(questionId, opinion)}
        callback_function={(res) => { console.log(res); return res['ok'] !== undefined; } }
        trigger_update={triggerVote}
        set_trigger_update={setTriggerVote}
      />
      {
        voteDate !== null ?
          <div className="w-full p-2 items-center text-center text-xs font-extralight">{ "🗳️ " + nsToStrDate(voteDate) }</div> :
          <></>
      }
    </div>
	);
};

export default VoteOpinion;