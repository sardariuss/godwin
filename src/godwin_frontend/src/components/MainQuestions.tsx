import { OrderBy, Direction, Category, CategoryInfo, _SERVICE } from "../../declarations/godwin_backend/godwin_backend.did";

import { ActorSubclass } from "@dfinity/agent";
import ListQuestions from "./ListQuestions";

import { useState } from "react";

export enum Filter {
  CANDIDATE,
  OPEN,
  ARCHIVED,
  REJECTED
};

const filterToText = (filter: Filter) => {
  switch (filter) {
    case Filter.CANDIDATE:
      return "Candidate";
    case Filter.OPEN:
      return "Open";
    case Filter.ARCHIVED:
      return "Archived";
    case Filter.REJECTED:
      return "Rejected";
  }
}

const tabs = [Filter.CANDIDATE, Filter.OPEN, Filter.ARCHIVED, Filter.REJECTED];

const getQueryParams = (filter: Filter) : [OrderBy, Direction] => {
  switch (filter) {
    case Filter.CANDIDATE:
      return [{ 'INTEREST_SCORE' : null          }, { 'BWD' : null }];
    case Filter.OPEN:
      return [{ 'STATUS' : { 'OPEN' : null     } }, { 'FWD' : null }];
    case Filter.ARCHIVED:
      return [{ 'STATUS' : { 'CLOSED' : null   } }, { 'FWD' : null }];
    case Filter.REJECTED:
      return [{ 'STATUS' : { 'REJECTED' : null } }, { 'FWD' : null }];
  }
}

export type MainQuestionsInput = {
  actor: ActorSubclass<_SERVICE>,
  categories: Map<Category, CategoryInfo>,
  filter: Filter
}

const MainQuestions = ({actor, categories, filter}: MainQuestionsInput) => {

  const [currentFilter, setCurrentFilter] = useState<Filter>(filter);

	return (
    <div className="border-none mx-96 my-16 justify-center">
      <div className="mb-4 border-b border-gray-200 dark:border-gray-700">
        <ul className="flex flex-wrap text-sm text-gray-400 font-medium text-center">
        {
          tabs.map((tab, index) => (
            <li key={index} className="grow">
              <button className={"inline-block p-4 border-b-2 rounded-t-lg " + (tab == currentFilter ? 
                "text-white border-blue-700 font-bold" : 
                "border-transparent hover:text-gray-600 hover:border-gray-300 dark:hover:text-gray-300")
                } type="button" role="tab" onClick={(e) => setCurrentFilter(tab)}>{filterToText(tab)}</button>
            </li>
          ))
        }
        </ul>
      </div>
      <ListQuestions actor={actor} categories={categories} order_by={getQueryParams(currentFilter)[0]} query_direction={getQueryParams(currentFilter)[1]}/>
    </div>
	);
};

export default MainQuestions;
