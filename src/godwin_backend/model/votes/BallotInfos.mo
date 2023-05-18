import Types               "Types";

import Map                 "mo:map/Map";

import Principal           "mo:base/Principal";
import Option              "mo:base/Option";
import Debug               "mo:base/Debug";
import Nat                 "mo:base/Nat";

module {

  // For convenience: from base module
  type Principal              = Principal.Principal;

  type Map<K, V>              = Map.Map<K, V>;

  type VoteId                 = Types.VoteId;
  type BallotTransactions     = Types.BallotTransactions;

  public class BallotInfos(
    _register: Map<Principal, Map<VoteId, BallotTransactions>>,
  ) {

    public func getBallotInfos(principal: Principal) : Map<VoteId, BallotTransactions> {
      Option.get(Map.get(_register, Map.phash, principal), Map.new<VoteId, BallotTransactions>(Map.nhash));
    };

    public func setBallotTransactions(principal: Principal, vote_id: VoteId, transactions: BallotTransactions) {
      let voter_register = getBallotInfos(principal);
      Map.set(voter_register, Map.nhash, vote_id, transactions);
      Map.set(_register, Map.phash, principal, voter_register);
    };

    public func getBallotTransactions(principal: Principal, vote_id: VoteId) : BallotTransactions {
      let user_infos = switch(Map.get(_register, Map.phash, principal)){
        case(null) { Debug.trap("Cannot find ballot info for this principal: '" # Principal.toText(principal) # "'"); };
        case(?infos) { infos; };
      };
      switch(Map.get(user_infos, Map.nhash, vote_id)){
        case(null) { Debug.trap("Cannot find ballot transactions this principal: '" # Principal.toText(principal) # "' and vote ID : '" # Nat.toText(vote_id) # "'"); };
        case(?transactions) { transactions; };
      };
    };

  };

};