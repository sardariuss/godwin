import Types "../../src/godwin_backend/model/Types";
import Interests "../../src/godwin_backend/model/votes/Interests";
import Game "../../src/godwin_backend/model/Game";
import Factory "../../src/godwin_backend/model/Factory";
import State "../../src/godwin_backend/model/State";
import Duration "../../src/godwin_backend/model/Duration";

import WSet "../../src/godwin_backend/utils/wrappers/WSet";

import TestableItems "testableItems";
import Principals "Principals";

import Matchers "mo:matchers/Matchers";
import Suite "mo:matchers/Suite";

import Principal "mo:base/Principal";
import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";
import Debug "mo:base/Debug";
import Nat32 "mo:base/Nat32";
import Nat "mo:base/Nat";

import Fuzz "mo:fuzz";
import Blob "mo:base/Blob";
import Bool "mo:base/Bool";
import Array "mo:base/Array";

module {

  // For convenience: from base module
  type Principal = Principal.Principal;
  type Fuzzer = Fuzz.Fuzzer;
  type Duration = Types.Duration;
  type Interest = Types.Interest;
  type Cursor = Types.Cursor;
  type Category = Types.Category;
  type CursorArray = Types.CursorArray;
  
  public func random(fuzzer: Fuzzer) : Float {
    fuzzer.float.randomRange(0.0, 1.0);
  };

  public func randomInterest(fuzzer: Fuzzer) : Interest {
    if (fuzzer.bool.random()) { #UP; } else { #DOWN; };
  };

  public func randomOpinion(fuzzer: Fuzzer) : Cursor {
    fuzzer.float.randomRange(-1.0, 1.0);
  };

  public func randomTitle(fuzzer: Fuzzer) : Text { 
    fuzzer.text.randomAlphabetic(fuzzer.nat.randomRange(10, 30));
  };

  public func randomCategorization(fuzzer: Fuzzer, categories: [Category]) : CursorArray {
    let cursors = Buffer.Buffer<(Category, Cursor)>(categories.size());
    for (category in Array.vals(categories)) {
      cursors.add((category, fuzzer.float.randomRange(-1.0, 1.0)));
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