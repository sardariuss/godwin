import OpenedVote, { OpenedVoteInput } from "./OpenedVote";
import ListComponents                          from "../base/ListComponents";
import { Sub }                                 from "../../ActorContext";
import { ScanResults, fromScanLimitResult }    from "../../utils";
import { Direction, QueryOpenedVoteItem }      from "../../../declarations/godwin_sub/godwin_sub.did";

import { Principal }                           from "@dfinity/principal";
import { toNullable }                          from "@dfinity/utils";
import React                                   from "react";

type OpenedVotesProps = {
  principal: Principal;
  sub: Sub;
};

export const OpenedVotes = ({principal, sub}: OpenedVotesProps) => {

  const query_opened_votes = (direction: Direction, limit: bigint, next: QueryOpenedVoteItem | undefined) : Promise<ScanResults<QueryOpenedVoteItem>> => {
    return sub.actor.queryOpenedVotes(principal, direction, limit, next === undefined ? [] : toNullable(next.vote_id)).then( 
      fromScanLimitResult
    );
  };

  return (
    <>
    {
      React.createElement(ListComponents<QueryOpenedVoteItem, OpenedVoteInput>, {
        query_components: query_opened_votes,
        generate_input: (opened_vote: QueryOpenedVoteItem) => { return { opened_vote, sub, principal  } },
        build_component: OpenedVote,
        generate_key: (result: QueryOpenedVoteItem) => { return result.vote_id.toString(); },
      })
    }
    </>
  )

};