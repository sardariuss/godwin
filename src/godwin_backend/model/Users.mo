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
import CursorMap       "votes/representation/CursorMap";
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
import Buffer          "mo:base/Buffer";

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
      Option.map(_users.getOpt(principal), func(user: User) : PolarizationMap { user.convictions; });
    };
    
    public func getUserOpinions(principal: Principal) : ?[Opinions.Ballot] {
      Option.map(_users.getOpt(principal), func(user: User) : [Opinions.Ballot] {
        let ballots = Buffer.Buffer<Opinions.Ballot>(Set.size(user.opinions));
        for(vote_id in Set.keys(user.opinions)) {
          switch(Map.get(_opinion_votes.getVote(vote_id).ballots, Map.phash, principal)){
            case(?ballot) { ballots.add(ballot); };
            case(null) { Debug.trap("Ballot not found"); };
          };
        };
        Buffer.toArray(ballots);
      });
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
      addUserBallots(vote_opinion.id, vote_opinion.ballots);
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
    : PolarizationMap {
      
      // Compute the decay coefficient.
      let decay_coef = switch(_decay_params){
        case(null) { 1.0; };
        case(?params) { Float.exp(Float.fromInt(date) * params.lambda - params.shift); };
      };

      // Add the contribution of the current categorization.
      var contribution = PolarizationMap.mul(computeContribution(user_opinion, new_categorization, date), decay_coef);

      // Remove the contribution of the previous categorization if any.
      Option.iterate(old_categorization, func(old_cat: PolarizationMap) {
        let old_contribution = PolarizationMap.mul(computeContribution(user_opinion, old_cat, date), decay_coef);
        contribution := PolarizationMap.sub(contribution, old_contribution);
      });

      // Add the resulting contribution to the user's convictions.
      PolarizationMap.add(convictions, contribution);
    };
  
    func computeContribution(
      user_opinion: Cursor,
      categorization: PolarizationMap,
      date: Int  
    ) : PolarizationMap {

      // Example to compute the shift in convictions
      //   cursor: 0.5
      //   categorization:
      //     identity: [left: 100, center:0,   right:0 ]
      //     economy:  [left: 10,  center:30,  right:60]
      //     culture:  [left: 0,   center:100, right:0 ]

      // 1. Transform the opinion cursor into a vector of cursors
      // 0.5 -> [0.5]
      //        [0.5]
      //        [0.5]

      let opinion_cursors = Utils.make(_categories.keys(), Categories.key, Categories.equal, user_opinion);

      // 2. Transform the categorization into a vector of cursors
      // 
      // [left: 100, center:0,   right:0 ]    [-1.0]
      // [left: 10,  center:30,  right:60] -> [0.5 ]
      // [left: 0,   center:100, right:0 ]    [0   ]

      let categorization_cursors = PolarizationMap.toCursorMap(categorization);

      // 3. Multiply the cursors together
      // 
      // [-1.0]   [0.5]   [-0.5]
      // [0.5 ] * [0.5] = [0.25]
      // [0   ]   [0.5]   [0   ]
      let cursor_shift = CursorMap.leftMultiply(categorization_cursors, opinion_cursors);
      
      // 4. Transform back the resulting cursors into polarizations
      //   
      //   [-0.5] -> [left: 0.5, center:0.5,  right:0.0 ]
      //   [0.25]    [left: 0,   center:0.25, right:0.25]
      //   [0   ]    [left: 0,   center:0,    right:0   ]
      //
      CursorMap.toPolarizationMap(cursor_shift);
    };

  };

};