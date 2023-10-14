import CONSTANTS    from "../Constants"
import BitcoinToken from "./icons/BitcoinToken";

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
        <div className="w-4 h-4">
          <BitcoinToken/>
        </div>
        <span className="italic">This operation requires bitcoins.</span>
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
        <div className="w-4 h-4">
          <BitcoinToken/>
        </div>
        <span className="italic">This operation requires bitcoins.</span>
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
        <span>{" Your convictions profile will get updated everytime you give your opinion on a statement."}</span>
      </div>
    </div>
  )
}

export const HelpPositionDetails = () => {
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
        <div className="w-4 h-4">
          <BitcoinToken/>
        </div>
        <span className="italic">This operation requires bitcoins.</span>
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
        <span>{" When closed the results of the opinion and positioning votes are revealed."}</span>
      </div>
      <div> 
        <span>{ CONSTANTS.INFO_BULLET } </span>
        <span>{" You can still give your opinion on closed statements, but your vote won't be genuine nor count in the results."}</span>
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
        <span>{" While a statement is opened, you can give your genuine opinion on it and position it according to the sub's dimensions."}</span>
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
        <span>{" The statements voted the most legit get opened, the rest of them get rejected after a while."}</span>
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