import Map "mo:map/Map";

import Utils "../../utils/Utils";

module {

  type Map<K, V> = Map.Map<K, V>;
  type Map2D<K1, K2, V> = Map.Map<K1, Map<K2, V>>;

  public class SubaccountMap(subaccounts_ : Map2D<Nat, Nat, Blob>) {

    public func linkSubaccount(question_id: Nat, iteration: Nat, subaccount: Blob) {
      ignore Utils.put2D(subaccounts_, Map.nhash, question_id, Map.nhash, iteration, subaccount); // @todo
    };

    public func getSubaccount(question_id: Nat, iteration: Nat) : ?Blob {
      Utils.get2D(subaccounts_, Map.nhash, question_id, Map.nhash, iteration);
    };

  };
 
}