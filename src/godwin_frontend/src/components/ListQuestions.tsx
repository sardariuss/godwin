
import QuestionComponent, { QuestionInput } from "./Question";
import ListComponents                       from "./base/ListComponents";
import { ScanResults, toMap, VoteKind }     from "../utils";
import { UserAction } from "./MainQuestions";
import { Sub }                              from "../ActorContext";
import { Direction, QueryQuestionItem }     from "../../declarations/godwin_sub/godwin_sub.did";

import React                                from "react";

export type ListQuestionsInput = {
  sub: Sub,
  query_questions: (direction: Direction, limit: bigint, next: QueryQuestionItem | undefined) => Promise<ScanResults<QueryQuestionItem>>,
  user_action: UserAction | undefined
}

const ListQuestions = ({sub, query_questions, user_action}: ListQuestionsInput) => {

  return (
    <>
    {
      React.createElement(ListComponents<QueryQuestionItem, QuestionInput>, {
        query_components: query_questions,
        generate_input: (queried_question: QueryQuestionItem) => { return { sub, queried_question, user_action } },
        build_component: QuestionComponent,
        generate_key: (item: QueryQuestionItem) => { return item.question.id.toString() }
      })
    }
    </>
  )
}

export default ListQuestions;