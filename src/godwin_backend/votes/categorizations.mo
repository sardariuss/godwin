import Types "../types";
import VoteRegister "voteRegister";
import CategoryPolarizationTrie "../representation/categoryPolarizationTrie";

module {

  // For convenience: from types module
  type B = Types.CategoryCursorTrie;
  type A = Types.CategoryPolarizationTrie;
  
  public type Register = VoteRegister.Register<B, A>;  

  public func putBallot(register: Register, id: Nat, principal: Principal, ballot: B) : Register {
    VoteRegister.putBallot(register, id, principal, ballot, CategoryPolarizationTrie.addCategoryCursorTrie, CategoryPolarizationTrie.subCategoryCursorTrie);
  };

  public func removeBallot(register: Register, id: Nat, principal: Principal) : Register {
    VoteRegister.removeBallot(register, id, principal, CategoryPolarizationTrie.addCategoryCursorTrie, CategoryPolarizationTrie.subCategoryCursorTrie);
  };

};