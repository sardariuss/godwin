import Types            "../../src/godwin_sub/model/votes/Types";
import Opinions         "../../src/godwin_sub/model/votes/Opinions";
import Votes            "../../src/godwin_sub/model/votes/Votes";
import Decay            "../../src/godwin_sub/model/votes/Decay";
import Polarization     "../../src/godwin_sub/model/votes/representation/Polarization";

import Principals                               "common/Principals";
import { compare; optionalTestify; Testify; } = "common/Testify";

import Map              "mo:map/Map";

import Principal        "mo:base/Principal";
import Array            "mo:base/Array";
import Nat              "mo:base/Nat";
import Text             "mo:base/Text";
import Result           "mo:base/Result";
import Time             "mo:base/Time";
import Debug            "mo:base/Debug";

import { test; suite; } "mo:test/async";


await suite("Opinions module test suite", func(): async () {
  
  type Result<Ok, Err> = Result.Result<Ok, Err>;
  
  type Opinions      = Opinions.Opinions;
  type OpinionBallot = Types.OpinionBallot;
  type OpinionVote   = Types.OpinionVote;
  type Polarization  = Types.Polarization;
  type VoteId        = Types.VoteId;
  type Cursor        = Types.Cursor;

  let now = Time.now();
  let principals = Principals.init();
  let decay_parameters = Decay.initParameters(#DAYS(365), now);
  let opinions = Opinions.build(Opinions.initRegister(), decay_parameters);

  await test("New vote 0", func() : async () {
    compare(
      Result.toOption(opinions.findVote(opinions.newVote(now))),
      ?Votes.initVote<Cursor, Polarization>(0, Decay.computeDecay(decay_parameters, now), Polarization.nil()),
      optionalTestify(Testify.opinionVote));
  });
  await test("New vote 1", func() : async () {
    compare(
      Result.toOption(opinions.findVote(opinions.newVote(now))),
      ?Votes.initVote<Cursor, Polarization>(1, Decay.computeDecay(decay_parameters, now), Polarization.nil()),
      optionalTestify(Testify.opinionVote));
  });
  await test("New vote 2", func() : async () {
    compare(
      Result.toOption(opinions.findVote(opinions.newVote(now))),
      ?Votes.initVote<Cursor, Polarization>(2, Decay.computeDecay(decay_parameters, now), Polarization.nil()),
      optionalTestify(Testify.opinionVote));
  });
  await test("Add ballot to vote 0", func() : async () {
    let ballot : OpinionBallot = { date = 123456789; answer = 0.0; };
    assert Result.isOk(await* opinions.putBallot(principals[0], 0, ballot));
    compare(
      Result.toOption(opinions.findBallot(principals[0], 0)),
      ?ballot,
      optionalTestify(Testify.opinionBallot));
  });
  await test("Update ballot to vote 0", func() : async () {
    let ballot : OpinionBallot = { date = 12121212; answer = 1.0; };
    assert Result.isOk(await* opinions.putBallot(principals[0], 0, ballot));
    compare(
      Result.toOption(opinions.findBallot(principals[0], 0)),
      ?ballot,
      optionalTestify(Testify.opinionBallot));
  });
  await test("Vote aggregate vote 1", func() : async () {
    let vote_id = 1;
    assert Result.isOk(await* opinions.putBallot(principals[0], vote_id, { date = 7714;  answer = 1.0; }));
    assert Result.isOk(await* opinions.putBallot(principals[1], vote_id, { date = 23271; answer = 0.5; }));
    assert Result.isOk(await* opinions.putBallot(principals[2], vote_id, { date = 65600; answer = 0.5; }));
    assert Result.isOk(await* opinions.putBallot(principals[3], vote_id, { date = 68919; answer = 0.5; }));
    assert Result.isOk(await* opinions.putBallot(principals[4], vote_id, { date = 47827; answer = 0.5; }));
    assert Result.isOk(await* opinions.putBallot(principals[5], vote_id, { date = 60277; answer = 0.5; }));
    assert Result.isOk(await* opinions.putBallot(principals[6], vote_id, { date = 64031; answer = 0.0; }));
    assert Result.isOk(await* opinions.putBallot(principals[7], vote_id, { date = 83560; answer = 0.0; }));
    assert Result.isOk(await* opinions.putBallot(principals[8], vote_id, { date = 98166; answer =-1.0; }));
    assert Result.isOk(await* opinions.putBallot(principals[9], vote_id, { date = 10111; answer =-1.0; }));
    compare(
      opinions.getVote(vote_id).aggregate,
      { left = 2.0; center = 4.5; right = 3.5; },
      Testify.polarization);
  });
  await test("Reveal ballots", func() : async () {
    for (principal in Array.vals(principals)){
      compare(
        opinions.revealBallots(principal, principal, #FWD, 10, null).keys.size(),
        if (principal == principals[0]) 2 else 1,
        Testify.nat);
    };
  });
  await test("Get voter ballots", func() : async () {
    for (principal in Array.vals(principals)){
      compare(
        Map.size(opinions.getVoterBallots(principal)),
        if (principal == principals[0]) 2 else 1,
        Testify.nat);
    };
  });
  
});