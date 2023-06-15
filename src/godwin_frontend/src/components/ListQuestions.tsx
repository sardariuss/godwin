
import QuestionComponent, { QuestionInput } from "./Question";
import ListComponents                       from "./base/ListComponents";
import { ScanResults, toMap, StatusEnum }   from "../utils";
import { Sub }                              from "../ActorContext";
import { Direction }                        from "../../declarations/godwin_backend/godwin_backend.did";

import React                                from "react";

export type ListQuestionsInput = {
  sub: Sub,
  preferredStatus: StatusEnum | undefined,
  query_questions: (direction: Direction, limit: bigint, next: bigint | undefined) => Promise<ScanResults<bigint>>,
}

const ListQuestions = ({sub, preferredStatus, query_questions}: ListQuestionsInput) => {

  return (
    <>
    {
      React.createElement(ListComponents<bigint, QuestionInput>, {
        query_components: query_questions,
        generate_input: (id: bigint) => { return { actor: sub.actor, categories: toMap(sub.categories), preferredStatus: preferredStatus, questionId: id } },
        build_component: QuestionComponent,
        generate_key: (id: bigint) => { return id.toString() }
      })
    }
    </>
  )
}

export default ListQuestions;