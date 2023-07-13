import { ListComponents }                                                                         from "../base/ListComponents";
import InterestDetailedBallot, { InterestDetailedBallotInput }                                    from "../interest/InterestDetailedBallot";
import OpinionDetailedBallot, { OpinionDetailedBallotInput }                                      from "../opinion/OpinionDetailedBallot";
import CategorizationDetailedBallot, { CategorizationDetailedBallotInput }                        from "../categorization/CategorizationDetailedBallot";
import { fromScanLimitResult, ScanResults, VoteKind, voteKindToString }                           from "../../utils";
import { Sub }                                                                                    from "./../../ActorContext";
import { RevealedInterestBallot, RevealedOpinionBallot, RevealedCategorizationBallot, Direction } from "../../../declarations/godwin_sub/godwin_sub.did";

import { Principal }                                                                              from "@dfinity/principal";
import { useState } from "react";

type QueryFunction<T> = (direction: Direction, limit: bigint, next: T | undefined) => Promise<ScanResults<T>>;

type VoterHistoryProps = {
  principal: Principal;
  sub: Sub;
  voteKind: VoteKind;
};

export const VoterHistory = ({principal, sub, voteKind, }: VoterHistoryProps) => {

  const queryInterestBallots = (direction: Direction, limit: bigint, next: RevealedInterestBallot | undefined) : Promise<ScanResults<RevealedInterestBallot>> => {
    return sub.actor.queryInterestBallots(principal, direction, limit, next? [next.vote_id] : []).then(
      fromScanLimitResult
    )
  };

  const queryOpinionBallots = (direction: Direction, limit: bigint, next: RevealedOpinionBallot | undefined) : Promise<ScanResults<RevealedOpinionBallot>> => {
    return sub.actor.queryOpinionBallots(principal, direction, limit, next? [next.vote_id] : []).then(
      fromScanLimitResult
    )
  };

  const queryCategorizationBallots = (direction: Direction, limit: bigint, next: RevealedCategorizationBallot | undefined) : Promise<ScanResults<RevealedCategorizationBallot>> => {
    return sub.actor.queryCategorizationBallots(principal, direction, limit, next? [next.vote_id] : []).then(
      fromScanLimitResult
    )
  };

  // Workaround: Put the functions into state to avoid unwanted refreshes
  const [queryInterestBallotsState] = useState<QueryFunction<RevealedInterestBallot>>(() => queryInterestBallots);
  const [queryOpinionBallotsState] = useState<QueryFunction<RevealedOpinionBallot>>(() => queryOpinionBallots);
  const [queryCategorizationBallotsState] = useState<QueryFunction<RevealedCategorizationBallot>>(() => queryCategorizationBallots);

  // Workaround: put each list into a div to avoid crash when switching voteKind
  return (
    <div className="w-full flex flex-col">
      <div>
      {
        voteKind === VoteKind.INTEREST ?
          <ListComponents<RevealedInterestBallot, InterestDetailedBallotInput>
            query_components={queryInterestBallotsState}
            generate_input={(ballot: RevealedInterestBallot) : InterestDetailedBallotInput => { return { ballot, sub} }}
            build_component={InterestDetailedBallot}
            generate_key={(ballot: RevealedInterestBallot) => { return voteKindToString(voteKind) + "_" + ballot.vote_id.toString() }}
          /> : <></>
      }
      </div>
      <div className="w-full flex">
      {
        voteKind === VoteKind.OPINION ?
          <ListComponents<RevealedOpinionBallot, OpinionDetailedBallotInput> 
            query_components={queryOpinionBallotsState} 
            generate_input={(ballot: RevealedOpinionBallot) : OpinionDetailedBallotInput => { return { ballot, sub} }}
            build_component={OpinionDetailedBallot}
            generate_key={(ballot: RevealedOpinionBallot) => { return voteKindToString(voteKind) + "_" + ballot.vote_id.toString() }}
          /> : <></>
      }
      </div>
      <div>
      {
        voteKind === VoteKind.CATEGORIZATION ?
          <ListComponents<RevealedCategorizationBallot, CategorizationDetailedBallotInput>
            query_components={queryCategorizationBallotsState}
            generate_input={(ballot: RevealedCategorizationBallot) : CategorizationDetailedBallotInput => { return { ballot, sub} }}
            build_component={CategorizationDetailedBallot}
            generate_key={(ballot: RevealedCategorizationBallot) => { return voteKindToString(voteKind) + "_" + ballot.vote_id.toString() }}
          /> : <></>
      }
      </div>
    </div>
  );
};