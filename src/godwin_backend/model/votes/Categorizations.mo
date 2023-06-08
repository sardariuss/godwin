import Types               "Types";
import Votes               "Votes";
import VotePolicy          "VotePolicy";
import PayToVote           "PayToVote";

import PayRules            "../PayRules";
import PolarizationMap     "representation/PolarizationMap";
import CursorMap           "representation/CursorMap";
import PayForElement       "../token/PayForElement";
import PayTypes            "../token/Types";
import Categories          "../Categories";

import Map                 "mo:map/Map";

module {

  type Map<K, V>              = Map.Map<K, V>;

  type Categories             = Categories.Categories;
  
  type VoteId                 = Types.VoteId;
  type CursorMap              = Types.CursorMap;
  type PolarizationMap        = Types.PolarizationMap;

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
    transactions_register: Map<Principal, Map<VoteId, TransactionsRecord>>,
    token_interface: ITokenInterface,
    categories: Categories,
    pay_rules: PayRules
  ) : Categorizations {
    Votes.Votes<CursorMap, PolarizationMap>(
      vote_register,
      VotePolicy.VotePolicy<CursorMap, PolarizationMap>(
        #BALLOT_CHANGE_FORBIDDEN,
        func(cursor_map: CursorMap) : Bool { CursorMap.isValid(cursor_map, categories); },
        PolarizationMap.addCursorMap,
        PolarizationMap.subCursorMap,
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
      )
    );
  };

};