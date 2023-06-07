import Types "Types";

module {

  type Time                  = Int;
  type Question              = Types.Question;
  type Status                = Types.Status;
  type Key                   = Types.Key;
  type DateEntry             = Types.DateEntry;
  type TextEntry             = Types.TextEntry;
  type AuthorEntry           = Types.AuthorEntry;
  type StatusEntry           = Types.StatusEntry;
  type InterestScore         = Types.InterestScore;

  public func toAuthorKey(question: Question) : Key {
    #AUTHOR({
      question_id = question.id;
      author = question.author;
      date = question.date;
    });
  };

  public func toTextKey(question: Question) : Key {
    #TEXT({
      question_id = question.id;
      text = question.text;
      date = question.date;
    });
  };

  public func toDateKey(question: Question) : Key {
    #DATE({
      question_id = question.id;
      date = question.date;
    });
  };

  public func toStatusKey(question_id: Nat, status: Status, date: Time) : Key {
    #STATUS({question_id; status; date;});
  };

  public func toInterestScoreKey(question_id: Nat, score: Float) : Key {
    #INTEREST_SCORE({
      question_id;
      score;
    });
  };

}