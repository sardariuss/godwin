import AppealDigest                                                                                from "./interest/AppealDigest";
import OpinionAggregate                                                                            from "./opinion/OpinionAggregate";
import AppealBar                                                                                   from "./interest/AppealBar";
import CategorizationAggregateDigest                                                               from "./categorization/CategorizationAggregateDigest";
import SinglePolarizationBar                                                                       from "./base/SinglePolarizationBar";
import CategorizationPolarizationBars                                                              from "./categorization/CategorizationPolarizationBars";
import { statusToString, toMap, VoteKind }                                                         from "../utils";
import { nsToStrDate }                                                                             from "../utils/DateUtils";
import CONSTANTS                                                                                   from "../Constants";
import { _SERVICE, Status, Category, CategoryInfo, InterestVote, OpinionVote, CategorizationVote } from "../../declarations/godwin_backend/godwin_backend.did";

import { ActorSubclass }                                                                           from "@dfinity/agent";
import { useEffect, useState }                                                                     from "react";

import { CandidateIcon, OpenIcon, ClosedIcon, TimedOutIcon, CensoredIcon }                         from "./icons/StatusIcons";

type Props = {
  actor: ActorSubclass<_SERVICE>,
  questionId: bigint;
  status: Status;
  date: bigint;
  iteration: bigint;
  isHistory: boolean;
  categories: Map<Category, CategoryInfo>
  showBorder: boolean;
  borderDashed: boolean;
};

const StatusComponent = ({actor, questionId, status, date, iteration, isHistory, categories, showBorder, borderDashed}: Props) => {

  const [selectedVote,       setSelectedVote      ] = useState<          VoteKind | undefined>(undefined);
  const [interestVote,       setInterestVote      ] = useState<      InterestVote | undefined>(undefined);
  const [opinionVote,        setOpinionVote       ] = useState<       OpinionVote | undefined>(undefined);
  const [categorizationVote, setCategorizationVote] = useState<CategorizationVote | undefined>(undefined);

  const fetchRevealedVotes = async () => {
  
    setInterestVote(undefined);
    setOpinionVote(undefined);
    setCategorizationVote(undefined);

    if (isHistory){
      if (status['CANDIDATE'] !== undefined) {
				let interest_vote_id = (await actor.findInterestVoteId(questionId, iteration))['ok'];
				if (interest_vote_id !== undefined) {
          setInterestVote((await actor.revealInterestVote(interest_vote_id))['ok']);
				}
			} else if (status['OPEN'] !== undefined) {
				let opinion_vote_id = (await actor.findOpinionVoteId(questionId, iteration))['ok'];
				if (opinion_vote_id !== undefined) {
					setOpinionVote((await actor.revealOpinionVote(opinion_vote_id))['ok']);
				}
				let categorization_vote_id = (await actor.findCategorizationVoteId(questionId, iteration))['ok'];
				if (categorization_vote_id !== undefined) {
					setCategorizationVote((await actor.revealCategorizationVote(categorization_vote_id))['ok']);
				}
			}
    }
  }

  useEffect(() => {
    fetchRevealedVotes();
  }, [status, date, iteration, isHistory]);

	return (
    <div className={`group/status border-gray-500 pl-2 ml-4
      ${showBorder? ( borderDashed ? "border-l-2 border-dashed" : "border-l-2 border-solid") : ""}
      ${ !isHistory && showBorder ? "hover:border-gray-700 hover:dark:border-gray-300" : ""}
    `}>
      <div className={`text-gray-700 dark:text-gray-300 -ml-6 ${ !showBorder || borderDashed  ? "pb-3" : "pb-5"}`}>
        <div className="flex flex-row gap-x-3">
          <span className={"flex items-center justify-center w-8 h-8 rounded-full -left-4 ring-2 " 
          + ( isHistory ? "bg-gray-100 fill-gray-800 ring-gray-300 dark:bg-gray-700 dark:fill-gray-400 dark:ring-gray-400" :
           "                       bg-blue-200                         fill-blue-500                         ring-blue-500 \
                              dark:bg-blue-800                    dark:fill-blue-500                    dark:ring-blue-500" )
          + ( !isHistory && showBorder ? 
              "group-hover/status:bg-blue-300      group-hover/status:fill-blue-600      group-hover/status:ring-blue-600\
          group-hover/status:dark:bg-blue-700 group-hover/status:dark:fill-blue-400 group-hover/status:dark:ring-blue-400" 
          : "")}>
            {
              status['CANDIDATE'] !== undefined ?
                <CandidateIcon/> :
              status['OPEN'] !== undefined ?
                <OpenIcon/> :
              status['CLOSED'] !== undefined ?
                <ClosedIcon/> :
              status['REJECTED'] !== undefined && status['REJECTED']['TIMED_OUT'] !== undefined ?
                <TimedOutIcon/> :
              status['REJECTED'] !== undefined && status['REJECTED']['CENSORED'] !== undefined ?
                <CensoredIcon/> : <></>
            }
          </span>
          <div className="flex flex-col grow">
            <div className="flex flex-row items-center gap-x-1">
              <div className={`font-light text-sm ${ !isHistory && showBorder ? "group-hover/status:text-black group-hover/status:dark:text-white" : ""}`}>
                { statusToString(status) } 
              </div>
              <div className={`flex flex-row items-center gap-x-3`}>
              {
                isHistory ? 
                  status['CANDIDATE'] !== undefined ?
                    <AppealDigest 
                      aggregate={interestVote !== undefined ? interestVote.aggregate : undefined}
                      setSelected={(selected: boolean) => { setSelectedVote(selected ? VoteKind.INTEREST : undefined) }}
                      selected={ selectedVote === VoteKind.INTEREST}
                    />
                  : status['OPEN'] !== undefined ?
                  <div className="flex flex-row items-center gap-x-1">
                    <OpinionAggregate
                      aggregate={opinionVote !== undefined ? opinionVote.aggregate : undefined}
                      setSelected={(selected: boolean) => { setSelectedVote(selected ? VoteKind.OPINION : undefined) }}
                      selected={ selectedVote === VoteKind.OPINION}
                    />
                    {" · "}
                    <CategorizationAggregateDigest 
                      aggregate={categorizationVote !== undefined ? toMap(categorizationVote.aggregate) : undefined}
                      categories={categories}
                      setSelected={(selected: boolean) => { setSelectedVote(selected ? VoteKind.CATEGORIZATION : undefined) }}
                      selected={ selectedVote === VoteKind.CATEGORIZATION}
                    />
                  </div>
                  : <> </>
                : <> </>
              }
              </div>
            </div>
            <div className={`text-xs font-extralight ${ !isHistory && showBorder ? "group-hover/status:text-black group-hover/status:dark:text-white" : ""}`}>{ nsToStrDate(date) }</div>
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
                  <SinglePolarizationBar
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
                  categories={categories}
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
