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
  type Polarization       = Types.Polarization;
  type PolarizationMap    = Types.PolarizationMap;
  type Decay              = Types.Decay; 
  type UserHistory        = Types.UserHistory;
  type StatusInfo         = Types.StatusInfo;
  type StatusHistory      = Types.StatusHistory;
  type StatusData         = Types.StatusData;

  public func build(
    status_history: Map<Nat, StatusHistory>,
    interests_history_: Map2D<Nat, Nat, InterestVote>,
    opinons_history_: Map2D<Nat, Nat, OpinionVote>,
    categorizations_history_: Map2D<Nat, Nat, CategorizationVote>,
    user_history: Map<Principal, UserHistory>,
    half_life: ?Duration,
    date_init: Time,
    categories: Categories
  ) : History {
    History(
      WMap.WMap(status_history, Map.nhash),
      WMap.WMap2D(interests_history_, Map.nhash, Map.nhash),
      WMap.WMap2D(opinons_history_, Map.nhash, Map.nhash),
      WMap.WMap2D(categorizations_history_, Map.nhash, Map.nhash),
      WMap.WMap(user_history, Map.phash),
      categories,
      Decay.computeOptDecay(date_init, half_life)
    );
  };

  public func unwrapStatus(status_data: StatusData) : Status {
    switch(status_data){
      case(#CANDIDATE(_)) { #CANDIDATE; };
      case(#OPEN(_))      { #OPEN;      };
      case(#CLOSED(_))    { #CLOSED;    };
      case(#REJECTED(_))  { #REJECTED;  };
      case(#TRASH(_))     { #TRASH;     };
    };
  };
  
  public class History(
    status_history_: WMap.WMap<Nat, StatusHistory>,
    interests_history_: WMap.WMap2D<Nat, Nat, InterestVote>,
    opinons_history_: WMap.WMap2D<Nat, Nat, OpinionVote>,
    categorizations_history_: WMap.WMap2D<Nat, Nat, CategorizationVote>,
    user_history_: WMap.WMap<Principal, UserHistory>,
    categories_: Categories,
    decay_params_: ?Decay
  ) {

    public func getDecay() : ?Decay {
      decay_params_;
    };

    public func getStatusHistory(question_id: Nat) : ?StatusHistory {
      status_history_.getOpt(question_id);
    };

    public func getInterestVote(question_id: Nat, iteration: Nat) : ?InterestVote {
      interests_history_.getOpt(question_id, iteration);
    };

    public func getOpinionVote(question_id: Nat, iteration: Nat) : ?OpinionVote {
      opinons_history_.getOpt(question_id, iteration);
    };

    public func getCategorizationVote(question_id: Nat, iteration: Nat) : ?CategorizationVote {
      categorizations_history_.getOpt(question_id, iteration);
    };

    public func getStatusIteration(question_id: Nat, status: Status) : Nat {
      Option.getMapped(
        status_history_.getOpt(question_id),
        func(history: StatusHistory) : Nat {
          Option.getMapped(Map.get(history, Status.status_hash, status), func(timestamps: [Time]) : Nat { timestamps.size(); }, 0);
        },
        0
      );
    };

    public func getUserConvictions(principal: Principal) : ?PolarizationMap {
      Option.map(user_history_.getOpt(principal), func(history: UserHistory) : PolarizationMap { history.convictions; });
    };
    
    public func getUserVotes(principal: Principal) : ?Set<VoteId> {
      Option.map(user_history_.getOpt(principal), func(history: UserHistory) : Set<VoteId> { history.votes; });
    };

    public func removeCategory(category: Category) {
      user_history_.forEach(func(principal, user_history) {
        user_history_.set(principal, { user_history with convictions = Trie.remove(user_history.convictions, Categories.key(category), Categories.equal).0 });
      });
    };

    public func addCategory(category: Category) {
      user_history_.forEach(func(principal, user_history) {
        user_history_.set(principal, { user_history with convictions = Trie.put(user_history.convictions, Categories.key(category), Categories.equal, Polarization.nil()).0 });
      });
    };

    public func add(question_id: Nat, status_info: StatusInfo, status_data: StatusData) {
      // Assert the status data matches with the status info
      if(unwrapStatus(status_data) != status_info.status) {
        Debug.trap("Given info and data don't correspond to the same status");
      };
      // Add the iteration to the question status history
      // @todo: have a generic map of arrays
      let history = Option.get(status_history_.getOpt(question_id), Map.new<Status, [Time]>());
      var iterations = Option.get(Map.get(history, Status.status_hash, status_info.status), []);
      let current_iteration = iterations.size();
      iterations := Utils.append<Time>(iterations, [status_info.date]);
      Map.set(history, Status.status_hash, status_info.status, iterations);
      status_history_.set(question_id, history);
      // Add the status data to the history
      switch(status_data){
        case(#CANDIDATE({vote_interest;})) {
          // Add the vote to vote the history
          interests_history_.set(question_id, current_iteration, vote_interest);
        };
        case(#OPEN({vote_opinion; vote_categorization;})) {
          // Add the votes to vote the histories
          opinons_history_.set(question_id, current_iteration, vote_opinion);
          categorizations_history_.set(question_id, current_iteration, vote_categorization);
          // Add the ballots to the user history
          addUserBallots(question_id, current_iteration, vote_opinion.ballots);
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
        case(_) {};
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