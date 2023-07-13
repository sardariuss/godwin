import { CandidateIcon, OpenIcon, ClosedIcon, TimedOutIcon, CensoredIcon }           from "./icons/StatusIcons";
import AppealDigest                                                                  from "./interest/AppealDigest";
import OpinionAggregate                                                              from "./opinion/OpinionAggregate";
import OpinionPolarizationBar                                                        from "./opinion/OpinionPolarizationBar";
import AppealBar                                                                     from "./interest/AppealBar";
import CategorizationAggregateDigest                                                 from "./categorization/CategorizationAggregateDigest";
import CategorizationPolarizationBars                                                from "./categorization/CategorizationPolarizationBars";
import { statusToString, toMap, VoteKind, getStatusDuration, durationToNanoSeconds, StatusEnum, statusToEnum } from "../utils";
import { nsToStrDate, formatTimeDiff }                                               from "../utils/DateUtils";
import CONSTANTS                                                                     from "../Constants";
import { Sub }                                                                       from "../ActorContext";
import { StatusInfo, InterestVote, OpinionVote, CategorizationVote, StatusData, SchedulerParameters }                 from "../../declarations/godwin_sub/godwin_sub.did";

import Countdown                                                                     from "react-countdown";
import { useEffect, useState }                                                       from "react";

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

const StatusComponent = ({sub, statusData, isToggledHistory, toggleHistory, isHistory, showBorder, borderDashed}: Props) => {

  const [status] = useState<StatusEnum>(statusToEnum(statusData.status_info.status));
  const [statusEndDate] = useState<Date | undefined>(computeEndDate(statusData, sub.scheduler_parameters));

  const [{ status_info, previous_status }]          = useState<StatusData          >(statusData);
  const [selectedVote,       setSelectedVote      ] = useState<VoteKind | undefined>(undefined );

//  const [interestVote,       setInterestVote      ] = useState<      InterestVote | undefined>(undefined);
//  const [opinionVote,        setOpinionVote       ] = useState<       OpinionVote | undefined>(undefined);
//  const [categorizationVote, setCategorizationVote] = useState<CategorizationVote | undefined>(undefined);

//  const fetchRevealedVotes = async () => {
//  
//    setInterestVote(undefined);
//    setOpinionVote(undefined);
//    setCategorizationVote(undefined);
//
//    // Reveal the results of the vote(s) associated with the previous state
//    if (previousStatusInfo !== undefined && previousStatusInfo.status['CANDIDATE'] !== undefined) {
//      let interest_vote_id = (await sub.actor.findInterestVoteId(questionId, previousStatusInfo.iteration))['ok'];
//      if (interest_vote_id !== undefined) {
//        setInterestVote((await sub.actor.revealInterestVote(interest_vote_id))['ok']);
//      }
//    } else if (previousStatusInfo !== undefined && previousStatusInfo.status['OPEN'] !== undefined) {
//      let opinion_vote_id = (await sub.actor.findOpinionVoteId(questionId, previousStatusInfo.iteration))['ok'];
//      if (opinion_vote_id !== undefined) {
//        setOpinionVote((await sub.actor.revealOpinionVote(opinion_vote_id))['ok']);
//      }
//      let categorization_vote_id = (await sub.actor.findCategorizationVoteId(questionId, previousStatusInfo.iteration))['ok'];
//      if (categorization_vote_id !== undefined) {
//        setCategorizationVote((await sub.actor.revealCategorizationVote(categorization_vote_id))['ok']);
//      }
//    }
//  }

  const getStatus = () : StatusEnum => {
    return statusToEnum(status_info.status);
  }

  const toggleVote = (vote_kind: VoteKind, toggled: boolean) => {
    setSelectedVote(toggled ? vote_kind : undefined); 
    
    // Show the history if a vote is selected and the history is not already shown
    if (toggled && !isToggledHistory) { 
      toggleHistory(true); 
    } 
  }

//  useEffect(() => {
//    fetchRevealedVotes();
//  }, [status_info, previousStatusInfo, isHistory]);

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
                status === StatusEnum.OPEN ? <OpenIcon/> :
                status === StatusEnum.CLOSED ? <ClosedIcon/> :
                status === StatusEnum.TIMED_OUT ? <TimedOutIcon/> :
                status === StatusEnum.CENSORED ? <CensoredIcon/> : <></>
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
            <div className="flex flex-row items-center gap-x-1 w-full">
              <div className={`font-light text-sm ${ !isHistory && showBorder ? "group-hover/status:text-black group-hover/status:dark:text-white" : ""}`}>
                { statusToString(status_info.status) } 
              </div>
              <div className={`flex flex-row items-center gap-x-3`}>
              {
                status_info.status['OPEN'] !== undefined || status_info.status['REJECTED'] !== undefined ?
                  <AppealDigest 
                    aggregate={interestVote !== undefined ? interestVote.aggregate : undefined}
                    setSelected={(selected: boolean) => { toggleVote(VoteKind.INTEREST, selected); }}
                    selected={ selectedVote === VoteKind.INTEREST}
                  />
                : status_info.status['CLOSED'] !== undefined ?
                <div className="flex flex-row items-center gap-x-1">
                  <OpinionAggregate
                    aggregate={opinionVote !== undefined ? opinionVote.aggregate : undefined}
                    setSelected={(selected: boolean) => { toggleVote(VoteKind.OPINION, selected); }}
                    selected={ selectedVote === VoteKind.OPINION}
                  />
                  {" · "}
                  <CategorizationAggregateDigest 
                    aggregate={categorizationVote !== undefined ? toMap(categorizationVote.aggregate) : undefined}
                    categories={toMap(sub.categories)}
                    setSelected={(selected: boolean) => { toggleVote(VoteKind.CATEGORIZATION, selected); }}
                    selected={ selectedVote === VoteKind.CATEGORIZATION}
                  />
                </div>
                : <> </>
              }
              </div>
            </div>
            <div className="flex flex-row justify-between">
              <div className={`text-xs font-extralight 
                ${ !isHistory && showBorder ? "group-hover/status:text-black group-hover/status:dark:text-white" : ""}`}>
                  { nsToStrDate(status_info.date) }
              </div>
              { statusEndDate !== undefined && !isHistory ?
                <Countdown date={statusEndDate} renderer={props => <div className="text-xs font-light">{ "ends " + formatTimeDiff(props.total / 1000) }</div>}>
                  <div>Good to go</div>
                </Countdown> : <></>
              }
            </div>
            <div className={ selectedVote !== undefined ? "mt-5" : "" }>
              <div>
              {
                selectedVote === VoteKind.INTEREST && interestVote !== undefined ?
                  <AppealBar vote={interestVote}/> : <></>
              }
              </div>
              <div>
              {     
                selectedVote === VoteKind.OPINION && opinionVote !== undefined ?
                  <OpinionPolarizationBar
                    name={"OPINION"}
                    showName={false}
                    polarizationInfo={CONSTANTS.OPINION_INFO}
                    vote={opinionVote}
                  /> : <></>
              }
              </div>
              <div>
              {
                selectedVote === VoteKind.CATEGORIZATION && categorizationVote !== undefined ?
                <CategorizationPolarizationBars
                  showName={true}
                  categorizationVote={categorizationVote}
                  categories={toMap(sub.categories)}
                /> : <></>
              }
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
	);
};

export default StatusComponent;
