import RBT "mo:stableRBT/StableRBTree";
import Trie "mo:base/Trie";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Int "mo:base/Int";
import Result "mo:base/Result";
import TrieSet "mo:base/TrieSet";
import Principal "mo:base/Principal";

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
    endorsements: Nat;
    votes: Trie<Opinion, Nat>;
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
    name: ?Text;
    profile: Trie<PoliticalDimension, Float>;
  };

  type Trie<K, V> = Trie.Trie<K, V>;
  type Key<K> = Trie.Key<K>;
  type Result<Ok, Err> = Result.Result<Ok, Err>;
  type Principal = Principal.Principal;
  type Set<K> = TrieSet.Set<K>;

  func keyText(t: Text) : Key<Text> { { key = t; hash = Text.hash(t) } };
  func keyNat(n: Nat) : Key<Nat> { { key = n; hash = Int.hash(n) } };
  func keyPrincipal(p: Principal) : Key<Principal> { { key = p; hash = Principal.hash(p) } };
  func keyOpinion(o: Opinion) : Key<Opinion> { 
    switch(o){
      case(#ABS_AGREE){
        { key = #ABS_AGREE; hash = Int.hash(0); }
      };
      case(#RATHER_AGREE){
        { key = #RATHER_AGREE; hash = Int.hash(1); }
      };
      case(#NEUTRAL){
        { key = #NEUTRAL; hash = Int.hash(2); }
      };
      case(#RATHER_DISAGREE){
        { key = #RATHER_DISAGREE; hash = Int.hash(3); }
      };
      case(#ABS_DISAGREE){
        { key = #ABS_DISAGREE; hash = Int.hash(4); }
      };
    };
  };

  func equalOpinion(a: Opinion, b:Opinion) : Bool {
    return a == b;
  };

  type Opinion = {
    #ABS_AGREE;
    #RATHER_AGREE;
    #NEUTRAL;
    #RATHER_DISAGREE;
    #ABS_DISAGREE;
  };

  private stable var opinion_parameters_ = Trie.empty<Opinion, Float>();
  opinion_parameters_ := Trie.put(opinion_parameters_, keyOpinion(#ABS_AGREE), equalOpinion, 1.0).0;
  opinion_parameters_ := Trie.put(opinion_parameters_, keyOpinion(#RATHER_AGREE), equalOpinion, 0.5).0;
  opinion_parameters_ := Trie.put(opinion_parameters_, keyOpinion(#NEUTRAL), equalOpinion, 0.0).0;
  opinion_parameters_ := Trie.put(opinion_parameters_, keyOpinion(#RATHER_DISAGREE), equalOpinion, -0.5).0;
  opinion_parameters_ := Trie.put(opinion_parameters_, keyOpinion(#ABS_DISAGREE), equalOpinion, -1.0).0;

  private stable var political_categories_ = Trie.empty<PoliticalDimension, PoliticalSides>();
  political_categories_ := Trie.put(political_categories_, keyText("IDENTITY"), Text.equal, ("CONSTRUCTIVISM", "ESSENTIALISM")).0;
  political_categories_ := Trie.put(political_categories_, keyText("COOPERATION"), Text.equal, ("INTERNATIONALISM", "NATIONALISM")).0;
  political_categories_ := Trie.put(political_categories_, keyText("PROPERTY"), Text.equal, ("COMMUNISM", "CAPITALISM")).0;
  political_categories_ := Trie.put(political_categories_, keyText("ECONOMY"), Text.equal, ("REGULATION", "LAISSEZFAIRE")).0;
  political_categories_ := Trie.put(political_categories_, keyText("CULTURE"), Text.equal, ("PROGRESSIVISM", "CONSERVATISM")).0;
  political_categories_ := Trie.put(political_categories_, keyText("TECHNOLOGY"), Text.equal, ("ECOLOGY", "PRODUCTION")).0;
  political_categories_ := Trie.put(political_categories_, keyText("JUSTICE"), Text.equal, ("REHABILITATION", "PUNITION")).0;
  political_categories_ := Trie.put(political_categories_, keyText("CHANGE"), Text.equal, ("REVOLUTION", "REFORM")).0;

  // key = question_id, value = question
  private stable var questions_ = RBT.init<Nat, Question>();
  private stable var question_index_ : Nat = 0;

  // key = user_id, value = map( key = question_id, value = opinion )
  private stable var votes_ = Trie.empty<Principal, Trie<Nat, Opinion>>();

  // key = user_id, value = set( question_id )
  private stable var endorsements_ = Trie.empty<Principal, Set<Nat>>();

  public func getQuestion(index: Nat) : async ?Question {
    return RBT.get<Nat, Question>(questions_, Nat.compare, index);
  };

  public func getQuestions() : async RBT.ScanLimitResult<Nat, Question> {
    return RBT.scanLimit<Nat, Question>(questions_, Nat.compare, 0, 10, #fwd, 10);
  };

  func initVotes() : Trie<Opinion, Nat> {
    var votes = Trie.empty<Opinion, Nat>();
    votes := Trie.put(votes, keyOpinion(#ABS_AGREE), equalOpinion, 0).0;
    votes := Trie.put(votes, keyOpinion(#RATHER_AGREE), equalOpinion, 0).0;
    votes := Trie.put(votes, keyOpinion(#NEUTRAL), equalOpinion, 0).0;
    votes := Trie.put(votes, keyOpinion(#RATHER_DISAGREE), equalOpinion, 0).0;
    votes := Trie.put(votes, keyOpinion(#ABS_DISAGREE), equalOpinion, 0).0;
    return votes;
  };

  public shared({caller}) func createQuestion(title: Text, text: Text) : async Question {
    let question = {
      id = question_index_;
      author = caller;
      title = title;
      text = text;
      endorsements = 0;
      votes = initVotes();
      status = #CREATED;
      category = null;
    };
    questions_ := RBT.put(questions_, Nat.compare, question_index_, question);
    question_index_ := question_index_ + 1;
    return question;
  };

  type EndorsementError = {
    #QuestionNotFound;
    #AlreadyEndorsed;
  };

  // @todo: maybe one shall be able to remove endorsement
  public shared({caller}) func endorse(question_id: Nat) : async Result<(), EndorsementError> {
    switch(RBT.get<Nat, Question>(questions_, Nat.compare, question_id)){
      case(null){
        return #err(#QuestionNotFound);
      };
      case(?question){
        // Get the user endorsements (initialized with an empty set if none is found)
        var user_endorsements = TrieSet.empty<Nat>();
        switch(Trie.get(endorsements_, keyPrincipal(caller), Principal.equal)){
          case(null){};
          case(?endorsements){
            user_endorsements := endorsements;
          };
        };
        // Check if the question has already been endorsed
        switch(Trie.get(user_endorsements, keyNat(question_id), Nat.equal)){
          case(?question_id){
            // The user has already given its endorsement
            return #err(#AlreadyEndorsed);
          };
          case(null){
            // Add the question to the user endorsements
            user_endorsements := TrieSet.put(user_endorsements, question_id, Int.hash(question_id), Nat.equal);
            endorsements_ := Trie.put(endorsements_, keyPrincipal(caller), Principal.equal, user_endorsements).0;
            // Increase the question's endorsements
            let updated_question = {
              id = question.id;
              author = question.author;
              title = question.title;
              text = question.text;
              endorsements = question.endorsements + 1;
              votes = question.votes;
              status = question.status;
              category = question.category;
            };
            questions_ := RBT.put(questions_, Nat.compare, question_index_, updated_question);
            // Success
            return #ok;
          };
        };
      };
    };
  };

  type VoteError = {
    #QuestionNotFound;
    #QuestionNotOpen;
    #AlreadyVoted;
  };

  func addVote(question: Question, opinion: Opinion) : Question {
    // Get the current number of votes for this opinion
    var opinion_votes : Nat = 0;
    switch(Trie.get(question.votes, keyOpinion(opinion), equalOpinion)){
      case(null){};
      case(?total){
        opinion_votes := total;
      };
    };
    // Update the question
    return {
      id = question.id;
      author = question.author;
      title = question.title;
      text = question.text;
      endorsements = question.endorsements;
      votes = Trie.put(question.votes, keyOpinion(opinion), equalOpinion, opinion_votes).0;
      status = question.status;
      category = question.category;
    };
  };

  public shared({caller}) func vote(question_id: Nat, opinion: Opinion) : async Result<(), VoteError> {
    switch(RBT.get<Nat, Question>(questions_, Nat.compare, question_id)){
      case(null){
        return #err(#QuestionNotFound);
      };
      case(?question){
        if (question.status == #CREATED){
          return #err(#QuestionNotOpen);
        };
        // Get the user votes (initialized with an empty list if none is found)
        var user_votes = Trie.empty<Nat, Opinion>();
        switch(Trie.get(votes_, keyPrincipal(caller), Principal.equal)){
          case(null){};
          case(?votes){
            user_votes := votes;
          };
        };
        // Check if the user has already vote on this question
        switch(Trie.get(user_votes, keyNat(question_id), Nat.equal)){
          case(?id){
            // The user has already voted
            return #err(#AlreadyVoted);
          };
          case(null){
            // Add the vote
            user_votes := Trie.put(user_votes, keyNat(question_id), Nat.equal, opinion).0;
            votes_ := Trie.put(votes_, keyPrincipal(caller), Principal.equal, user_votes).0;
            // Add the vote to the question
            questions_ := RBT.put(questions_, Nat.compare, question_index_, addVote(question, opinion));
            // Success
            return #ok;
          };
        };
      };
    };
  };

};
