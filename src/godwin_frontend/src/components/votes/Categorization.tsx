import { ActorContext } from "../../ActorContext"
import { CategoriesContext } from "../../CategoriesContext"

import { CursorArray, Category, CategoryInfo } from "./../../../declarations/godwin_backend/godwin_backend.did";

import { RangeSlider } from "./RangeSlider";

import { nsToStrDate } from "../../utils";

import CONSTANTS from "../../Constants";

import React, { useContext, useState, useEffect } from "react";

type Props = {
  questionId: bigint;
};

const initCategorization = (categories: Map<Category, CategoryInfo>) => {
  let categorization: CursorArray = [];
  for (const [category, _] of categories.entries()) {
    categorization.push([category, 0.0]);
  }
  return categorization;
}

// @todo: add a button to perform the vote
const VoteCategorization = ({questionId}: Props) => {

	const {actor, isAuthenticated} = useContext(ActorContext);
  const {categories} = useContext(CategoriesContext);
  const [categorization, setCategorization] = useState<CursorArray>(initCategorization(categories));
  const [voteDate, setVoteDate] = useState<bigint | null>(null);

  const setCategoryCursor = (category_index: number, cursor: number) => {
    setCategorization(old_categorization => { 
      let new_categorization = old_categorization;
      new_categorization[category_index] = [old_categorization[category_index][0], cursor];
      console.log(new_categorization); 
      return new_categorization; 
    });
  };

  const updateCategorization = async () => {
    let categorization_vote = await actor.putCategorizationBallot(questionId, categorization);
    console.log(categorization_vote);
    await getBallot();
	};

  const getBallot = async () => {
    if (isAuthenticated){
      let categorization_vote = await actor.getCategorizationBallot(questionId);
      if (categorization_vote['ok'] !== undefined) {
        setCategorization(categorization_vote['ok'].answer);
        setVoteDate(categorization_vote['ok'].date);
      } else {
        setCategorization(initCategorization(categories));
        setVoteDate(null);
      }
    }
  }

  useEffect(() => {
    getBallot();
  }, []);

	return (
    <div className="flex flex-col items-center space-y-2 mb-2">
      <ul className="list-none divide-y-4 divide-slate-400/25">
      {
        categorization.map(([category, cursor], index) => (
          <li key={category}>
          <RangeSlider
            id={ category + questionId.toString() }
            cursor={ cursor }
            setCursor={ (cursor: number) => { setCategoryCursor(index, cursor); } }
            polarizationInfo = {{ left: categories.get(category).left, center: CONSTANTS.CATEGORIZATION_INFO.center, right: categories.get(category).right}}
            onMouseUp={ () => { updateCategorization() } }
          ></RangeSlider>
          </li>
        ))
      }
      </ul>
      {
        voteDate !== null ?
          <div className="w-full p-2 items-center text-center text-xs font-extralight">{ "🗳️ " + nsToStrDate(voteDate) }</div> :
          <></>
      }
    </div>
	);
};

export default VoteCategorization;