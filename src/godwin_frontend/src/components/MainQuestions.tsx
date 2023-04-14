import { OrderBy, Direction } from "../../declarations/godwin_backend/godwin_backend.did";
import { Sub } from "../ActorContext";
import { TabButton } from "./TabButton";
import { MainTabButton } from "./MainTabButton";
import ListQuestions from "./ListQuestions";
import { toMap } from "../utils";

import { useState } from "react";

export enum MainTab {
  FOR_YOU,
  BROWSE,
};

const mainTabToText = (mainTab: MainTab) => {
  switch (mainTab) {
    case MainTab.FOR_YOU:
      return "For You";
    case MainTab.BROWSE:
      return "Browse";
  }
}

const mainTabs = [MainTab.FOR_YOU, MainTab.BROWSE];

export enum BrowseFilter {
  CANDIDATE,
  OPEN,
  ARCHIVED,
  REJECTED
};

const filterToText = (filter: BrowseFilter) => {
  switch (filter) {
    case BrowseFilter.CANDIDATE:
      return "Candidate";
    case BrowseFilter.OPEN:
      return "Open";
    case BrowseFilter.ARCHIVED:
      return "Archived";
    case BrowseFilter.REJECTED:
      return "Rejected";
  }
}

const filters = [BrowseFilter.CANDIDATE, BrowseFilter.OPEN, BrowseFilter.ARCHIVED, BrowseFilter.REJECTED];

const getQueryParams = (filter: BrowseFilter) : [OrderBy, Direction] => {
  switch (filter) {
    case BrowseFilter.CANDIDATE:
      return [{ 'INTEREST_SCORE' : null          }, { 'BWD' : null }];
    case BrowseFilter.OPEN:
      return [{ 'STATUS' : { 'OPEN' : null     } }, { 'FWD' : null }];
    case BrowseFilter.ARCHIVED:
      return [{ 'STATUS' : { 'CLOSED' : null   } }, { 'FWD' : null }];
    case BrowseFilter.REJECTED:
      return [{ 'STATUS' : { 'REJECTED' : null } }, { 'FWD' : null }];
  }
}

export type MainQuestionsInput = {
  sub: Sub
}

const MainQuestions = ({sub}: MainQuestionsInput) => {

  const [currentMainTab, setCurrentMainTab] = useState<MainTab>(MainTab.FOR_YOU);
  const [currentBrowseFilter, setCurrentBrowseFilter] = useState<BrowseFilter>(BrowseFilter.CANDIDATE);

	return (
    <div>
      <div className="text-center">
        <div className="bg-gradient-to-r from-purple-700 from-10% via-indigo-800 via-30% to-sky-600 to-90% dark:text-white font-medium border-t border-gray-600 mt-16 pt-2 pb-1">
          { sub.name }
        </div>
        <div className="bg-gray-100 dark:bg-gray-700 dark:text-white font-normal border-y py-1 border-gray-600">
          { sub.categories.map((category, index) => 
            <span key={category[0]}>
              <span className="text-xs">{category[1].left.name.toLocaleLowerCase()  + " " }</span>
              <span>{category[1].left.symbol}</span>
              <span className="text-xs">{" vs "}</span>
              <span>{category[1].right.symbol}</span>
              <span className="text-xs">{" " + category[1].right.name.toLocaleLowerCase() }</span>
              {
                index < sub.categories.length - 1 ? 
                <span>{" · "}</span> : <></>
              }
            </span>
          )}
        </div>
      </div>
      <div className="border-none mx-96 justify-center">
        <div className="border-b border-gray-200 dark:border-gray-700">
          <ul className="flex flex-wrap text-sm text-gray-400 font-medium text-center">
          {
            mainTabs.map((tab, index) => (
              <li key={index} className="grow">
                <MainTabButton label={mainTabToText(tab)} isCurrent={tab == currentMainTab} setIsCurrent={() => setCurrentMainTab(tab)}/>
              </li>
            ))
          }
          </ul>
        </div>
        {
          currentMainTab === MainTab.BROWSE ?
          <div>
            <div className="mb-4 border-b border-gray-200 dark:border-gray-700">
              <ul className="flex flex-wrap text-sm text-gray-400 font-medium text-center">
              {
                filters.map((filter, index) => (
                  <li key={index} className="grow">
                    <TabButton label={filterToText(filter)} isCurrent={filter == currentBrowseFilter} setIsCurrent={() => setCurrentBrowseFilter(filter)}/>
                  </li>
                ))
              }
              </ul>
            </div>
            <ListQuestions actor={sub.actor} categories={toMap(sub.categories)} order_by={getQueryParams(currentBrowseFilter)[0]} query_direction={getQueryParams(currentBrowseFilter)[1]}/>
          </div>
          : <></>
        }
      </div>
    </div>
	);
};

export default MainQuestions;
