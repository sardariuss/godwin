import { ListComponents }                                                                         from "../base/ListComponents";
import { TabButton }                                                                              from "../TabButton";
import InterestBallot, { InterestBallotInput }                                                    from "../interest/InterestBallot";
import { interestToEnum }                                                                         from "../interest/InterestTypes";
import CursorBallot, { CursorBallotProps }                                                        from "../base/CursorBallot";
import CONSTANTS                                                                                  from "../../Constants";
import { toMap, getStrongestCategoryCursorInfo, fromScanLimitResult, ScanResults,
  VoteKind, VoteKinds, voteKindToString, toCursorInfo }                                           from "../../utils";
import { Sub }                                                                                    from "./../../ActorContext";
import { RevealedInterestBallot, RevealedOpinionBallot, RevealedCategorizationBallot, Direction } from "../../../declarations/godwin_backend/godwin_backend.did";

import { fromNullable }                                                                           from "@dfinity/utils";
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
          React.createElement(ListComponents<RevealedInterestBallot, InterestBallotInput>, {
            query_components: queryInterestBallots,
            generate_input: (ballot: RevealedInterestBallot) : InterestBallotInput => { return { 
              answer: fromNullable(ballot.answer) !== undefined ? interestToEnum(fromNullable(ballot.answer)) : null,
              dateNs: ballot.date,
              tx_record: fromNullable(ballot.transactions_record),
            } },
            build_component: InterestBallot,
            generate_key: (ballot: RevealedInterestBallot) => { return voteKindToString(voteKind) + "_" + ballot.vote_id.toString() }
          }) : <></>
      }
      </div>
      <div>
      {
        voteKind === VoteKind.OPINION ?
          React.createElement(ListComponents<RevealedOpinionBallot, CursorBallotProps>, {
            query_components: queryOpinionBallots,
            generate_input: (ballot: RevealedOpinionBallot) : CursorBallotProps => { return { 
              cursorInfo: fromNullable(ballot.answer) !== undefined ? toCursorInfo(fromNullable(ballot.answer), CONSTANTS.OPINION_INFO) : null,
              dateNs: ballot.date
            } },
            build_component: CursorBallot,
            generate_key: (ballot: RevealedOpinionBallot) => { return voteKindToString(voteKind) + "_" + ballot.vote_id.toString() }
          }) : <></>
        }
      </div>
      <div>
      {
        voteKind === VoteKind.CATEGORIZATION ?
          React.createElement(ListComponents<RevealedCategorizationBallot, CursorBallotProps>, {
            query_components: queryCategorizationBallots,
            generate_input: (ballot: RevealedCategorizationBallot) : CursorBallotProps => { return { 
              cursorInfo: fromNullable(ballot.answer) !== undefined ? getStrongestCategoryCursorInfo(toMap(fromNullable(ballot.answer)), toMap(sub.categories)) : null,
              dateNs: ballot.date,
              tx_record: fromNullable(ballot.transactions_record),
            } },
            build_component: CursorBallot,
            generate_key: (ballot: RevealedCategorizationBallot) => { return voteKindToString(voteKind) + "_" + ballot.vote_id.toString() }
          }) : <></>
        }
      </div>
    </div>
  );
};