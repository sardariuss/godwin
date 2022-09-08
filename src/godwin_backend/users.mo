import Types "types";

import Trie "mo:base/Trie";
import Iter "mo:base/Iter";
import Result "mo:base/Result";
import Principal "mo:base/Principal";

module {

  // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;
  type Iter<T> = Iter.Iter<T>;
  type Result<Ok, Err> = Result.Result<Ok, Err>;
  type Principal = Principal.Principal;

  // For convenience: from types module
  type User = Types.User;
  type Conviction = Types.Conviction;
  type Category = Types.Category;

  public type UserRegister = Trie<Principal, User>;

  public func empty() : UserRegister {
    Trie.empty<Principal, User>();
  };

  public func iter(register: UserRegister) : Iter<(Principal, User)> {
    return Trie.iter(register);
  };

  public func setConvictionToUpdate(user: User) : User {
    {
      principal = user.principal;
      name = user.name;
      convictions = {
        to_update = true;
        trie = user.convictions.trie;
      };
    };
  };

  public func setConvictions(user: User, trie_convictions: Trie<Category, Conviction>) : User {
    {
      principal = user.principal;
      name = user.name;
      convictions = {
        to_update = false;
        trie = trie_convictions;
      };
    };
  };

  public func getUser(register: UserRegister, principal: Principal) : ?User {
    Trie.get(register, Types.keyPrincipal(principal), Principal.equal);
  };

  public func putUser(register: UserRegister, user: User) : (UserRegister, ?User) {
    Trie.put(register, Types.keyPrincipal(user.principal), Principal.equal, user);
  };

  public func newUser(principal: Principal) : User {
    // Important: set convictions.to_update to true, because the associated principal could have voted actually creating the user
    { principal = principal; name = null; convictions = { to_update = true; trie = Trie.empty<Category, Conviction>(); } };
  };

};