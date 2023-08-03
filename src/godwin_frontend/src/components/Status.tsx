import { CandidateIcon, OpenIcon, ClosedIcon, TimedOutIcon, CensoredIcon }           from "./icons/StatusIcons";
import AppealDigest                                                                  from "./interest/AppealDigest";
import OpinionAggregate                                                              from "./opinion/OpinionAggregate";
import OpinionPolarizationBar                                                        from "./opinion/OpinionPolarizationBar";
import AppealBar                                                                     from "./interest/AppealBar";
import CategorizationAggregateDigest                                                 from "./categorization/CategorizationAggregateDigest";
import CategorizationPolarizationBars                                                from "./categorization/CategorizationPolarizationBars";
import { toMap, VoteKind, getStatusDuration, 
  durationToNanoSeconds, StatusEnum, statusToEnum, statusEnumToString }              from "../utils";
import { nsToStrDate, formatTimeDiff }                                               from "../utils/DateUtils";
import { Sub }                                                                       from "../ActorContext";
import { StatusData, SchedulerParameters, VoteAggregate, 
  OpinionAggregate as OpinionAggregateDid, PolarizationArray, Appeal }               from "../../declarations/godwin_sub/godwin_sub.did";

import Countdown                                                                     from "react-countdown";
import React, { useState }                                                           from "react";
import { fromNullable }                                                              from "@dfinity/utils";

type Props = {
  sub: Sub;
  statusData: StatusData;
  isToggledHistory: boolean;
  toggleHistory: (toggle: boolean) => void;
  isHistory: boolean;
  showBorder: boolean;
  borderDashed: boolean;
};

const computeEndDate = (status_data: StatusData, scheduler_parameters: SchedulerParameters) : Date | undefined => {
  let status_duration = getStatusDuration(status_data.status_info.status, scheduler_parameters);
  if (status_duration === undefined) {
    return undefined;
  }
  return new Date(Number((status_data.status_info.date + durationToNanoSeconds(status_duration)) / BigInt(1000000)));
};

export const findInterestAggregate = (status_data: StatusData) : [bigint, Appeal]  | undefined => {
  let aggregates = getPreviousVoteAggregates(status_data);
  for (var {vote_id, aggregate} of aggregates) {
    if (aggregate['INTEREST'] !== undefined){
      return [vote_id, aggregate['INTEREST']];
    }
  };
  return undefined;
}

export const findOpinionAggregate = (status_data: StatusData) : [bigint, OpinionAggregateDid]  | undefined => {
  let aggregates = getPreviousVoteAggregates(status_data);
  for (var {vote_id, aggregate} of aggregates) {
    if (aggregate['OPINION'] !== undefined){
      return [vote_id, aggregate['OPINION']];
    }
  };
  return undefined;
}

export const findCategorizationAggregate = (status_data: StatusData) : [bigint, PolarizationArray]  | undefined => {
  let aggregates = getPreviousVoteAggregates(status_data);
  for (var {vote_id, aggregate} of aggregates) {
    if (aggregate['CATEGORIZATION'] !== undefined){
      return [vote_id, aggregate['CATEGORIZATION']];
    }
  };
  return undefined;
}

const getPreviousVoteAggregates = (status_data: StatusData) : VoteAggregate[] => {
  let previous = fromNullable(status_data.previous_status);
  if (previous === undefined) {
    return [];
  } else {
    return previous.vote_aggregates;
  }
}

const StatusComponent = ({sub, statusData, isToggledHistory, toggleHistory, isHistory, showBorder, borderDashed}: Props) => {

  const [status]                        = useState<StatusEnum>                               (statusToEnum(statusData.status_info.status)              );
  const [date]                          = useState<string>                                   (nsToStrDate(statusData.status_info.date)                 );
  const [statusEndDate]                 = useState<Date | undefined>                         (computeEndDate(statusData, sub.info.scheduler_parameters));
  const [selectedVote, setSelectedVote] = useState<VoteKind | undefined>                     (undefined                                                );
  const [previousInterestVote]          = useState<[bigint, Appeal             ] | undefined>(findInterestAggregate(statusData)                        );
  const [previousOpinionVote]           = useState<[bigint, OpinionAggregateDid] | undefined>(findOpinionAggregate(statusData)                         );
  const [previousCategorizationVote]    = useState<[bigint, PolarizationArray  ] | undefined>(findCategorizationAggregate(statusData)                  );

  const toggleVote = (vote_kind: VoteKind, toggled: boolean) => {
    setSelectedVote(toggled ? vote_kind : undefined);  
    // Show the history if a vote is selected and the history is not already shown
    if (toggled && !isToggledHistory) { 
      toggleHistory(true); 
    } 
  }

	return (
    <div>
      <div className={`text-gray-700 dark:text-gray-300`}>
        <div className="flex flex-row">
          <div className={`flex flex-row justify-center px-1 group/status ${!isHistory && showBorder ? "hover:cursor-pointer" : ""}`}
            onClick={(e) => { 
              if (!isHistory && showBorder) { 
                toggleHistory(!isToggledHistory); 
                // Hide the selected vote if the history is hidden
                if (isToggledHistory) {
                  setSelectedVote(undefined); 
                }
              }
            }}>
            <span className={"flex items-center justify-center w-8 h-8 rounded-full ring-2 z-10 " 
            + ( isHistory ? "bg-gray-100 fill-gray-800 ring-gray-300 dark:bg-gray-700 dark:fill-gray-400 dark:ring-gray-400" :
            "                       bg-blue-200                         fill-blue-500                         ring-blue-500 \
                                dark:bg-blue-800                    dark:fill-blue-500                    dark:ring-blue-500" )
            + ( !isHistory && showBorder ? 
                "group-hover/status:bg-blue-300      group-hover/status:fill-blue-600      group-hover/status:ring-blue-600\
            group-hover/status:dark:bg-blue-700 group-hover/status:dark:fill-blue-400 group-hover/status:dark:ring-blue-400" 
            : "")}>
              {
                status === StatusEnum.CANDIDATE ? <CandidateIcon/> :
                status === StatusEnum.OPEN      ? <OpenIcon/>      :
                status === StatusEnum.CLOSED    ? <ClosedIcon/>    :
                status === StatusEnum.TIMED_OUT ? <TimedOutIcon/>  :
                status === StatusEnum.CENSORED  ? <CensoredIcon/>  : <></>
              }
            </span>
            <div className={`border-gray-500 -ml-[17px] w-5 grow
              ${ showBorder? "border-l-2" : "" }
              ${ borderDashed ? "border-dashed" : "border-solid" }
              ${ !showBorder || borderDashed  ? "pb-5" : "pb-8" }
              ${ !isHistory && showBorder ? "group-hover/status:border-gray-700 group-hover/status:dark:border-gray-300" : ""}
            `}>
              {"." /* Hack to be able to display the border */}
            </div>
          </div>
          <div className="flex flex-col w-full">
            <div className="flex flex-row items-center gap-x-1 w-full justify-start">
              <div className={`font-light text-sm ${ !isHistory && showBorder ? "group-hover/status:text-black group-hover/status:dark:text-white" : ""}`}>
                { statusEnumToString(status) } 
              </div>
              {
                previousInterestVote !== undefined ?
                  <AppealDigest 
                    aggregate={previousInterestVote[1]}
                    setSelected={(selected: boolean) => { toggleVote(VoteKind.INTEREST, selected); }}
                    selected={ selectedVote === VoteKind.INTEREST}
                  /> : <></>
              }
              {
                previousInterestVote !== undefined && previousOpinionVote !== undefined ?
                  <div>{ /*spacer*/ " · "}</div> : <></>
              }
              {
               previousOpinionVote !== undefined ?
                  <OpinionAggregate
                    aggregate={previousOpinionVote[1]}
                    setSelected={(selected: boolean) => { toggleVote(VoteKind.OPINION, selected); }}
                    selected={ selectedVote === VoteKind.OPINION}
                  /> : <></>
              }
              {
                previousCategorizationVote !== undefined && (previousInterestVote !== undefined || previousOpinionVote !== undefined) ?
                  <div>{ /*spacer*/ " · "}</div> : <></>
              }
              {
                previousCategorizationVote !== undefined ?
                  <CategorizationAggregateDigest 
                    aggregate={toMap(previousCategorizationVote[1])}
                    categories={sub.info.categories}
                    setSelected={(selected: boolean) => { toggleVote(VoteKind.CATEGORIZATION, selected); }}
                    selected={ selectedVote === VoteKind.CATEGORIZATION}
                  /> : <> </>
              }
            </div>
            <div className="flex flex-row justify-start space-x-1">
              <div className={`text-xs font-extralight 
                ${ !isHistory && showBorder ? "group-hover/status:text-black group-hover/status:dark:text-white" : ""}`}>
                  { date }
              </div>
              { statusEndDate !== undefined && !isHistory ?
                <Countdown date={statusEndDate} renderer={props => <div className="text-xs font-light">{ "(ends " + formatTimeDiff(props.total / 1000) + ")"}</div>}>
                  <div>{ /* @todo */}</div>
                </Countdown> : <></>
              }
            </div>
            <div className={ selectedVote !== undefined ? "mt-5" : "" }>
              {
                selectedVote === VoteKind.INTEREST && previousInterestVote !== undefined ?
                  <AppealBar sub={sub} vote_id={previousInterestVote[0]}/> : <></>
              }
              {     
                selectedVote === VoteKind.OPINION && previousOpinionVote !== undefined ?
                  <OpinionPolarizationBar sub={sub} vote_id={previousOpinionVote[0]}/> : <></>
              }
              {
                selectedVote === VoteKind.CATEGORIZATION && previousCategorizationVote !== undefined ?
                <CategorizationPolarizationBars sub={sub} vote_id={previousCategorizationVote[0]}/> : <></>
              }
            </div>
          </div>
        </div>
      </div>
    </div>
	);
};

export default StatusComponent;
