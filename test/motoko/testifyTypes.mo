import Types     "../../src/godwin_backend/model/questions/Types";
import Questions "../../src/godwin_backend/model/questions/Questions";
import VoteTypes "../../src/godwin_backend/model/votes/Types";
import Votes "../../src/godwin_backend/model/votes/Votes";
import Cursor "../../src/godwin_backend/model/votes/representation/Cursor";
import Polarization "../../src/godwin_backend/model/votes/representation/Polarization";

import Utils  "../../src/godwin_backend/utils/Utils";

import Map     "mo:map/Map";

import Testify "mo:testing/Testify";

import Array   "mo:base/Array";
import Nat     "mo:base/Nat";
import Text    "mo:base/Text";
import Buffer  "mo:base/Buffer";
import Principal "mo:base/Principal";
import Float   "mo:base/Float";
import Int     "mo:base/Int";

module {

  type ScanLimitResult   = Types.ScanLimitResult;
  type Question          = Types.Question;
  type OpenQuestionError = Types.OpenQuestionError;
  type OpinionBallot     = VoteTypes.OpinionBallot;
  type Polarization      = VoteTypes.Polarization;

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

  public let testify_opinion_ballot : Testify.Testify<OpinionBallot> = {
    toText = func (b : OpinionBallot) : Text { Votes.ballotToText(b, Cursor.toText); };
    equal  = func (b1 : OpinionBallot, b2 : OpinionBallot) : Bool { Votes.ballotsEqual(b1, b2, Cursor.equal); };
  };

  public let testify_opinion_vote : Testify.Testify<VoteTypes.OpinionVote> = {
    toText = func (v : VoteTypes.OpinionVote) : Text { 
      let status = switch(v.status) { case(#OPEN) { "OPEN"; }; case(#CLOSED) { "CLOSED"; }; };
      let ballots = Buffer.Buffer<Text>(Map.size(v.ballots));
      for ((key, value) in Map.entries(v.ballots)) {
        ballots.add("[" # Principal.toText(key) # " ,  (answer=" # Float.toText(value.answer) # ", date=" # Int.toText(value.date) # ")] ");
      };
      "id: " # Nat.toText(v.id) #
      " aggregate: " # Polarization.toText(v.aggregate) #
      " status: " # status #
      " ballots: " # Text.join("", ballots.vals());
    };
    equal  = func (v1 : VoteTypes.OpinionVote, v2 : VoteTypes.OpinionVote) : Bool { 
      v1.id == v2.id and
      v1.aggregate == v2.aggregate and
      v1.status == v2.status and
      Utils.mapEqual<Principal, OpinionBallot>(v1.ballots, v2.ballots, Map.phash, func(v1, v2): Bool{
        Votes.ballotsEqual(v1, v2, Cursor.equal);
      }); 
    };
  };

  public let testify_polarization : Testify.Testify<Polarization> = {
    toText = Polarization.toText; 
    equal = Polarization.equal;
  };

  public let testify_bool      = Testify.Testify.bool;
  public let testify_nat       = Testify.Testify.nat;
  public let testify_nat8      = Testify.Testify.nat8;
  public let testify_nat16     = Testify.Testify.nat16;
  public let testify_nat32     = Testify.Testify.nat32;
  public let testify_nat64     = Testify.Testify.nat64;
  public let testify_int       = Testify.Testify.int;
  public let testify_int8      = Testify.Testify.int8;
  public let testify_int16     = Testify.Testify.int16;
  public let testify_int32     = Testify.Testify.int32;
  public let testify_int64     = Testify.Testify.int64;
  public let testify_float     = Testify.Testify.float;
  public let testify_char      = Testify.Testify.char;
  public let testify_text      = Testify.Testify.text;
  public let testify_blob      = Testify.Testify.blob;
  public let testify_error     = Testify.Testify.error;
  public let testify_principal = Testify.Testify.principal;

};