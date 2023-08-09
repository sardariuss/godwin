import Types             "../../src/godwin_sub/model/votes/Types";
import Opinions          "../../src/godwin_sub/model/votes/Opinions";
import Votes             "../../src/godwin_sub/model/votes/Votes";
import Decay             "../../src/godwin_sub/model/votes/Decay";
import Polarization      "../../src/godwin_sub/model/votes/representation/Polarization";
import Ref               "../../src/godwin_sub/utils/Ref";
import Wref              "../../src/godwin_sub/utils/wrappers/WRef";

import Principals                               "common/Principals";
import { compare; optionalTestify; Testify; } = "common/Testify";

import Map               "mo:map/Map";

import Principal         "mo:base/Principal";
import Array             "mo:base/Array";
import Nat               "mo:base/Nat";
import Text              "mo:base/Text";
import Result            "mo:base/Result";
import Time              "mo:base/Time";
import Debug             "mo:base/Debug";

import { test; suite; }  "mo:test/async";

class MockedVotersHistory() : Types.IVotersHistory {
  public func addVote(voter: Principal, vote_id: Types.VoteId) {};
  public func getVoterHistory(voter: Principal) : [Types.VoteId] { []; };
};

await suite("Opinions module test suite", func(): async () {
  
  type Result<Ok, Err>  = Result.Result<Ok, Err>;
  type Map<K, V>        = Map.Map<K, V>;
  
  type Opinions         = Opinions.Opinions;
  type OpinionBallot    = Types.OpinionBallot;
  type OpinionVote      = Types.OpinionVote;
  type Polarization     = Types.Polarization;
  type VoteId           = Types.VoteId;
  type Cursor           = Types.Cursor;
  type OpinionAnswer    = Types.OpinionAnswer;
  type OpinionAggregate = Types.OpinionAggregate;
  type DecayParameters  = Types.DecayParameters;

  let now = Time.now();
  let principals = Principals.init();
  let vote_decay        = Wref.WRef(Ref.init<DecayParameters>(Decay.getDecayParameters(#DAYS(365), now)));
  let late_ballot_decay = Wref.WRef(Ref.init<DecayParameters>(Decay.getDecayParameters(#DAYS(7), now)  ));
  let opinions = Opinions.build(Opinions.initRegister(), MockedVotersHistory(), vote_decay, late_ballot_decay);

  await test("New vote 0", func() : async () {
    compare(
      Result.toOption(opinions.findVote(opinions.newVote(now))),
      ?Votes.initVote<OpinionAnswer, OpinionAggregate>(0, { polarization = Polarization.nil(); decay = null; }),
      optionalTestify(Testify.opinionVote.equal));
  });
  await test("New vote 1", func() : async () {
    compare(
      Result.toOption(opinions.findVote(opinions.newVote(now))),
      ?Votes.initVote<OpinionAnswer, OpinionAggregate>(1, { polarization = Polarization.nil(); decay = null; }),
      optionalTestify(Testify.opinionVote.equal));
  });
  await test("New vote 2", func() : async () {
    compare(
      Result.toOption(opinions.findVote(opinions.newVote(now))),
      ?Votes.initVote<OpinionAnswer, OpinionAggregate>(2, { polarization = Polarization.nil(); decay = null; }),
      optionalTestify(Testify.opinionVote.equal));
  });
  await test("Add ballot to vote 0", func() : async () {
    let ballot : OpinionBallot = { date = 123456789; answer = { cursor = 0.0; late_decay = null; } };
    assert Result.isOk(await* opinions.putBallot(principals[0], 0, ballot.date, ballot.answer.cursor));
    compare(
      Result.toOption(opinions.findBallot(principals[0], 0)),
      ?ballot,
      optionalTestify(Testify.opinionBallot.equal));
  });
  await test("Update ballot to vote 0", func() : async () {
    let ballot : OpinionBallot = { date = 12121212; answer = { cursor = 1.0; late_decay = null; } };
    assert Result.isOk(await* opinions.putBallot(principals[0], 0, ballot.date, ballot.answer.cursor));
    compare(
      Result.toOption(opinions.findBallot(principals[0], 0)),
      ?ballot,
      optionalTestify(Testify.opinionBallot.equal));
  });
  await test("Vote aggregate vote 1", func() : async () {
    let vote_id = 1;
    assert Result.isOk(await* opinions.putBallot(principals[0], vote_id, 7714,   1.0));
    assert Result.isOk(await* opinions.putBallot(principals[1], vote_id, 23271,  0.5));
    assert Result.isOk(await* opinions.putBallot(principals[2], vote_id, 65600,  0.5));
    assert Result.isOk(await* opinions.putBallot(principals[3], vote_id, 68919,  0.5));
    assert Result.isOk(await* opinions.putBallot(principals[4], vote_id, 47827,  0.5));
    assert Result.isOk(await* opinions.putBallot(principals[5], vote_id, 60277,  0.5));
    assert Result.isOk(await* opinions.putBallot(principals[6], vote_id, 64031,  0.0));
    assert Result.isOk(await* opinions.putBallot(principals[7], vote_id, 83560,  0.0));
    assert Result.isOk(await* opinions.putBallot(principals[8], vote_id, 98166, -1.0));
    assert Result.isOk(await* opinions.putBallot(principals[9], vote_id, 10111, -1.0));
    compare(
      opinions.getVote(vote_id).aggregate.polarization,
      { left = 2.0; center = 4.5; right = 3.5; },
      Testify.polarization.equal);
  });
  // @todo: reactivate this test
//  await test("Get voter ballots", func() : async () {
//    for (principal in Array.vals(principals)){
//      compare(
//        Map.size(opinions.getVoterBallots(principal)),
//        if (principal == principals[0]) 2 else 1,
//        Testify.nat.equal);
//    };
//  });
  
});