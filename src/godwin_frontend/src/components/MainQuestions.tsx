import { TabButton }                                                           from "./TabButton";
import { MainTabButton }                                                       from "./MainTabButton";
import OpenQuestion                                                            from "./OpenQuestion";
import SubBanner                                                               from "./SubBanner";
import QuestionComponent, { QuestionInput }                                    from "./Question";
import Spinner                                                                 from "./Spinner";
import { HelpProposeDetails, HelpSelectDetails, HelpVoteDetails, 
  HelpMapDetails, HelpArchivedDetails, HelpOpenDetails,
  HelpCandidateDetails, HelpRejectedDetails }                                  from "./HelpMessages";
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

export enum HomeFilter {
  PROPOSE,
  SELECT,
  VOTE,
  MAP
};

const homeFilterToText = (filter: HomeFilter) => {
  switch (filter) {
    case HomeFilter.PROPOSE:
      return "Propose";
    case HomeFilter.SELECT:
      return "Select";
    case HomeFilter.VOTE:
      return "Vote";
    case HomeFilter.MAP:
      return "Map";
  }
}

const homeFilterToVoteKind = (filter: HomeFilter) : VoteKind | undefined => {
  switch (filter) {
    case HomeFilter.PROPOSE:
      return undefined;
    case HomeFilter.SELECT:
      return VoteKind.INTEREST;
    case HomeFilter.VOTE:
      return VoteKind.OPINION;
    case HomeFilter.MAP:
      return VoteKind.CATEGORIZATION;
  }
}

const home_filters = [HomeFilter.VOTE, HomeFilter.MAP, HomeFilter.SELECT, HomeFilter.PROPOSE];

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

const browse_filters = [BrowseFilter.ARCHIVED, BrowseFilter.OPEN, BrowseFilter.CANDIDATE , BrowseFilter.REJECTED];

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

  const { subgodwin }                                 = useParams();
  
  const {subs, getPrincipal }                         = useContext(ActorContext);
  
  const [initialized,         setInitialized        ] = useState<boolean>        (false                 );
  const [sub,                 setSub                ] = useState<Sub | undefined>(undefined             );
  const [currentMainTab,      setCurrentMainTab     ] = useState<MainTab        >(MainTab.HOME          );
  const [currentHomeFilter,   setCurrentHomeFilter  ] = useState<HomeFilter     >(HomeFilter.VOTE       );
  const [currentBrowseFilter, setCurrentBrowseFilter] = useState<BrowseFilter   >(BrowseFilter.CANDIDATE);
  const [toggleHelp,          setToggleHelp         ] = useState<boolean        >(false                 );
  
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
      let vote_kind = homeFilterToVoteKind(currentHomeFilter);
      if (vote_kind !== undefined) {
        setQueryQuestionInput(() => (direction: Direction, limit: bigint, next: QuestionInput | undefined) =>
          sub.actor.queryFreshVotes(voteKindToCandidVariant(vote_kind), direction, limit, next? [next.question_id] : []).then(convertVoteScanResults));
      } else {
        setQueryQuestionInput(() => () => Promise.resolve({ ids : [], next: undefined}));
      }
    }
  }

  useEffect(() => {
    if (subgodwin !== undefined) {
      setSub(subs.get(subgodwin));
    }
    // A first useEffect is called before the context is up-to-date with the all the subs
    // We consider the component initialized only after the second useEffect call, when the map of subs is populated
    if (subs.size > 0) {
      setInitialized(true);
    };
  }, [subs]);

  useEffect(() => {
    refreshQueryQuestions();
  }, [sub, currentBrowseFilter, currentHomeFilter, currentMainTab]);

  // Hide the help message when the current tab changes
  useEffect(() => {
    setToggleHelp(false);
  }, [currentMainTab, currentHomeFilter, currentBrowseFilter]);

	return (
    <div className="flex flex-col items-center w-full flex-grow">
    {
      !initialized? 
        <div className="w-6 h-6 mt-4">
          <Spinner/>
        </div>
      : sub === undefined ?  
        <div className="text-black dark:text-white">
          { CONSTANTS.SUB_DOES_NOT_EXIST }
        </div> 
      : 
        <div className="flex flex-col items-center w-full flex-grow">
          <SubBanner sub={sub}/>
          <div className="flex flex-col border-x border-t dark:border-gray-700 sticky xl:top-18 lg:top-16 md:top-14 sm:top-14 z-20 bg-white dark:bg-slate-900 xl:w-1/3 lg:w-2/3 md:w-2/3 sm:w-full w-full">
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
                  home_filters.map((filter, index) => (
                    <li key={index} className="w-1/4">
                      <TabButton 
                        label={homeFilterToText(filter)} 
                        isCurrent={filter == currentHomeFilter} 
                        setIsCurrent={() => { setCurrentHomeFilter(filter); }}
                        isHelpVisible={toggleHelp}
                        setIsHelpVisible={setToggleHelp}
                      />
                    </li>))
                ) : (
                  browse_filters.map((filter, index) => (
                    <li key={index} className="w-1/4">
                      <TabButton 
                        label={browseFilterToText(filter)} 
                        isCurrent={filter == currentBrowseFilter} 
                        setIsCurrent={() => setCurrentBrowseFilter(filter)} 
                        isHelpVisible={toggleHelp}
                        setIsHelpVisible={setToggleHelp}
                      />
                    </li>
                  ))
                )
              }
              </ul>
            </div>
          </div>
          <div className="flex flex-col border dark:border-gray-700 xl:w-1/3 lg:w-2/3 md:w-2/3 sm:w-full w-full flex-grow">
            {
              !toggleHelp ? <></> :
              currentMainTab === MainTab.HOME ?
                currentHomeFilter === HomeFilter.VOTE          ? <HelpVoteDetails/>                                                  :
                currentHomeFilter === HomeFilter.MAP           ? <HelpMapDetails/>                                                   :
                currentHomeFilter === HomeFilter.SELECT        ? <HelpSelectDetails/>                                                :
                currentHomeFilter === HomeFilter.PROPOSE       ? <HelpProposeDetails max_num_characters={sub.info.character_limit}/> : <></> :
              currentMainTab === MainTab.BROWSE ?
                currentBrowseFilter === BrowseFilter.ARCHIVED  ? <HelpArchivedDetails/>                                              :
                currentBrowseFilter === BrowseFilter.OPEN      ? <HelpOpenDetails/>                                                  :
                currentBrowseFilter === BrowseFilter.CANDIDATE ? <HelpCandidateDetails/>                                             :
                currentBrowseFilter === BrowseFilter.REJECTED  ? <HelpRejectedDetails/>                                              : <></> : <></>
            }
            {
              currentMainTab === MainTab.HOME && currentHomeFilter === HomeFilter.PROPOSE ?
                <OpenQuestion textInputId={"propose_vote_sub"} onSubmitQuestion={()=>{ refreshQueryQuestions(); }} subId={subgodwin} canSelectSub={false}/>
                : <></>
            }
            <div className="w-full flex flex-grow">
            {
              React.createElement(ListComponents<QuestionInput, QuestionInput>, {
                query_components: queryQuestionInput,
                generate_input: (item: QuestionInput) => { return item },
                build_component: QuestionComponent,
                generate_key: (item: QuestionInput) => { return item.question_id.toString() },
                empty_list_message: () => { 
                  return currentMainTab === MainTab.HOME ? 
                    currentHomeFilter === HomeFilter.PROPOSE ? "" : CONSTANTS.EMPTY_HOME : CONSTANTS.GENERIC_EMPTY 
                }
              })
            }
            </div>
          </div>
        </div>
    }
    </div>
	);
};

export default MainQuestions;
