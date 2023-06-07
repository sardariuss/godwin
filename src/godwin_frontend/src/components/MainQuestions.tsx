import { QuestionOrderBy, Direction } from "../../declarations/godwin_backend/godwin_backend.did";
import { ActorContext, Sub } from "../ActorContext";
import { TabButton } from "./TabButton";
import { MainTabButton } from "./MainTabButton";
import { ListQuestions } from "./ListQuestions";
import { ScanResults, fromScanLimitResult, toMap } from "../utils";
import OpenQuestion from "./OpenQuestion";
import SubBanner from "./SubBanner";

import { useParams } from "react-router-dom";
import { useState, useContext, useEffect } from "react";

export enum MainTab {
  HOME,
  BROWSE,
};

const mainTabToText = (mainTab: MainTab) => {
  switch (mainTab) {
    case MainTab.HOME:
      return "Home";
    case MainTab.BROWSE:
      return "Browse";
  }
}

const mainTabs = [MainTab.HOME, MainTab.BROWSE];

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

const getQueryParams = (filter: BrowseFilter) : [QuestionOrderBy, Direction] => {
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

type QueryFunction = (next: bigint | undefined) => Promise<ScanResults<bigint>>;

const MainQuestions = () => {

  const { subgodwin } = useParams();
  const {subs} = useContext(ActorContext);
  const [sub, setSub] = useState<Sub | undefined>(undefined);
  const [currentMainTab, setCurrentMainTab] = useState<MainTab>(MainTab.HOME);
  const [currentBrowseFilter, setCurrentBrowseFilter] = useState<BrowseFilter>(BrowseFilter.CANDIDATE);
  const [queryQuestions, setQueryQuestions] = useState<QueryFunction>(() => () => Promise.resolve({ ids : [], next: undefined}));

  useEffect(() => {
    if (subgodwin !== undefined) {
      setSub(subs.get(subgodwin));
    }
  }, [subgodwin, subs]);

  useEffect(() => {
    if (sub === undefined) {
      setQueryQuestions(() => () => Promise.resolve({ ids : [], next: undefined}));
    } else {
      setQueryQuestions(() => (next: bigint | undefined) => sub.actor.queryQuestions(getQueryParams(currentBrowseFilter)[0], getQueryParams(currentBrowseFilter)[1], BigInt(10), next? [next] : []).then(
        fromScanLimitResult
      ));
    }
  }, [sub, currentBrowseFilter]);

	return (
    (
      sub === undefined ?  
        <div>Unknown subgodwin @todo</div> : 
        <div className="flex flex-col items-center w-full">
          <div className="flex flex-col sticky top-0 z-20 bg-white dark:bg-slate-900 items-center w-full">
            <SubBanner sub={sub}/>
            <div className="flex flex-col border-x dark:border-gray-700 w-1/3">
              <div className="border-b dark:border-gray-700 w-full">
                <ul className="flex flex-wrap text-sm dark:text-gray-400 font-medium text-center">
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
                currentMainTab === MainTab.HOME ?
                <OpenQuestion onSubmitQuestion={()=>{}} subId={subgodwin !== undefined ? subgodwin : null}></OpenQuestion> :
                <div className="border-b dark:border-gray-700">
                  <ul className="flex flex-wrap text-sm dark:text-gray-400 font-medium text-center">
                  {
                    filters.map((filter, index) => (
                      <li key={index} className="grow">
                        <TabButton label={filterToText(filter)} isCurrent={filter == currentBrowseFilter} setIsCurrent={() => setCurrentBrowseFilter(filter)}/>
                      </li>
                    ))
                  }
                  </ul>
                </div>
              }
            </div>
          </div>
          <div className="flex flex-col border mb-5 dark:border-gray-700 w-1/3">
            <ListQuestions sub={sub}  query_questions={queryQuestions}/>
          </div>
        </div>
    )
	);
};

export default MainQuestions;
