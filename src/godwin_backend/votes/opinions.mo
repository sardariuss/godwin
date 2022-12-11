import Types "../types";
import VoteRegister "voteRegister";
import Polarization "../representation/polarization";

module {

  // For convenience: from types module
  type B = Types.Cursor;
  type A = Types.Polarization;
  
  public type Register = VoteRegister.Register<B, A>;  

  public func putBallot(register: Register, id: Nat, principal: Principal, ballot: B) : Register {
    VoteRegister.putBallot(register, id, principal, ballot, Polarization.addCursor, Polarization.subCursor);
  };

  public func removeBallot(register: Register, id: Nat, principal: Principal) : Register {
    VoteRegister.removeBallot(register, id, principal, Polarization.addCursor, Polarization.subCursor);
  };

};