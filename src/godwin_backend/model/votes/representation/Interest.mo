import Types "Types";

module {

  type Interest = Types.Interest;

  public func isValid(interest: Interest) : Bool {
    true; // A variant is always valid.
  };
  
}