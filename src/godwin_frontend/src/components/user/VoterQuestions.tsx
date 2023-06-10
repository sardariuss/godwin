import { Sub }                              from "../../ActorContext";
import ListQuestions                        from "../ListQuestions";
import { ScanResults, fromScanLimitResult } from "../../utils";
import { Question, TransactionsRecord }     from "../../../declarations/godwin_backend/godwin_backend.did";

import { Principal }                        from "@dfinity/principal";
import { toNullable }                       from "@dfinity/utils";

type VoterQuestionsProps = {
  principal: Principal;
  sub: Sub;
};

export const VoterQuestions = ({principal, sub}: VoterQuestionsProps) => {

  const query_questions = (next: bigint | undefined) : Promise<ScanResults<[bigint, [] | [Question], [] | [TransactionsRecord]]>> => {
    return sub.actor.queryQuestionsFromAuthor(principal, { 'BWD' : null }, BigInt(10), toNullable(next)).then(
      fromScanLimitResult
    );
  };

  return (
    <ListQuestions sub={sub} query_questions={query_questions}/>
  );

};