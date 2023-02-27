import Types "Types";
import Utils "../utils/Utils";
import WMap "../utils/wrappers/WMap";
import Status "Status";
import Categories "Categories";
import Votes "votes/Votes";
import Polarization "votes/representation/Polarization";
import Cursor "votes/representation/Cursor";
import PolarizationMap "votes/representation/PolarizationMap";
import Opinions "votes/Opinions";
import Categorizations "votes/Categorizations";
import Decay "Decay";
import Duration "../utils/Duration";

import Map "mo:map/Map";
import Set "mo:map/Set";

import Debug "mo:base/Debug";
import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";
import Option "mo:base/Option";
import Array "mo:base/Array";
import Float "mo:base/Float";
import Principal "mo:base/Principal";
import Trie "mo:base/Trie";

module {

  // For convenience: from base module
  type Time = Int;
  type Buffer<T> = Buffer.Buffer<T>;
  type Iter<T> = Iter.Iter<T>;

  // For convenience: from map module
  type Map<K, V> = Map.Map<K, V>;
  type WMap<K, V> = WMap.WMap<K, V>;
  type Set<K> = Set.Set<K>;

  // For convenience: from types module
  type Categories = Categories.Categories;
  type Question = Types.Question;
  type Status = Types.Status;
  type StatusRecord = Types.StatusRecord;
  type StatusHistory = Types.StatusHistory;
  type VoteId = Types.VoteId;
  type Duration = Duration.Duration;
  type Category = Types.Category;
  type Cursor = Types.Cursor;
  type Polarization = Types.Polarization;
  type PolarizationMap = Types.PolarizationMap;
  type Decay = Types.Decay;
  type Categorizations = Categorizations.Categorizations;
  type Opinions = Opinions.Opinions;
  type CategorizationVote = Categorizations.Vote;
  type OpinionVote = Opinions.Vote;
  type UserHistory = Types.UserHistory;

  public func build(
    status_history: Map.Map<Nat, StatusHistory>,
    user_history: Map.Map<Principal, UserHistory>,
    half_life: ?Duration,
    date_init: Time,
    categories: Categories
  ) : History {
    History(WMap.WMap(status_history, Map.nhash), WMap.WMap(user_history, Map.phash), categories, Decay.computeOptDecay(date_init, half_life));
  };

  public func toStatus(status_record: StatusRecord) : Status {
    switch(status_record){
      case(#CANDIDATE(_)) { #CANDIDATE; };
      case(#OPEN(_))      { #OPEN; };
      case(#CLOSED(_))    { #CLOSED; };
      case(#REJECTED(_))  { #REJECTED; };
      case(#TRASH(_))     { #TRASH; };
    };
  };
  
  public class History(
    status_history_: WMap.WMap<Nat, StatusHistory>,
    user_history_: WMap.WMap<Principal, UserHistory>,
    categories_: Categories,
    decay_params_: ?Decay
  ) {

    public func getDecay() : ?Decay {
      decay_params_;
    };

    public func getStatusHistory(question_id: Nat) : ?StatusHistory {
      status_history_.get(question_id);
    };

    public func getStatusIndex(question_id: Nat, status: Status) : Nat {
      Option.getMapped(
        status_history_.get(question_id),
        func(history: StatusHistory) : Nat {
          Option.get(Map.get(history.records, Status.status_hash, status), []).size();
        },
        0
      );
    };

    public func findUserHistory(principal: Principal, categories: Categories) : ?UserHistory {
      if (Principal.isAnonymous(principal)){
        null;
      } else {
        ?getUserHistory(principal, categories);
      };
    };

    public func getUserHistory(principal: Principal, categories: Categories) : UserHistory {
      if (Principal.isAnonymous(principal)){
        Debug.trap("User's principal cannot be anonymous.");
      };
      switch (user_history_.get(principal)){
        case(?history) { history; };
        case(null) {
          {
            ballots = Set.new<VoteId>();
            convictions = PolarizationMap.nil(categories);
          };
        };
      };
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

    public func add(question_id: Nat, status_record: StatusRecord) {
      let history = Option.get(status_history_.get(question_id), { records = Map.new<Status, [StatusRecord]>(); timeline = []; });
      let status = toStatus(status_record);
      // Add to the records
      let status_records = Buffer.fromArray<StatusRecord>(Option.get(Map.get(history.records, Status.status_hash, status), []));
      // Update the users convictions if needed
      switch(status_record){
        case(#OPEN({vote_opinion; vote_categorization;})){
          let new_categorization = vote_categorization.aggregate;
          let previous_categorization = Option.map(status_records.getOpt(status_records.size() - 1), func(status_record2: StatusRecord) : PolarizationMap {
            switch(status_record2){
              case(#OPEN({vote_categorization; vote_opinion;})) { vote_categorization.aggregate; };
              case(_) { Debug.trap("@todo"); };
            };
          });
          let new_opinion_ballots = vote_opinion.ballots;
          let old_opinion_ballots = Buffer.map<StatusRecord, Map<Principal, Types.Ballot<Cursor>>>(status_records, func (status_record2: StatusRecord) : Map<Principal, Types.Ballot<Cursor>> {
            switch(status_record2){
              case(#OPEN({vote_categorization; vote_opinion;})) { vote_opinion.ballots; };
              case(_) { Debug.trap("@todo"); };
            };
          });
          onVoteClosed(question_id, previous_categorization, new_categorization, old_opinion_ballots.vals(), new_opinion_ballots);
        };
        case(_) {
        };
      };
      status_records.add(status_record);
      Map.set(history.records, Status.status_hash, status, Buffer.toArray(status_records));
      // Add to the timeline
      let timeline = Buffer.fromArray<(Status, Nat)>(history.timeline);
      timeline.add((status, status_records.size() - 1));
      // Update the history
      status_history_.set(question_id, {records = history.records; timeline = Buffer.toArray(timeline)});
    };

    // Watchout: this function makes a strong assumption that it is called only once every time the question status transitions from #OPEN to #CLOSED
    func onVoteClosed(
      question_id: Nat,
      previous_categorization: ?PolarizationMap,
      new_categorization: PolarizationMap,
      old_opinions_ballots: Iter<Map<Principal, Types.Ballot<Cursor>>>,
      new_opinion_ballots: Map<Principal, Types.Ballot<Cursor>>) 
    {
      // Process old votes by removing removing the contribution of the previous categorization 
      // and adding the contribution of the new categorization
      for (old_vote in old_opinions_ballots){
        for ((principal, {answer; date;}) in Map.entries(old_vote)){
          var user_history = getUserHistory(principal, categories_);
          user_history := { user_history with convictions = updateBallotContribution(user_history.convictions, answer, date, new_categorization, previous_categorization); };
          user_history_.set(principal, user_history);
        };
      };

      // Process new votes
      Iter.iterate<(Principal, Types.Ballot<Cursor>)>(Map.entries(new_opinion_ballots), func((principal, {answer; date;}), index) {
        var user_history = getUserHistory(principal, categories_);
        Set.add(user_history.ballots, Votes.votehash, (question_id, index));
        user_history := { user_history with
          convictions = updateBallotContribution(user_history.convictions, answer, date, new_categorization, null);
        };
        user_history_.set(principal, user_history);
      });
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