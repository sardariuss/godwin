import Types "Types";
import Votes "votes/Votes";
import Polarization "votes/representation/Polarization";
import Cursor "votes/representation/Cursor";
import PolarizationMap "votes/representation/PolarizationMap";
import Opinions "votes/Opinions";
import Categorizations "votes/Categorizations";
import Categories "Categories";
import Utils "../utils/Utils";
import WMap "../utils/wrappers/WMap";
import Decay "Decay";

import Map "mo:map/Map";
import Set "mo:map/Set";

import Trie "mo:base/Trie";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Debug "mo:base/Debug";
import Option "mo:base/Option";
import Array "mo:base/Array";
import Float "mo:base/Float";
import TrieSet "mo:base/TrieSet";
import Iter "mo:base/Iter";
import Buffer "mo:base/Buffer";

module {

  // For convenience: from base module
  type Time = Int;
  type Trie<K, V> = Trie.Trie<K, V>;
  type Principal = Principal.Principal;

  type Map<K, V> = Map.Map<K, V>;
  type Set<K> = Set.Set<K>;

  // For convenience: from types module
  type User = Types.User;
  type VoteId = Types.VoteId;
  type Duration = Types.Duration;
  type Question = Types.Question;
  type Category = Types.Category;
  type Categories = Categories.Categories;
  type Cursor = Types.Cursor;
  type Polarization = Types.Polarization;
  type PolarizationMap = Types.PolarizationMap;
  type Decay = Types.Decay;
  type WMap<K, V> = WMap.WMap<K, V>;
  type Categorizations = Categorizations.Categorizations;
  type Opinions = Opinions.Opinions;
  type Status = Types.Status;
  type CategorizationVote = Categorizations.Vote;
  type OpinionVote = Opinions.Vote;

  public func build(
    register: Map<Principal, User>,
    date_init: Time,
    half_life: ?Duration
  ) : Users {
    Users(WMap.WMap(register, Map.phash), Decay.computeOptDecay(date_init, half_life));
  };

  public class Users(register_: WMap<Principal, User>, decay_params_: ?Decay) {

    public func getDecay() : ?Decay {
      decay_params_;
    };

    /// Get the user associated with the given principal.
    /// \param[in] principal The principal associated to the user.
    /// \trap If the given principal is anonymous
    /// \return The user if in the register
    public func getUser(principal: Principal) : User {
      switch(findUser(principal)){
        case(null) { Debug.trap("The user does not exist."); };
        case(?user) { user; };
      };
    };

    /// Find the user associated with the given principal or create it 
    /// if it is not in the register.
    /// \param[in] principal The principal associated to the user.
    /// \return Null if the principal is anonymous, the user otherwise.
    public func findUser(principal: Principal) : ?User {
      register_.get(principal);
    };

    public func setUserName(principal: Principal, name: Text) {
      register_.set(principal, {getUser(principal) with name = ?name; });
    };

    public func getOrCreateUser(principal: Principal, categories: Categories) : User {
      if (Principal.isAnonymous(principal)){
        Debug.trap("User's principal cannot be anonymous.");
      };
      switch (register_.get(principal)){
        case(?user) { user; };
        case(null) {
          let new_user = {
            principal;
            name = null;
            ballots = Set.new<VoteId>();
            convictions = PolarizationMap.nil(categories);
          };
          putUser(new_user);
          new_user;
        };
      };
    };

    /// Put the user in the register.
    /// \param[in] user The user to put in the register.
    /// \trap If the user principal is anonymous.
    public func putUser(user: User) {
      if (Principal.isAnonymous(user.principal)){
        Debug.trap("User's principal cannot be anonymous.");
      };
      register_.set(user.principal, user);
    };

    public func removeCategory(category: Category) {
      register_.forEach(func(principal, user) {
        putUser({ user with convictions = Trie.remove(user.convictions, Categories.key(category), Categories.equal).0 });
      });
    };

    public func addCategory(category: Category) {
      register_.forEach(func(principal, user) {
        putUser({ user with convictions = Trie.put(user.convictions, Categories.key(category), Categories.equal, Polarization.nil()).0 });
      });
    };

    // @todo
    // Warning: assumes that the question is not closed yet but will be after convictions have been updated
    // Warning: does not work if transition from #VOTING(#INTEREST) to #CLOSED
    // Watchout: this function makes a strong assumption that it is called only once every time the question status will be closed
    public func updateConvictions(question: Question, opinions: Opinions, categorizations: Categorizations, categories: Categories) {

      let (new_categorization, previous_categorization) = do {
        let categorization_votes = Buffer.fromIter<CategorizationVote>(categorizations.getVotes(question.id));
        switch(categorization_votes.removeLast()){
          case(null) {
            Debug.trap("Cannot compute users' convictions without a categorization vote");
          };
          case(?new_categorization) {
            let previous_categorization = categorization_votes.removeLast();
            (new_categorization.aggregate, Option.map(previous_categorization, func(vote: CategorizationVote) : PolarizationMap { vote.aggregate; }));
          };
        };
      };

      let (new_opinion_vote, old_opinon_votes) = do {
        let opinion_votes = Buffer.fromIter<OpinionVote>(opinions.getVotes(question.id));
        switch(opinion_votes.removeLast()){
          case(null) {
            Debug.trap("Cannot compute users' convictions without an opinion vote");
          };
          case(?last) {
            (last, opinion_votes.vals());
          };
        };
      };

      // Process old votes by removing removing the contribution of the previous categorization 
      // and adding the contribution of the new categorization
      for (old_vote in old_opinon_votes){
        for ((principal, {answer; date;}) in Map.entries(old_vote.ballots)){
          updateBallotContribution(principal, answer, date, categories, new_categorization, previous_categorization);
        };
      };

      // Process new votes by just adding the contribution of the new categorization
      for ((principal, {answer; date;}) in Map.entries(new_opinion_vote.ballots)){
        updateBallotContribution(principal, answer, date, categories, new_categorization, null);
      };
    };

    // \note To compute the users convictions, the user's opinion (cursor converted into a polarization)
    // is multiplied by the categorization (polarization converted into a cursor)
    // This is done for every category using a trie of polarization initialized with the opinion.
    // The PolarizationMap.mul uses a leftJoin, so that the resulting convictions contains
    // only the categories from the definitions.
    func updateBallotContribution(
      principal: Principal,
      user_opinion: Cursor,
      date: Int,
      categories: Categories,
      new_categorization: PolarizationMap,
      old_categorization: ?PolarizationMap) {

      let user = getUser(principal);

      // Create a Polarization trie from the cursor, based on given categories.
      let opinion_trie = Utils.make(categories.keys(), Categories.key, Categories.equal, Cursor.toPolarization(user_opinion));

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

      putUser({ user with convictions = PolarizationMap.add(user.convictions, contribution); });
    };

  };

};