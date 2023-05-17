import { Sub } from "./../ActorContext";

import { Principal } from "@dfinity/principal";

import { ScanResults, fromScanLimitResult } from "../utils";

import ListQuestions from "./ListQuestions";

type VoterQuestionsProps = {
  principal: Principal;
  sub: Sub;
};

export const VoterQuestions = ({principal, sub}: VoterQuestionsProps) => {

  const query_questions = (next: bigint | undefined) : Promise<ScanResults<bigint>> => {
    return sub.actor.getQuestionIdsFromAuthor(principal, { 'BWD' : null }, BigInt(10), next? [next] : []).then(
      fromScanLimitResult
    );
  };

  return (
    <ListQuestions sub={sub}  query_questions={query_questions}/>
  );

};