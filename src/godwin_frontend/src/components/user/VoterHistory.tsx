import QuestionComponent, { QuestionInput }                                from "../Question";
import { ListComponents }                                                  from "../base/ListComponents";
import { fromScanLimitResult, ScanResults, VoteKind, ScanLimitResult,
  convertScanResults, voteKindFromCandidVariant, voteKindToCandidVariant } from "../../utils";
import CONSTANTS                                                           from "../../Constants";
import { Sub }                                                             from "./../../ActorContext";
import { Direction, QueryVoteItem, }                                       from "../../../declarations/godwin_sub/godwin_sub.did";

import { Principal }                                                       from "@dfinity/principal";
import { fromNullable }                                                    from "@dfinity/utils";
import React, { useState, useEffect }                                      from "react";

type QueryQuestionInputFunction = (direction: Direction, limit: bigint, next: QuestionInput | undefined) => Promise<ScanResults<QuestionInput>>;

type VoterHistoryProps = {
  principal: Principal;
  sub: Sub;
  isLoggedUser: boolean;
  voteKind: VoteKind;
  onOpinionChange?: () => void;
};

export const VoterHistory = ({principal, sub, isLoggedUser, voteKind, onOpinionChange}: VoterHistoryProps) => {

  const [queryQuestionInput, setQueryQuestionInput] = useState<QueryQuestionInputFunction>(() => () => Promise.resolve({ ids : [], next: undefined}));

  const convertVoteScanResults = (scan_results: ScanLimitResult<QueryVoteItem>) : ScanResults<QuestionInput> => {
    return convertScanResults(fromScanLimitResult(scan_results), (item: QueryVoteItem) : QuestionInput => {
      return { 
        sub,
        question_id: item.question_id,
        question: fromNullable(item.question),
        vote: { 
          kind: voteKindFromCandidVariant(item.vote[0]),
          data: item.vote[1]
        }, 
        principal,
        showReopenQuestion: false,
        allowVote: isLoggedUser,
        onOpinionChange
      }});
  }

  const refreshQueryQuestions = () => {
    setQueryQuestionInput(() => (direction: Direction, limit: bigint, next: QuestionInput | undefined) =>
      sub.actor.queryVoterBallots(voteKindToCandidVariant(voteKind), principal, direction, limit, next? [next.question_id] : []).then(convertVoteScanResults));
  }

  useEffect(() => {
    refreshQueryQuestions();
  }, [sub, isLoggedUser, voteKind, principal]);

  return (
    <div className="w-full flex flex-col flex-grow">
    {
      React.createElement(ListComponents<QuestionInput, QuestionInput>, {
        query_components: queryQuestionInput,
        generate_input: (item: QuestionInput) => { return item },
        build_component: QuestionComponent,
        generate_key: (item: QuestionInput) => { return item.question_id.toString() },
        empty_list_message: () => { return CONSTANTS.GENERIC_EMPTY }
      })
    }
    </div>
  );
};