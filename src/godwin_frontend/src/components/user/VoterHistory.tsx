import { ListComponents }                                                            from "../base/ListComponents";
import UserQuestionInterestBallots, { UserQuestionInterestBallotsInput }             from "../interest/UserQuestionInterestBallots";
import UserQuestionOpinionBallots, { UserQuestionOpinionBallotsInput }               from "../opinion/UserQuestionOpinionBallots";
import UserQuestionCategorizationBallots, { UserQuestionCategorizationBallotsInput } from "../categorization/UserQuestionCategorizationBallots";
import { fromScanLimitResult, ScanResults, VoteKind, voteKindToString }              from "../../utils";
import { Sub }                                                                       from "./../../ActorContext";
import { 
  UserQuestionInterestBallots as UserQuestionInterestBallotsDid,
  UserQuestionOpinionBallots as  UserQuestionOpinionBallotsDid,
  UserQuestionCategorizationBallots as UserQuestionCategorizationBallotsDid,
  Direction }                                                                        from "../../../declarations/godwin_sub/godwin_sub.did";

import { Principal }                                                                 from "@dfinity/principal";
import { useState }                                                                  from "react";

type QueryFunction<T> = (direction: Direction, limit: bigint, next: T | undefined) => Promise<ScanResults<T>>;

type VoterHistoryProps = {
  principal: Principal;
  sub: Sub;
  voteKind: VoteKind;
};

export const VoterHistory = ({principal, sub, voteKind, }: VoterHistoryProps) => {

  const queryInterestBallots = (direction: Direction, limit: bigint, next: UserQuestionInterestBallotsDid | undefined) : Promise<ScanResults<UserQuestionInterestBallotsDid>> => {
    return sub.actor.queryInterestBallots(principal, direction, limit, next? [next.question_id] : []).then(
      fromScanLimitResult
    )
  };

  const queryOpinionBallots = (direction: Direction, limit: bigint, next: UserQuestionOpinionBallotsDid | undefined) : Promise<ScanResults<UserQuestionOpinionBallotsDid>> => {
    return sub.actor.queryOpinionBallots(principal, direction, limit, next? [next.question_id] : []).then(
      fromScanLimitResult
    )
  };

  const queryCategorizationBallots = (direction: Direction, limit: bigint, next: UserQuestionCategorizationBallotsDid | undefined) : Promise<ScanResults<UserQuestionCategorizationBallotsDid>> => {
    return sub.actor.queryCategorizationBallots(principal, direction, limit, next? [next.question_id] : []).then(
      fromScanLimitResult
    )
  };

  // Workaround: Put the functions into state to avoid unwanted refreshes
  const [queryInterestBallotsState] = useState<QueryFunction<UserQuestionInterestBallots>>(() => queryInterestBallots);
  const [queryOpinionBallotsState] = useState<QueryFunction<UserQuestionOpinionBallots>>(() => queryOpinionBallots);
  const [queryCategorizationBallotsState] = useState<QueryFunction<UserQuestionCategorizationBallots>>(() => queryCategorizationBallots);

  // Workaround: put each list into a div to crash when switching voteKind
  return (
    <div className="w-full flex flex-col">
      <div>
      {
        voteKind === VoteKind.INTEREST ?
          <ListComponents<UserQuestionInterestBallots, UserQuestionInterestBallotsInput>
            query_components={queryInterestBallotsState}
            generate_input={(question_ballots: UserQuestionInterestBallots) : UserQuestionInterestBallotsInput => { return { question_ballots } }}
            build_component={UserQuestionInterestBallots}
            generate_key={(question_ballots: UserQuestionInterestBallots) => { return voteKindToString(voteKind) + "_" + question_ballots.question_id.toString() }}
          /> : <></>
      }
      </div>
      <div className="w-full flex">
      {
        voteKind === VoteKind.OPINION ?
          <ListComponents<UserQuestionOpinionBallots, UserQuestionOpinionBallotsInput> 
            query_components={queryOpinionBallotsState} 
            generate_input={(question_ballots: UserQuestionOpinionBallots) : UserQuestionOpinionBallotsInput => { return { question_ballots} }}
            build_component={UserQuestionOpinionBallots}
            generate_key={(question_ballots: UserQuestionOpinionBallots) => { return voteKindToString(voteKind) + "_" + question_ballots.question_id.toString() }}
          /> : <></>
      }
      </div>
      <div>
      {
        voteKind === VoteKind.CATEGORIZATION ?
          <ListComponents<UserQuestionCategorizationBallots, UserQuestionCategorizationBallotsInput>
            query_components={queryCategorizationBallotsState}
            generate_input={(question_ballots: UserQuestionCategorizationBallots) : UserQuestionCategorizationBallotsInput => { return { sub, question_ballots } }}
            build_component={UserQuestionCategorizationBallots}
            generate_key={(question_ballots: UserQuestionCategorizationBallots) => { return voteKindToString(voteKind) + "_" + question_ballots.question_id.toString() }}
          /> : <></>
      }
      </div>
    </div>
  );
};