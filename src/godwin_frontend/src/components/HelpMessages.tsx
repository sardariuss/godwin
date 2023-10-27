import CONSTANTS from "../Constants"

type HelpProposeDetailsInput = {
  max_num_characters: bigint
}

export const HelpProposeDetails = ({max_num_characters} : HelpProposeDetailsInput) => {
  return (
    <div className="flex flex-col text-sm text-black dark:text-white px-5 py-1 border-b dark:border-gray-700 bg-slate-100 dark:bg-slate-800">
      <div>
        <span>{ CONSTANTS.INSTRUCTION_BULLET } </span>
        <span>{" Write a statement, not a question."}</span>
      </div>
      <div>
        <span>{ CONSTANTS.INSTRUCTION_BULLET } </span>
        <span>{" " + max_num_characters.toString() + " characters maximum."}</span>
      </div>
      <div>
        <span>{ CONSTANTS.INSTRUCTION_BULLET } </span>
        <span>{" Try to avoid negation."}</span>
      </div>
      <div> 
        <span>{ CONSTANTS.INFO_BULLET } </span>
        <span>{" Only the most interesting statements get opened to vote."}</span>
      </div>
      <div className="flex flex-row space-x-1 items-center"> 
        <img src="token_ball.png" alt="single_ball" className="h-5"></img>
        <span className="italic">This operation requires balls.</span>
      </div>
    </div>
  )
}

export const HelpSelectDetails = () => {
  return (
    <div className="flex flex-col text-sm text-black dark:text-white px-5 py-1 border-b dark:border-gray-700 bg-slate-100 dark:bg-slate-800">
      <div> 
        <span>{ CONSTANTS.INSTRUCTION_BULLET } </span>
        <span>{" Pick "}</span>
        <span className="text-blue-700 dark:text-blue-300">{CONSTANTS.INTEREST_INFO.up.name}</span>
        <span>{CONSTANTS.INTEREST_INFO.up.symbol}</span>
        <span>{" if you think the statement is interesting enough to open a vote."}</span>
      </div>
      <div> 
        <span>{ CONSTANTS.INSTRUCTION_BULLET } </span>
        <span>{" Pick "}</span>
        <span className="text-blue-700 dark:text-blue-300">{CONSTANTS.INTEREST_INFO.down.name}</span>
        <span>{CONSTANTS.INTEREST_INFO.down.symbol}</span>
        <span>{" if you think the statement is off topic or way too obvious."}</span>
      </div>
      <div> 
        <span>{ CONSTANTS.INSTRUCTION_BULLET } </span>
        <span>{" Let it on "}</span>
        <span className="text-blue-700 dark:text-blue-300">{CONSTANTS.INTEREST_INFO.neutral.name}</span>
        <span>{CONSTANTS.INTEREST_INFO.neutral.symbol}</span>
        <span>{" if neither apply."}</span>
      </div>
      <div> 
        <span>{ CONSTANTS.INFO_BULLET } </span>
        <span>{" Only the most interesting statements get opened to vote."}</span>
      </div>
      <div className="flex flex-row space-x-1 items-center"> 
        <img src="token_ball.png" alt="single_ball" className="h-5"></img>
        <span className="italic">This operation requires balls.</span>
      </div>
    </div>
  )
}

export const HelpVoteDetails = () => {
  return (
    <div className="flex flex-col text-sm text-black dark:text-white px-5 py-1 border-b dark:border-gray-700 bg-slate-100 dark:bg-slate-800">
      <div> 
        { CONSTANTS.INSTRUCTION_BULLET + " " }
        <span className="text-blue-700 dark:text-blue-300">{CONSTANTS.OPINION_INFO.right.name}</span>
        {CONSTANTS.OPINION_INFO.right.symbol}
        {" or "}
        <span className="text-blue-700 dark:text-blue-300">{CONSTANTS.OPINION_INFO.left.name}</span>
        {CONSTANTS.OPINION_INFO.left.symbol}
        {" on each statement by sliding the cursor right or left."}
      </div>
      <div> 
        { CONSTANTS.INFO_BULLET }
        <span>{" The closer the cursor is to one side, the more convinced you are."}</span>
      </div>
      <div> 
        { CONSTANTS.INFO_BULLET }
        <span>{" Your profile gets updated more precisely with every vote."}</span>
      </div>
    </div>
  )
}

export const HelpMapDetails = () => {
  return (
    <div className="flex flex-col text-sm text-black dark:text-white px-5 py-1 border-b dark:border-gray-700 bg-slate-100 dark:bg-slate-800">
      <div> 
        <span>{ CONSTANTS.INSTRUCTION_BULLET } </span>
        <span>{" For each dimension, do people who agree with this statement belong more to the left or to the right category?"}</span>
      </div>
      <div> 
        <span>{ CONSTANTS.INFO_BULLET } </span>
        <span>{" The closer the cursor is to one side, the more agreeing with the statement shifts voters' profile to that side."}</span>
      </div>
      <div> 
        <span>{ CONSTANTS.INFO_BULLET } </span>
        <span>{" It is possible that none of the categories apply."}</span>
      </div>
      <div className="flex flex-row space-x-1 items-center"> 
        <img src="token_ball.png" alt="single_ball" className="h-5"></img>
        <span className="italic">This operation requires balls.</span>
      </div>
    </div>
  )
}

export const HelpArchivedDetails = () => {
  return (
    <div className="flex flex-col text-sm text-black dark:text-white px-5 py-1 border-b dark:border-gray-700 bg-slate-100 dark:bg-slate-800">
      <div> 
        <span>{ CONSTANTS.INFO_BULLET } </span>
        <span>{" The archived tab gathers all the statements that have been closed."}</span>
      </div>
      <div> 
        <span>{ CONSTANTS.INFO_BULLET } </span>
        <span>{" When closed the results of the vote and mapping are revealed."}</span>
      </div>
      <div> 
        <span>{ CONSTANTS.INFO_BULLET } </span>
        <span>{" You can still vote on closed statements but it won't count as genuine."}</span>
      </div>
      <div> 
        <span>{ CONSTANTS.INFO_BULLET } </span>
        <span>{" You can try to reopen a closed statement for a reduced price."}</span>
      </div>
    </div>
  )
}

export const HelpOpenDetails = () => {
  return (
    <div className="flex flex-col text-sm text-black dark:text-white px-5 py-1 border-b dark:border-gray-700 bg-slate-100 dark:bg-slate-800">
      <div> 
        <span>{ CONSTANTS.INFO_BULLET } </span>
        <span>{" The open tab gathers all the currently opened statements."}</span>
      </div>
      <div> 
        <span>{ CONSTANTS.INFO_BULLET } </span>
        <span>{" While a statement is opened, you can vote on it and map it in the sub's space."}</span>
      </div>
    </div>
  )
}

export const HelpCandidateDetails = () => {
  return (
    <div className="flex flex-col text-sm text-black dark:text-white px-5 py-1 border-b dark:border-gray-700 bg-slate-100 dark:bg-slate-800">
      <div> 
        <span>{ CONSTANTS.INFO_BULLET } </span>
        <span>{" The candidate tab gathers all the recently proposed statements."}</span>
      </div>
      <div> 
        <span>{ CONSTANTS.INFO_BULLET } </span>
        <span>{" The most legit get opened, the rest of them get rejected after a while."}</span>
      </div>
    </div>
  )
}

export const HelpRejectedDetails = () => {
  return (
    <div className="flex flex-col text-sm text-black dark:text-white px-5 py-1 border-b dark:border-gray-700 bg-slate-100 dark:bg-slate-800">
      <div> 
        <span>{ CONSTANTS.INFO_BULLET } </span>
        <span>{" The rejected tab gathers all the statements that haven't been selected."}</span>
      </div>
      <div> 
        <span>{ CONSTANTS.INFO_BULLET } </span>
        <span>{" You can try to open a timed-out statement again for a reduced price."}</span>
      </div>
      <div> 
        <span>{ CONSTANTS.INFO_BULLET } </span>
        <span>{" Rejected statements get deleted after a while."}</span>
      </div>
    </div>
  )
}