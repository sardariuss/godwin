import { Category, CategoryInfo, _SERVICE } from "../../../declarations/godwin_backend/godwin_backend.did";
import { ActorSubclass } from "@dfinity/agent";
import VoteCategorization from "../votes/Categorization";
import SingleCursorVote from "../base/SingleCursorVote";

import CONSTANTS from "../../Constants";

import { useState } from "react";

type Props = {
	actor: ActorSubclass<_SERVICE>,
	categories: Map<Category, CategoryInfo>,
  questionId: bigint
};

const OpenVotes = ({actor, categories, questionId}: Props) => {

  const [showCategorization, setShowCategorization] = useState<boolean>(false);

  return (
    <div className="flex flex-col items-center w-full">
      <div className="grid grid-cols-10 items-center w-full">
        { showCategorization ?
          <div className="dark:fill-gray-400 w-2/3 place-self-center hover:cursor-pointer hover:dark:fill-white" onClick={(e) => setShowCategorization(false)}>
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 96 960 960"><path d="M561 816 320 575l241-241 43 43-198 198 198 198-43 43Z"/></svg>
          </div> : <></>
        }
        <div className="col-start-2 col-span-8 place-self-center grow">
        { showCategorization ?
          <VoteCategorization actor={actor} categories={categories} questionId={questionId}/> :
          <SingleCursorVote 
            countdownDurationMs={5000} 
            polarizationInfo={CONSTANTS.OPINION_INFO} 
            questionId={questionId} 
            allowUpdateBallot={true}
            putBallot={actor.putOpinionBallot} 
            getBallot={actor.getOpinionBallot}
          />
        }
        </div>
        { showCategorization ? <></> :
          <div className="dark:fill-gray-400 w-2/3 place-self-center hover:cursor-pointer hover:dark:fill-white" onClick={(e) => setShowCategorization(true)}>
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 96 960 960"><path d="m375 816-43-43 198-198-198-198 43-43 241 241-241 241Z"/></svg>
          </div>
        }
      </div>
    </div>
  )
}

export default OpenVotes