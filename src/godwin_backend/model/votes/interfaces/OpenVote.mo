import Types "../../Types";
import Votes "../Votes";

import SubaccountGenerator "../../token/SubaccountGenerator";

import WRef "../../../utils/wrappers/WRef";
import Ref "../../../utils/Ref";

import Map "mo:map/Map";

import Principal "mo:base/Principal";
import Result "mo:base/Result";

module {

  // For convenience: from base module
  type Principal = Principal.Principal;
  type Result<Ok, Err> = Result.Result<Ok, Err>;

  type Map<K, V> = Map.Map<K, V>;
  
  type Ref<T> = Ref.Ref<T>;
  type WRef<T> = WRef.WRef<T>;

  type SubaccountType = SubaccountGenerator.SubaccountType;

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

  // @todo: should be a singleton
  public class OpenPayableVote<T, A>(
    _votes: Votes.Votes<T, A>,
    _subaccounts: Map<Nat, Blob>,
    _subaccount_index: WRef<Nat>,
    _payin: (Principal, Blob) -> async* Result<(), Text>
  ) {

    public func openVote(principal: Principal) : async* Result<Nat, OpenVoteError> {
      let subaccount = SubaccountGenerator.getSubaccount(#OPEN_VOTE, getNextSubaccountId());
      let pay_result = await* _payin(principal, subaccount);
      switch(pay_result){
        case(#err(err)) { #err(#PayinError(err)); };
        case(#ok(_)) {
          let id = _votes.newVote();
          Map.set(_subaccounts, Map.nhash, id, subaccount);
          #ok(id);
        };
      };
    };

    func getNextSubaccountId() : Nat {
      let id = _subaccount_index.get();
      _subaccount_index.set(id + 1);
      id;
    };

  };

};