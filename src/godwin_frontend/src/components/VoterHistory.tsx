import { useEffect, useState } from "react";
import { Sub } from "./../ActorContext";

import { Principal } from "@dfinity/principal";

import { ScanResults, fromScanLimitResult, CursorInfo, toCursorInfo, nsToStrDate, timeAgo } from "../utils";
import { OpinionBallot, Question } from "../../declarations/godwin_backend/godwin_backend.did";

import Ballot from "./votes/Ballot";

import CONSTANTS from "../Constants";

type VoterHistoryProps = {
  principal: Principal;
  sub: Sub;
};

export const VoterHistory = ({principal, sub}: VoterHistoryProps) => {

  const [allVotes, setAllVotes] = useState<[Question, OpinionBallot][]>([]);
  const [opinionScanResults, setOpinionScanResults] = useState<ScanResults<[bigint, OpinionBallot]> | undefined>(undefined);

  const fetchOpinionHistory = async () => {
    let opinion_history = await sub.actor.getVoterOpinionHistory(principal, BigInt(10), []);
    setOpinionScanResults(fromScanLimitResult(opinion_history));

    let all_votes : [Question, OpinionBallot][] = [];
    for (let [vote_id, ballot] of opinion_history.keys){
      let question = await sub.actor.getQuestion(vote_id);
      if (question['ok'] !== undefined){
        all_votes.push([question['ok'], ballot]);
      }
    }
    setAllVotes(all_votes);
  };

  useEffect(() => {
    fetchOpinionHistory();
  }, []);

  return (
    <ol>
      {
        allVotes.map(([question, ballot]) => {
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
        })
      }
    </ol>
  );
};