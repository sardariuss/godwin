import Types "../../Types";
import Votes2 "../Votes2";
import WMap "../../../utils/wrappers/WMap";

import SubaccountGenerator "../../token/SubaccountGenerator";

import Map "mo:map/Map";
import Utils "../../../utils/Utils";

import Principal "mo:base/Principal";
import Option "mo:base/Option";
import Debug "mo:base/Debug";
import Prelude "mo:base/Prelude";
import Iter "mo:base/Iter";
import Int "mo:base/Int";
import Nat32 "mo:base/Nat32";
import Result "mo:base/Result";
import Buffer "mo:base/Buffer";

module {

  // For convenience: from base module
  type Principal = Principal.Principal;
  type Time = Int;
  type Iter<T> = Iter.Iter<T>;
  type VoteId = Types.VoteId;
  type Result<Ok, Err> = Result.Result<Ok, Err>;
  type Buffer<T> = Buffer.Buffer<T>;

  type Map<K, V> = Map.Map<K, V>;

  type Ballot<T> = Types.Ballot<T>;
  type Vote<T, A> = Types.Vote<T, A>;
  type PublicVote<T, A> = Types.PublicVote<T, A>;
  type GetBallotError = Types.GetBallotError;
  type PutBallotError = Types.PutBallotError;
  type GetVoteError = Types.GetVoteError;
  type UpdateBallotAuthorization = Types.UpdateBallotAuthorization;
  type SubaccountGenerator = SubaccountGenerator.SubaccountGenerator;

  // For convenience
  type WMap<K, V> = WMap.WMap<K, V>;


  type Callback<A> = (Nat, ?A, ?A) -> ();

  type SubaccountsStruct = {
    subaccounts: Map<Nat, Blob>;
    generator: SubaccountGenerator;
  };

  public class OpenVote<T, A>(
    votes_: Votes2.Votes2<T, A>
  ) {

    public func openVote() : Nat {
      votes_.newVote();
    };

  };

  public class OpenVoteWithSubaccount<T, A>(
    votes_: Votes2.Votes2<T, A>,
    subaccounts_: Map<Nat, Blob>,
    generator_: SubaccountGenerator
  ) {

    public func openVote() : Nat {
      let subaccount = generator_.generateSubaccount();
      let id = votes_.newVote();
      Map.set(subaccounts_, Map.nhash, id, subaccount);
      id;
    };

  };

  public class OpenVotePayin<T, A>(
    votes_: Votes2.Votes2<T, A>,
    subaccounts_: Map<Nat, Blob>,
    generator_: SubaccountGenerator,
    payin_: (Principal, Blob) -> async Result<(), ()>
  ) {

    public func openVote(principal: Principal) : async Result<Nat, ()> {
      let subaccount = generator_.generateSubaccount();
      let pay_result = await payin_(principal, subaccount);
      Result.mapOk<(), Nat, ()>(pay_result, func() : Nat {
        let id = votes_.newVote();
        Map.set(subaccounts_, Map.nhash, id, subaccount);
        id;
      });
    };

  };

};