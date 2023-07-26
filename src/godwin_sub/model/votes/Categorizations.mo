import Types               "Types";
import Votes               "Votes";
import PayToVote           "PayToVote";
import PolarizationMap     "representation/PolarizationMap";
import CursorMap           "representation/CursorMap";
import PayForElement       "../token/PayForElement";
import PayTypes            "../token/Types";
import PayRules            "../PayRules";
import Categories          "../Categories";

import UtilsTypes          "../../utils/Types";

import Map                 "mo:map/Map";

import Result              "mo:base/Result";
import Option              "mo:base/Option";

module {

  type Result<Ok, Err>        = Result.Result<Ok, Err>;
  type Time                   = Int;
  type Map<K, V>              = Map.Map<K, V>;

  type Categories             = Categories.Categories;
  type VoteId                 = Types.VoteId;
  type CursorMap              = Types.CursorMap;
  type PolarizationMap        = Types.PolarizationMap;
  type VoteStatus             = Types.VoteStatus;
  type Ballot                 = Types.CategorizationBallot;
  type Vote                   = Types.CategorizationVote;
  type IVotePolicy            = Types.IVotePolicy<CursorMap, PolarizationMap>;
  type IVotersHistory         = Types.IVotersHistory;
  type TransactionsRecord     = PayTypes.TransactionsRecord;
  type ITokenInterface        = PayTypes.ITokenInterface;
  type PayoutArgs             = PayTypes.PayoutArgs;
  type PayRules               = PayRules.PayRules;

  type ScanLimitResult<K>     = UtilsTypes.ScanLimitResult<K>;
  type Direction              = UtilsTypes.Direction;

  type GetVoteError           = Types.GetVoteError;
  type RevealVoteError        = Types.RevealVoteError;
  type FindBallotError        = Types.FindBallotError;
  type PutBallotError         = Types.PutBallotError;
  type RevealedBallot<T>      = Types.RevealedBallot<T>;

  public type Register        = Votes.Register<CursorMap, PolarizationMap>;
  public type Categorizations = Votes.Votes<CursorMap, PolarizationMap>;

  public func initRegister() : Register {
    Votes.initRegister<CursorMap, PolarizationMap>();
  };

  public func build(
    vote_register: Votes.Register<CursorMap, PolarizationMap>,
    voters_history: IVotersHistory,
    transactions_register: Map<Principal, Map<VoteId, TransactionsRecord>>,
    token_interface: ITokenInterface,
    categories: Categories,
    pay_rules: PayRules
  ) : Categorizations {
    Votes.Votes<CursorMap, PolarizationMap>(
      vote_register,
      voters_history,
      VotePolicy(categories),
      ?PayToVote.PayToVote<CursorMap, PolarizationMap>(
        PayForElement.build(
          transactions_register,
          token_interface,
          #PUT_CATEGORIZATION_BALLOT,
        ),
        pay_rules.getCategorizationVotePrice(),
        pay_rules.computeCategorizationPayout
      )
    );
  };

  class VotePolicy(
    _categories: Categories
  ) : IVotePolicy {

    public func canPutBallot(vote: Vote, principal: Principal, ballot: Ballot) : Result<(), PutBallotError> {
      // Verify the user did not vote already
      if (Option.isSome(Map.get(vote.ballots, Map.phash, principal))){
        return #err(#ChangeBallotNotAllowed);
      };
      // Verify the ballot is valid
      if (not CursorMap.isValid(ballot.answer, _categories)){
        return #err(#InvalidBallot);
      };
      #ok;
    };

    public func emptyAggregate(date: Time) : PolarizationMap {
      PolarizationMap.nil(_categories);
    };

    public func addToAggregate(aggregate: PolarizationMap, new_ballot: Ballot, old_ballot: ?Ballot) : PolarizationMap {
      var polarization_map = aggregate;
      // Add the new ballot to the polarization
      polarization_map := PolarizationMap.addCursorMap(polarization_map, new_ballot.answer);
      // If there was an old ballot, remove it from the polarization
      Option.iterate(old_ballot, func(ballot: Ballot) {
        polarization_map := PolarizationMap.subCursorMap(polarization_map, ballot.answer);
      });
      polarization_map;
    };

    public func onStatusChanged(status: VoteStatus, aggregate: PolarizationMap, date: Time) : PolarizationMap {
      aggregate;
    };

    public func canRevealBallot(vote: Vote, caller: Principal, voter: Principal) : Bool {
      vote.status != #OPEN or caller == voter;
    };
  };

};