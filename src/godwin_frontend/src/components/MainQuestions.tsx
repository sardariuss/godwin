import { TabButton }                                                           from "./TabButton";
import { MainTabButton }                                                       from "./MainTabButton";
import OpenQuestion                                                            from "./OpenQuestion";
import SubBanner                                                               from "./SubBanner";
import QuestionComponent, { QuestionInput }                                    from "./Question";
import ListComponents                                                          from "./base/ListComponents";
import { ActorContext, Sub }                                                   from "../ActorContext";
import CONSTANTS                                                               from "../Constants";
import { ScanResults, fromScanLimitResult, VoteKind, voteKindToCandidVariant, 
  voteKindFromCandidVariant, convertScanResults, ScanLimitResult }             from "../utils";
import { QuestionOrderBy, Direction, QueryQuestionItem, QueryVoteItem }        from "../../declarations/godwin_sub/godwin_sub.did";

import { useParams }                                                           from "react-router-dom";
import React, { useState, useContext, useEffect }                              from "react";
import { fromNullable }                                                        from "@dfinity/utils";

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

const voteKindAction = (vote_kind: VoteKind) => {
  switch (vote_kind) {
    case VoteKind.INTEREST:
      return "Select";
    case VoteKind.OPINION:
      return "Vote";
    case VoteKind.CATEGORIZATION:
      return "Categorize";
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
      return { 'HOTNESS' : null };
    case BrowseFilter.OPEN:
      return { 'STATUS' : { 'OPEN' : null } };
    case BrowseFilter.ARCHIVED:
      return { 'ARCHIVE' : null };
    case BrowseFilter.REJECTED:
      return { 'TRASH' : null  } ;
  }
}

type QueryQuestionInputFunction = (direction: Direction, limit: bigint, next: QuestionInput | undefined) => Promise<ScanResults<QuestionInput>>;

const MainQuestions = () => {

  const { subgodwin } = useParams();
  const {subs,                getPrincipal          } = useContext(ActorContext);
  const [sub,                 setSub                ] = useState<Sub | undefined>(undefined             );
  const [currentMainTab,      setCurrentMainTab     ] = useState<MainTab        >(MainTab.HOME          );
  const [currentHomeFilter,   setCurrentHomeFilter  ] = useState<VoteKind       >(VoteKind.INTEREST     );
  const [currentBrowseFilter, setCurrentBrowseFilter] = useState<BrowseFilter   >(BrowseFilter.CANDIDATE);
  
  const [queryQuestionInput, setQueryQuestionInput] = useState<QueryQuestionInputFunction>(() => () => Promise.resolve({ ids : [], next: undefined}));

  const convertQuestionScanResults = (scan_results: ScanLimitResult<QueryQuestionItem>) : ScanResults<QuestionInput> => {
    return convertScanResults(fromScanLimitResult(scan_results), (item: QueryQuestionItem) : QuestionInput => {
      return {
        sub,
        question_id: item.question.id,
        question: item.question,
        statusData: item.status_data,
        principal: getPrincipal(),
        showReopenQuestion: item.can_reopen,
        allowVote: false
      }}
    );
  }

  const convertVoteScanResults = (scan_results: ScanLimitResult<QueryVoteItem>) : ScanResults<QuestionInput> => {
    return convertScanResults(fromScanLimitResult(scan_results), (item: QueryVoteItem) : QuestionInput => {
      return {
        sub,
        question_id: item.question_id,
        question: fromNullable(item.question),
        vote: { 
          kind: voteKindFromCandidVariant(item.vote[0]),
          data: item.vote[1]
        },
        principal: getPrincipal(),
        showReopenQuestion: false,
        allowVote: true
      }});
  }

  const refreshQueryQuestions = () => {
    if (sub === undefined) {
      setQueryQuestionInput(() => () => Promise.resolve({ ids : [], next: undefined}));
    } else if (currentMainTab === MainTab.BROWSE) {
      setQueryQuestionInput(() => (direction: Direction, limit: bigint, next: QuestionInput | undefined) =>
        sub.actor.queryQuestions(getQueryOrderBy(currentBrowseFilter), direction, limit, next? [next.question_id] : []).then(convertQuestionScanResults));
    } else if (currentMainTab === MainTab.HOME) {
      setQueryQuestionInput(() => (direction: Direction, limit: bigint, next: QuestionInput | undefined) =>
        sub.actor.queryFreshVotes(voteKindToCandidVariant(currentHomeFilter), direction, limit, next? [next.question_id] : []).then(convertVoteScanResults));
    }
  }

  useEffect(() => {
    if (subgodwin !== undefined) {
      setSub(subs.get(subgodwin));
    }
  }, [subgodwin, subs]);

  useEffect(() => {
    refreshQueryQuestions();
  }, [sub, currentBrowseFilter, currentHomeFilter, currentMainTab]);

	return (
    (
      sub === undefined ?  
        <div className="flex flex-col items-center w-full text-black dark:text-white">
          { CONSTANTS.SUB_DOES_NOT_EXIST }
        </div> : 
        <div className="flex flex-col items-center w-full">
          <SubBanner sub={sub}/>
          <div className="flex flex-col sticky xl:top-18 lg:top-16 md:top-14 top-14 z-20 bg-white dark:bg-slate-900 items-center w-full">
            <div className="flex flex-col border-x dark:border-gray-700 bg-white dark:bg-slate-900 xl:w-1/3 lg:w-2/3 md:w-2/3 sm:w-full w-full">
              <div className="border-b dark:border-gray-700 w-full">
                <ul className="flex flex-wrap text-sm dark:text-gray-400 font-medium text-center">
                {
                  mainTabs.map((tab, index) => (
                    <li key={index} className="w-1/2">
                      <MainTabButton label={mainTabToText(tab)} isCurrent={tab == currentMainTab} setIsCurrent={() => setCurrentMainTab(tab)}/>
                    </li>
                  ))
                }
                </ul>
              </div>
              <div className="border-b dark:border-gray-700 w-full">
                <ul className="flex flex-wrap text-sm dark:text-gray-400 font-medium text-center w-full">
                {
                  currentMainTab === MainTab.HOME ? (
                    vote_kind_filters.map((filter, index) => (
                      <li key={index} className="w-1/3">
                        <TabButton label={voteKindAction(filter)} isCurrent={filter == currentHomeFilter} setIsCurrent={() => setCurrentHomeFilter(filter)}/>
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
          <div className="flex flex-col border mb-5 dark:border-gray-700 xl:w-1/3 lg:w-2/3 md:w-2/3 sm:w-full w-full">
            {
              currentMainTab === MainTab.HOME ?
              <div className="border-b dark:border-gray-700">
                <OpenQuestion onSubmitQuestion={()=>{}} subId={subgodwin} canSelectSub={false}></OpenQuestion>
              </div> : <></>
            }
            <div className="w-full flex">
            {
              React.createElement(ListComponents<QuestionInput, QuestionInput>, {
                query_components: queryQuestionInput,
                generate_input: (item: QuestionInput) => { return item },
                build_component: QuestionComponent,
                generate_key: (item: QuestionInput) => { return item.question_id.toString() }
              })
            }
            </div>
          </div>
        </div>
    )
	);
};

export default MainQuestions;
