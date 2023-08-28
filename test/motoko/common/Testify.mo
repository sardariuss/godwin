import Types         "../../../src/godwin_sub/stable/Types";
import QuestionTypes "../../../src/godwin_sub/model/questions/Types";
import Questions     "../../../src/godwin_sub/model/questions/Questions";
import VoteTypes     "../../../src/godwin_sub/model/votes/Types";
import Votes         "../../../src/godwin_sub/model/votes/Votes";
import Cursor        "../../../src/godwin_sub/model/votes/representation/Cursor";
import Polarization  "../../../src/godwin_sub/model/votes/representation/Polarization";
import PayTypes      "../../../src/godwin_sub/model/token/Types";

import Utils         "../../../src/godwin_sub/utils/Utils";
import UtilsTypes    "../../../src/godwin_sub/utils/Types";

import Map           "mo:map/Map";

import Array         "mo:base/Array";
import Nat           "mo:base/Nat";
import Text          "mo:base/Text";
import Buffer        "mo:base/Buffer";
import Principal     "mo:base/Principal";
import Float         "mo:base/Float";
import Int           "mo:base/Int";
import Option        "mo:base/Option";
import Debug         "mo:base/Debug";
import Prim          "mo:⛔";

module {

  type ScanLimitResult      = QuestionTypes.ScanLimitResult;
  type Question             = QuestionTypes.Question;
  type OpenQuestionError    = QuestionTypes.OpenQuestionError;
  type OpinionBallot        = VoteTypes.OpinionBallot;
  type Polarization         = VoteTypes.Polarization;
  type OpinionAnswer        = VoteTypes.OpinionAnswer;
  type InterestDistribution = VoteTypes.InterestDistribution;
  type RealNumber           = UtilsTypes.RealNumber;
  type PayoutArgs           = PayTypes.PayoutArgs;
  type QuestionPayouts      = PayTypes.QuestionPayouts;
  type RawPayout            = PayTypes.RawPayout;
  type PriceRegister        = Types.Current.PriceRegister;
  
  let FLOAT_EPSILON : Float = 1e-12;

  // Utility Functions, needs to be declared before used
  private func intToText(i : Int) : Text {
    if (i == 0) return "0";
    let negative = i < 0;
    var t = "";
    var n = if (negative) { -i } else { i };
    while (0 < n) {
      t := (switch (n % 10) {
        case 0 { "0" };
        case 1 { "1" };
        case 2 { "2" };
        case 3 { "3" };
        case 4 { "4" };
        case 5 { "5" };
        case 6 { "6" };
        case 7 { "7" };
        case 8 { "8" };
        case 9 { "9" };
        case _ { Prim.trap("unreachable") };
      }) # t;
      n /= 10;
    };
    if (negative) { "-" # t } else { t };
  };

  public type Testify<T> = {
    toText : (t : T) -> Text;
    compare  : (x : T, y : T) -> Bool;
  };

  public func testify<T>(
    toText : (t : T) -> Text,
    compare  : (x : T, y : T) -> Bool
  ) : Testify<T> = { toText; compare };

  public func optionalTestify<T>(
    testify : Testify<T>,
  ) : Testify<?T> = {
    toText = func (t : ?T) : Text = switch (t) {
      case (null) { "null" };
      case (? t)  { "?" # testify.toText(t) }
    };
    compare = func (x : ?T, y : ?T) : Bool = switch (x) {
      case (null) switch (y) {
        case (null) { true };
        case (_)  { false };
      };
      case (? x) switch(y) {
        case (null) { false };
        case (? y)  { testify.compare(x, y) };
      };
    };
  };

  public func compare<T>(actual: T, expected: T, testify: Testify<T>){
    if (not testify.compare(actual, expected)){
      Debug.print("Actual: " # testify.toText(actual));
      Debug.print("Expected: " # testify.toText(expected));
      assert(false);
    };
  };

  func equalFloat(f1: Float, f2: Float) : Bool {
    Float.equalWithin(f1, f2, FLOAT_EPSILON);
  };

  func optToText<T>(item: ?T, to_text: (T) -> Text) : Text {
    switch(item){
      case(null) { "(null)"; };
      case(?item) { to_text(item); };
    };
  };

  func optEqual<T>(item1: ?T, item2: ?T, equal: (T, T) -> Bool) : Bool {
    switch((item1, item2)){
      case(?i1, ?i2) { equal(i1, i2); };
      case(null, null) { true; };
      case(_) { false; };
    };
  };

  func opinionBallotToText(b : OpinionBallot) : Text { 
    Votes.ballotToText(b, func(answer: OpinionAnswer): Text {
      "{ cursor = " # Cursor.toText(answer.cursor) #
      ", late_decay = " # optToText(answer.late_decay, Float.toText) # " }";
    });
  };

  func opinionBallotsEqual(b1 : OpinionBallot, b2 : OpinionBallot) : Bool { 
    Votes.ballotsEqual(b1, b2, func(answer1: OpinionAnswer, answer2: OpinionAnswer) : Bool {
      answer1.cursor == answer2.cursor and optEqual(answer1.late_decay, answer2.late_decay, equalFloat);
    });
  };

  func payoutArgsToText(p: PayoutArgs) : Text {
    "refund_share = "  # Float.toText(p.refund_share) # ", " #
    "reward_tokens = " # optToText(p.reward_tokens, Nat.toText);
  };

  func rawPayoutToText(p: RawPayout) : Text {
    "refund_share = "  # Float.toText(p.refund_share) # ", " #
    "reward = " # optToText(p.reward, Float.toText);
  };

  func payoutArgsEqual(p1: PayoutArgs, p2: PayoutArgs) : Bool {
    Float.equalWithin(p1.refund_share, p2.refund_share, FLOAT_EPSILON) and
    optEqual(p1.reward_tokens, p2.reward_tokens, Nat.equal);
  };

  func rawPayoutEqual(p1: RawPayout, p2: RawPayout) : Bool {
    Float.equalWithin(p1.refund_share, p2.refund_share, FLOAT_EPSILON) and
    optEqual(p1.reward, p2.reward, equalFloat);
  };

  /// Submodule of primitive testify functions (excl. 'Any', 'None' and 'Null').
  /// https://github.com/dfinity/motoko/blob/master/src/prelude/prelude.mo
  public module Testify {

    public let bool = {
      equal : Testify<Bool> = {
        toText = func (t : Bool) : Text { if (t) { "true" } else { "false" } };
        compare  = func (x : Bool, y : Bool) : Bool { x == y };
      };
    };

    public let nat = {
      equal : Testify<Nat> = {
        toText = intToText;
        compare  = func (x : Nat, y : Nat) : Bool { x == y };
      };
    };

    public let nat8 = {
      equal : Testify<Nat8> = {
        toText = func (n : Nat8) : Text = intToText(Prim.nat8ToNat(n));
        compare  = func (x : Nat8, y : Nat8) : Bool { x == y };
      };
    };

    public let nat16 = {
      equal : Testify<Nat16> = {
        toText = func (n : Nat16) : Text = intToText(Prim.nat16ToNat(n));
        compare  = func (x : Nat16, y : Nat16) : Bool { x == y };
      };
    };

    public let nat32 = {
        equal : Testify<Nat32> = {
        toText = func (n : Nat32) : Text = intToText(Prim.nat32ToNat(n));
        compare  = func (x : Nat32, y : Nat32) : Bool { x == y };
      };
    };

    public let nat64 = {
      equal : Testify<Nat64> = {
        toText = func (n : Nat64) : Text = intToText(Prim.nat64ToNat(n));
        compare  = func (x : Nat64, y : Nat64) : Bool { x == y };
      };
    };

    public let int = {
      equal : Testify<Int> = {
        toText = intToText;
        compare  = func (x : Int, y : Int) : Bool { x == y };
      };
    };

    public let int8 = {
      equal : Testify<Int8> = {
        toText = func (i : Int8) : Text = intToText(Prim.int8ToInt(i));
        compare  = func (x : Int8, y : Int8) : Bool { x == y };
      };
    };

    public let int16 = {
      equal : Testify<Int16> = {
        toText = func (i : Int16) : Text = intToText(Prim.int16ToInt(i));
        compare  = func (x : Int16, y : Int16) : Bool { x == y };
      };
    };

    public let int32 = {
      equal : Testify<Int32> = {
        toText = func (i : Int32) : Text = intToText(Prim.int32ToInt(i));
        compare  = func (x : Int32, y : Int32) : Bool { x == y };
      };
    };

    public let int64 = {
      equal : Testify<Int64> = {
        toText = func (i : Int64) : Text =  intToText(Prim.int64ToInt(i));
        compare  = func (x : Int64, y : Int64) : Bool { x == y };
      };
    };

    public let float = {
      equal : Testify<Float> = {
        toText = func (f : Float) : Text = Prim.floatToText(f);
        compare  = func (x : Float, y : Float) : Bool { Float.equalWithin(x, y, FLOAT_EPSILON); };
      };
      greaterThan : Testify<Float> = {
        toText = func (f : Float) : Text = Prim.floatToText(f);
        compare  = func (x : Float, y : Float) : Bool { x > y };
      };
      greaterThanOrEqual : Testify<Float> = {
        toText = func (f : Float) : Text = Prim.floatToText(f);
        compare  = func (x : Float, y : Float) : Bool { x >= y };
      };
      lessThan : Testify<Float> = {
        toText = func (f : Float) : Text = Prim.floatToText(f);
        compare  = func (x : Float, y : Float) : Bool { x < y };
      };
      lessThanOrEqual : Testify<Float> = {
        toText = func (f : Float) : Text = Prim.floatToText(f);
        compare  = func (x : Float, y : Float) : Bool { x <= y };
      };
    };

    public let realNumber = {
      equal: Testify<RealNumber> = {
        toText = func (real_number : RealNumber) : Text = switch(real_number){          
          case(#POSITIVE_INFINITY) { "POSITIVE_INFINITY"; };
          case(#NEGATIVE_INFINITY) { "NEGATIVE_INFINITY"; };
          case(#NUMBER(x)) { "NUMBER: " # Float.toText(x); };
        };
        compare  = func (x : RealNumber, y : RealNumber) : Bool { 
          switch(x, y){
            case(#POSITIVE_INFINITY, #POSITIVE_INFINITY) { true; };
            case(#NEGATIVE_INFINITY, #NEGATIVE_INFINITY) { true; };
            case(#NUMBER(x), #NUMBER(y)) { Float.equalWithin(x, y, FLOAT_EPSILON); };
            case(_, _) { false; };
          };
        };
      };
    };

    public let floatEpsilon9 = {
      equal : Testify<Float> = {
        toText = func (f : Float) : Text = Prim.floatToText(f);
        compare  = func (x : Float, y : Float) : Bool { Float.equalWithin(x, y, 1e-9); };
      };
    };

    public let floatEpsilon6 = {
      equal : Testify<Float> = {
        toText = func (f : Float) : Text = Prim.floatToText(f);
        compare  = func (x : Float, y : Float) : Bool { Float.equalWithin(x, y, 1e-6); };
      };
    };

    public let floatEpsilon3 = {
      equal : Testify<Float> = {
        toText = func (f : Float) : Text = Prim.floatToText(f);
        compare  = func (x : Float, y : Float) : Bool { Float.equalWithin(x, y, 1e-3); };
      };
    };

    public let char = {
      equal : Testify<Char> = {
        toText = func (c : Char) : Text = Prim.charToText(c);
        compare  = func (x : Char, y : Char) : Bool { x == y };
      };
    };

    public let text = {
      equal : Testify<Text> = {
        toText = func (t : Text) : Text { t };
        compare  = func (x : Text, y : Text) : Bool { x == y };
      };
    };

    public let blob = {
      equal : Testify<Blob> = {
        toText = func (b : Blob) : Text { encodeBlob(b) };
        compare  = func (x : Blob, y : Blob) : Bool { x == y };
      };
    };

    public let error = {
      equal : Testify<Error> = {
        toText = func (e : Error) : Text { Prim.errorMessage(e) };
        compare  = func (x : Error, y : Error) : Bool {
          Prim.errorCode(x)  == Prim.errorCode(y) and 
          Prim.errorMessage(x) == Prim.errorMessage(y);
        };
      };
    };

    public let principal = {
      equal : Testify<Principal> = {
        toText = func (p : Principal) : Text { debug_show(p) };
        compare  = func (x : Principal, y : Principal) : Bool { x == y };
      };
    };

    public let question = {
      equal : Testify<Question> = {
        toText = func (t : Question) : Text { Questions.toText(t); };
        compare  = func (x : Question, y : Question) : Bool { Questions.equal(x, y) };
      };
    };

    public let openQuestionError = {
      equal : Testify<OpenQuestionError> = {
        toText = func (t : OpenQuestionError) : Text { switch(t){
          case (#PrincipalIsAnonymous) { return "PrincipalIsAnonymous"; };
          case (#TextTooLong) { return "TextTooLong"; };
        } };
        compare  = func (x : OpenQuestionError, y : OpenQuestionError) : Bool { x == y; };
      };
    };

    public let scanLimitResult = {
      equal : Testify<ScanLimitResult> = {
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
        compare = func (qr1: ScanLimitResult, qr2: ScanLimitResult) : Bool { 
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

    public let opinionBallot = {
      equal : Testify<OpinionBallot> = {
        toText = opinionBallotToText;
        compare  = opinionBallotsEqual;
      };
    };

    public let opinionVote = {
      equal : Testify<VoteTypes.OpinionVote> = {
        toText = func (v : VoteTypes.OpinionVote) : Text { 
          let status = switch(v.status) { case(#OPEN) { "OPEN"; }; case(#LOCKED) { "LOCKED" }; case(#CLOSED) { "CLOSED"; }; };
          let ballots = Buffer.Buffer<Text>(Map.size(v.ballots));
          for ((principal, ballot) in Map.entries(v.ballots)) {
            ballots.add("[" # Principal.toText(principal) # ", " # opinionBallotToText(ballot) # "] ");
          };
          "id: " # Nat.toText(v.id) #
          " aggregate: { polarization: " # Polarization.toText(v.aggregate.polarization) # ", decay: " # optToText(v.aggregate.decay, Float.toText) # " }" #
          " status: " # status #
          " ballots: " # Text.join("", ballots.vals());
        };
        compare = func (v1 : VoteTypes.OpinionVote, v2 : VoteTypes.OpinionVote) : Bool { 
          v1.id == v2.id and
          v1.aggregate.polarization == v2.aggregate.polarization and
          optEqual(v1.aggregate.decay, v2.aggregate.decay, equalFloat) and
          v1.status == v2.status and
          Utils.mapEqual<Principal, OpinionBallot>(v1.ballots, v2.ballots, Map.phash, opinionBallotsEqual)
        };
      };
    };

    public let polarization = {
      equal : Testify<Polarization> = {
        toText = Polarization.toText; 
        compare = Polarization.equal;
      };
    };

    public let interestDistribution = {
      equal: Testify<InterestDistribution> = {
        toText  = func (distrib : InterestDistribution) : Text {
          "Shares: [up = " # Float.toText(distrib.shares.up) # ", down = " # Float.toText(distrib.shares.down) # "], " #
          "Reward ratio: " # Float.toText(distrib.reward_ratio);
        };
        compare = func (d1: InterestDistribution, d2: InterestDistribution) : Bool {
          Float.equalWithin(d1.shares.up,    d2.shares.up,    FLOAT_EPSILON) and
          Float.equalWithin(d1.shares.down,  d2.shares.down,  FLOAT_EPSILON) and
          Float.equalWithin(d1.reward_ratio, d2.reward_ratio,  1e-5); // Reward uses ERF which is not so precise
        };
      };
    };

    public let priceRegister = {
      equal : Testify<PriceRegister> = {
        toText = func(register: PriceRegister) : Text {
          "open_vote_price_e8s = "           # Nat.toText(register.open_vote_price_e8s)     # ", " #
          "reopen_vote_price_e8s = "         # Nat.toText(register.reopen_vote_price_e8s)   # ", " #
          "interest_vote_price_e8s = "       # Nat.toText(register.interest_vote_price_e8s) # ", " #
          "categorization_vote_price_e8s = " # Nat.toText(register.categorization_vote_price_e8s);
        };
        compare = func(r1: PriceRegister, r2: PriceRegister) : Bool {
          r1.open_vote_price_e8s           == r2.open_vote_price_e8s and
          r1.reopen_vote_price_e8s         == r2.reopen_vote_price_e8s and
          r1.interest_vote_price_e8s       == r2.interest_vote_price_e8s and
          r1.categorization_vote_price_e8s == r2.categorization_vote_price_e8s;
        };
      };
    };
    
    public let payoutArgs = {
      equal : Testify<PayoutArgs> = { toText = payoutArgsToText; compare = payoutArgsEqual; };
    };

    public let rawPayout = {
      equal : Testify<RawPayout> = { toText = rawPayoutToText; compare = rawPayoutEqual; };
    };

    public let openedQuestionPayout = {
      equal : Testify<QuestionPayouts> = {
        toText = func(p: QuestionPayouts) : Text {
          "author_payout = " # rawPayoutToText(p.author_payout) # ", " #
          "creator_reward = " # optToText(p.creator_reward, Float.toText);
        };
        compare = func(p1: QuestionPayouts, p2: QuestionPayouts) : Bool {
          rawPayoutEqual(p1.author_payout, p2.author_payout) and
          optEqual(p1.creator_reward, p2.creator_reward, Float.equal);
        };
      };
    };

    private let hex : [Char] = [
      '0', '1', '2', '3', 
      '4', '5', '6', '7', 
      '8', '9', 'a', 'b', 
      'c', 'd', 'e', 'f',
    ];

    private func encodeByte(n : Nat8, acc : Text) : Text {
      let c0 = hex[Prim.nat8ToNat(n / 16)];
      let c1 = hex[Prim.nat8ToNat(n % 16)];
      Prim.charToText(c0) # Prim.charToText(c1) # acc;
    };

    private func encodeBlob(b : Blob) : Text {
      let bs = Prim.blobToArray(b);
      var t = "";
      var i = bs.size();
      while (0 < i) {
        i -= 1;
        t := encodeByte(bs[i], t);
      };
      t;
    };
  };

};
