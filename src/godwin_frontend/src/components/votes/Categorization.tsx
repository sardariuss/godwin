import { Category, Cursor, _SERVICE} from "./../../../declarations/godwin_backend/godwin_backend.did";
import ActorContext from "../../ActorContext"

import React, { useContext, useState } from "react";
import { ActorSubclass } from "@dfinity/agent";

type Props = {
  question_id: bigint,
  categories: string[]
};

type ActorContextValues = {
  actor: ActorSubclass<_SERVICE>,
  logged_in: boolean
};

// @todo: change the state of the buttons based on the categorization for the logged user for this question
const VoteCategorization = ({question_id, categories}: Props) => {

	const {actor, logged_in} = useContext(ActorContext) as ActorContextValues;
  const [categorization, setCategorization] = useState<Map<Category, Cursor>>(new Map(categories.map(category => [category, 0.0])));

  const updateCategorization = async () => {
    let categorizationResult = await actor.putCategorizationBallot(question_id, Array.from(categorization, ([category, cursor]) => ([category, cursor])));
    console.log(categorizationResult);
	}

  const updateCategory = (category: string, cursor: number) => {
    setCategorization(new Map(categorization.set(category, cursor)));
  }

  const getCursor = (category: string) => {
    const cursor = categorization.get(category);
    if (cursor === undefined) { return "UNDEF";        }
    if (cursor > 0.6)         { return "RIGHT";        }
    if (cursor > 0.2)         { return "RATHER RIGHT"; }
    if (cursor > -0.2)        { return "NEUTRAL";      }
    if (cursor > -0.6)        { return "RATHER LEFT";  }
    else                      { return "LEFT";         }
  }

	return (
    <div className="flex flex-col items-center space-x-1">
      {
        categories.map(category => (
          <div key={question_id + "_" + category}>
            <label htmlFor="small-range" className="block mb-2 text-sm font-medium text-gray-900 dark:text-white"> { category + " " + getCursor(category) } </label>
            <input id="small-range" min="-1" max="1" step="0.1" disabled={!logged_in} type="range" onChange={(e) => updateCategory(category, Number(e.target.value))} onMouseUp={(e) => updateCategorization()} className="w-24 h-1 mb-6 bg-gray-200 rounded-lg appearance-none cursor-pointer range-sm dark:bg-gray-700"></input>
          </div>
        )
        )
      }
    </div>
	);
};

export default VoteCategorization;
