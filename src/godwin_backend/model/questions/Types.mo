import Map "mo:map/Map";

module {

  type Time = Int;
  type Map<K, V> = Map.Map<K, V>;

  public type QuestionId = Nat;

  public type Question = {
    id: QuestionId;
    author: Principal;
    text: Text;
    date: Time;
  };

  public type Status = {
    #CANDIDATE;
    #OPEN;
    #CLOSED;
    #REJECTED;
  };

  public type StatusInfo = {
    status: Status;
    iteration: Nat;
    date: Time;
  };

  public type StatusData = {
    var current: StatusInfo;
    history: Map<Status, [Time]>;
  };

  public type StatusHistory = Map<Status, [Time]>;
  
  public let questionHash = Map.nhash;

  public type OpenQuestionError = {
    #PrincipalIsAnonymous;
    #TextTooLong;
  };
  
}