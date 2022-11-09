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
- users can endorse newly created questions
- most endorsed questions get selected
- users can give their opinion on selected questions
- selected questions get archived after a while, opinion aggregate is saved
- admin can vote to categorize questions that have just been archived
- categorization closes after a while, categorization aggregate is saved, users' convictions get updated

### TO DO
- a user shall be able to set a username, which is unique among all users.
- order created questions by hotness (for front-end).
- users have another convictions' profile offline profile, which is update when answering on archived questions.
- admin shall be able to add/remove/replace categories
- replace endorsements (upvotes) by cursor where right=upvote, left=censor
- add public getters to get created/selected/archived questions. For selected questions, the getter automatically set the user's opinion to center for every selected question if no vote yet. 

### TO THINK
- shall categorization and selection happen at the same time ?
- add lifetime to a question. when lifetime is over, question is removed. censoring/upvoting can add lifetime to the question, but if censoring > upvoting, lifetime goes to 0.
- reward/penalize users with tokens.
- categorization shall be made by randomly picked users, where 

### FOR LATER
- being able to tag questions as duplicate
- add decay on vote, so the older the question (or the vote?) the less change on user profile
- add optional comment on voting on opinion and categorization, being able to upvote comments that

### IN THE FUTURE
 - be able to follow users
 - add political parties (as an average of profiles of its members.)
 - add ranking (or title) based on participation
 - per country platform + translations