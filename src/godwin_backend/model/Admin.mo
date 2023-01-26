import Types "Types";
import Questions "Questions";
import Utils "../utils/Utils";
import Categories "Categories";

import Result "mo:base/Result";
import Time "mo:base/Time";
import Buffer "mo:base/Buffer";
import Array "mo:base/Array";
import Text "mo:base/Text";
import PolarizationMap "votes/representation/PolarizationMap";

module {

//  // For convenience: from base module
//  type Result<Ok, Err> = Result.Result<Ok, Err>;
//  // For convenience: from types module
//  type Question = Types.Question;
//  type Appeal = Types.Appeal;
//  type Polarization = Types.Polarization;
//  type CursorMap = Types.CursorMap;
//  type PolarizationMap = Types.PolarizationMap;
//  type PolarizationArray = Types.PolarizationArray;
//  type Interest = Types.Interest;
//  type Cursor = Types.Cursor;
//  type CreateStatus = Types.CreateStatus;
//  type Questions = Questions.Questions;
//  
//  public type CreateQuestionError = {
//    #PrincipalIsAnonymous;
//    #InsufficientCredentials;
//  };
//
//  public func createQuestions(questions: Questions, principal: Principal, inputs: [(Text, CreateStatus)]) : [Question] {
//    let buffer = Buffer.Buffer<Question>(inputs.size());
//    for (input in Array.vals(inputs)){
//      let date = Time.now();
//      let question = questions.createQuestion(principal, date, input.0, "");
//      // Update the question based on status
//      let updated_question = switch(input.1){
//        case(#INTEREST({ interest_score; })){ 
//          { 
//            question with 
//            status = #INTEREST(Vote.new<Interest, Appeal>(date, { ups = 0; downs = 0; score = interest_score; })) 
//          } 
//        };
//        case(#OPEN(#OPINION({ interest_score; opinion_aggregate; }))) { 
//          { 
//            question with 
//            interests_history = [Vote.new<Interest, Appeal>(date, { ups = 0; downs = 0; score = interest_score; })]; 
//            status = #OPEN({ stage = #OPINION; iteration = { 
//              opinion = Vote.new<Cursor, Polarization>(date, opinion_aggregate); 
//              categorization = Vote.new<CursorMap, PolarizationMap>(0, PolarizationMap.nil([])); 
//            }; }); 
//          }
//        };
//        case(#OPEN(#CATEGORIZATION({ interest_score; opinion_aggregate; categorization_aggregate; }))) { 
//          { 
//            question with 
//            interests_history = [Vote.new<Interest, Appeal>(date, { ups = 0; downs = 0; score = 0; })]; 
//            status = #OPEN({ stage = #CATEGORIZATION; iteration = { 
//              opinion = Vote.new<Cursor, Polarization>(date, opinion_aggregate); 
//              categorization = Vote.new<CursorMap, PolarizationMap>(0, Utils.arrayToTrie(categorization_aggregate, Categories.key, Categories.equal));
//            };});
//          } 
//        };
//        case(#CLOSED({ interest_score; opinion_aggregate; categorization_aggregate; })){
//          { 
//            question with 
//            status = #CLOSED(date);
//            interests_history = [Vote.new<Interest, Appeal>(date, { ups = 0; downs = 0; score = interest_score; })];
//            vote_history = [{ 
//              opinion = Vote.new<Cursor, Polarization>(date, opinion_aggregate);
//              categorization = Vote.new<CursorMap, PolarizationMap>(0, Utils.arrayToTrie(categorization_aggregate, Categories.key, Categories.equal)); 
//            }]
//          }
//        };
//        case(#REJECTED({ interest_score; })){ 
//          { 
//            question with 
//            status = #REJECTED(date);
//            interests_history = [Vote.new<Interest, Appeal>(date, { ups = 0; downs = 0; score = interest_score; })];
//          }
//        };
//      };
//      questions.replaceQuestion(updated_question);
//      buffer.add(updated_question);
//    };
//    Buffer.toArray(buffer);
//  };

};