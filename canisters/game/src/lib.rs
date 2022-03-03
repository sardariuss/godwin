use ic_cdk_macros;
use ic_cdk::export::{candid::{CandidType}, Principal};

#[ic_cdk_macros::import(canister = "graphql")]
struct GraphQLCanister;

use serde::{Deserialize};
use serde_json::{Result, Value};

#[derive(Debug, serde::Deserialize, ic_cdk::export::candid::CandidType, Clone)]
struct User {
   id: String,
   username: String
}

#[derive(Debug, serde::Deserialize, ic_cdk::export::candid::CandidType, Clone)]
struct Question {
   id: String,
   author: User,
   text: String,
   interest: i32
}

/// Add a user
/// \param[in] username The name of the user
/// \return The added user
#[ic_cdk_macros::update]
async fn add_user(username: String) -> User {
   let query = String::from(r#"mutation ($username: String!) {
      createUser(input: {username: $username}) {
         id
         username
      }
   }"#);
   let params = format!(r#"{{"username": "{}"}}"#, username);
   let json_str = GraphQLCanister::graphql_mutation(
      query, params).await;
   let json_data : Value = serde_json::from_str(&json_str.0).unwrap();
   let user : User = serde_json::from_value(json_data["data"]["createUser"][0].clone()).unwrap();
   return user;
}

/// Getter for the user
/// \param[in] username The username of the user to find
/// \return The user with given username
#[ic_cdk_macros::query]
async fn get_user(username: String) -> User {
   let query = String::from(r#"query ($username: String!) {
      readUser(search: {username: {eq: $username}}) {
         id
         username
      }
   }"#);
   let params = format!(r#"{{"username": "{}"}}"#, username);
   let json_str = GraphQLCanister::graphql_query(
      query, params).await;
   let json_data : Value = serde_json::from_str(&json_str.0).unwrap();
   let user : User = serde_json::from_value(json_data["data"]["readUser"][0].clone()).unwrap();
   return user;
}

/// Getter for the users
/// \return The list of users
#[ic_cdk_macros::query]
async fn get_users() -> Vec<User> {
   let query = r#"query{
      readUser {
         id
         username
      }
   }"#.to_string();
   let params = format!(r#"{{}}"#);
   let json_str = GraphQLCanister::graphql_query(
      query, params).await;
   let json_data : Value = serde_json::from_str(&json_str.0).unwrap();
   let users : Vec<User> = serde_json::from_value(json_data["data"]["readUser"].clone()).unwrap();
   return users;
}

/// Add a question
/// \param[in] author_id The ID of the author
/// \param[in] text The text of the question to add
/// \return The added question
#[ic_cdk_macros::update]
async fn add_question(author_id: String, text: String) -> Question {
   let query = String::from(r#"mutation ($author_id: ID!, $text: String!) {
      createQuestion(input: {author: {connect: $author_id}, text: $text, interest: 0}) {
         id
         author {
            id
            username
         }
         text
         interest
      }
   }    
   "#);
   
   let params = format!(r#"{{
      "author_id": "{}",
      "text": "{}"
    }}"#, author_id, text);

   let json_str = GraphQLCanister::graphql_mutation(
      query, params).await;
   let json_data : Value = serde_json::from_str(&json_str.0).unwrap();
   let question : Question = serde_json::from_value(json_data["data"]["createQuestion"][0].clone()).unwrap();
   return question;
}

/// Getter for the question
/// \param[in] question_id The ID of the question to find
/// \return The question with given ID
#[ic_cdk_macros::query]
async fn get_question(question_id: String) -> Question {
   let query = String::from(r#"query ($question_id: ID!) {
      readQuestion(search: {id: {eq: $question_id}}) {
         id
         author {
            id
            username
         }
         text
         interest
      }
   }
   "#);
   let params = format!(r#"{{"question_id": "{}"}}"#, question_id);
   let json_str = GraphQLCanister::graphql_query(query, params).await;
   let json_data : Value = serde_json::from_str(&json_str.0).unwrap();
   let question : Question = serde_json::from_value(json_data["data"]["readQuestion"][0].clone()).unwrap();
   return question;
}

/// Getter for the questions
/// \return The list of questions
#[ic_cdk_macros::query]
async fn get_questions() -> Vec<Question> {
   let query = String::from(r#"query{
      readQuestion {
         id
         author {
            id
            username
         }
         text
         interest
      }
   }"#);
   let params = format!(r#"{{}}"#);
   let json_str = GraphQLCanister::graphql_query(query, params).await;
   let json_data : Value = serde_json::from_str(&json_str.0).unwrap();
   let questions : Vec<Question> = serde_json::from_value(json_data["data"]["readQuestion"].clone()).unwrap();
   return questions;
}