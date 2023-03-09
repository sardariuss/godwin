import ICRC1 "mo:icrc1/ICRC1";

import Map "mo:map/Map";

import Utils "../utils/Utils";

import List "mo:base/List";
import Nat8 "mo:base/Nat8";
import Principal "mo:base/Principal";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";

module {

  type Map<K, V> = Map.Map<K, V>;
  type Map2D<K1, K2, V> = Map.Map<K1, Map<K2, V>>;
  type Account = ICRC1.Account;

  public class TokenVote() {

    let accounts_ : Map2D<Nat, Nat, Account> = Map.new();

    public func linkAccount(question_id: Nat, iteration: Nat, account: Account) {
      ignore Utils.put2D(accounts_, Map.nhash, question_id, Map.nhash, iteration, account); // @todo
    };

    public func getAccount(question_id: Nat, iteration: Nat) : ?Account {
      Utils.get2D(accounts_, Map.nhash, question_id, Map.nhash, iteration);
    };

  };

  public class AccountGenerator() {

    var index_ : Nat = 0;

    let sub_identifier_ : Principal = Principal.fromText("@todo");

    public func generateAccount() : Account {
      let account = {
        owner = sub_identifier_;
        subaccount = ?bytesToSubaccount(natToBytes(index_));
      };
      index_ := index_ + 1;
      return account;
    };

  };

  func bytesToSubaccount(bytes : [Nat8]) : Blob {
    let buffer = Buffer.fromArray<Nat8>(bytes);
    while (buffer.size() < 32) {
      buffer.add(0);
    };
    while (buffer.size() > 32) {
      ignore buffer.removeLast();
    };
    Blob.fromArray(Buffer.toArray(buffer));
  };

  func natToBytes(n : Nat) : [Nat8] {
    
    var a : Nat8 = 0;
    var b : Nat = n;
    var bytes = List.nil<Nat8>();
    var test = true;
    while test {
      a := Nat8.fromNat(b % 256);
      b := b / 256;
      bytes := List.push<Nat8>(a, bytes);
      test := b > 0;
    };
    List.toArray<Nat8>(bytes);
  };
 
}