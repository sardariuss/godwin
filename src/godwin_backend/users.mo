import Types "types";

import Trie "mo:base/Trie";
import Iter "mo:base/Iter";

module {

  // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;
  type Iter<T> = Iter.Iter<T>;

  // For convenience: from types module
  type User = Types.User;

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

};