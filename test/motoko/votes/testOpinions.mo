import Types          "../../../src/godwin_backend/model/votes/Types";
import Opinions       "../../../src/godwin_backend/model/votes/Opinions";
import Votes          "../../../src/godwin_backend/model/votes/Votes";
import Polarization   "../../../src/godwin_backend/model/votes/representation/Polarization";

import TestifyTypes   "../testifyTypes";
import Principals     "../Principals";

import Map            "mo:map/Map";

import Testify        "mo:testing/Testify";
import SuiteState     "mo:testing/SuiteState";
import TestStatus     "mo:testing/Status";

import Principal      "mo:base/Principal";
import Array          "mo:base/Array";
import Nat            "mo:base/Nat";
import Text           "mo:base/Text";
import Result         "mo:base/Result";

module {

  type NamedTest<T> = SuiteState.NamedTest<T>;
  type Suite<T> = SuiteState.Suite<T>;
  type TestStatus = TestStatus.Status;
  type TestAsync<T> = SuiteState.TestAsync<T>;

  // For convenience: from base module
  type Time = Int;

  type Opinions      = Opinions.Opinions;
  type OpinionBallot = Types.OpinionBallot;
  type OpinionVote   = Types.OpinionVote;
  type Polarization  = Types.Polarization;
  type VoteId        = Types.VoteId;
  type Cursor        = Types.Cursor;

  let { testifyElement; optionalTestify; } = Testify;
  let { describe; itp; equal; itsp; } = SuiteState;

  let { testify_opinion_ballot; testify_nat; testify_polarization; testify_opinion_vote; } = TestifyTypes;

  func asyncEqualOptBallots(
    testify  : Testify.TestifyElement<?OpinionBallot>,
    actual   : (opinions: Opinions) -> async* ?OpinionBallot
  ) : TestAsync<Opinions> = func (opinions : Opinions, print: (t : Text) -> ()) : async* Bool {
    let a = await* actual(opinions);
    let b = testify.equal(testify.element, a);
    if (not b) print("💬 expected: " # testify.toText(testify.element) # ", actual: " # testify.toText(a));
    b;
  };

  func asyncEqualOpinionAggregate(
    testify  : Testify.TestifyElement<Polarization>,
    actual   : (opinions: Opinions) -> async* Polarization
  ) : TestAsync<Opinions> = func (opinions : Opinions, print: (t : Text) -> ()) : async* Bool {
    let a = await* actual(opinions);
    let b = testify.equal(testify.element, a);
    if (not b) print("💬 expected: " # testify.toText(testify.element) # ", actual: " # testify.toText(a));
    b;
  };

  public func run(test_status: TestStatus) : async* () {

    let principals = Principals.init();
    let opinions = Opinions.build(Opinions.initRegister());

    let s = SuiteState.Suite<Opinions>(opinions);

    await* s.run([
      describe("New votes", [
        itp("New vote 0", equal(
          testifyElement(optionalTestify(testify_opinion_vote), ?Votes.initVote<Cursor, Polarization>(0, Polarization.nil())),
          func (opinions: Opinions) : ?OpinionVote { Result.toOption(opinions.findVote(opinions.newVote())); }
        )),
        itp("New vote 1", equal(
          testifyElement(optionalTestify(testify_opinion_vote), ?Votes.initVote<Cursor, Polarization>(1, Polarization.nil())),
          func (opinions: Opinions) : ?OpinionVote { Result.toOption(opinions.findVote(opinions.newVote())); }
        )),
        itp("New vote 2", equal(
          testifyElement(optionalTestify(testify_opinion_vote), ?Votes.initVote<Cursor, Polarization>(2, Polarization.nil())),
          func (opinions: Opinions) : ?OpinionVote { Result.toOption(opinions.findVote(opinions.newVote())); }
        ))
      ]),
      describe("putBallot", [
        itsp("Add ballot", asyncEqualOptBallots(
          testifyElement(optionalTestify(testify_opinion_ballot), ?{ date = 123456789; answer = 0.0; } : ?OpinionBallot),
          func (opinions: Opinions) : async* ?OpinionBallot { 
            let vote_id = 0;
            let ballot : OpinionBallot = { date = 123456789; answer = 0.0; };
            ignore (await* opinions.putBallot(principals[0], vote_id, ballot));
            Result.toOption(opinions.findBallot(principals[0], vote_id));
          }
        )),
        itsp("Update ballot", asyncEqualOptBallots(
          testifyElement(optionalTestify(testify_opinion_ballot), ?{ date = 12121212; answer = 1.0; } : ?OpinionBallot),
          func (opinions: Opinions) : async* ?OpinionBallot { 
            let vote_id = 0;
            let ballot : OpinionBallot = { date = 12121212; answer = 1.0; };
            ignore (await* opinions.putBallot(principals[0], vote_id, ballot));
            Result.toOption(opinions.findBallot(principals[0], vote_id));
          }
        ))
      ]),
      describe("test aggregate", [
        itsp("aggregate vote 1", asyncEqualOpinionAggregate(
          testifyElement(testify_polarization, {left = 2.0; center = 4.5; right = 3.5;}),
          func (opinions: Opinions) : async* Polarization {
            let vote_id = 1;
            ignore (await* opinions.putBallot(principals[0], vote_id, { date = 7714;  answer = 1.0; }));
            ignore (await* opinions.putBallot(principals[1], vote_id, { date = 23271; answer = 0.5; }));
            ignore (await* opinions.putBallot(principals[2], vote_id, { date = 65600; answer = 0.5; }));
            ignore (await* opinions.putBallot(principals[3], vote_id, { date = 68919; answer = 0.5; }));
            ignore (await* opinions.putBallot(principals[4], vote_id, { date = 47827; answer = 0.5; }));
            ignore (await* opinions.putBallot(principals[5], vote_id, { date = 60277; answer = 0.5; }));
            ignore (await* opinions.putBallot(principals[6], vote_id, { date = 64031; answer = 0.0; }));
            ignore (await* opinions.putBallot(principals[7], vote_id, { date = 83560; answer = 0.0; }));
            ignore (await* opinions.putBallot(principals[8], vote_id, { date = 98166; answer =-1.0; }));
            ignore (await* opinions.putBallot(principals[9], vote_id, { date = 10111; answer =-1.0; }));
            opinions.getVote(vote_id).aggregate;
          }
        )),
      ]),
      describe("test revealBallots",
        Array.tabulate(principals.size(), func(index: Nat) : NamedTest<Opinions> {
          let voter = principals[index];
          itp(
            "Get number ballots (via revealBallots) from voter '" # Principal.toText(voter) # "'",
            equal(
              testifyElement(testify_nat, if (index == 0) 2 else 1),
              func (opinions: Opinions) : Nat { 
                opinions.revealBallots(voter, #FWD, 10, null).keys.size();
              }
            )
          );
        })
      ),
      describe("test getVoterBallots",
        Array.tabulate(principals.size(), func(index: Nat) : NamedTest<Opinions> {
          let voter = principals[index];
          itp(
            "Get number ballots (via getVoterBallots) from voter '" # Principal.toText(voter) # "'",
            equal(
              testifyElement(testify_nat, if (index == 0) 2 else 1),
              func (opinions: Opinions) : Nat { 
                Map.size(opinions.getVoterBallots(voter));
              }
            )
          );
        })
      )
    ]);

    test_status.add(s.getStatus());
  };

};