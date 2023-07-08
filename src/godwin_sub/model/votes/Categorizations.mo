import Types               "Types";
import Votes               "Votes";
import VotePolicy          "VotePolicy";
import PayToVote           "PayToVote";
import PolarizationMap     "representation/PolarizationMap";
import CursorMap           "representation/CursorMap";
import VotersHistory       "VotersHistory";
import PayForElement       "../token/PayForElement";
import PayTypes            "../token/Types";
import PayRules            "../PayRules";
import Categories          "../Categories";

import Map                 "mo:map/Map";

module {

  type Map<K, V>              = Map.Map<K, V>;

  type Categories             = Categories.Categories;
  type VotersHistory          = VotersHistory.VotersHistory;
  type VoteId                 = Types.VoteId;
  type CursorMap              = Types.CursorMap;
  type PolarizationMap        = Types.PolarizationMap;
  type CategorizationBallot   = Types.CategorizationBallot;
  type DecayParameters        = Types.DecayParameters;
  type TransactionsRecord     = PayTypes.TransactionsRecord;
  type ITokenInterface        = PayTypes.ITokenInterface;
  type PayoutArgs             = PayTypes.PayoutArgs;
  type PayRules               = PayRules.PayRules;

  public type Register        = Votes.Register<CursorMap, PolarizationMap>;

  public type Categorizations = Votes.Votes<CursorMap, PolarizationMap>;

  public func initRegister() : Register {
    Votes.initRegister<CursorMap, PolarizationMap>();
  };

  public func build(
    vote_register: Votes.Register<CursorMap, PolarizationMap>,
    voters_history: VotersHistory,
    transactions_register: Map<Principal, Map<VoteId, TransactionsRecord>>,
    token_interface: ITokenInterface,
    categories: Categories,
    pay_rules: PayRules,
    decay_params: DecayParameters
  ) : Categorizations {
    Votes.Votes<CursorMap, PolarizationMap>(
      vote_register,
      voters_history,
      VotePolicy.VotePolicy<CursorMap, PolarizationMap>(
        #BALLOT_CHANGE_FORBIDDEN,
        func(cursor_map: CursorMap) : Bool { CursorMap.isValid(cursor_map, categories); },
        addCategorizationBallot,
        removeCategorizationBallot,
        PolarizationMap.nil(categories)
      ),
      ?PayToVote.PayToVote<CursorMap, PolarizationMap>(
        PayForElement.build(
          transactions_register,
          token_interface,
          #PUT_CATEGORIZATION_BALLOT,
        ),
        pay_rules.getCategorizationVotePrice(),
        pay_rules.computeCategorizationPayout
      ),
      decay_params,
      #REVEAL_BALLOT_VOTE_CLOSED
    );
  };

  func addCategorizationBallot(polarization: PolarizationMap, ballot: CategorizationBallot) : PolarizationMap {
    PolarizationMap.addCursorMap(polarization, ballot.answer);
  };

  func removeCategorizationBallot(polarization: PolarizationMap, ballot: CategorizationBallot) : PolarizationMap {
    PolarizationMap.subCursorMap(polarization, ballot.answer);
  };

};