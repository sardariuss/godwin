import Types  "Types";

import Nat8   "mo:base/Nat8";
import Nat64  "mo:base/Nat64";
import Blob   "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Array  "mo:base/Array";

module {

  public let MODULE_VERSION : Nat8 = 0;

  type SubaccountPrefix = Types.SubaccountPrefix;

  public func getSubaccount(t: SubaccountPrefix, id: Nat) : Blob {
    let buffer = Buffer.Buffer<Nat8>(32);
    // Add the version (1 byte)
    buffer.add(MODULE_VERSION);
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

  func typeToNat8(t : SubaccountPrefix) : Nat8 {
    switch t {
      case (#OPEN_QUESTION)                { 0; };
      case (#PUT_INTEREST_BALLOT)          { 1; };
      case (#PUT_CATEGORIZATION_BALLOT)    { 2; };
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