import Types "types";

import Trie "mo:base/Trie";
import Nat "mo:base/Nat";

module {
  // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;

  // For convenience: from types module
  type User = Types.User;
  type Interest = Types.Interest;
  type Cursor = Types.Cursor;
  type CategoryCursorTrie = Types.CategoryCursorTrie;
  type CategoryPolarizationArray = Types.CategoryPolarizationArray;

  public func newUser(principal: Principal, convictions: CategoryPolarizationArray) : User {
    {
      principal;
      name = null;
      ballots = {
        interests = Trie.empty<Nat, Interest>();
        opinions = Trie.empty<Nat, Cursor>();
        categorizations = Trie.empty<Nat, CategoryCursorTrie>();
      };
      // Important: set convictions.to_update to true, because the principal could have already voted
      // before findUser is called (we don't want to assume the frontend called findUser right after the
      // user logged in).
      convictions = { to_update = true; array = convictions; };
    };
  };

  public func pruneConvictions(user: User) : User {
    {
      principal = user.principal;
      name = user.name;
      ballots = user.ballots;
      convictions = { to_update = true; array = user.convictions.array; };
    };
  };

  public func updateConvictions(user: User, convictions: CategoryPolarizationArray) : User {
    {
      principal = user.principal;
      name = user.name;
      ballots = user.ballots;
      convictions = { to_update = false; array = convictions; };
    };
  };

  public func updateInterests(user: User, interests: Trie<Nat, Interest>) : User {
    {
      principal = user.principal;
      name = user.name;
      ballots = { interests; opinions = user.ballots.opinions; categorizations = user.ballots.categorizations; };
      convictions = user.convictions;
    };
  };

  public func updateOpinions(user: User, opinions: Trie<Nat, Cursor>) : User {
    {
      principal = user.principal;
      name = user.name;
      ballots = { interests = user.ballots.interests; opinions; categorizations = user.ballots.categorizations; };
      convictions = user.convictions;
    };
  };

  public func updateCategorizations(user: User, categorizations: Trie<Nat, CategoryCursorTrie>) : User {
    {
      principal = user.principal;
      name = user.name;
      ballots = { interests = user.ballots.interests; opinions = user.ballots.opinions; categorizations; };
      convictions = user.convictions;
    };
  };

  public func getInterest(user: User, question_id: Nat) : ?Interest {
    Trie.get(user.ballots.interests, Types.keyNat(question_id), Nat.equal);
  };

  public func getOpinion(user: User, question_id: Nat) : ?Cursor {
    Trie.get(user.ballots.opinions, Types.keyNat(question_id), Nat.equal);
  };

  public func getCategorization(user: User, question_id: Nat) : ?CategoryCursorTrie {
    Trie.get(user.ballots.categorizations, Types.keyNat(question_id), Nat.equal);
  };

};