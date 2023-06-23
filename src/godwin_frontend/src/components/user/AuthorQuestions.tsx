import AuthorQuestion, { AuthorQuestionInput }                  from "./AuthorQuestion";
import ListComponents                                           from "../base/ListComponents";
import { Sub }                                                  from "../../ActorContext";
import { ScanResults, fromScanLimitResult }                     from "../../utils";
import { Question, TransactionsRecord, Direction }              from "../../../declarations/godwin_sub/godwin_sub.did";

import { Principal }                                            from "@dfinity/principal";
import { fromNullable }                                         from "@dfinity/utils";
import React                                                    from "react";

type AuthorQuestionsProps = {
  principal: Principal;
  sub: Sub;
};

type QueryResult = [bigint, [] | [Question], [] | [TransactionsRecord]];

export const AuthorQuestions = ({principal, sub}: AuthorQuestionsProps) => {

  const query_questions = (direction: Direction, limit: bigint, next: QueryResult | undefined) : Promise<ScanResults<QueryResult>> => {
    return sub.actor.queryQuestionsFromAuthor(principal, direction, limit, next === undefined ? [] : [next[0]]).then(
      fromScanLimitResult
    );
  };

  return (
    <>
    {
      React.createElement(ListComponents<QueryResult, AuthorQuestionInput>, {
        query_components: query_questions,
        generate_input: (result: QueryResult) => { return { question: fromNullable(result[1]), tx_record : fromNullable(result[2]) } },
        build_component: AuthorQuestion,
        generate_key: (result: QueryResult) => { return result[0].toString() }
      })
    }
    </>
  )

};