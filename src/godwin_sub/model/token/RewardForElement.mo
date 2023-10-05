import Types               "Types";

import Map                 "mo:map/Map";

import Principal           "mo:base/Principal";
import Debug               "mo:base/Debug";
import Nat                 "mo:base/Nat";

module {

  // For convenience: from base module
  type Principal                = Principal.Principal;

  type Map<K, V>                = Map.Map<K, V>;
  
  type ITokenInterface          = Types.ITokenInterface;
  type Balance                  = Types.Balance;
  type MintResult               = Types.MintResult;

  type Id                       = Nat;

  // \note: Use the ITokenInterface to not link with the actual TokenInterface which uses
  // the canister:godwin_token. This is required to be able to build the tests.
  public class RewardForElement(
    _beneficiary: Principal,
    _mint_register: Map<Id, MintResult>,
    _token_interface: ITokenInterface
  ) {

    public func reward(id: Id, token_amount_e9s: Balance) : async* () {
      if (Map.has(_mint_register, Map.nhash, id)){
        Debug.trap("The element " # Nat.toText(id) # " has already been rewarded.");
      };
      let result = await _token_interface.mint(_beneficiary, token_amount_e9s);
      Map.set(_mint_register, Map.nhash, id, result);
    };

  };
};