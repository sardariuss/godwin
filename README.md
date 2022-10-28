# Godwin

## Introduction

People tend to be more divided than ever on political subjects. One individual's political view is often reduced to a left-right dichotomy and the subtilities of one opinion are ignored. Radical stances are often put at the forefront by the media and social networks in order to sell more. The bi-partisan democratic system and [imperfect votings systems](https://www.youtube.com/watch?v=tJag3vuG834) lead to individuals voting against a candidate perceived as the greatest evil, rather than voting for a candidate they adhere to.

Some [tools](https://www.reddit.com/r/PoliticalCompass/) do exist to give to individuals a more accurate representation of their opinion. But they have some limitations:
 - the questions and categorizations are made by a centralized group of individuals
 - questions can be old, not apply to where i live, or poorly categorized

## Concept: make a decentralized 8 values
 - users ask questions, most popular gets open to vote
 - people vote on the question (agree or disagree)
 - then the question gets categorized by the community
 - once categorized, users' profiles gets updated accordingly
 - branding: famous politicians pictures and quotes for profile

## Roadmap:

### V0.1
DONE:
- questions can pass into 3 selection stages: created, selected, archived
- users can ask new questions
- users can upvote/downvote new questions
- users can vote on selected questions
- users can categorize archived questions
- user profiles get updated after a question is categorized
- question status gets updated according to the rules
BACKEND TODO:
 - being able to change scheduler parameters as admin
 - being able to change categories definitions as admin
 - add user categorization neutral bar
 - order question by hotness
 - make user name unique
 - run scheduler via heartbeat
TO THINK:
- add user "boldness" indicator, or just a boolean slider for if question has been answered blindly or not ?
- should we allow to modify the vote on a question ? yes but it can change your "boldness" depending on question status

LATER:
 - add sensitive vote to hide sensitive questions
 - add duplicate vote to mark questions as duplicate

### V0.2: DAO and tokenization
- implement SNS, use its DAO instead of an admin
- people can lock the token, and get rewarded when:
  - their question(s) gets open
  - they vote
  - they categorize questions (by DAO users only)
- launch ICO

### v0.3: Beautifying and NFTs
 - create NFTs of avatars/quotes of politicians
 - pre-mint them
 - be able to rare NFTs vs tokens

### Later
 - add decay so the older the question (or the vote?) the less change on the user profile
 - add possibility to comment questions (ordered by upvote, like reddit)
 - be able to follow users
 - add political parties (as an average of profiles of its members.)
 - add ranking (or title) based on participation
 - improve profile visualization
 - per country platform + translations
 - add ads
 - think about political sub-categories
 - find finer voting scheme for categorization of questions
 - dashboard of people's opinion on questions, indicators
 - proof of humanity