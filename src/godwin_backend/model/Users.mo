import Types           "Types";
import Status          "Status";
import Categories      "Categories";
import Decay           "Decay";
import Votes2          "votes/Votes2";
import Opinions        "votes/Opinions";
import Categorizations "votes/Categorizations";
import Interests       "votes/Interests";
import Polarization    "votes/representation/Polarization";
import Cursor          "votes/representation/Cursor";
import PolarizationMap "votes/representation/PolarizationMap";

import Utils           "../utils/Utils";
import WMap            "../utils/wrappers/WMap";
import Duration        "../utils/Duration";

import Map             "mo:map/Map";
import Set             "mo:map/Set";

import Debug           "mo:base/Debug";
import Iter            "mo:base/Iter";
import Option          "mo:base/Option";
import Float           "mo:base/Float";
import Principal       "mo:base/Principal";
import Trie            "mo:base/Trie";

module {

  // For convenience: from base module
  type Time               = Int;
  type Iter<T>            = Iter.Iter<T>;

  // For convenience: from map module
  type Map<K, V>          = Map.Map<K, V>;
  type Map2D<K1, K2, V>   = Map<K1, Map<K2, V>>;
  type WMap<K, V>         = WMap.WMap<K, V>;
  type WMap2D<K1, K2, V>  = WMap.WMap2D<K1, K2, V>;
  type Set<K>             = Set.Set<K>;

  // For convenience: from other modules
  type Categories         = Categories.Categories;
  type Duration           = Duration.Duration;
  type InterestVote       = Interests.Vote;
  type OpinionVote        = Opinions.Vote;
  type CategorizationVote = Categorizations.Vote;
  type OpinionBallot      = Opinions.Ballot;

  // For convenience: from types module
  type Question           = Types.Question;
  type Status             = Types.Status;
  type VoteId             = Types.VoteId;
  type Category           = Types.Category;
  type Cursor             = Types.Cursor;
  type CursorMap          = Types.CursorMap;
  type Polarization       = Types.Polarization;
  type PolarizationMap    = Types.PolarizationMap;
  type Decay              = Types.Decay; 
  type UserHistory        = Types.UserHistory;
  type StatusInfo         = Types.StatusInfo;
  type StatusHistory      = Types.StatusHistory;
  type StatusData         = Types.StatusData;
  type Vote<T, A>         = Types.Vote<T, A>;

  type User = {
    convictions: PolarizationMap;
    interest_votes: Set<Nat>;
    opinion_votes: Set<Nat>;
    categorization_votes: Set<Nat>;
  };

  public func build(
    register: Map.Map<Principal, User>,
    opinion_votes: Votes2.Votes2<Cursor, Polarization>,
    categorization_votes: Votes2.Votes2<CursorMap, PolarizationMap>,
    categories: Categories,
    half_life: ?Duration,
    date_init: Time,
  ) : Users {
    Users(
      WMap.WMap(register, Map.phash),
      opinion_votes,
      categorization_votes,
      categories,
      Decay.computeOptDecay(date_init, half_life)
    );
  };

  public class Users(
    register_: WMap.WMap<Principal, User>,
    opinion_votes_: Votes2.Votes2<Cursor, Polarization>,
    categorization_votes_: Votes2.Votes2<CursorMap, PolarizationMap>,
    categories_: Categories,
    decay_params_: ?Decay
  ) {

    public func getDecay() : ?Decay {
      decay_params_;
    };

    public func update(question_id: Nat, vote_opinion_id: Nat, vote_categorization_id: Nat) {
      let vote_opinion = switch(opinion_votes_.findVote(vote_opinion_id)){
        case (null) { Debug.trap("Opinion vote not found"); };
        case (?vote) { vote };
      };
      let vote_categorization = switch(categorization_votes_.findVote(vote_categorization_id)){
        case (null) { Debug.trap("Categorization vote not found"); };
        case (?vote) { vote };
      };
      // Update the user convictions: add the new opinion vote
      updateUserConvictions(question_id, vote_opinion.ballots, vote_categorization.aggregate, null);
      // Update the user convictions: update the old opinion votes
      if (current_iteration > 0){
        let previous_vote_categorization = categorizations_history_.get(question_id, current_iteration - 1);
        for (iteration in Iter.range(0, current_iteration - 1)) {
          let old_vote_opinion = opinons_history_.get(question_id, iteration);
          updateUserConvictions(question_id, old_vote_opinion.ballots, vote_categorization.aggregate, ?previous_vote_categorization.aggregate);
        };
      };
    };

    func getUserHistory(principal: Principal) : UserHistory {
      Option.get(user_history_.getOpt(principal), {
        votes = Set.new<VoteId>();
        convictions = PolarizationMap.nil(categories_);
      });
    };

    func addUserBallots(question_id: Nat, index: Nat, opinion_ballots: Map<Principal, OpinionBallot>) {
      for ((principal, {answer; date;}) in Map.entries(opinion_ballots)){
        var user_history = getUserHistory(principal);
        Set.add(user_history.votes, Votes.votehash, (question_id, index));
      };
    };

    func updateUserConvictions(
      question_id: Nat,
      opinion_ballots: Map<Principal, OpinionBallot>,
      new_categorization: PolarizationMap,
      previous_categorization: ?PolarizationMap
    ) {
      // Process old votes by removing removing the contribution of the previous categorization 
      // and adding the contribution of the new categorization
      for ((principal, {answer; date;}) in Map.entries(opinion_ballots)){
        var user_history = getUserHistory(principal);
        user_history := { user_history with convictions = updateBallotContribution(user_history.convictions, answer, date, new_categorization, previous_categorization); };
        user_history_.set(principal, user_history);
      };
    };

    // \note To compute the users convictions, the user's opinion (cursor converted into a polarization)
    // is multiplied by the categorization (polarization converted into a cursor)
    // This is done for every category using a trie of polarization initialized with the opinion.
    // The PolarizationMap.mul uses a leftJoin, so that the resulting convictions contains
    // only the categories from the definitions.
    func updateBallotContribution(
      convictions: PolarizationMap,
      user_opinion: Cursor,
      date: Int,
      new_categorization: PolarizationMap,
      old_categorization: ?PolarizationMap)
    : PolarizationMap 
    {
      // Create a Polarization trie from the cursor, based on given categories.
      let opinion_trie = Utils.make(categories_.keys(), Categories.key, Categories.equal, Cursor.toPolarization(user_opinion));

      // Compute the decay coefficient
      let decay_coef = Option.getMapped(decay_params_, func(params: Decay) : Float { Float.exp(Float.fromInt(date) * params.lambda - params.shift); }, 1.0);

      // Add the opinion times new categorization.
      var contribution = PolarizationMap.mul(
        PolarizationMap.mulCursorMap(opinion_trie, PolarizationMap.toCursorMap(new_categorization)),
        decay_coef);

      // Remove the opinion times old categorization if any.
      Option.iterate(old_categorization, func(old_cat: PolarizationMap) {
        let old_contribution = PolarizationMap.mul(
          PolarizationMap.mulCursorMap(opinion_trie, PolarizationMap.toCursorMap(old_cat)),
          decay_coef);
        contribution := PolarizationMap.sub(contribution, old_contribution);
      });

      PolarizationMap.add(convictions, contribution);
    };

  };

};