import Types "Types";

module {

  type Time                  = Int;
  type QuestionId            = Types.QuestionId;
  type Question              = Types.Question;
  type Status                = Types.Status;
  type Key                   = Types.Key;
  type DateEntry             = Types.DateEntry;
  type TextEntry             = Types.TextEntry;
  type AuthorEntry           = Types.AuthorEntry;
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

  public func toArchiveKey(question_id: Nat, date: Time) : Key {
    #ARCHIVE({question_id; date;})
  };

  public func toHotnessKey(question_id: Nat, score: Float) : Key {
    #HOTNESS({
      question_id;
      score;
    });
  };

  public func toOpinionVoteKey(question_id: Nat, date: Time, is_late: Bool) : Key {
    #OPINION_VOTE({question_id; date; is_late;})
  };

  public func getQuestionId(key: Key) : QuestionId {
    switch(key){
      case(#AUTHOR        ({question_id})) { question_id; };
      case(#TEXT          ({question_id})) { question_id; };
      case(#DATE          ({question_id})) { question_id; };
      case(#STATUS        ({question_id})) { question_id; };
      case(#HOTNESS({question_id})) { question_id; };
      case(#ARCHIVE       ({question_id})) { question_id; };
      case(#OPINION_VOTE  ({question_id})) { question_id; };
    };
  };

}