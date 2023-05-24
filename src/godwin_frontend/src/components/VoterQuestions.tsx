import { Sub } from "./../ActorContext";

import { Principal } from "@dfinity/principal";

import { ScanResults, fromScanLimitResult } from "../utils";

import { toNullable } from "@dfinity/utils";

import ListQuestions from "./ListQuestions";

import { Question, TransactionsRecord } from "../../declarations/godwin_backend/godwin_backend.did";

type VoterQuestionsProps = {
  principal: Principal;
  sub: Sub;
};

export const VoterQuestions = ({principal, sub}: VoterQuestionsProps) => {

  const query_questions = (next: bigint | undefined) : Promise<ScanResults<[bigint, [] | [Question], [] | [TransactionsRecord]]>> => {
    return sub.actor.getQuestionsFromAuthor(principal, { 'BWD' : null }, BigInt(10), toNullable(next)).then(
      fromScanLimitResult
    );
  };

  return (
    <ListQuestions sub={sub} query_questions={query_questions}/>
  );

};