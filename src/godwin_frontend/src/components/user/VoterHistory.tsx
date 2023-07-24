import QuestionComponent, { QuestionInput }                                from "../Question";
import { ListComponents }                                                  from "../base/ListComponents";
import { fromScanLimitResult, ScanResults, VoteKind, ScanLimitResult,
  convertScanResults, voteKindFromCandidVariant, voteKindToCandidVariant } from "../../utils";
import { Sub }                                                             from "./../../ActorContext";
import { Direction, QueryVoteItem, }                                       from "../../../declarations/godwin_sub/godwin_sub.did";


import { Principal }                                                       from "@dfinity/principal";
import React, { useState, useEffect }                                      from "react";

type VoterHistoryProps = {
  principal: Principal;
  sub: Sub;
  voteKind: VoteKind;
};

type QueryQuestionInputFunction = (direction: Direction, limit: bigint, next: QuestionInput | undefined) => Promise<ScanResults<QuestionInput>>;

export const VoterHistory = ({principal, sub, voteKind }: VoterHistoryProps) => {

  const [queryQuestionInput, setQueryQuestionInput] = useState<QueryQuestionInputFunction>(() => () => Promise.resolve({ ids : [], next: undefined}));

  const convertVoteScanResults = (scan_results: ScanLimitResult<QueryVoteItem>) : ScanResults<QuestionInput> => {
    return convertScanResults(fromScanLimitResult(scan_results), (item: QueryVoteItem) : QuestionInput => {
      return { 
        sub,
        question: item.question,
        vote: { 
          kind: voteKindFromCandidVariant(item.vote[0]),
          data: item.vote[1]
        }, 
        showReopenQuestion: false 
      }});
  }

  const refreshQueryQuestions = () => {
    setQueryQuestionInput(() => (direction: Direction, limit: bigint, next: QuestionInput | undefined) =>
      sub.actor.queryVoterBallots(voteKindToCandidVariant(voteKind), principal, direction, limit, next? [next.question.id] : []).then(convertVoteScanResults));
  }

  useEffect(() => {
    refreshQueryQuestions();
  }, [sub, voteKind, principal]);

  return (
    <div className="w-full flex flex-col">
    {
      React.createElement(ListComponents<QuestionInput, QuestionInput>, {
        query_components: queryQuestionInput,
        generate_input: (item: QuestionInput) => { return item },
        build_component: QuestionComponent,
        generate_key: (item: QuestionInput) => { return item.question.id.toString() }
      })
    }
    </div>
  );
};