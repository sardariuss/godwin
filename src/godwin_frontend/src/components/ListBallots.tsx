import { useEffect, useState } from "react";

import { CursorInfo, ScanResults, VoteKind, voteKindToString, toCursorInfo, fromScanLimitResult, getStrongestCategoryCursorInfo, toMap, interestToCursorInfo, interestToEnum } from "../utils";

import { TransactionsRecord, VoteId, InterestBallot, OpinionBallot, CategorizationBallot, CategoryArray__1 } from "../../declarations/godwin_backend/godwin_backend.did";

import WrappedBallot from "./WrappedBallot";

import { Sub } from "../ActorContext";

import { toNullable, fromNullable } from "@dfinity/utils";

import { Principal } from "@dfinity/principal";

import CONSTANTS from "../Constants";

const interestBallotToBallotInfo = (interest_ballot: [VoteId, [] | [InterestBallot], [] | [TransactionsRecord]]) : BallotInfo => {
  let [vote_id, ballot, tx_rec] = interest_ballot;
  let cursor = ballot[0] !== undefined ? interestToCursorInfo(interestToEnum(ballot[0].answer)) : undefined;
  let date = fromNullable(ballot)?.date;
  let tx_record = fromNullable(tx_rec);
  return { vote_kind: VoteKind.INTEREST, vote_id, cursor, date, tx_record };
};

const opinionBallotToBallotInfo = (opinion_ballot: [VoteId, [] | [OpinionBallot], [] | [TransactionsRecord]]) : BallotInfo => {
  let [vote_id, ballot, tx_rec] = opinion_ballot;
  let cursor = ballot[0] !== undefined ? toCursorInfo(ballot[0].answer, CONSTANTS.OPINION_INFO) : undefined;
  let date = fromNullable(ballot)?.date;
  let tx_record = fromNullable(tx_rec);
  return { vote_kind: VoteKind.OPINION, vote_id, cursor, date, tx_record };
};

const categorizationBallotToBallotInfo = (categories: CategoryArray__1, categorization_ballot: [VoteId, [] | [CategorizationBallot], [] | [TransactionsRecord]]) : BallotInfo => {
  let [vote_id, ballot, tx_rec] = categorization_ballot;
  let cursor = ballot[0] !== undefined ? getStrongestCategoryCursorInfo(toMap(ballot[0].answer), toMap(categories)) : undefined;
  let date = fromNullable(ballot)?.date;
  let tx_record = fromNullable(tx_rec);
  return { vote_kind: VoteKind.CATEGORIZATION, vote_id, cursor, date, tx_record };
};

export type BallotInfo = {
  vote_kind: VoteKind,
  vote_id: bigint,
  cursor: CursorInfo | undefined,
  date: bigint | undefined,
  tx_record: TransactionsRecord | undefined,
};

export type ListBallotsInput = {
  vote_kind: VoteKind,
  sub: Sub,
  principal: Principal,
};

export const ListBallots = ({sub, principal, vote_kind}: ListBallotsInput) => {

  const [results, setResults] = useState<ScanResults<BallotInfo>>({ ids : [], next: undefined});
  const [trigger_next, setTriggerNext] = useState<boolean>(false);

  const direction = { 'BWD' : null };
  const limit = BigInt(10);

  const queryBallots = async (previous: bigint | undefined) : Promise<ScanResults<BallotInfo>> => {
    switch(vote_kind){
      case VoteKind.INTEREST:
        return await queryInterestBallots(previous);
      case VoteKind.OPINION:
        return await queryOpinionBallots(previous);
      case VoteKind.CATEGORIZATION:
        return await queryCategorizationBallots(previous);
      default:
        throw new Error("Invalid vote kind");
    }
  };
  
  const queryInterestBallots = async (previous: bigint | undefined) : Promise<ScanResults<BallotInfo>> => {
    let interest_history = fromScanLimitResult(await sub.actor.revealInterestBallots(principal, direction, limit, toNullable(previous)));
    let interest_ballots : BallotInfo[] = [];
    for (let interest_ballot of interest_history.ids){
      interest_ballots.push(interestBallotToBallotInfo(interest_ballot));
    }
    let next = interest_history.next !== undefined ? interestBallotToBallotInfo(interest_history.next) : undefined;
    return { ids: interest_ballots, next };
  };
  

  const queryOpinionBallots = async (previous: bigint | undefined) : Promise<ScanResults<BallotInfo>> => {
    let opinion_history = fromScanLimitResult(await sub.actor.revealOpinionBallots(principal, direction, limit, toNullable(previous)));
    let opinion_ballots : BallotInfo[] = [];
    for (let opinion_ballot of opinion_history.ids){
      opinion_ballots.push(opinionBallotToBallotInfo(opinion_ballot));
    }
    let next = opinion_history.next !== undefined ? opinionBallotToBallotInfo(opinion_history.next) : undefined;
    return { ids: opinion_ballots, next };
  };
  
  const queryCategorizationBallots = async (previous: bigint | undefined) : Promise<ScanResults<BallotInfo>> => {
    let categorization_history = fromScanLimitResult(await sub.actor.revealCategorizationBallots(principal, direction, limit, toNullable(previous)));
    let categorization_ballots : BallotInfo[] = [];
    for (let categorization_ballot of categorization_history.ids){
      categorization_ballots.push(categorizationBallotToBallotInfo(sub.categories, categorization_ballot));
    }
    let next = categorization_history.next !== undefined ? categorizationBallotToBallotInfo(sub.categories, categorization_history.next) : undefined;
    return { ids: categorization_ballots, next };
  };
	
  const refreshBallots = async () => {
    setResults(await queryBallots(undefined));
  };

  const getNextBallots = async () => {
    if (results.next !== undefined){
      let query_result = await queryBallots(results.next.vote_id);
      setResults({ 
        ids: [...new Set([...results.ids, ...Array.from(query_result.ids)])],
        next: query_result.next 
      });
    }
  };

  const atEnd = () => {
    var c = [document.scrollingElement.scrollHeight, document.body.scrollHeight, document.body.offsetHeight].sort(function(a,b){return b-a}) // select longest candidate for scrollable length
    return (window.innerHeight + window.scrollY + 2 >= c[0]) // compare with scroll position + some give
  }

  const scrolling = () => {
    if (atEnd()) {
      setTriggerNext(true);
    }
  }

  useEffect(() => {
    refreshBallots();
    window.addEventListener('scroll', scrolling, {passive: true});
    return () => {
      window.removeEventListener('scroll', scrolling);
    };
  }, [vote_kind]);

  useEffect(() => {
    if (trigger_next){
      setTriggerNext(false);
      getNextBallots();
    };
  }, [trigger_next]);

	return (
    <ol className="w-full">
      {[...results.ids].map(ballot_info => (
        <li key={voteKindToString(ballot_info.vote_kind) + ballot_info.vote_id.toString()}>
          <WrappedBallot sub={sub} ballot_info={ballot_info} />
        </li>
      ))}
    </ol>
	);
};

export default ListBallots;
