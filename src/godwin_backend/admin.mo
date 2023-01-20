import Types "types";
import Questions "questions/questions";
import Utils "utils";

import Result "mo:base/Result";
import Time "mo:base/Time";
import Buffer "mo:base/Buffer";
import Array "mo:base/Array";
import Text "mo:base/Text";
import CategoryPolarizationTrie "representation/categoryPolarizationTrie";

module {

//  // For convenience: from base module
//  type Result<Ok, Err> = Result.Result<Ok, Err>;
//  // For convenience: from types module
//  type Question = Types.Question;
//  type InterestAggregate = Types.InterestAggregate;
//  type Polarization = Types.Polarization;
//  type CategoryCursorTrie = Types.CategoryCursorTrie;
//  type CategoryPolarizationTrie = Types.CategoryPolarizationTrie;
//  type CategoryPolarizationArray = Types.CategoryPolarizationArray;
//  type Interest = Types.Interest;
//  type Cursor = Types.Cursor;
//  type CreateQuestionStatus = Types.CreateQuestionStatus;
//  type Questions = Questions.Questions;
//  
//  public type CreateQuestionError = {
//    #PrincipalIsAnonymous;
//    #InsufficientCredentials;
//  };
//
//  public func createQuestions(questions: Questions, principal: Principal, inputs: [(Text, CreateQuestionStatus)]) : [Question] {
//    let buffer = Buffer.Buffer<Question>(inputs.size());
//    for (input in Array.vals(inputs)){
//      let date = Time.now();
//      let question = questions.createQuestion(principal, date, input.0, "");
//      // Update the question based on status
//      let updated_question = switch(input.1){
//        case(#CANDIDATE({ interest_score; })){ 
//          { 
//            question with 
//            status = #CANDIDATE(Vote.new<Interest, InterestAggregate>(date, { ups = 0; downs = 0; score = interest_score; })) 
//          } 
//        };
//        case(#OPEN(#OPINION({ interest_score; opinion_aggregate; }))) { 
//          { 
//            question with 
//            interests_history = [Vote.new<Interest, InterestAggregate>(date, { ups = 0; downs = 0; score = interest_score; })]; 
//            status = #OPEN({ stage = #OPINION; iteration = { 
//              opinion = Vote.new<Cursor, Polarization>(date, opinion_aggregate); 
//              categorization = Vote.new<CategoryCursorTrie, CategoryPolarizationTrie>(0, CategoryPolarizationTrie.nil([])); 
//            }; }); 
//          }
//        };
//        case(#OPEN(#CATEGORIZATION({ interest_score; opinion_aggregate; categorization_aggregate; }))) { 
//          { 
//            question with 
//            interests_history = [Vote.new<Interest, InterestAggregate>(date, { ups = 0; downs = 0; score = 0; })]; 
//            status = #OPEN({ stage = #CATEGORIZATION; iteration = { 
//              opinion = Vote.new<Cursor, Polarization>(date, opinion_aggregate); 
//              categorization = Vote.new<CategoryCursorTrie, CategoryPolarizationTrie>(0, Utils.arrayToTrie(categorization_aggregate, Types.keyText, Text.equal));
//            };});
//          } 
//        };
//        case(#CLOSED({ interest_score; opinion_aggregate; categorization_aggregate; })){
//          { 
//            question with 
//            status = #CLOSED(date);
//            interests_history = [Vote.new<Interest, InterestAggregate>(date, { ups = 0; downs = 0; score = interest_score; })];
//            vote_history = [{ 
//              opinion = Vote.new<Cursor, Polarization>(date, opinion_aggregate);
//              categorization = Vote.new<CategoryCursorTrie, CategoryPolarizationTrie>(0, Utils.arrayToTrie(categorization_aggregate, Types.keyText, Text.equal)); 
//            }]
//          }
//        };
//        case(#REJECTED({ interest_score; })){ 
//          { 
//            question with 
//            status = #REJECTED(date);
//            interests_history = [Vote.new<Interest, InterestAggregate>(date, { ups = 0; downs = 0; score = interest_score; })];
//          }
//        };
//      };
//      questions.replaceQuestion(updated_question);
//      buffer.add(updated_question);
//    };
//    Buffer.toArray(buffer);
//  };

};