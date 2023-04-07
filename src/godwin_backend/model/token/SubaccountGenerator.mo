import WRef "../../utils/wrappers/WRef";
import Ref "../../utils/Ref";

import List "mo:base/List";
import Nat8 "mo:base/Nat8";
import Nat64 "mo:base/Nat64";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Array "mo:base/Array";

module {

  type Ref<T> = Ref.Ref<T>;
  type WRef<T> = WRef.WRef<T>;

  let GENERATOR_VERSION : Nat8 = 0;

  public type SubaccountType = {
    #OPEN_VOTE;
    #PUT_INTEREST_BALLOT;
    #PUT_CATEGORIZATION_BALLOT;
  };

  func typeToNat8(t : SubaccountType) : Nat8 {
    switch t {
      case (#OPEN_VOTE)                    { 0; };
      case (#PUT_INTEREST_BALLOT)          { 1; };
      case (#PUT_CATEGORIZATION_BALLOT)    { 2; };
    };
  };

  public func getSubaccount(t: SubaccountType, id: Nat) : Blob {
    let buffer = Buffer.Buffer<Nat8>(32);
    // Add the version (1 byte)
    buffer.add(GENERATOR_VERSION);
    // Add the type    (1 byte)
    buffer.add(typeToNat8(t));
    // Add the id      (8 bytes)
    buffer.append(Buffer.fromArray(nat64ToBytes(Nat64.fromNat(id)))); // Traps on overflow
    // Add padding     (22 bytes)
    buffer.append(Buffer.fromArray(Array.tabulate<Nat8>(22, func i = 0)));
    // Assert that the buffer is 32 bytes
    assert(buffer.size() == 32);
    // Return the subaccount as a blob
    Blob.fromArray(Buffer.toArray(buffer));
  };

  public func build(index: Ref<Nat>) : SubaccountGenerator {
    SubaccountGenerator(WRef.WRef<Nat>(index));
  };

  public class SubaccountGenerator(_index: WRef<Nat>) {

    public func getNext() : Nat {
      let nat = _index.get();
      _index.set(nat + 1);
      nat;
    };

  };

  func nat64ToBytes(x : Nat64) : [Nat8] {
    [ 
      Nat8.fromNat(Nat64.toNat((x >> 56) & (255))),
      Nat8.fromNat(Nat64.toNat((x >> 48) & (255))),
      Nat8.fromNat(Nat64.toNat((x >> 40) & (255))),
      Nat8.fromNat(Nat64.toNat((x >> 32) & (255))),
      Nat8.fromNat(Nat64.toNat((x >> 24) & (255))),
      Nat8.fromNat(Nat64.toNat((x >> 16) & (255))),
      Nat8.fromNat(Nat64.toNat((x >> 8) & (255))),
      Nat8.fromNat(Nat64.toNat((x & 255))) 
    ];
  };
 
}