import Types "../types";

import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Int "mo:base/Int";
import Text "mo:base/Text";

module {

  // For convenience: from types module
  type Question = Types.Question;

  public func toText(question: Question) : Text {
    var buffer : Buffer.Buffer<Text> = Buffer.Buffer<Text>(8);
    buffer.add("id: " # Nat.toText(question.id) # ", ");
    buffer.add("author: " # Principal.toText(question.author) # ", ");
    buffer.add("title: " # question.title # ", ");
    buffer.add("text: " # question.text # ", ");
    buffer.add("date: " # Int.toText(question.date) # ", ");
    Text.join("", buffer.vals());
  };
  
  public func equal(q1: Question, q2: Question) : Bool {
    return Nat.equal(q1.id, q2.id)
        and Principal.equal(q1.author, q2.author)
        and Text.equal(q1.title, q2.title)
        and Text.equal(q1.text, q2.text)
        and Int.equal(q1.date, q2.date);
  };

};