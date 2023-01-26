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

## Backlog

### DONE
- a user is automatically created on logging with II
- users can ask questions
- users can give interest on newly created questions
- most interesting questions get selected
- users can give their opinion on selected questions
- selected questions get archived after a while, opinion aggregate is saved
- users can vote to categorize questions that have just been archived
- categorization closes after a while, categorization aggregate is saved, users' convictions get updated

### TO DO
- update the 2D map with https://github.com/ZhenyaUsenko/motoko-hash-map/issues/3
- remove the Admin module and game createQuestions; find another way to create scenarios
- remove trieToArray function from canister, have a public type with an array for the votes and user convictions (make a new Convictions module)
- find out a new way to select the questions? what if no question to select, still update last_selection_date ?
- add tests (e.g. for convictions decay)

### NICE TO HAVE
- remove all usage of Trie, use Map instead

### FOR LATER
- add the main canister, be able to create sub-godwins
- implement the token (requires to find rules first)
- investigate the elastic search to be able to tag questions as duplicate

### IN THE FUTURE
 - add optional comment on voting on opinion and categorization, being able to upvote comments that
 - be able to follow users
 - add political parties (as an average of profiles of its members.)
 - add ranking (or title) based on participation