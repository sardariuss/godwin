
import QuestionComponent, { QuestionInput } from "./Question";
import ListComponents                       from "./base/ListComponents";
import { ScanResults, toMap, VoteKind }     from "../utils";
import { Sub }                              from "../ActorContext";
import { Direction }                        from "../../declarations/godwin_sub/godwin_sub.did";

import React                                from "react";

export type ListQuestionsInput = {
  sub: Sub,
  query_questions: (direction: Direction, limit: bigint, next: bigint | undefined) => Promise<ScanResults<bigint>>,
  vote_kind: VoteKind | undefined
}

const ListQuestions = ({sub, query_questions, vote_kind}: ListQuestionsInput) => {

  return (
    <>
    {
      React.createElement(ListComponents<bigint, QuestionInput>, {
        query_components: query_questions,
        generate_input: (id: bigint) => { return { sub: sub, questionId: id, vote_kind } },
        build_component: QuestionComponent,
        generate_key: (id: bigint) => { return id.toString() }
      })
    }
    </>
  )
}

export default ListQuestions;