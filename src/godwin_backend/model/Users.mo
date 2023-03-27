import Types           "Types";
import Status          "Status";
import Categories      "Categories";
import Decay           "Decay";
import Votes           "votes/Votes";
import Opinions        "votes/Opinions";
import Categorizations "votes/Categorizations";
import Interests       "votes/Interests";
import Polarization    "votes/representation/Polarization";
import Cursor          "votes/representation/Cursor";
import PolarizationMap "votes/representation/PolarizationMap";
import QuestionVoteHistory "QuestionVoteHistory";

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
import Array           "mo:base/Array";

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
  type QuestionVoteHistory = QuestionVoteHistory.QuestionVoteHistory;
  type Votes<T, A>        = Votes.Votes<T, A>;
  type Vote<T, A>        = Types.Vote<T, A>;

  // For convenience: from types module
  type Question           = Types.Question;
  type Status             = Types.Status;
  type Category           = Types.Category;
  type Cursor             = Types.Cursor;
  type Polarization       = Types.Polarization;
  type CursorMap          = Types.CursorMap;
  type PolarizationMap    = Types.PolarizationMap;
  type Decay              = Types.Decay; 
  type User               = Types.User;
  type StatusInfo         = Types.StatusInfo;
  type StatusHistory      = Types.StatusHistory;
  type StatusData         = Types.StatusData;


  public func build(
    users: Map<Principal, User>,
    opinion_history: QuestionVoteHistory,
    opinion_votes: Votes<Cursor, Polarization>,
    categorization_history: QuestionVoteHistory,
    categorization_votes: Votes<CursorMap, PolarizationMap>,
    half_life: ?Duration,
    date_init: Time,
    categories: Categories
  ) : Users {
    Users(
      WMap.WMap(users, Map.phash),
      opinion_history,
      opinion_votes,
      categorization_history,
      categorization_votes,
      categories,
      Decay.computeOptDecay(date_init, half_life)
    );
  };
  
  public class Users(
    _users: WMap.WMap<Principal, User>,
    _opinion_history: QuestionVoteHistory,
    _opinion_votes: Votes<Cursor, Polarization>,
    _categorization_history: QuestionVoteHistory,
    _categorization_votes: Votes<CursorMap, PolarizationMap>,
    _categories: Categories,
    _decay_params: ?Decay
  ) {

    public func getDecay() : ?Decay {
      _decay_params;
    };

    public func getUserConvictions(principal: Principal) : ?PolarizationMap {
      Option.map(_users.getOpt(principal), func(history: User) : PolarizationMap { history.convictions; });
    };
    
    public func getUserOpinions(principal: Principal) : ?Set<Nat> {
      Option.map(_users.getOpt(principal), func(history: User) : Set<Nat> { history.opinions; });
    };

    public func removeCategory(category: Category) {
      _users.forEach(func(principal, user) {
        _users.set(principal, { user with convictions = Trie.remove(user.convictions, Categories.key(category), Categories.equal).0 });
      });
    };

    public func addCategory(category: Category) {
      _users.forEach(func(principal, user) {
        _users.set(principal, { user with convictions = Trie.put(user.convictions, Categories.key(category), Categories.equal, Polarization.nil()).0 });
      });
    };

    public func onClosingQuestion(question_id: Nat) {
      // Get the last votes
      let vote_opinion = _opinion_votes.getVote(
        switch(_opinion_history.getCurrentVote(question_id)){
          case(?vote_id) { vote_id };
          case(null) { Debug.trap("@todo"); };
        });
      let vote_categorization = _categorization_votes.getVote(
        switch(_categorization_history.getCurrentVote(question_id)){
          case(?vote_id) { vote_id };
          case(null) { Debug.trap("@todo"); };
        });
      // Add the ballots to the user history
      addUserBallots(question_id, vote_opinion.ballots);
      // Update the user convictions: add the last opinion vote
      updateUserConvictions(question_id, vote_opinion.ballots, vote_categorization.aggregate, null);

      let previous_categorization = Option.map(_categorization_history.findPreviousVote(question_id), func(vote_id: Nat) : Vote<CursorMap, PolarizationMap> {
        _categorization_votes.getVote(vote_id);
      });

      switch(previous_categorization) {
        case (null) {};
        case (?old_categorization) {
          // Update the old opinion votes
          let opinion_history = _opinion_history.getHistoricalVotes(question_id);
          for (vote_id in Array.vals(opinion_history)) {
            let old_vote_opinion = _opinion_votes.getVote(vote_id);
            updateUserConvictions(question_id, old_vote_opinion.ballots, vote_categorization.aggregate, ?old_categorization.aggregate);
          };
        };
      };
    };

    func getUser(principal: Principal) : User {
      Option.get(_users.getOpt(principal), {
        opinions = Set.new<Nat>();
        convictions = PolarizationMap.nil(_categories);
      });
    };

    func addUserBallots(vote_id: Nat, opinion_ballots: Map<Principal, OpinionBallot>) {
      for ((principal, {answer; date;}) in Map.entries(opinion_ballots)){
        var user = getUser(principal);
        Set.add(user.opinions, Map.nhash, vote_id);
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
        var user = getUser(principal);
        user := { user with convictions = updateBallotContribution(user.convictions, answer, date, new_categorization, previous_categorization); };
        _users.set(principal, user);
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
      let opinion_trie = Utils.make(_categories.keys(), Categories.key, Categories.equal, Cursor.toPolarization(user_opinion));

      // Compute the decay coefficient
      let decay_coef = Option.getMapped(_decay_params, func(params: Decay) : Float { Float.exp(Float.fromInt(date) * params.lambda - params.shift); }, 1.0);

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