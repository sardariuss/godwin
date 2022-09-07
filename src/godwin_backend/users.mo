import Register "register";
import Types "types";
import Pool "pool";
import Questions "questions";
import Categories "categories";

import RBT "mo:stableRBT/StableRBTree";

import Array "mo:base/Array";
import Trie "mo:base/Trie";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Int "mo:base/Int";
import Result "mo:base/Result";
import Principal "mo:base/Principal";
import Debug "mo:base/Debug";
import Hash "mo:base/Hash";
import Option "mo:base/Option";
import Time "mo:base/Time";
import Iter "mo:base/Iter";
import Order "mo:base/Order";
import Float "mo:base/Float";
import Buffer "mo:base/Buffer";

module {

  // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;
  type Key<K> = Trie.Key<K>;
  type Result<Ok, Err> = Result.Result<Ok, Err>;
  type Principal = Principal.Principal;
  type Hash = Hash.Hash;
  type Register<B> = Register.Register<B>;
  type Time = Time.Time;
  type Order = Order.Order;

  // For convenience: from types module
  type Question = Types.Question;
  type Dimension = Types.Dimension;
  type Sides = Types.Sides;
  type Direction = Types.Direction;
  type Category = Types.Category;
  type Endorsement = Types.Endorsement;
  type Opinion = Types.Opinion;
  type Pool = Types.Pool;
  type PoolParameters = Types.PoolParameters;
  type CategoryAggregationParameters = Types.CategoryAggregationParameters;
  type User = Types.User;

  public type UserRegister = {
    users: Trie<Principal, User>;
  };

  public func empty() : UserRegister {
    {
      users = Trie.empty<Principal, User>();
    };
  };

};