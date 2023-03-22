import WRef "../../utils/wrappers/WRef";
import Ref "../../utils/Ref";

import List "mo:base/List";
import Nat8 "mo:base/Nat8";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";

module {

  type Ref<T> = Ref.Ref<T>;
  type WRef<T> = WRef.WRef<T>;

  public func build(index: Ref<Nat>) : SubaccountGenerator {
    SubaccountGenerator(WRef.WRef<Nat>(index));
  };

  public class SubaccountGenerator(index_: WRef<Nat>) {

    public func generateSubaccount() : Blob {
      let subaccount = bytesToSubaccount(natToBytes(index_.get()));
      index_.set(index_.get() + 1);
      return subaccount;
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