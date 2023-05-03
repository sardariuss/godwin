import Types     "../../../src/godwin_backend/model/questions/Types";
import Queries   "../../../src/godwin_backend/model/questions/QuestionQueries";
import Questions "../../../src/godwin_backend/model/questions/Questions";

import Testify "mo:testing/Testify";

import Array   "mo:base/Array";
import Nat     "mo:base/Nat";
import Text    "mo:base/Text";
import Buffer  "mo:base/Buffer";

module {

  type ScanLimitResult   = Queries.ScanLimitResult;
  type Question          = Types.Question;
  type OpenQuestionError = Types.OpenQuestionError;

  public let testify_question : Testify.Testify<Question> = {
    toText = func (t : Question) : Text { Questions.toText(t); };
    equal  = func (x : Question, y : Question) : Bool { Questions.equal(x, y) };
  };

  public let testify_open_question_error : Testify.Testify<OpenQuestionError> = {
    toText = func (t : OpenQuestionError) : Text { switch(t){
      case (#PrincipalIsAnonymous) { return "PrincipalIsAnonymous"; };
      case (#TextTooLong) { return "TextTooLong"; };
    } };
    equal  = func (x : OpenQuestionError, y : OpenQuestionError) : Bool { x == y; };
  };

  public let testify_scan_limit_result : Testify.Testify<ScanLimitResult> = {
    toText = func (result : ScanLimitResult) : Text {
      var buffer : Buffer.Buffer<Text> = Buffer.Buffer<Text>(0);
      buffer.add("keys = [");
      for (id in Array.vals(result.keys)) {
        buffer.add(Nat.toText(id) # ", ");
      };
      buffer.add("], next = ");
      switch(result.next){
        case(null){ buffer.add("null"); };
        case(?id) { buffer.add(Nat.toText(id)); };
      };
      Text.join("", buffer.vals());
    };
    equal = func (qr1: ScanLimitResult, qr2: ScanLimitResult) : Bool { 
      let equal_keys = Array.equal(qr1.keys, qr2.keys, func(id1: Nat, id2: Nat) : Bool {
        Nat.equal(id1, id2);
      });
      let equal_next = switch(qr1.next) {
        case(null) { 
          switch(qr2.next) {
            case(null) { true };
            case(_) { false; };
          };
        };
        case(?next1) {
          switch(qr2.next) {
            case(null) { false };
            case(?next2) { Nat.equal(next1, next2); };
          };
        };
      };
      equal_keys and equal_next;
    };
  };

};