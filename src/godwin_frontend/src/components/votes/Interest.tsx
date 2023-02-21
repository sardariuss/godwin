import { ActorContext } from "../../ActorContext"

import { useContext } from "react";

type Props = {
  question_id: bigint;
};

// @todo: change the state of the buttons based on the interest for the logged user for this question
// @todo: putInterestBallot on click
const VoteInterest = ({question_id}: Props) => {

	const {actor, isAuthenticated} = useContext(ActorContext);

	const upVote = async () => {
    // 🤔 🧠 
		console.log("upVote");
		let up_vote = await actor.putInterestBallot(question_id, { 'UP' : null } );
		console.log(up_vote);
	};

	const downVote = async () => {
		console.log("downVote");
    let down_vote = await actor.putInterestBallot(question_id, { 'DOWN' : null });
		console.log(down_vote);
	};

  const duplicateVote = async () => {
		console.log("duplicateVote");
    // @todo
	};

	return (
    <div className="flex flex-col gap-y-2 w-full justify-center">
      <ul className="flex flew-row w-full justify-center">
        <li>
          <input type="radio" id={"interest-up" + + question_id.toString() } name={"interest" + question_id.toString() } value="interest-up" className="hidden peer" required/>
          <label htmlFor={ "interest-up" + question_id.toString() } className="grow-0 flex-0 items-center p-1 bg-white rounded-2xl cursor-pointer dark:hover:text-2xl peer-checked:text-3xl peer-checked:bg-gray-100 dark:peer-checked:bg-gray-700 dark:bg-gray-800">
          🤓
          </label>
        </li>
        <li>
          <input type="radio" id={"interest-down" + + question_id.toString() } name={"interest" + question_id.toString() } value="interest-down" className="hidden peer"/>
          <label htmlFor={ "interest-down" + question_id.toString() } className="grow-0 flex-0 items-center p-1 bg-white rounded-2xl cursor-pointer dark:hover:text-2xl peer-checked:text-3xl peer-checked:bg-gray-100 dark:peer-checked:bg-gray-700 dark:bg-gray-800">
          🤡
          </label>
        </li>
        <li>
          <input type="radio" id={"duplicate" + + question_id.toString() } name={"interest" + question_id.toString() } value="duplicate" className="hidden peer"/>
          <label htmlFor={ "duplicate" + question_id.toString() } className="grow-0 flex-0 items-center p-1 bg-white rounded-2xl cursor-pointer dark:hover:text-2xl peer-checked:text-3xl peer-checked:bg-gray-100 dark:peer-checked:bg-gray-700 dark:bg-gray-800">
          👀
          </label>
        </li>
      </ul>
      <button type="button" className="text-gray-900 text-center items-center bg-white hover:bg-gray-100 border border-gray-200 focus:ring-4 focus:outline-none focus:ring-gray-100 font-medium rounded-lg text-sm dark:focus:ring-gray-600 dark:bg-gray-800 dark:border-gray-700 dark:text-white dark:hover:bg-gray-700 mr-2 mb-2">
        💰 Vote
      </button>
    </div>
	);
};

export default VoteInterest;
