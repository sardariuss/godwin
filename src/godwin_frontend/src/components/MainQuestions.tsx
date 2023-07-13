import { QuestionOrderBy, Direction, QueryQuestionItem } from "../../declarations/godwin_sub/godwin_sub.did";
import { ActorContext, Sub } from "../ActorContext";
import { TabButton } from "./TabButton";
import { MainTabButton } from "./MainTabButton";
import ListQuestions from "./ListQuestions";
import { ScanResults, StatusEnum, fromScanLimitResult, VoteKind, voteKindToCandidVariant } from "../utils";
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

export enum UserAction {
  SELECT,
  VOTE,
  CATEGORIZE,
  REOPEN_QUESTION
};

const voteKindToUserAction = (vote_kind: VoteKind) => {
  switch (vote_kind) {
    case VoteKind.INTEREST:
      return UserAction.SELECT;
    case VoteKind.OPINION:
      return UserAction.VOTE;
    case VoteKind.CATEGORIZATION:
      return UserAction.CATEGORIZE;
  }
}

const userActionToText = (user_action: UserAction) => {
  switch (user_action) {
    case UserAction.SELECT:
      return "Select";
    case UserAction.VOTE:
      return "Vote";
    case UserAction.CATEGORIZE:
      return "Categorize";
    case UserAction.REOPEN_QUESTION:
      return "Reopen";
  }
}

const vote_kind_filters = [VoteKind.INTEREST, VoteKind.OPINION, VoteKind.CATEGORIZATION];

export enum BrowseFilter {
  CANDIDATE,
  OPEN,
  ARCHIVED,
  REJECTED
};

const browseFilterToText = (filter: BrowseFilter) => {
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

const browse_filters = [BrowseFilter.CANDIDATE, BrowseFilter.OPEN, BrowseFilter.ARCHIVED, BrowseFilter.REJECTED];

const getQueryOrderBy = (filter: BrowseFilter) : QuestionOrderBy => {
  switch (filter) {
    case BrowseFilter.CANDIDATE:
      return { 'INTEREST_SCORE' : null          };
    case BrowseFilter.OPEN:
      return { 'STATUS' : { 'OPEN' : null     } };
    case BrowseFilter.ARCHIVED:
      return { 'ARCHIVE' : null };
    case BrowseFilter.REJECTED:
      return { 'STATUS' : { 'REJECTED' : null  } } ;
  }
}

type QueryFunction = (direction: Direction, limit: bigint, next: QueryQuestionItem | undefined) => Promise<ScanResults<QueryQuestionItem>>;

const MainQuestions = () => {

  const { subgodwin } = useParams();
  const {subs} = useContext(ActorContext);
  const [sub, setSub] = useState<Sub | undefined>(undefined);
  const [currentMainTab, setCurrentMainTab] = useState<MainTab>(MainTab.HOME);
  const [currentHomeFilter, setCurrentHomeFilter] = useState<VoteKind>(VoteKind.INTEREST);
  const [currentBrowseFilter, setCurrentBrowseFilter] = useState<BrowseFilter>(BrowseFilter.CANDIDATE);
  const [currentUserAction, setCurrentUserAction] = useState<UserAction | undefined>(undefined);
  const [queryQuestions, setQueryQuestions] = useState<QueryFunction>(() => () => Promise.resolve({ ids : [], next: undefined}));

  useEffect(() => {
    if (subgodwin !== undefined) {
      setSub(subs.get(subgodwin));
    }
  }, [subgodwin, subs]);

  useEffect(() => {
    if (sub === undefined) {
      setQueryQuestions(() => () => Promise.resolve({ ids : [], next: undefined}));
    } else if (currentMainTab === MainTab.HOME) {
      setQueryQuestions(() => (direction: Direction, limit: bigint, next: QueryQuestionItem | undefined) => 
        sub.actor.queryFreshVotes(voteKindToCandidVariant(currentHomeFilter), direction, limit, next? [next.question.id] : []).then(fromScanLimitResult));
    } else if (currentMainTab === MainTab.BROWSE) {
      setQueryQuestions(() => (direction: Direction, limit: bigint, next: QueryQuestionItem | undefined) => 
        sub.actor.queryQuestions(getQueryOrderBy(currentBrowseFilter), direction, limit, next? [next.question.id] : []).then(fromScanLimitResult));
    }
    setCurrentUserAction(currentMainTab === MainTab.HOME ? voteKindToUserAction(currentHomeFilter) : UserAction.REOPEN_QUESTION);
  }, [sub, currentBrowseFilter, currentHomeFilter, currentMainTab]);

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
                <div className="border-b dark:border-gray-700">
                  <OpenQuestion onSubmitQuestion={()=>{}} subId={subgodwin !== undefined ? subgodwin : null}></OpenQuestion>
                </div> : <></>
              }
              <div className="border-b dark:border-gray-700">
                <ul className="flex flex-wrap text-sm dark:text-gray-400 font-medium text-center">
                {
                  currentMainTab === MainTab.HOME ? (
                    vote_kind_filters.map((filter, index) => (
                      <li key={index} className="w-1/3">
                        <TabButton label={userActionToText(voteKindToUserAction(filter))} isCurrent={filter == currentHomeFilter} setIsCurrent={() => setCurrentHomeFilter(filter)}/>
                      </li>))
                  ) : (
                    browse_filters.map((filter, index) => (
                      <li key={index} className="w-1/4">
                        <TabButton label={browseFilterToText(filter)} isCurrent={filter == currentBrowseFilter} setIsCurrent={() => setCurrentBrowseFilter(filter)}/>
                      </li>
                    ))
                  )
                }
                </ul>
              </div>
            </div>
          </div>
          <div className="flex flex-col border mb-5 dark:border-gray-700 w-1/3">
          <div className="w-full flex">
            <ListQuestions 
              sub={sub}
              query_questions={queryQuestions}
              user_action={currentUserAction}
            />
          </div>
        </div>
      </div>
    )
	);
};

export default MainQuestions;
