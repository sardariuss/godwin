import Types     "../../../src/godwin_sub/model/Types";

import Principal "mo:base/Principal";
import Buffer    "mo:base/Buffer";
import Iter      "mo:base/Iter";

import Fuzz      "mo:fuzz";
import Array     "mo:base/Array";
import Float     "mo:base/Float";

module {

  type Principal     = Principal.Principal;
  type Fuzzer        = Fuzz.Fuzzer;
  type Cursor        = Types.Cursor;
  type Category      = Types.Category;
  type CursorArray   = Types.CursorArray;
  type Interest      = Types.Interest;
  
  public func random(fuzzer: Fuzzer) : Float {
    fuzzer.float.randomRange(0.0, 1.0);
  };

  // Make the up vote more likely than the down vote
  public func randomInterest(fuzzer: Fuzzer) : Interest {
    if (fuzzer.float.randomRange(0.0, 1.0) > 0.4){ #UP; } else { #DOWN; };
  };

  public func randomOpinion(fuzzer: Fuzzer) : Cursor {
    fuzzer.float.randomRange(-1.0, 1.0);
  };

  public func randomCategorization(fuzzer: Fuzzer, categorization: [(Text, Float)]) : CursorArray {
    let cursors = Buffer.Buffer<(Category, Cursor)>(categorization.size());
    for ((category, cursor) in Array.vals(categorization)) {
      let margin = fuzzer.float.randomRange(0.0, 1.0);
      let lower_bound = Float.max(-1.0, cursor - margin);
      let upper_bound = Float.min( 1.0, cursor + margin);
      cursors.add((category, fuzzer.float.randomRange(lower_bound, upper_bound)));
    };
    Buffer.toArray(cursors);
  };

  public func generatePrincipals(fuzzer: Fuzzer, num: Nat) : [Principal] {
    let principals = Buffer.Buffer<Principal>(num);
    for (i in Iter.range(1, num)) {
      principals.add(fuzzer.principal.randomPrincipal(10));
    };
    Buffer.toArray(principals);
  };

  public func randomUser(fuzzer: Fuzzer, principals: [Principal]) : Principal {
    principals[fuzzer.nat.randomRange(0, principals.size() - 1)];
  };

};