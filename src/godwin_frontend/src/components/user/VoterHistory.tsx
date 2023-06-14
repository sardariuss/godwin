import { ListComponents }                                                                         from "../base/ListComponents";
import { TabButton }                                                                              from "../TabButton";
import InterestDetailedBallot, { InterestDetailedBallotInput }                                    from "../interest/InterestDetailedBallot";
import OpinionDetailedBallot, { OpinionDetailedBallotInput }                                      from "../opinion/OpinionDetailedBallot";
import CategorizationDetailedBallot, { CategorizationDetailedBallotInput }                        from "../categorization/CategorizationDetailedBallot";
import { fromScanLimitResult, ScanResults, VoteKind, VoteKinds, voteKindToString }                from "../../utils";
import { Sub }                                                                                    from "./../../ActorContext";
import { RevealedInterestBallot, RevealedOpinionBallot, RevealedCategorizationBallot, Direction } from "../../../declarations/godwin_backend/godwin_backend.did";

import { Principal }                                                                              from "@dfinity/principal";
import React, { useState }                                                                        from "react";

type VoterHistoryProps = {
  principal: Principal;
  sub: Sub;
};

export const VoterHistory = ({principal, sub}: VoterHistoryProps) => {

  const [voteKind, setVoteKind] = useState<VoteKind>(VoteKind.INTEREST);

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

  return (
    <div className="flex flex-col w-full">
      <div className="border-b dark:border-gray-700">
        <ul className="flex flex-wrap text-sm dark:text-gray-400 font-medium text-center">
        {
          VoteKinds.map((type, index) => (
            <li key={index} className="w-1/3">
              <TabButton label={voteKindToString(type)} isCurrent={type === voteKind} setIsCurrent={() => setVoteKind(type)}/>
            </li>
          ))
        }
        </ul>
      </div>
      <div>
      {
        voteKind === VoteKind.INTEREST ?
          React.createElement(ListComponents<RevealedInterestBallot, InterestDetailedBallotInput>, {
            query_components: queryInterestBallots,
            generate_input: (ballot: RevealedInterestBallot) : InterestDetailedBallotInput => { return { ballot, sub} },
            build_component: InterestDetailedBallot,
            generate_key: (ballot: RevealedInterestBallot) => { return voteKindToString(voteKind) + "_" + ballot.vote_id.toString() }
          }) : <></>
      }
      </div>
      <div>
      {
        voteKind === VoteKind.OPINION ?
          React.createElement(ListComponents<RevealedOpinionBallot, OpinionDetailedBallotInput>, {
            query_components: queryOpinionBallots,
            generate_input: (ballot: RevealedOpinionBallot) : OpinionDetailedBallotInput => { return { ballot, sub} },
            build_component: OpinionDetailedBallot,
            generate_key: (ballot: RevealedOpinionBallot) => { return voteKindToString(voteKind) + "_" + ballot.vote_id.toString() }
          }) : <></>
        }
      </div>
      <div>
      {
        voteKind === VoteKind.CATEGORIZATION ?
          React.createElement(ListComponents<RevealedCategorizationBallot, CategorizationDetailedBallotInput>, {
            query_components: queryCategorizationBallots,
            generate_input: (ballot: RevealedCategorizationBallot) : CategorizationDetailedBallotInput => { return { ballot, sub} },
            build_component: CategorizationDetailedBallot,
            generate_key: (ballot: RevealedCategorizationBallot) => { return voteKindToString(voteKind) + "_" + ballot.vote_id.toString() }
          }) : <></>
        }
      </div>
    </div>
  );
};