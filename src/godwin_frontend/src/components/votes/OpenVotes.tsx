import { Category, CategoryInfo, _SERVICE } from "../../../declarations/godwin_backend/godwin_backend.did";
import SvgButton                            from "../base/SvgButton";
import ArrowLeftIcon                        from "../icons/ArrowLeftIcon";
import ArrowRightIcon                       from "../icons/ArrowRightIcon";
import CategorizationVote                   from "../votes/CategorizationVote";
import OpinionVote                          from "../votes/OpinionVote";

import CONSTANTS                            from "../../Constants";

import { ActorSubclass }                    from "@dfinity/agent";

import { useState }                         from "react";

type Props = {
	actor               : ActorSubclass<_SERVICE>,
	categories          : Map<Category, CategoryInfo>,
  opinionVoteId       : bigint | undefined,
  categorizationVoteId: bigint | undefined
};

const OpenVotes = ({actor, categories, opinionVoteId, categorizationVoteId}: Props) => {

  const [showCategorization, setShowCategorization] = useState<boolean>(false);

  return (
    <div className="flex flex-col items-center w-full">
      <div className="grid grid-cols-10 items-center w-full">
        { showCategorization ?
            <div className="w-2/3 place-self-center">
              <SvgButton onClick={() => setShowCategorization(false)} disabled={false} hidden={false}>
                <ArrowLeftIcon/>
              </SvgButton>
            </div> : <></>
        }
        <div className="col-start-2 col-span-8 place-self-center grow">
        { showCategorization ?
            categorizationVoteId !== undefined ?
              <CategorizationVote actor={actor} categories={categories} voteId={categorizationVoteId}/> : <></> :
            opinionVoteId !== undefined ?
              <OpinionVote
                polarizationInfo={CONSTANTS.OPINION_INFO} 
                voteId={opinionVoteId} 
                actor={actor} 
              /> : <></>
        }
        </div>
        { !showCategorization ?
            <div className="w-2/3 place-self-center">
              <SvgButton onClick={() => setShowCategorization(true)} disabled={false} hidden={false}>
                <ArrowRightIcon/>
              </SvgButton>
            </div> : <></>
        }
      </div>
    </div>
  )
}

export default OpenVotes