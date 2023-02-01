import Godwin "../godwin_backend/main";
import Types "../godwin_backend/model/Types";

import Map "mo:map/Map";

import Result "mo:base/Result";
import Principal "mo:base/Principal";
import Buffer "mo:base/Buffer";

shared({ caller }) actor class Master() {

  type Parameters = Types.Parameters;
  type Result<Ok, Err> = Result.Result<Ok, Err>;

  let admin_ = caller;

  let black_hole_ = Principal.fromText("e3mmv-5qaaa-aaaah-aadma-cai");

  let sub_godwins_ = Buffer.Buffer<Godwin.Godwin>(0);

  type CanisterSettings = {
     settings : ?{
        controllers : ?[Principal];
        compute_allocation : ?Nat;
        memory_allocation : ?Nat;
        freezing_threshold : ?Nat;
     };
  };

  public shared({caller}) func createSubGodwin(parameters: Parameters) : async Result<(), Types.VerifyCredentialsError> {

    if (caller != admin_) {
      return #err(#InsufficientCredentials);
    };

    sub_godwins_.add(await (system Godwin.Godwin)(#new {settings = ?{ 
      controllers = ?[black_hole_];
      compute_allocation = null;
      memory_allocation = null;
      freezing_threshold = null;
    }})(parameters));

    #ok;

  };

};
