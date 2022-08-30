import RBT "mo:stableRBT/StableRBTree";
import Trie "mo:base/Trie";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Result "mo:base/Result";

actor {
  
  type Direction = {
    #LR;
    #RL;
  };

  type QuestionStatus = {
    #CREATED;
    #CAN_VOTE;
    #CAN_CATEGORIZE;
    #CLOSED;
  };

  type Question = {
    id: Nat;
    author: Principal;
    title: Text;
    text: Text;
    interest: Int;
    status: QuestionStatus;
    category: ?(Text, ?Direction);
  };

  type PoliticalDimension = Text;
  type PoliticalSide = Text;
  type PoliticalSides = (PoliticalSide, PoliticalSide);
  type PoliticalCategory = {
    dimension: PoliticalDimension;
    sides: PoliticalSides;
  };

  type User = {
    principal: Principal;
    name: Text;
    profile: RBT.Tree<PoliticalDimension, Float>;
  };

  type Opinion = Text;

  type Ballot = {
    id: Nat;
    user: Principal;
    question_id: Nat;
    opinion: Opinion;
  };

  type Interest = {
    id: Nat;
    user: Principal;
    question_id: Nat;
    vote: InterestVote;
  };

  type InterestVote = Text;

  type Trie<K, V> = Trie.Trie<K, V>;
  type Key<K> = Trie.Key<K>;
  type Result<Ok, Err> = Result.Result<Ok, Err>;

  func key(t: Text) : Key<Text> { { key = t; hash = Text.hash(t) } };

  private stable var interest_parameters_ = Trie.empty<InterestVote, Float>();
  interest_parameters_ := Trie.put(interest_parameters_, key("UPVOTE"), Text.equal, 1.0).0;
  interest_parameters_ := Trie.put(interest_parameters_, key("DOWNVOTE"), Text.equal, -1.0).0;

  private stable var opinion_parameters_ = Trie.empty<Opinion, Float>();
  opinion_parameters_ := Trie.put(opinion_parameters_, key("ABS_AGREE"), Text.equal, 1.0).0;
  opinion_parameters_ := Trie.put(opinion_parameters_, key("RATHER_AGREE"), Text.equal, 0.5).0;
  opinion_parameters_ := Trie.put(opinion_parameters_, key("NEUTRAL"), Text.equal, 0.0).0;
  opinion_parameters_ := Trie.put(opinion_parameters_, key("RATHER_DISAGREE"), Text.equal, -0.5).0;
  opinion_parameters_ := Trie.put(opinion_parameters_, key("ABS_DISAGREE"), Text.equal, -1.0).0;

  private stable var political_categories_ = Trie.empty<PoliticalDimension, PoliticalSides>();
  political_categories_ := Trie.put(political_categories_, key("IDENTITY"), Text.equal, ("CONSTRUCTIVISM","ESSENTIALISM")).0;
  political_categories_ := Trie.put(political_categories_, key("COOPERATION"), Text.equal, ("INTERNATIONALISM","NATIONALISM")).0;
  political_categories_ := Trie.put(political_categories_, key("PROPERTY"), Text.equal, ("COMMUNISM","CAPITALISM")).0;
  political_categories_ := Trie.put(political_categories_, key("ECONOMY"), Text.equal, ("REGULATION","LAISSEZFAIRE")).0;
  political_categories_ := Trie.put(political_categories_, key("CULTURE"), Text.equal, ("PROGRESSIVISM","CONSERVATISM")).0;
  political_categories_ := Trie.put(political_categories_, key("TECHNOLOGY"), Text.equal, ("ECOLOGY","PRODUCTION")).0;
  political_categories_ := Trie.put(political_categories_, key("JUSTICE"), Text.equal, ("REHABILITATION","PUNITION")).0;
  political_categories_ := Trie.put(political_categories_, key("CHANGE"), Text.equal, ("REVOLUTION","REFORM")).0;

  private stable var list_questions_ = RBT.init<Nat, Question>();
  private stable var question_index_ : Nat = 0;

  private stable var ballots_ = RBT.init<Nat, Ballot>();
  private stable var ballot_index_ : Nat = 0;

  private stable var list_interests_ = RBT.init<Nat, Interest>();
  private stable var interest_index_ : Nat = 0;

  public func getQuestion(index: Nat) : async ?Question {
    return RBT.get<Nat, Question>(list_questions_, Nat.compare, index);
  };

  public func getQuestions() : async RBT.ScanLimitResult<Nat, Question> {
    return RBT.scanLimit<Nat, Question>(list_questions_, Nat.compare, 0, 10, #fwd, 10);
  };

  public shared({caller}) func createQuestion(title: Text, text: Text) : async Question {
    let question = {
      id = question_index_;
      author = caller;
      title = title;
      text = text;
      interest = 0;
      status = #CREATED;
      category = null;
    };
    list_questions_ := RBT.put(list_questions_, Nat.compare, question_index_, question);
    question_index_ := question_index_ + 1;
    return question;
  };

  type InterestVoteError = {
    #QuestionNotFound;
  };

  public shared({caller}) func setInterest(question_id: Nat, interest_vote: InterestVote) : async Result<Interest, InterestVoteError> {
    switch(RBT.get<Nat, Question>(list_questions_, Nat.compare, question_id)){
      case(null){
        return #err(#QuestionNotFound);
      };
      case(?question){
        // @todo: check the interest is in the map
        // @todo: check if the user has already given its interest
        let interest = {
          id = interest_index_;
          user = caller;
          question_id = question_id;
          vote = interest_vote;
        };
        list_interests_ := RBT.put(list_interests_, Nat.compare, interest_index_, interest);
        interest_index_ := interest_index_ + 1;
        return #ok(interest);
      };
    };
  };

  type VoteError = {
    #QuestionNotFound;
    #WrongStatus;
  };

  public shared({caller}) func vote(question_id: Nat, opinion: Text) : async Result<Ballot, VoteError> {
    switch(RBT.get<Nat, Question>(list_questions_, Nat.compare, question_id)){
      case(null){
        return #err(#QuestionNotFound);
      };
      case(?question){
        if (question.status != #CAN_VOTE){
          return #err(#WrongStatus);
        };
        // @todo: check opinion is in the map
        // @todo: check if user has already voted
        let ballot = {
          id = ballot_index_;
          user = caller;
          question_id = question_id;
          opinion = opinion;
        };
        ballots_ := RBT.put(ballots_, Nat.compare, ballot_index_, ballot);
        ballot_index_ := ballot_index_ + 1;
        return #ok(ballot);
      };
    };
  };
  

};
