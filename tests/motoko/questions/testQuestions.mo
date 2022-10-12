import Types "../../../src/godwin_backend/types";
import StageHistory "../../../src/godwin_backend/stageHistory";

import Matchers "mo:matchers/Matchers";
import Suite "mo:matchers/Suite";
import Testable "mo:matchers/Testable";

import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Array "mo:base/Array";
import Nat "mo:base/Nat";
import Buffer "mo:base/Buffer";

module {
  public class TestQuestions() = {

    // For convenience: from base module
    type Principal = Principal.Principal;
    // For convenience: from matchers module
    let { run;test;suite; } = Suite;
    // For convenience: from types module
    type Question = Types.Question;

  };

};