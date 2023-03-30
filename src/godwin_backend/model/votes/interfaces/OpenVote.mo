import Types "../../Types";
import Votes "../Votes";

import SubaccountGenerator "../../token/SubaccountGenerator";

import Map "mo:map/Map";

import Principal "mo:base/Principal";
import Result "mo:base/Result";

module {

  // For convenience: from base module
  type Principal = Principal.Principal;
  type Result<Ok, Err> = Result.Result<Ok, Err>;

  type Map<K, V> = Map.Map<K, V>;

  type Vote<T, A> = Types.Vote<T, A>;
  type SubaccountGenerator = SubaccountGenerator.SubaccountGenerator;
  type OpenVoteError = Types.OpenVoteError;

  public class OpenVote<T, A>(
    _votes: Votes.Votes<T, A>
  ) {

    public func openVote() : Nat {
      _votes.newVote();
    };

  };

  public class OpenVoteWithSubaccount<T, A>(
    _votes: Votes.Votes<T, A>,
    _subaccounts: Map<Nat, Blob>,
    _generator: SubaccountGenerator
  ) {

    public func openVote() : Nat {
      let subaccount = _generator.generateSubaccount();
      let id = _votes.newVote();
      Map.set(_subaccounts, Map.nhash, id, subaccount);
      id;
    };

  };

  public class OpenVotePayin<T, A>(
    _votes: Votes.Votes<T, A>,
    _subaccounts: Map<Nat, Blob>,
    _generator: SubaccountGenerator,
    _payin: (Principal, Blob) -> async* Result<(), ()>
  ) {

    public func openVote(principal: Principal) : async* Result<Nat, OpenVoteError> {
      let subaccount = _generator.generateSubaccount();
      let pay_result = await* _payin(principal, subaccount);
      switch(pay_result){
        case(#err(_)) { #err(#PayinError); };
        case(#ok(_)) {
          let id = _votes.newVote();
          Map.set(_subaccounts, Map.nhash, id, subaccount);
          #ok(id);
        };
      };
    };

  };

};