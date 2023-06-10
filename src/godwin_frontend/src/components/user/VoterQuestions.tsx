import ListComponents                                           from "../base/ListComponents";
import TransactionsRecordComponent, { TransactionsRecordInput } from "../token/TransactionsRecord";
import { Sub }                                                  from "../../ActorContext";
import { ScanResults, fromScanLimitResult }                     from "../../utils";
import { Question, TransactionsRecord, Direction }              from "../../../declarations/godwin_backend/godwin_backend.did";

import { Principal }                                            from "@dfinity/principal";
import { fromNullable }                                         from "@dfinity/utils";
import React                                                    from "react";

type VoterQuestionsProps = {
  principal: Principal;
  sub: Sub;
};

type QueryResult = [bigint, [] | [Question], [] | [TransactionsRecord]];

export const VoterQuestions = ({principal, sub}: VoterQuestionsProps) => {

  const query_questions = (direction: Direction, limit: bigint, next: QueryResult | undefined) : Promise<ScanResults<QueryResult>> => {
    console.log("query_questions");
    return sub.actor.queryQuestionsFromAuthor(principal, direction, limit, next === undefined ? [] : [next[0]]).then(
      fromScanLimitResult
    );
  };

  return (
    <>
    {
      React.createElement(ListComponents<QueryResult, TransactionsRecordInput>, {
        query_components: query_questions,
        generate_input: (result: QueryResult) => { return { tx_record : fromNullable(result[2]) } },
        build_component: TransactionsRecordComponent,
        generate_key: (result: QueryResult) => { return result[0].toString() }
      })
    }
    </>
  )

};