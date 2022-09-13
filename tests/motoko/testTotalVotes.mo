import Types "../../src/godwin_backend/types";
import Votes "../../src/godwin_backend/votes";

import Matchers "mo:matchers/Matchers";
import Suite "mo:matchers/Suite";
import Testable "mo:matchers/Testable";

import Trie "mo:base/Trie";
import Text "mo:base/Text";
import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Principal "mo:base/Principal";
import Nat "mo:base/Nat";

class TestTotalVotes() = {

  // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;
  // For convenience: from matchers module
  let { run;test;suite; } = Suite;
  type Opinion = Types.Opinion;
  type TotalVotes<B> = Types.TotalVotes<B>;

  type OpinionTotalVotes = TotalVotes<Opinion>;

  let principal_0 = Principal.fromText("sixzy-7pdha-xesaj-edo76-wuzat-gdfeh-eihfz-5b6on-eqcu2-4p23j-qqe");
  let principal_1 = Principal.fromText("2an7n-c4inx-7otxp-f4gmm-lz4yk-z6rvd-ogxe4-fype3-icqva-w5ylq-sae");
  let principal_2 = Principal.fromText("zl5om-yevaq-syyny-vn5bl-ahjnu-cc2qx-b7oqi-ojbct-xrxjw-ivql6-uqe");

  func testableOpinionTotalVotes(total: OpinionTotalVotes) : Testable.TestableItem<OpinionTotalVotes> {
    {
      display = func (total: OpinionTotalVotes) : Text { 
        var buffer : Buffer.Buffer<Text> = Buffer.Buffer<Text>(0);
        buffer.add("all = " # Nat.toText(total.all) # "; [");
        let opinions = [#AGREE(#ABSOLUTE), #AGREE(#MODERATE), #NEUTRAL, #DISAGREE(#MODERATE), #DISAGREE(#ABSOLUTE)];
        for (opinion in Array.vals(opinions)){
          buffer.add("{" # Types.toTextOpinion(opinion) # "} = ");
          switch (Trie.get(total.per_ballot, { key = opinion; hash = Types.hashOpinion(opinion); }, Types.equalOpinion)){
            case(null){ buffer.add("0"); };
            case(?per_ballot){ buffer.add(Nat.toText(per_ballot)); };
          };
          buffer.add(", ");
        };
        buffer.add("]");
        Text.join("", buffer.vals());
      };
      equals = func (total1: OpinionTotalVotes, total2: OpinionTotalVotes) : Bool { 
        var equals : Bool = (total1.all == total2.all);
        let opinions = [#AGREE(#ABSOLUTE), #AGREE(#MODERATE), #NEUTRAL, #DISAGREE(#MODERATE), #DISAGREE(#ABSOLUTE)];
        for (opinion in Array.vals(opinions)){
          var per_ballot_1 : Nat = 0;
          var per_ballot_2 : Nat = 0;
          switch (Trie.get(total1.per_ballot, { key = opinion; hash = Types.hashOpinion(opinion); }, Types.equalOpinion)){
            case(null){};
            case(?per_ballot){per_ballot_1 := per_ballot;};
          };
          switch (Trie.get(total2.per_ballot, { key = opinion; hash = Types.hashOpinion(opinion); }, Types.equalOpinion)){
            case(null){};
            case(?per_ballot){ per_ballot_2 := per_ballot;};
          };
          equals := (equals and Nat.equal(per_ballot_1, per_ballot_2));
        };
        equals;
      };
      item = total;
    };
  };

  // 3 users, each vote once, 1 cancelled his vote: 2 votes shall be counted
  func opinionScenario1() : Testable.TestableItem<OpinionTotalVotes> {
    var opinions = Votes.empty<Opinion>();
    opinions := Votes.putBallot(opinions, principal_0, 0, Types.hashOpinion, Types.equalOpinion, #NEUTRAL).0;
    opinions := Votes.putBallot(opinions, principal_1, 0, Types.hashOpinion, Types.equalOpinion, #NEUTRAL).0;
    opinions := Votes.putBallot(opinions, principal_2, 0, Types.hashOpinion, Types.equalOpinion, #NEUTRAL).0;
    opinions := Votes.removeBallot(opinions, principal_2, 0, Types.hashOpinion, Types.equalOpinion).0;
    testableOpinionTotalVotes(Votes.getTotalVotes(opinions, 0));
  };

  func opinionExpected1() : OpinionTotalVotes {
    var per_ballot = Trie.empty<Opinion, Nat>();
    per_ballot := Trie.put(per_ballot, { key = #NEUTRAL; hash = Types.hashOpinion(#NEUTRAL); }, Types.equalOpinion, 2).0;
    {
      all = 2;
      per_ballot = per_ballot; 
    };
  };

  // 3 users, change their mind 3 times: only their last vote shall be taken into account
  func opinionScenario2() : Testable.TestableItem<OpinionTotalVotes> {
    var opinions = Votes.empty<Opinion>();
    opinions := Votes.putBallot(opinions, principal_0, 0, Types.hashOpinion, Types.equalOpinion, #NEUTRAL).0;
    opinions := Votes.putBallot(opinions, principal_0, 0, Types.hashOpinion, Types.equalOpinion, #AGREE(#ABSOLUTE)).0;
    opinions := Votes.putBallot(opinions, principal_0, 0, Types.hashOpinion, Types.equalOpinion, #DISAGREE(#MODERATE)).0;
    opinions := Votes.putBallot(opinions, principal_1, 0, Types.hashOpinion, Types.equalOpinion, #NEUTRAL).0;
    opinions := Votes.putBallot(opinions, principal_1, 0, Types.hashOpinion, Types.equalOpinion, #AGREE(#MODERATE)).0;
    opinions := Votes.putBallot(opinions, principal_1, 0, Types.hashOpinion, Types.equalOpinion, #DISAGREE(#ABSOLUTE)).0;
    opinions := Votes.putBallot(opinions, principal_2, 0, Types.hashOpinion, Types.equalOpinion, #NEUTRAL).0;
    opinions := Votes.putBallot(opinions, principal_2, 0, Types.hashOpinion, Types.equalOpinion, #AGREE(#MODERATE)).0;
    opinions := Votes.putBallot(opinions, principal_2, 0, Types.hashOpinion, Types.equalOpinion, #NEUTRAL).0;
    testableOpinionTotalVotes(Votes.getTotalVotes(opinions, 0));
  };

  func opinionExpected2() : OpinionTotalVotes {
    var per_ballot = Trie.empty<Opinion, Nat>();
    per_ballot := Trie.put(per_ballot, { key = #NEUTRAL; hash = Types.hashOpinion(#NEUTRAL); }, Types.equalOpinion, 1).0;
    per_ballot := Trie.put(per_ballot, { key = #DISAGREE(#MODERATE); hash = Types.hashOpinion(#DISAGREE(#MODERATE)); }, Types.equalOpinion, 1).0;
    per_ballot := Trie.put(per_ballot, { key = #DISAGREE(#ABSOLUTE); hash = Types.hashOpinion(#DISAGREE(#ABSOLUTE)); }, Types.equalOpinion, 1).0;
    {
      all = 3;
      per_ballot = per_ballot;
    };
  };

  // 3 users, each vote on 3 questions, main question (0) shall be not be impacted by other questions
  func opinionScenario3() : Testable.TestableItem<OpinionTotalVotes> {
    var opinions = Votes.empty<Opinion>();
    opinions := Votes.putBallot(opinions, principal_0, 0, Types.hashOpinion, Types.equalOpinion, #NEUTRAL).0;
    opinions := Votes.putBallot(opinions, principal_0, 1, Types.hashOpinion, Types.equalOpinion, #AGREE(#MODERATE)).0;
    opinions := Votes.putBallot(opinions, principal_0, 2, Types.hashOpinion, Types.equalOpinion, #DISAGREE(#MODERATE)).0;
    opinions := Votes.putBallot(opinions, principal_1, 0, Types.hashOpinion, Types.equalOpinion, #NEUTRAL).0;
    opinions := Votes.putBallot(opinions, principal_1, 1, Types.hashOpinion, Types.equalOpinion, #AGREE(#MODERATE)).0;
    opinions := Votes.putBallot(opinions, principal_1, 2, Types.hashOpinion, Types.equalOpinion, #DISAGREE(#MODERATE)).0;
    opinions := Votes.putBallot(opinions, principal_2, 0, Types.hashOpinion, Types.equalOpinion, #NEUTRAL).0;
    opinions := Votes.putBallot(opinions, principal_2, 1, Types.hashOpinion, Types.equalOpinion, #AGREE(#MODERATE)).0;
    opinions := Votes.putBallot(opinions, principal_2, 2, Types.hashOpinion, Types.equalOpinion, #DISAGREE(#MODERATE)).0;
    testableOpinionTotalVotes(Votes.getTotalVotes(opinions, 0));
  };

  func opinionExpected3() : OpinionTotalVotes {
    var per_ballot = Trie.empty<Opinion, Nat>();
    per_ballot := Trie.put(per_ballot, { key = #NEUTRAL; hash = Types.hashOpinion(#NEUTRAL); }, Types.equalOpinion, 3).0;
    {
      all = 3;
      per_ballot = per_ballot;
    };
  };

  public let suiteTotalVotes = suite("suiteTotalVotes", [
    test("scenario 1", opinionExpected1(), Matchers.equals(opinionScenario1())),
    test("scenario 2", opinionExpected2(), Matchers.equals(opinionScenario2())),
    test("scenario 3", opinionExpected3(), Matchers.equals(opinionScenario3())),
  ]);
};