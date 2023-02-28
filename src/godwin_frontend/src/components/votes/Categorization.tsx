import { ActorContext } from "../../ActorContext"
import { CategoriesContext } from "../../CategoriesContext"

import { CursorArray } from "./../../../declarations/godwin_backend/godwin_backend.did";

import { RangeSlider2 } from "./RangeSlider";

import { nsToStrDate } from "../../utils";

import React, { useContext, useState, useEffect } from "react";

type Props = {
  questionId: bigint;
};

// Array<[Category, CategoryInfo]> -> Array<[Category, Cursor__1]>
const initCategorization = (categories: Array<[string, any]>) => {
  let categorization: number[] = [];
  for (let i = 0; i < categories.length; i++) {
    categorization.push(0.0);
  }
  return categorization;
};

const VoteCategorization = ({questionId}: Props) => {

	const {actor, isAuthenticated} = useContext(ActorContext);
  const {categories} = useContext(CategoriesContext);
  const [categorization, setCategorization] = useState<number[]>(initCategorization(categories));
  const [voteDate, setVoteDate] = useState<bigint | null>(null);

  const setCategoryCursor = (category_index: number, cursor: number) => {
    setCategorization(old_categorization => { 
      let new_categorization = old_categorization;
      new_categorization[category_index] = cursor;
      console.log(new_categorization); 
      return new_categorization; 
    });
  };

  const updateCategorization = async () => {
    let categorization_ballot : CursorArray = [];
    categories.map((category, index) => { categorization_ballot.push([category[0], categorization[index]]); });
    let categorization_vote = await actor.putCategorizationBallot(questionId, categorization_ballot);
    console.log(categorization_vote);
    await getBallot();
	};

  const getBallot = async () => {
    if (isAuthenticated){
      let categorization_vote = await actor.getCategorizationBallot(questionId);
      if (categorization_vote['ok'] !== undefined && categorization_vote['ok'].length > 0) {
        setCategorization(categorization_vote['ok'][0].answer);
        setVoteDate(categorization_vote['ok'][0].date);
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
    <div className="flex flex-col items-center space-y-2">
      <ul className="list-none">
      {
        categories.map((category, index) => (
          <li key={category[0]}>
          <RangeSlider2 
            id={ category[0] + questionId.toString() }
            index = { index }
            cursor={ categorization }
            setCursor={ setCategoryCursor }
            category= { category[0] }
            leftLabel= { category[1].left.name }
            rightLabel= { category[1].right.name }
            leftColor={ category[1].left.color }
            rightColor={ category[1].right.color }
            thumbLeft={ category[1].left.symbol }
            thumbCenter={ "🙏" }
            thumbRight={ category[1].right.symbol }
            onMouseUp={ () => {} }
          ></RangeSlider2>
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