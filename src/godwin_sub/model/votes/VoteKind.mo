import Types "Types";

module {

  // For convenience: from types module
  type VoteKind = Types.VoteKind;

  public func toText(vote_kind: VoteKind) : Text {
    switch(vote_kind){
      case(#INTEREST)       { "INTEREST";       };
      case(#OPINION)        { "OPINION";        };
      case(#CATEGORIZATION) { "CATEGORIZATION"; };
    };
  };

};