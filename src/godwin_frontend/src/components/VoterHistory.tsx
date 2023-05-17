import { useEffect, useState } from "react";
import { Sub } from "./../ActorContext";

import { Principal } from "@dfinity/principal";

import { toCursorInfo, VoteType, VoteTypes, voteTypeToString, getStrongestCategoryCursorInfo, toMap } from "../utils";
import { InterestBallot, OpinionBallot, CategorizationBallot, Question } from "../../declarations/godwin_backend/godwin_backend.did";

import { TabButton } from "./TabButton";

import Ballot from "./votes/Ballot";

import CONSTANTS from "../Constants";

type VoterHistoryProps = {
  principal: Principal;
  sub: Sub;
};

export const VoterHistory = ({principal, sub}: VoterHistoryProps) => {

  const [voteType, setVoteType] = useState<VoteType>(VoteType.INTEREST);

  const [interestVotes, setInterestVotes] = useState<[Question, InterestBallot][]>([]);
  const [opinionVotes, setOpinionVotes] = useState<[Question, OpinionBallot][]>([]);
  const [categorizationVotes, setCategorizationVotes] = useState<[Question, CategorizationBallot][]>([]);
  //const [opinionScanResults, setOpinionScanResults] = useState<ScanResults<[bigint, OpinionBallot]> | undefined>(undefined);

  const fetchInterestHistory = async () => {
    let interest_history = await sub.actor.getVoterInterestHistory(principal, BigInt(10), []);
    let votes : [Question, InterestBallot][] = [];
    for (let [vote_id, ballot] of interest_history.keys){
      let question = await sub.actor.getQuestionIteration({ 'INTEREST' : null }, vote_id);
      if (question['ok'] !== undefined){
        votes.push([question['ok'][0], ballot]);
      }
    }
    setInterestVotes(votes);
  };

  const fetchOpinionHistory = async () => {
    let opinion_history = await sub.actor.getVoterOpinionHistory(principal, BigInt(10), []);
    let votes : [Question, OpinionBallot][] = [];
    for (let [vote_id, ballot] of opinion_history.keys){
      let question = await sub.actor.getQuestionIteration({ 'OPINION' : null }, vote_id);
      if (question['ok'] !== undefined){
        votes.push([question['ok'][0], ballot]);
      }
    }
    setOpinionVotes(votes);
  };

  const fetchCategorizationHistory = async () => {
    let categorization_history = await sub.actor.getVoterCategorizationHistory(principal, BigInt(10), []);
    let votes : [Question, CategorizationBallot][] = [];
    for (let [vote_id, ballot] of categorization_history.keys){
      let question = await sub.actor.getQuestionIteration({ 'CATEGORIZATION' : null }, vote_id);
      if (question['ok'] !== undefined){
        votes.push([question['ok'][0], ballot]);
      }
    }
    setCategorizationVotes(votes);
  };

  useEffect(() => {
    if (voteType === VoteType.INTEREST){
      fetchInterestHistory();
    } else if (voteType === VoteType.OPINION){
      fetchOpinionHistory();
    } else if (voteType === VoteType.CATEGORIZATION){
      fetchCategorizationHistory();
    }
  }, [voteType]);

  return (
    <div className="flex flex-col w-full">
      <div className="border-b dark:border-gray-700">
        <ul className="flex flex-wrap text-sm dark:text-gray-400 font-medium text-center">
        {
          VoteTypes.map((type, index) => (
            <li key={index} className="w-1/3">
              <TabButton label={voteTypeToString(type)} isCurrent={type === voteType} setIsCurrent={() => setVoteType(type)}/>
            </li>
          ))
        }
        </ul>
      </div>
      <ol>
        {
          voteType === VoteType.INTEREST ? interestVotes.map(([question, ballot]) => {
            return (
              <li className="flex w-full text-black dark:text-white border-b dark:border-gray-700 hover:bg-slate-50 hover:dark:bg-slate-850 py-2" key={question.id.toString()}>
                <div className="grid grid-cols-4 py-1 px-6 w-full">
                  <div className="col-span-3 w-full justify-start text-sm font-normal">
                    {question.text.toString()}
                  </div>
                  <Ballot cursorInfo={toCursorInfo(ballot.answer, CONSTANTS.INTEREST_INFO)} dateNs={ballot.date} />
                </div>
              </li>
            );
          }) :
          voteType === VoteType.OPINION ? opinionVotes.map(([question, ballot]) => {
            return (
              <li className="flex w-full text-black dark:text-white border-b dark:border-gray-700 hover:bg-slate-50 hover:dark:bg-slate-850 py-2" key={question.id.toString()}>
                <div className="grid grid-cols-4 py-1 px-6 w-full">
                  <div className="col-span-3 w-full justify-start text-sm font-normal">
                    {question.text.toString()}
                  </div>
                  <Ballot cursorInfo={toCursorInfo(ballot.answer, CONSTANTS.OPINION_INFO)} dateNs={ballot.date} />
                </div>
              </li>
            );
          }) :
          voteType === VoteType.CATEGORIZATION ? categorizationVotes.map(([question, ballot]) => {
            return (
              <li className="flex w-full text-black dark:text-white border-b dark:border-gray-700 hover:bg-slate-50 hover:dark:bg-slate-850 py-2" key={question.id.toString()}>
                <div className="grid grid-cols-4 py-1 px-6 w-full">
                  <div className="col-span-3 w-full justify-start text-sm font-normal">
                    {question.text.toString()}
                  </div>
                  <Ballot cursorInfo={getStrongestCategoryCursorInfo(toMap(ballot.answer), toMap(sub.categories))} dateNs={ballot.date} />
                </div>
              </li>
            );
          }) : <></>
        }
      </ol>
    </div>
  );
};