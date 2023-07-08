## Test Coverage

| canister | module | test | left to do | complete |
| ------ | ------ | ------ | ------ | ------ |
| GodwinSub | Questions.mo | testQuestions.mo | N/A | ?% |


PayRules (requires updates on payrules design)
  - getters
  - compute a few payouts

Model 
  - getters (low interest)

Factory
  - correctly build the model based on input params (low interest)

Categories
  - N/A

Controller
  - getName : getName
  - getHalfLife
  - getSelectionScore
  - getCategories
  - addCategory
  - removeCategory
  - getSchedulerParameters
  - setSchedulerParameters
  - searchQuestions
  - getQuestion
  - openQuestion
  - reopenQuestion
  - getInterestBallot
  - putInterestBallot
  - getOpinionBallot
  - putOpinionBallot
  - getCategorizationBallot
  - putCategorizationBallot
  - getStatusHistory
  - revealInterestVote
  - revealOpinionVote
  - revealCategorizationVote
  - findInterestVoteId
  - findOpinionVoteId
  - findCategorizationVoteId
  - getQuestionIteration
  - queryQuestions
  - queryQuestionsFromAuthor
  - queryFreshVotes
  - queryInterestBallots
  - queryOpinionBallots
  - queryCategorizationBallots
  - getVoterConvictions
  - run
